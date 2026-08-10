import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document_version.dart';
import '../models/instrument_sterilization.dart';
import 'auth_service.dart';

/// CRUD y workflow (borrador -> en revisión -> publicada -> archivada) de
/// métodos de esterilización y ficha técnica de un instrumento (catálogo
/// global o instrumento personalizado). Ver
/// supabase/schema_v32_cssd_workspace.sql para el modelo y RLS — capçalera+
/// versions, mismo patrón que [PreferenceCardService]/[TrayService], pero
/// SIN pasar por `PublicVersionedContentService` (pensada solo para
/// Biblioteca Pública): aquí un contenido puede ser tanto global (lo aprueba
/// el Editorial Board, `my_is_reviewer_or_above()`) como de organización (lo
/// aprueba `approver`/`administrator` del espacio), y esa doble autoridad la
/// resuelven las RPCs de Supabase, no el cliente.
class SterilizationService {
  SterilizationService._();
  static final SterilizationService instance = SterilizationService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _publishedJoin = '*, published_version:published_version_id(*)';

  // ============================================================
  // Lectura
  // ============================================================

  /// Cabeceras de método de esterilización de un instrumento, con su versión
  /// publicada resuelta en [SterilizationMethodEntry.publishedVersion] (join,
  /// mismo patrón que [TrayService.fetchTray]). Un mismo instrumento puede
  /// tener varias cabeceras (una por método posible: vapor, plasma...).
  Future<List<SterilizationMethodEntry>> fetchMethods(String refType, String refId) async {
    final rows = await _client
        .from('instrument_sterilization_methods')
        .select(_publishedJoin)
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId);
    final entries =
        (rows as List<dynamic>).map((r) => SterilizationMethodEntry.fromRow(r as Map<String, dynamic>)).toList();
    entries.sort((a, b) => (a.publishedVersion?.method.dbValue ?? '').compareTo(b.publishedVersion?.method.dbValue ?? ''));
    return entries;
  }

  Future<InstrumentTechnicalInfo?> fetchTechnicalInfo(String refType, String refId) async {
    final row = await _client
        .from('instrument_technical_info')
        .select(_publishedJoin)
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .maybeSingle();
    if (row == null) return null;
    return InstrumentTechnicalInfo.fromRow(row);
  }

  /// Todos los métodos de esterilización PUBLICADOS del catálogo global,
  /// agrupados por instrumento — para poder buscar instrumentos por método
  /// (p.ej. "Autoclau"/"Plasma") en Inicio sin una consulta por instrumento
  /// (EPIC 5 · Smart Search). Cabeceras sin versión publicada (borradores
  /// pendientes de aprobación) no aparecen, igual que en el resto de la app.
  Future<Map<String, List<SterilizationMethod>>> fetchAllCatalogMethods() async {
    final rows = await _client
        .from('instrument_sterilization_methods')
        .select('instrument_ref_id, published_version:published_version_id(method)')
        .eq('instrument_ref_type', 'catalog');
    final result = <String, List<SterilizationMethod>>{};
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final refId = row['instrument_ref_id'] as String;
      final versionRow = row['published_version'] as Map<String, dynamic>?;
      final methodValue = versionRow?['method'] as String?;
      if (methodValue == null) continue;
      (result[refId] ??= []).add(SterilizationMethodLabel.fromDb(methodValue));
    }
    return result;
  }

  /// Fichas técnicas PUBLICADAS que referencian un fabricante, para
  /// [ManufacturerDetailScreen] ("usado en"). RLS ya limita lo privado
  /// (workspace) al grupo del usuario; el catálogo global es visible para
  /// todos.
  Future<List<InstrumentTechnicalInfo>> fetchTechnicalInfoForManufacturer(String manufacturerId) async {
    final rows = await _client
        .from('instrument_technical_info_versions')
        .select('*, instrument_technical_info(*)')
        .eq('manufacturer_id', manufacturerId)
        .eq('status', GroupDocumentVersionStatus.published.dbValue);
    final result = <InstrumentTechnicalInfo>[];
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final headerRow = row['instrument_technical_info'] as Map<String, dynamic>?;
      if (headerRow == null) continue;
      final version = InstrumentTechnicalInfoVersion.fromRow(row);
      result.add(InstrumentTechnicalInfo.fromRow(headerRow).copyWith(publishedVersion: version));
    }
    return result;
  }

  // ============================================================
  // Workflow -- métodos de esterilización
  // ============================================================

  /// Crea una cabecera de método nueva con su primera versión en borrador.
  Future<SterilizationMethodVersion> createSterilizationMethod({
    required String refType,
    required String refId,
    String? organizationId,
    String? workspaceId,
    required SterilizationMethod method,
  }) async {
    final versionRow = await _client.rpc('create_sterilization_method', params: {
      'p_instrument_ref_type': refType,
      'p_instrument_ref_id': refId,
      'p_organization_id': organizationId,
      'p_workspace_id': workspaceId,
      'p_method': method.dbValue,
    });
    return SterilizationMethodVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  /// Devuelve el borrador propio en curso para [methodId] si existe, o crea
  /// uno nuevo a partir de la versión publicada (inserción directa, se apoya
  /// en la política RLS de insert -- NO es una RPC, mismo patrón que
  /// [PreferenceCardService.startEditing]).
  Future<SterilizationMethodVersion> startEditingMethod(String methodId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('instrument_sterilization_method_versions')
        .select()
        .eq('method_id', methodId)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      return SterilizationMethodVersion.fromRow(existing);
    }

    final header =
        await _client.from('instrument_sterilization_methods').select(_publishedJoin).eq('id', methodId).single();
    final published = SterilizationMethodEntry.fromRow(header).publishedVersion;
    if (published == null) {
      throw StateError('Este método todavía no tiene una versión publicada.');
    }
    final versions = await fetchMethodVersionHistory(methodId);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('instrument_sterilization_method_versions')
        .insert({
          'method_id': methodId,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'method': published.method.dbValue,
          'temperature': published.temperature,
          'time_minutes': published.timeMinutes,
          'pressure': published.pressure,
          'drying': published.drying,
          'recommended_cycle': published.recommendedCycle,
          'compatibility_notes': published.compatibilityNotes,
          'restrictions': published.restrictions,
          'observations': published.observations,
          'lubrication_required': published.lubricationRequired,
          'lubrication_type': published.lubricationType,
          'lubrication_notes': published.lubricationNotes,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return SterilizationMethodVersion.fromRow(versionRow);
  }

  Future<SterilizationMethodVersion> saveMethodDraft(SterilizationMethodVersion version) async {
    final row = await _client
        .from('instrument_sterilization_method_versions')
        .update(version.toRow())
        .eq('id', version.id)
        .select()
        .single();
    return SterilizationMethodVersion.fromRow(row);
  }

  Future<void> submitMethodVersionForReview(String versionId) async {
    await _client.rpc('submit_sterilization_method_version_for_review', params: {'p_version_id': versionId});
  }

  Future<void> approveMethodVersion(String versionId, {String? comment}) async {
    await _client.rpc('approve_sterilization_method_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> rejectMethodVersion(String versionId, {String? comment}) async {
    await _client.rpc('reject_sterilization_method_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<SterilizationMethodVersion> restoreMethodVersion(String versionId) async {
    final row = await _client.rpc('restore_sterilization_method_version', params: {'p_version_id': versionId});
    return SterilizationMethodVersion.fromRow(row as Map<String, dynamic>);
  }

  Future<List<SterilizationMethodVersion>> fetchMethodVersionHistory(String methodId) async {
    final rows = await _client
        .from('instrument_sterilization_method_versions')
        .select()
        .eq('method_id', methodId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>).map((r) => SterilizationMethodVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Versiones en revisión de métodos de esterilización (globales y de
  /// organización mezcladas -- la RLS de select ya limita qué filas ve cada
  /// usuario: Editorial Board para las globales, rol de espacio para las de
  /// organización), para la cola de aprobación (Fase 3 · Bloc B).
  Future<List<SterilizationMethodVersion>> fetchMethodReviewQueue() async {
    final rows = await _client
        .from('instrument_sterilization_method_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>).map((r) => SterilizationMethodVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  // ============================================================
  // Workflow -- ficha técnica
  // ============================================================

  Future<InstrumentTechnicalInfoVersion> createTechnicalInfo({
    required String refType,
    required String refId,
    String? organizationId,
    String? workspaceId,
  }) async {
    final versionRow = await _client.rpc('create_technical_info', params: {
      'p_instrument_ref_type': refType,
      'p_instrument_ref_id': refId,
      'p_organization_id': organizationId,
      'p_workspace_id': workspaceId,
    });
    return InstrumentTechnicalInfoVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  Future<InstrumentTechnicalInfoVersion> startEditingTechnicalInfo(String infoId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('instrument_technical_info_versions')
        .select()
        .eq('info_id', infoId)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      return InstrumentTechnicalInfoVersion.fromRow(existing);
    }

    final header =
        await _client.from('instrument_technical_info').select(_publishedJoin).eq('id', infoId).single();
    final published = InstrumentTechnicalInfo.fromRow(header).publishedVersion;
    if (published == null) {
      throw StateError('Esta ficha técnica todavía no tiene una versión publicada.');
    }
    final versions = await fetchTechnicalInfoVersionHistory(infoId);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('instrument_technical_info_versions')
        .insert({
          'info_id': infoId,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'manufacturer_id': published.manufacturerId,
          'ifu_document_id': published.ifuDocumentId,
          'maintenance_notes': published.maintenanceNotes,
          'inspection_notes': published.inspectionNotes,
          'useful_life_notes': published.usefulLifeNotes,
          'maintenance_interval_days': published.maintenanceIntervalDays,
          'last_maintenance_at': published.lastMaintenanceAt?.toIso8601String().split('T').first,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return InstrumentTechnicalInfoVersion.fromRow(versionRow);
  }

  Future<InstrumentTechnicalInfoVersion> saveTechnicalInfoDraft(InstrumentTechnicalInfoVersion version) async {
    final row = await _client
        .from('instrument_technical_info_versions')
        .update(version.toRow())
        .eq('id', version.id)
        .select()
        .single();
    return InstrumentTechnicalInfoVersion.fromRow(row);
  }

  Future<void> submitTechnicalInfoVersionForReview(String versionId) async {
    await _client.rpc('submit_technical_info_version_for_review', params: {'p_version_id': versionId});
  }

  Future<void> approveTechnicalInfoVersion(String versionId, {String? comment}) async {
    await _client.rpc('approve_technical_info_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> rejectTechnicalInfoVersion(String versionId, {String? comment}) async {
    await _client.rpc('reject_technical_info_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<InstrumentTechnicalInfoVersion> restoreTechnicalInfoVersion(String versionId) async {
    final row = await _client.rpc('restore_technical_info_version', params: {'p_version_id': versionId});
    return InstrumentTechnicalInfoVersion.fromRow(row as Map<String, dynamic>);
  }

  Future<List<InstrumentTechnicalInfoVersion>> fetchTechnicalInfoVersionHistory(String infoId) async {
    final rows = await _client
        .from('instrument_technical_info_versions')
        .select()
        .eq('info_id', infoId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => InstrumentTechnicalInfoVersion.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Ver [fetchMethodReviewQueue] -- mismo criterio, entidad distinta.
  Future<List<InstrumentTechnicalInfoVersion>> fetchTechnicalInfoReviewQueue() async {
    final rows = await _client
        .from('instrument_technical_info_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((r) => InstrumentTechnicalInfoVersion.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
