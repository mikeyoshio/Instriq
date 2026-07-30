import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/manufacturer.dart';

/// Catálogo compartido de fabricantes (`manufacturers`, ver Fase C): select
/// público, insert abierto a cualquier autenticado, sin update/delete. Se
/// cachea en memoria porque es una lista pequeña y de lectura muy frecuente
/// (autocompletar en la ficha técnica de cada instrumento).
class ManufacturerService {
  ManufacturerService._();
  static final ManufacturerService instance = ManufacturerService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Manufacturer> _manufacturers = [];

  List<Manufacturer> get manufacturers => List.unmodifiable(_manufacturers);

  Future<List<Manufacturer>> fetchAll() async {
    final rows = await _client.from('manufacturers').select().order('name');
    _manufacturers =
        (rows as List<dynamic>).map((r) => Manufacturer.fromRow(r as Map<String, dynamic>)).toList();
    return _manufacturers;
  }

  Manufacturer? byId(String id) {
    for (final m in _manufacturers) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Filtro en memoria sobre el caché ya cargado (ver [fetchAll]) — pensado
  /// para alimentar un `Autocomplete` mientras la persona teclea, sin ida y
  /// vuelta al servidor por cada letra.
  List<Manufacturer> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return manufacturers;
    return _manufacturers.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  /// Da de alta un fabricante nuevo, o reutiliza el existente si otro
  /// usuario lo creó justo antes (choque de unicidad en `name`): dos
  /// personas rellenando la misma ficha técnica casi a la vez no deben ver
  /// un error, sino acabar apuntando al mismo fabricante.
  Future<Manufacturer> createOrGet(String name) async {
    final trimmed = name.trim();
    try {
      final row = await _client.from('manufacturers').insert({'name': trimmed}).select().single();
      final created = Manufacturer.fromRow(row);
      if (!_manufacturers.any((m) => m.id == created.id)) {
        _manufacturers = [..._manufacturers, created]..sort((a, b) => a.name.compareTo(b.name));
      }
      return created;
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final row = await _client.from('manufacturers').select().eq('name', trimmed).single();
      final existing = Manufacturer.fromRow(row);
      if (!_manufacturers.any((m) => m.id == existing.id)) {
        _manufacturers = [..._manufacturers, existing]..sort((a, b) => a.name.compareTo(b.name));
      }
      return existing;
    }
  }
}
