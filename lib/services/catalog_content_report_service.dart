import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_content_report.dart';
import 'auth_service.dart';

/// CRUD de reportes de error de contenido del catálogo global -- ver
/// supabase/schema_v39_catalog_content_reports.sql. Sin RPC de creación (el
/// insert directo ya está cubierto por RLS, igual que
/// `CatalogCommunityPhotoService.submitPhoto`); resolver sí exige RPC porque
/// comprueba `my_is_editorial_board()` en el servidor, no aquí.
class CatalogContentReportService {
  CatalogContentReportService._();
  static final CatalogContentReportService instance = CatalogContentReportService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<CatalogContentReport> report({
    required String refType,
    required String refId,
    required String description,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Cal haver iniciat sessió per reportar un error');
    }
    final row = await _client
        .from('catalog_content_reports')
        .insert({
          'instrument_ref_type': refType,
          'instrument_ref_id': refId,
          'description': description,
          'reported_by': userId,
        })
        .select()
        .single();
    return CatalogContentReport.fromRow(row);
  }

  /// Cola de reportes abiertos para el Editorial Board -- la RLS de
  /// `catalog_content_reports_select` ya limita esto a quien tenga
  /// `my_is_editorial_board()`, así que no hace falta comprobar el rol aquí.
  Future<List<CatalogContentReport>> fetchOpenQueue() async {
    final rows = await _client
        .from('catalog_content_reports')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: true);
    return (rows as List<dynamic>).map((r) => CatalogContentReport.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<CatalogContentReport> resolve(String reportId, {String? resolutionNotes}) async {
    final row = await _client.rpc('resolve_catalog_content_report', params: {
      'p_report_id': reportId,
      'p_resolution_notes': resolutionNotes,
    });
    return CatalogContentReport.fromRow(row as Map<String, dynamic>);
  }
}
