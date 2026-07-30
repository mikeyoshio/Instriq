import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reference_document.dart';
import 'auth_service.dart';

/// CRUD mínimo de documentos de referencia (`reference_documents`, Fase C).
/// A diferencia de fabricante/cirujano/etiqueta, una IFU no tiene una clave
/// natural para deduplicar (el mismo título puede tener URLs distintas por
/// versión/idioma), así que [createOrGet] simplemente inserta — el nombre se
/// mantiene por simetría con el resto de servicios de Fase C, no porque
/// reutilice nada existente.
class ReferenceDocumentService {
  ReferenceDocumentService._();
  static final ReferenceDocumentService instance = ReferenceDocumentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<ReferenceDocument> createOrGet(
    String title,
    String url, {
    String docType = 'other',
    String? organizationId,
    String? manufacturerId,
  }) async {
    final row = await _client
        .from('reference_documents')
        .insert({
          'title': title.trim(),
          'url': url.trim(),
          'doc_type': docType,
          'organization_id': organizationId,
          'manufacturer_id': manufacturerId,
          'created_by': AuthService.instance.currentUser?.id,
        })
        .select()
        .single();
    return ReferenceDocument.fromRow(row);
  }

  Future<ReferenceDocument?> fetchById(String id) async {
    final row = await _client.from('reference_documents').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return ReferenceDocument.fromRow(row);
  }
}
