import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument_sterilization.dart';
import '../models/preference_card.dart';
import '../models/tray.dart';
import 'connectivity_service.dart';
import 'group_document_service.dart';
import 'preference_card_service.dart';
import 'sterilization_service.dart';
import 'tray_service.dart';

/// EPIC 7 / ADR-003: los nombres de valores existentes ('submitForReview')
/// no se tocan -- son el `type` persistido de operaciones ya en cola en
/// dispositivos reales, y renombrarlos las dejaría sin poder deserializarse.
enum SyncOperationType {
  createGroupDocument,
  saveGroupDocumentDraft,
  submitForReview,
  createTray,
  saveTrayDraft,
  submitTrayForReview,
  createPreferenceCard,
  savePreferenceCardDraft,
  submitPreferenceCardForReview,
  saveSterilizationMethodDraft,
  submitSterilizationMethodForReview,
  saveTechnicalInfoDraft,
  submitTechnicalInfoForReview,
}

class PendingSyncOperation {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingSyncOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere((t) => t.name == json['type']),
      payload: (json['payload'] as Map).cast<String, dynamic>(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Registro de una operación en cola que se descartó por un error de
/// negocio (permisos, validación...) en vez de un error de red. Se muestra
/// a la persona para que sepa que ese cambio concreto NO llegó a subirse.
class SyncFailure {
  final String description;
  final String error;
  final DateTime occurredAt;

  SyncFailure({required this.description, required this.error, required this.occurredAt});
}

/// Cola FIFO de operaciones de escritura hechas sin conexión. Persiste en
/// `shared_preferences` (clave `pending_sync_queue`) para sobrevivir a que se
/// cierre la app, y se vacía sola en cuanto [ConnectivityService] detecta que
/// ha vuelto la red.
///
/// No duplica la lógica de red: al reintentar, llama a los mismos métodos de
/// servicio que se usarían online.
///
/// ADR-003 (`docs/ADR_003_OFFLINE_STRATEGY.md`) fija el principio que
/// gobierna qué entra aquí: abrir un borrador nuevo desde cero (`startEditing`
/// para bandejas/tarjetas/esterilización, `create*` de esterilización/ficha
/// técnica) exige conexión -- son puntos de coordinación con el servidor
/// (reservar número de versión, decidir doble autoría global/organización).
/// Continuar editando un borrador ya abierto (`saveDraft`/`submitForReview`)
/// sí puede encolarse. `createDocument`/`createTray`/`createCard` son la
/// única excepción histórica: crean un documento/bandeja/tarjeta VACÍOS
/// (sin depender de ningún estado previo), así que no hay nada que
/// coordinar -- por eso ya tenían ruta offline antes de este ADR, y EPIC 7
/// se limita a extender ese mismo criterio a bandejas y tarjetas.
class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  static const _key = 'pending_sync_queue';

  final List<PendingSyncOperation> _queue = [];
  final ValueNotifier<List<SyncFailure>> failures = ValueNotifier([]);
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// Entidades creadas offline (id local -> id real) descubierto en cuanto la
  /// operación de creación consigue ejecutarse de verdad, para poder
  /// reescribir operaciones posteriores de la misma sesión de cola que
  /// todavía se refieran al id local (p.ej. enviar a revisión el borrador que
  /// se acaba de crear).
  final Map<String, String> _resolvedVersionIds = {};

  bool _processing = false;
  SharedPreferences? _prefs;

  int get pendingLength => _queue.length;

  bool isPendingLocalId(String id) => id.startsWith('local_');

  String newLocalId() => 'local_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _queue.addAll(list.map((e) => PendingSyncOperation.fromJson((e as Map).cast<String, dynamic>())));
    }
    pendingCount.value = _queue.length;
    ConnectivityService.instance.isOnline.addListener(() {
      if (ConnectivityService.instance.isOnline.value) processQueue();
    });
    if (ConnectivityService.instance.isOnline.value) processQueue();
  }

  Future<void> _persist() async {
    await _prefs?.setString(_key, jsonEncode(_queue.map((o) => o.toJson()).toList()));
    pendingCount.value = _queue.length;
  }

  Future<void> _enqueue(SyncOperationType type, Map<String, dynamic> payload) async {
    _queue.add(PendingSyncOperation(
      id: newLocalId(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    ));
    await _persist();
  }

  // --- Encolar operaciones (llamado desde los servicios cuando están offline) ---

  Future<GroupDocumentVersion> queueCreateDocument(DocumentKind kind, String workspaceId) async {
    final localId = newLocalId();
    await _enqueue(SyncOperationType.createGroupDocument, {
      'kind': kind.dbValue,
      'workspaceId': workspaceId,
      'localVersionId': localId,
    });
    return GroupDocumentVersion(
      id: localId,
      documentId: localId,
      versionNumber: 1,
      status: GroupDocumentVersionStatus.draft,
      title: '',
      pendingSync: true,
    );
  }

  Future<GroupDocumentVersion> queueSaveDraft(GroupDocumentVersion version) async {
    await _enqueue(SyncOperationType.saveGroupDocumentDraft, {
      'versionId': version.id,
      'versionRow': version.toRow(),
    });
    return version.copyWith(pendingSync: true);
  }

  Future<void> queueSubmitForReview(String versionId) async {
    await _enqueue(SyncOperationType.submitForReview, {'versionId': versionId});
  }

  Future<TrayVersion> queueCreateTray(String workspaceId) async {
    final localId = newLocalId();
    await _enqueue(SyncOperationType.createTray, {
      'workspaceId': workspaceId,
      'localVersionId': localId,
    });
    return TrayVersion(
      id: localId,
      trayId: localId,
      versionNumber: 1,
      status: GroupDocumentVersionStatus.draft,
      name: '',
      pendingSync: true,
    );
  }

  Future<TrayVersion> queueSaveTrayDraft(TrayVersion version) async {
    await _enqueue(SyncOperationType.saveTrayDraft, {
      'versionId': version.id,
      'versionRow': version.toRow(),
    });
    return version.copyWith(pendingSync: true);
  }

  Future<void> queueSubmitTrayForReview(String versionId) async {
    await _enqueue(SyncOperationType.submitTrayForReview, {'versionId': versionId});
  }

  Future<PreferenceCardVersion> queueCreatePreferenceCard(String workspaceId) async {
    final localId = newLocalId();
    await _enqueue(SyncOperationType.createPreferenceCard, {
      'workspaceId': workspaceId,
      'localVersionId': localId,
    });
    return PreferenceCardVersion(
      id: localId,
      cardId: localId,
      versionNumber: 1,
      status: GroupDocumentVersionStatus.draft,
      procedureName: '',
      pendingSync: true,
    );
  }

  Future<PreferenceCardVersion> queueSavePreferenceCardDraft(PreferenceCardVersion version) async {
    await _enqueue(SyncOperationType.savePreferenceCardDraft, {
      'versionId': version.id,
      'versionRow': version.toRow(),
    });
    return version.copyWith(pendingSync: true);
  }

  Future<void> queueSubmitPreferenceCardForReview(String versionId) async {
    await _enqueue(SyncOperationType.submitPreferenceCardForReview, {'versionId': versionId});
  }

  Future<SterilizationMethodVersion> queueSaveSterilizationMethodDraft(SterilizationMethodVersion version) async {
    await _enqueue(SyncOperationType.saveSterilizationMethodDraft, {
      'versionId': version.id,
      'versionRow': version.toRow(),
    });
    return version.copyWith(pendingSync: true);
  }

  Future<void> queueSubmitSterilizationMethodForReview(String versionId) async {
    await _enqueue(SyncOperationType.submitSterilizationMethodForReview, {'versionId': versionId});
  }

  Future<InstrumentTechnicalInfoVersion> queueSaveTechnicalInfoDraft(InstrumentTechnicalInfoVersion version) async {
    await _enqueue(SyncOperationType.saveTechnicalInfoDraft, {
      'versionId': version.id,
      'versionRow': version.toRow(),
    });
    return version.copyWith(pendingSync: true);
  }

  Future<void> queueSubmitTechnicalInfoForReview(String versionId) async {
    await _enqueue(SyncOperationType.submitTechnicalInfoForReview, {'versionId': versionId});
  }

  // --- Procesar la cola ---

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final op = _queue.first;
        try {
          await _run(op);
          _queue.removeAt(0);
          await _persist();
        } catch (e) {
          if (ConnectivityService.isNetworkError(e)) {
            // Seguimos sin red de verdad (o Supabase inalcanzable): dejamos la
            // operación en cabeza de la cola y paramos, para no desordenar el FIFO.
            break;
          }
          // Error de negocio: se descarta y se registra para avisar a la persona.
          _queue.removeAt(0);
          await _persist();
          failures.value = [
            ...failures.value,
            SyncFailure(
              description: _describe(op),
              error: e.toString(),
              occurredAt: DateTime.now(),
            ),
          ];
        }
      }
    } finally {
      _processing = false;
    }
  }

  /// Descarta un [SyncFailure] concreto del panel de avisos (no reintenta la
  /// operación -- ya se descartó de la cola cuando falló por error de
  /// negocio, ver [processQueue]). Usado por `sync_issues_screen.dart`.
  void dismiss(SyncFailure f) {
    failures.value = [...failures.value]..remove(f);
  }

  /// Vacía todo el panel de avisos de golpe.
  void clearAll() {
    failures.value = [];
  }

  String _describe(PendingSyncOperation op) {
    switch (op.type) {
      case SyncOperationType.createGroupDocument:
        return 'Crear documento (${op.payload['kind']})';
      case SyncOperationType.saveGroupDocumentDraft:
        return 'Guardar borrador de documento ${op.payload['versionId']}';
      case SyncOperationType.submitForReview:
        return 'Enviar a revisión documento ${op.payload['versionId']}';
      case SyncOperationType.createTray:
        return 'Crear bandeja';
      case SyncOperationType.saveTrayDraft:
        return 'Guardar borrador de bandeja ${op.payload['versionId']}';
      case SyncOperationType.submitTrayForReview:
        return 'Enviar a revisión bandeja ${op.payload['versionId']}';
      case SyncOperationType.createPreferenceCard:
        return 'Crear tarjeta de preferencia';
      case SyncOperationType.savePreferenceCardDraft:
        return 'Guardar borrador de tarjeta ${op.payload['versionId']}';
      case SyncOperationType.submitPreferenceCardForReview:
        return 'Enviar a revisión tarjeta ${op.payload['versionId']}';
      case SyncOperationType.saveSterilizationMethodDraft:
        return 'Guardar borrador de esterilización ${op.payload['versionId']}';
      case SyncOperationType.submitSterilizationMethodForReview:
        return 'Enviar a revisión método de esterilización ${op.payload['versionId']}';
      case SyncOperationType.saveTechnicalInfoDraft:
        return 'Guardar borrador de ficha técnica ${op.payload['versionId']}';
      case SyncOperationType.submitTechnicalInfoForReview:
        return 'Enviar a revisión ficha técnica ${op.payload['versionId']}';
    }
  }

  String _resolve(String maybeLocalId) => _resolvedVersionIds[maybeLocalId] ?? maybeLocalId;

  Future<void> _run(PendingSyncOperation op) async {
    switch (op.type) {
      case SyncOperationType.createGroupDocument:
        final kind = DocumentKindLabel.fromDb(op.payload['kind'] as String);
        final workspaceId = op.payload['workspaceId'] as String;
        final localVersionId = op.payload['localVersionId'] as String;
        final created = await GroupDocumentService.instance.createDocument(kind, workspaceId);
        _resolvedVersionIds[localVersionId] = created.id;
        break;
      case SyncOperationType.saveGroupDocumentDraft:
        final versionId = _resolve(op.payload['versionId'] as String);
        final row = (op.payload['versionRow'] as Map).cast<String, dynamic>();
        // saveDraft solo usa version.id + version.toRow() internamente, así
        // que basta con reconstruir un objeto con el id ya resuelto.
        final version = GroupDocumentVersion(
          id: versionId,
          documentId: '',
          versionNumber: 0,
          status: GroupDocumentVersionStatus.draft,
          title: row['title'] as String? ?? '',
          specialty: row['specialty'] as String?,
          content: row['content'] as String?,
          steps: (row['steps'] as List<dynamic>? ?? []).map(ProtocolStep.fromDynamic).toList(),
          relatedInstrumentIds:
              (row['related_instrument_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
          relatedTrayIds: (row['related_tray_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
          comment: row['comment'] as String?,
        );
        await GroupDocumentService.instance.saveDraft(version);
        break;
      case SyncOperationType.submitForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await GroupDocumentService.instance.submitForReview(versionId);
        break;
      case SyncOperationType.createTray:
        final workspaceId = op.payload['workspaceId'] as String;
        final localVersionId = op.payload['localVersionId'] as String;
        final created = await TrayService.instance.createTray(workspaceId);
        _resolvedVersionIds[localVersionId] = created.id;
        break;
      case SyncOperationType.saveTrayDraft:
        final versionId = _resolve(op.payload['versionId'] as String);
        final row = (op.payload['versionRow'] as Map).cast<String, dynamic>();
        final version = TrayVersion(
          id: versionId,
          trayId: '',
          versionNumber: 0,
          status: GroupDocumentVersionStatus.draft,
          name: row['name'] as String? ?? '',
          specialtyId: row['specialty_id'] as String?,
          description: row['description'] as String?,
          photoPaths: (row['photo_paths'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
          items: (row['items'] as List<dynamic>? ?? [])
              .map((e) => TrayItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
          observations: row['observations'] as String?,
          comment: row['comment'] as String?,
        );
        await TrayService.instance.saveDraft(version);
        break;
      case SyncOperationType.submitTrayForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await TrayService.instance.submitForReview(versionId);
        break;
      case SyncOperationType.createPreferenceCard:
        final workspaceId = op.payload['workspaceId'] as String;
        final localVersionId = op.payload['localVersionId'] as String;
        final created = await PreferenceCardService.instance.createCard(workspaceId);
        _resolvedVersionIds[localVersionId] = created.id;
        break;
      case SyncOperationType.savePreferenceCardDraft:
        final versionId = _resolve(op.payload['versionId'] as String);
        final row = (op.payload['versionRow'] as Map).cast<String, dynamic>();
        final version = PreferenceCardVersion(
          id: versionId,
          cardId: '',
          versionNumber: 0,
          status: GroupDocumentVersionStatus.draft,
          surgeonId: row['surgeon_id'] as String?,
          procedureName: row['procedure_name'] as String? ?? '',
          items: (row['items'] as List<dynamic>? ?? [])
              .map((e) => PreferenceCardItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
          generalNotes: row['general_notes'] as String?,
          validatedBySurgeon: row['validated_by_surgeon'] as bool? ?? false,
          comment: row['comment'] as String?,
        );
        await PreferenceCardService.instance.saveDraft(version);
        break;
      case SyncOperationType.submitPreferenceCardForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await PreferenceCardService.instance.submitForReview(versionId);
        break;
      case SyncOperationType.saveSterilizationMethodDraft:
        final versionId = _resolve(op.payload['versionId'] as String);
        final row = (op.payload['versionRow'] as Map).cast<String, dynamic>();
        final version = SterilizationMethodVersion(
          id: versionId,
          methodId: '',
          versionNumber: 0,
          status: GroupDocumentVersionStatus.draft,
          method: SterilizationMethodLabel.fromDb(row['method'] as String),
          temperature: row['temperature'] as String?,
          timeMinutes: row['time_minutes'] as String?,
          pressure: row['pressure'] as String?,
          drying: row['drying'] as String?,
          recommendedCycle: row['recommended_cycle'] as String?,
          compatibilityNotes: row['compatibility_notes'] as String?,
          restrictions: row['restrictions'] as String?,
          observations: row['observations'] as String?,
          lubricationRequired: row['lubrication_required'] as bool? ?? false,
          lubricationType: row['lubrication_type'] as String?,
          lubricationNotes: row['lubrication_notes'] as String?,
          comment: row['comment'] as String?,
        );
        await SterilizationService.instance.saveMethodDraft(version);
        break;
      case SyncOperationType.submitSterilizationMethodForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await SterilizationService.instance.submitMethodVersionForReview(versionId);
        break;
      case SyncOperationType.saveTechnicalInfoDraft:
        final versionId = _resolve(op.payload['versionId'] as String);
        final row = (op.payload['versionRow'] as Map).cast<String, dynamic>();
        final version = InstrumentTechnicalInfoVersion(
          id: versionId,
          infoId: '',
          versionNumber: 0,
          status: GroupDocumentVersionStatus.draft,
          manufacturerId: row['manufacturer_id'] as String?,
          ifuDocumentId: row['ifu_document_id'] as String?,
          maintenanceNotes: row['maintenance_notes'] as String?,
          inspectionNotes: row['inspection_notes'] as String?,
          usefulLifeNotes: row['useful_life_notes'] as String?,
          maintenanceIntervalDays: row['maintenance_interval_days'] as int?,
          lastMaintenanceAt:
              row['last_maintenance_at'] != null ? DateTime.tryParse(row['last_maintenance_at'] as String) : null,
          comment: row['comment'] as String?,
        );
        await SterilizationService.instance.saveTechnicalInfoDraft(version);
        break;
      case SyncOperationType.submitTechnicalInfoForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await SterilizationService.instance.submitTechnicalInfoVersionForReview(versionId);
        break;
    }
  }
}
