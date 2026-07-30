import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/surgeon.dart';
import 'profile_service.dart';

/// Cirujanas/os del grupo actual (`surgeons`, ver Fase C) — RLS los aísla al
/// `organization_id` de quien consulta, así que el caché en memoria debe
/// limpiarse al cambiar de grupo (ver [ProfileService._clearGroupContentCaches],
/// que llama a [clear] igual que con workspaces/documentos/tarjetas).
class SurgeonService {
  SurgeonService._();
  static final SurgeonService instance = SurgeonService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Surgeon> _surgeons = [];

  List<Surgeon> get surgeons => List.unmodifiable(_surgeons);

  void clear() {
    _surgeons = [];
  }

  Future<List<Surgeon>> fetchForOrganization() async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      _surgeons = [];
      return _surgeons;
    }
    final rows =
        await _client.from('surgeons').select().eq('organization_id', organizationId).order('name');
    _surgeons = (rows as List<dynamic>).map((r) => Surgeon.fromRow(r as Map<String, dynamic>)).toList();
    return _surgeons;
  }

  Surgeon? byId(String id) {
    for (final s in _surgeons) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Filtro en memoria sobre el caché ya cargado (ver [fetchForOrganization]),
  /// mismo patrón que [ManufacturerService.searchByName].
  List<Surgeon> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surgeons;
    return _surgeons.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  /// Da de alta un cirujano nuevo del grupo actual, o reutiliza el existente
  /// si otra persona lo creó justo antes (choque de unicidad en
  /// `(organization_id, name)`) — mismo patrón que
  /// [ManufacturerService.createOrGet].
  Future<Surgeon> createOrGet(String name) async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final trimmed = name.trim();
    try {
      final row = await _client
          .from('surgeons')
          .insert({'organization_id': organizationId, 'name': trimmed})
          .select()
          .single();
      final created = Surgeon.fromRow(row);
      if (!_surgeons.any((s) => s.id == created.id)) {
        _surgeons = [..._surgeons, created]..sort((a, b) => a.name.compareTo(b.name));
      }
      return created;
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final row = await _client
          .from('surgeons')
          .select()
          .eq('organization_id', organizationId)
          .eq('name', trimmed)
          .single();
      final existing = Surgeon.fromRow(row);
      if (!_surgeons.any((s) => s.id == existing.id)) {
        _surgeons = [..._surgeons, existing]..sort((a, b) => a.name.compareTo(b.name));
      }
      return existing;
    }
  }
}
