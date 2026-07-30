import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/specialty_entity.dart';

/// Lista cerrada de 16 especialidades ya sembradas en Supabase (sin política
/// de insert: no se pueden crear más desde el cliente). Se cachea para
/// siempre en memoria una vez cargada — no hace falta invalidar el caché
/// nunca, a diferencia de [SurgeonService]/[ManufacturerService].
class SpecialtyService {
  SpecialtyService._();
  static final SpecialtyService instance = SpecialtyService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<SpecialtyEntity>? _cache;

  Future<List<SpecialtyEntity>> fetchAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final rows = await _client.from('specialties').select().order('label');
    final result =
        (rows as List<dynamic>).map((r) => SpecialtyEntity.fromRow(r as Map<String, dynamic>)).toList();
    _cache = result;
    return result;
  }

  /// Null si [fetchAll] todavía no se ha llamado nunca, o si el slug no
  /// existe. Pensado para usarse tras un [fetchAll] previo (p.ej. en
  /// `initState`), no como primera carga.
  SpecialtyEntity? bySlug(String slug) {
    final cached = _cache;
    if (cached == null) return null;
    for (final s in cached) {
      if (s.slug == slug) return s;
    }
    return null;
  }

  SpecialtyEntity? byId(String id) {
    final cached = _cache;
    if (cached == null) return null;
    for (final s in cached) {
      if (s.id == id) return s;
    }
    return null;
  }
}
