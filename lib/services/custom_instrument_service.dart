import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/custom_instrument.dart';
import 'profile_service.dart';

/// CRUD del instrumental personalizado de un equipo y de sus variantes/fotos.
/// Ver supabase/schema_v13_custom_instruments.sql: cada fila está aislada por
/// RLS al workspace/hospital que la creó — este servicio nunca mezcla ese
/// contenido con el catálogo global (`lib/data/instruments_data.dart`).
class CustomInstrumentService {
  CustomInstrumentService._();
  static final CustomInstrumentService instance = CustomInstrumentService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _bucket = 'custom-instrument-photos';
  static const _variantsJoin = '*, custom_instrument_variants(*)';

  List<CustomInstrument> _instruments = [];

  List<CustomInstrument> get instruments => List.unmodifiable(_instruments);

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, instrumental de un workspace anterior puede quedar visible.
  void clear() {
    _instruments = [];
  }

  Future<void> fetchForWorkspace(String workspaceId) async {
    final rows = await _client
        .from('custom_instruments')
        .select(_variantsJoin)
        .eq('workspace_id', workspaceId)
        .order('name');
    _instruments = (rows as List<dynamic>)
        .map((r) => CustomInstrument.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  CustomInstrument? byId(String id) {
    for (final i in _instruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Fetch puntual por id (sin pasar por el caché de workspace) — usado por
  /// [RecentActivityService]/[FavoritesService] para resolver un ref a título
  /// humano sin haber cargado antes todo el workspace al que pertenece.
  Future<CustomInstrument> fetchById(String id) async {
    final row = await _client.from('custom_instruments').select().eq('id', id).single();
    return CustomInstrument.fromRow(row);
  }

  Future<CustomInstrument> create(CustomInstrument instrument) async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = await _client
        .from('custom_instruments')
        .insert(instrument.copyWith().toRow())
        .select(_variantsJoin)
        .single();
    final created = CustomInstrument.fromRow(row);
    _instruments.add(created);
    return created;
  }

  Future<CustomInstrument> update(CustomInstrument instrument) async {
    final row = await _client
        .from('custom_instruments')
        .update(instrument.toRow())
        .eq('id', instrument.id)
        .select(_variantsJoin)
        .single();
    final updated = CustomInstrument.fromRow(row);
    final index = _instruments.indexWhere((i) => i.id == updated.id);
    if (index == -1) {
      _instruments.add(updated);
    } else {
      _instruments[index] = updated;
    }
    return updated;
  }

  Future<void> delete(String id) async {
    await _client.from('custom_instruments').delete().eq('id', id);
    _instruments.removeWhere((i) => i.id == id);
  }

  Future<CustomInstrumentVariant> addVariant(CustomInstrumentVariant variant) async {
    final row = await _client.from('custom_instrument_variants').insert(variant.toRow()).select().single();
    final created = CustomInstrumentVariant.fromRow(row);
    _replaceVariantInMemory(created);
    return created;
  }

  Future<CustomInstrumentVariant> updateVariant(CustomInstrumentVariant variant) async {
    final row = await _client
        .from('custom_instrument_variants')
        .update(variant.toRow())
        .eq('id', variant.id)
        .select()
        .single();
    final updated = CustomInstrumentVariant.fromRow(row);
    _replaceVariantInMemory(updated);
    return updated;
  }

  Future<void> deleteVariant(String variantId, String customInstrumentId) async {
    await _client.from('custom_instrument_variants').delete().eq('id', variantId);
    final index = _instruments.indexWhere((i) => i.id == customInstrumentId);
    if (index != -1) {
      final instrument = _instruments[index];
      _instruments[index] = instrument.copyWith(
        variants: instrument.variants.where((v) => v.id != variantId).toList(),
      );
    }
  }

  void _replaceVariantInMemory(CustomInstrumentVariant variant) {
    final index = _instruments.indexWhere((i) => i.id == variant.customInstrumentId);
    if (index == -1) return;
    final instrument = _instruments[index];
    final variants = List<CustomInstrumentVariant>.of(instrument.variants);
    final variantIndex = variants.indexWhere((v) => v.id == variant.id);
    if (variantIndex == -1) {
      variants.add(variant);
    } else {
      variants[variantIndex] = variant;
    }
    _instruments[index] = instrument.copyWith(variants: variants);
  }

  /// Sube la foto de una variante al bucket privado, con la ruta convenida
  /// `{organization_id}/{workspace_id}/{custom_instrument_id}/{variant_id}.<ext>`
  /// (ver schema_v13), y guarda `photo_path` en la fila. El bucket NO es
  /// público: para mostrarla hay que pedir una signed URL con
  /// [getVariantPhotoUrl].
  Future<CustomInstrumentVariant> uploadVariantPhoto({
    required CustomInstrumentVariant variant,
    required String organizationId,
    required String workspaceId,
    required File file,
  }) async {
    final ext = _extensionOf(file.path);
    final path = '$organizationId/$workspaceId/${variant.customInstrumentId}/${variant.id}.$ext';
    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return updateVariant(variant.copyWith(photoPath: path));
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }

  /// El bucket es privado, así que la foto solo se puede mostrar con una URL
  /// firmada de vida corta — se resuelve cada vez que se necesita mostrar,
  /// no se guarda en ningún sitio.
  Future<String> getVariantPhotoUrl(String photoPath) {
    return _client.storage.from(_bucket).createSignedUrl(photoPath, 3600);
  }

  Future<void> deleteVariantPhoto(String photoPath) async {
    await _client.storage.from(_bucket).remove([photoPath]);
  }
}
