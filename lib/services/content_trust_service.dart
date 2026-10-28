import 'package:supabase_flutter/supabase_flutter.dart';

/// Fuente de información por campo y validación clínica (propuesta de
/// producto auditada esta sesión) sobre los 4 tipos de contenido privado de
/// uso diario -- ver supabase/schema_v58_content_trust_metadata.sql. Servicio
/// único y genérico (`ref_type`/`ref_id`) en vez de uno por tipo de
/// contenido: los 2 RPC ya son polimórficos en el propio Postgres.
class ContentTrustService {
  ContentTrustService._();
  static final ContentTrustService instance = ContentTrustService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> setSourceReference({
    required String refType,
    required String refId,
    required String? sourceReference,
  }) async {
    await _client.rpc('set_content_source_reference', params: {
      'p_ref_type': refType,
      'p_ref_id': refId,
      'p_source_reference': sourceReference,
    });
  }

  Future<void> markClinicallyReviewed({
    required String refType,
    required String refId,
    String? notes,
  }) async {
    await _client.rpc('mark_content_clinically_reviewed', params: {
      'p_ref_type': refType,
      'p_ref_id': refId,
      'p_notes': notes,
    });
  }
}
