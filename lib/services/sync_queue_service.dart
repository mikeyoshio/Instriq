import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import 'connectivity_service.dart';
import 'group_document_service.dart';

enum SyncOperationType { createGroupDocument, saveGroupDocumentDraft, submitForReview }

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

/// Cola FIFO de operaciones de escritura (crear/editar técnicas y
/// protocolos, enviar a revisión) hechas sin conexión. Persiste en
/// `shared_preferences` (clave `pending_sync_queue`) para sobrevivir a que se
/// cierre la app, y se vacía sola en cuanto [ConnectivityService] detecta que
/// ha vuelto la red.
///
/// No duplica la lógica de red: al reintentar, llama a los mismos métodos de
/// [GroupDocumentService] que se usarían online.
///
/// Las tarjetas de preferencia (`upsertPreferenceCard`) ya no pasan por esta
/// cola: con el modelo de versiones (Fase E, ver
/// supabase/schema_v22_preference_card_versioning.sql) editar una tarjeta ya
/// no es un simple upsert de fila, sino crear/guardar una versión borrador —
/// mismo motivo por el que [TrayService] tampoco usa esta cola. Regresión
/// conocida: la edición offline de tarjetas de preferencia que existía antes
/// de esta migración ya no está disponible.
class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  static const _key = 'pending_sync_queue';

  final List<PendingSyncOperation> _queue = [];
  final ValueNotifier<List<SyncFailure>> failures = ValueNotifier([]);
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// Documentos creados offline (id local -> id real) descubierto en cuanto
  /// [GroupDocumentService.createDocument] consigue ejecutarse de verdad, para
  /// poder reescribir operaciones posteriores de la misma sesión de cola que
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

  String _describe(PendingSyncOperation op) {
    switch (op.type) {
      case SyncOperationType.createGroupDocument:
        return 'Crear documento (${op.payload['kind']})';
      case SyncOperationType.saveGroupDocumentDraft:
        return 'Guardar borrador ${op.payload['versionId']}';
      case SyncOperationType.submitForReview:
        return 'Enviar a revisión ${op.payload['versionId']}';
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
          comment: row['comment'] as String?,
        );
        await GroupDocumentService.instance.saveDraft(version);
        break;
      case SyncOperationType.submitForReview:
        final versionId = _resolve(op.payload['versionId'] as String);
        await GroupDocumentService.instance.submitForReview(versionId);
        break;
    }
  }
}
