import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tag.dart';
import '../models/tagging.dart';
import 'auth_service.dart';

/// Etiquetado libre de cualquier entidad (`tags` + `taggings`, Fase C).
/// [Tag] es un catálogo público compartido (como [Manufacturer]); lo privado
/// es la relación etiqueta->entidad en `taggings`, aislada por
/// `organization_id` cuando la entidad etiquetada es privada de un grupo.
class TagService {
  TagService._();
  static final TagService instance = TagService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Tag> _tags = [];

  Future<void> _ensureLoaded() async {
    if (_tags.isNotEmpty) return;
    final rows = await _client.from('tags').select().order('name');
    _tags = (rows as List<dynamic>).map((r) => Tag.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Catálogo completo de etiquetas (mismo nombre que
  /// [ManufacturerService.fetchAll]/[SurgeonService.fetchForOrganization] —
  /// para cargarlo una vez y filtrar después en memoria sin volver a `await`,
  /// ver `home_screen.dart`).
  Future<List<Tag>> fetchAll() => searchByName('');

  /// Carga (o reutiliza el caché de) el catálogo completo de etiquetas y
  /// filtra en memoria — mismo patrón que
  /// [ManufacturerService.searchByName]/[SurgeonService.searchByName].
  Future<List<Tag>> searchByName(String query) async {
    await _ensureLoaded();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_tags);
    return _tags.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  /// Da de alta una etiqueta nueva, o reutiliza la existente si otra persona
  /// la creó justo antes (choque de unicidad en `name`) — mismo patrón que
  /// [ManufacturerService.createOrGet].
  Future<Tag> createOrGet(String name) async {
    final trimmed = name.trim();
    try {
      final row = await _client.from('tags').insert({'name': trimmed}).select().single();
      final created = Tag.fromRow(row);
      if (!_tags.any((t) => t.id == created.id)) {
        _tags = [..._tags, created]..sort((a, b) => a.name.compareTo(b.name));
      }
      return created;
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final row = await _client.from('tags').select().eq('name', trimmed).single();
      final existing = Tag.fromRow(row);
      if (!_tags.any((t) => t.id == existing.id)) {
        _tags = [..._tags, existing]..sort((a, b) => a.name.compareTo(b.name));
      }
      return existing;
    }
  }

  /// Etiquetas ya puestas a una entidad concreta (para mostrar chips en su
  /// ficha y para calcular el diff al guardar en el picker).
  Future<List<Tag>> fetchTagsFor(String refType, String refId) async {
    final rows = await _client
        .from('taggings')
        .select('tag_id, tags(id, name)')
        .eq('ref_type', refType)
        .eq('ref_id', refId);
    return (rows as List<dynamic>)
        .map((r) => (r as Map<String, dynamic>)['tags'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(Tag.fromRow)
        .toList();
  }

  /// [organizationId] debe ser null si la entidad etiquetada es global
  /// (instrumento de catálogo, fabricante, especialidad) o el grupo de quien
  /// etiqueta si es privada (bandeja, documento, cirujano...) — la RLS de
  /// `taggings` rechaza cualquier otra combinación.
  Future<void> addTag({
    required String tagId,
    required String refType,
    required String refId,
    String? organizationId,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Inicia sesión para poder etiquetar.');
    }
    await _client.from('taggings').insert({
      'tag_id': tagId,
      'ref_type': refType,
      'ref_id': refId,
      'organization_id': organizationId,
      'created_by': userId,
    });
  }

  /// Solo borra la propia (la RLS de `taggings` ya lo exige con
  /// `created_by = auth.uid()`), así que no hace falta pasar el user id aquí.
  Future<void> removeTag({
    required String tagId,
    required String refType,
    required String refId,
  }) async {
    await _client
        .from('taggings')
        .delete()
        .eq('tag_id', tagId)
        .eq('ref_type', refType)
        .eq('ref_id', refId);
  }

  /// Todas las relaciones de una etiqueta, para la pantalla "todo lo
  /// etiquetado con X" — el llamante las agrupa por [Tagging.refType] y
  /// resuelve cada una a un título con `resolveRef` (ver `ref_resolver.dart`).
  Future<List<Tagging>> fetchEntriesForTag(String tagId) async {
    final rows = await _client.from('taggings').select().eq('tag_id', tagId).order('ref_type');
    return (rows as List<dynamic>).map((r) => Tagging.fromRow(r as Map<String, dynamic>)).toList();
  }
}
