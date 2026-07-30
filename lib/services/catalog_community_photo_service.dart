import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_community_photo.dart';

/// Fotos aportadas por la comunidad para instrumentos del catálogo global sin
/// foto verificada. Ver supabase/schema_v16_community_photos.sql: la tabla
/// modera antes de publicar, pero el bucket de Storage es PÚBLICO (a
/// diferencia de custom-instrument-photos/tray-photos) porque el catálogo se
/// muestra también sin sesión — por eso aquí se usa [getPublicUrl] y no
/// createSignedUrl.
class CatalogCommunityPhotoService {
  CatalogCommunityPhotoService._();
  static final CatalogCommunityPhotoService instance = CatalogCommunityPhotoService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _bucket = 'catalog-community-photos';

  /// Ids de instrumentos de catálogo con al menos una foto aprobada — una
  /// única consulta para pintar el badge "sin foto" en CatalogScreen sin
  /// hacer una petición por instrumento.
  Future<Set<String>> fetchApprovedInstrumentIds(String refType) async {
    final rows = await _client
        .from('catalog_community_photos')
        .select('instrument_ref_id')
        .eq('instrument_ref_type', refType)
        .eq('status', 'approved');
    return (rows as List<dynamic>).map((r) => (r as Map<String, dynamic>)['instrument_ref_id'] as String).toSet();
  }

  /// La foto aprobada más reciente para un instrumento concreto (puede haber
  /// varias enviadas a lo largo del tiempo; solo interesa la última
  /// aprobada), o null si no hay ninguna.
  Future<CatalogCommunityPhoto?> fetchApprovedPhoto(String refType, String refId) async {
    final row = await _client
        .from('catalog_community_photos')
        .select()
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .eq('status', 'approved')
        .order('reviewed_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return CatalogCommunityPhoto.fromRow(row);
  }

  /// La foto pendiente (si existe) que YA subió el usuario actual para este
  /// instrumento — para no dejarle enviar una segunda mientras la primera
  /// sigue en revisión.
  Future<CatalogCommunityPhoto?> fetchOwnPendingPhoto(String refType, String refId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('catalog_community_photos')
        .select()
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .eq('submitted_by', userId)
        .eq('status', 'pending')
        .maybeSingle();
    if (row == null) return null;
    return CatalogCommunityPhoto.fromRow(row);
  }

  /// Lista global de fotos pendientes para el panel de moderación (solo
  /// legible por admins, ver RLS).
  Future<List<CatalogCommunityPhoto>> fetchPendingForAdmin() async {
    final rows = await _client
        .from('catalog_community_photos')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List<dynamic>).map((r) => CatalogCommunityPhoto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Sube la foto al bucket público y crea la fila en estado 'pending'.
  /// [consentAccepted] debe venir ya confirmado por la UI (checkbox
  /// explícito) — el insert se rechaza por RLS si no es true.
  Future<CatalogCommunityPhoto> submitPhoto({
    required String refType,
    required String refId,
    required File file,
    required bool consentAccepted,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cal haver iniciat sessió per pujar una foto.');
    }
    if (!consentAccepted) {
      throw StateError('Cal acceptar l\'avís abans de pujar la foto.');
    }
    final ext = _extensionOf(file.path);
    final path = '$refType/$refId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).upload(path, file);
    final row = await _client
        .from('catalog_community_photos')
        .insert({
          'instrument_ref_type': refType,
          'instrument_ref_id': refId,
          'photo_path': path,
          'submitted_by': userId,
          'consent_accepted': consentAccepted,
        })
        .select()
        .single();
    return CatalogCommunityPhoto.fromRow(row);
  }

  /// Aprueba o rechaza una foto pendiente (solo admins, vía RPC security
  /// definer). Al aprobar, si no se indica [creditName], el servidor usa el
  /// display_name del perfil de quien la subió.
  Future<CatalogCommunityPhoto> reviewPhoto({
    required String photoId,
    required bool approve,
    String? creditName,
    String? rejectionReason,
  }) async {
    final row = await _client.rpc('review_community_photo', params: {
      'p_photo_id': photoId,
      'p_approve': approve,
      'p_credit_name': creditName,
      'p_rejection_reason': rejectionReason,
    });
    return CatalogCommunityPhoto.fromRow(row as Map<String, dynamic>);
  }

  String getPublicUrl(String photoPath) {
    return _client.storage.from(_bucket).getPublicUrl(photoPath);
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }
}
