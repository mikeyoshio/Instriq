import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/instrument_sterilization.dart';

/// CRUD de métodos de esterilización y ficha técnica de un instrumento
/// (catálogo global o instrumento personalizado). Ver
/// supabase/schema_v15_clinical_knowledge_model.sql para el modelo y RLS.
/// Para el catálogo global ([refType] = 'catalog') se pasa [organizationId]
/// / [workspaceId] null en los upserts — ver [SterilizationMethodEntry].
class SterilizationService {
  SterilizationService._();
  static final SterilizationService instance = SterilizationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<SterilizationMethodEntry>> fetchMethods(String refType, String refId) async {
    final rows = await _client
        .from('instrument_sterilization_methods')
        .select()
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .order('method');
    return (rows as List<dynamic>)
        .map((r) => SterilizationMethodEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<InstrumentTechnicalInfo?> fetchTechnicalInfo(String refType, String refId) async {
    final row = await _client
        .from('instrument_technical_info')
        .select()
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .maybeSingle();
    if (row == null) return null;
    return InstrumentTechnicalInfo.fromRow(row);
  }

  Future<void> upsertMethod(SterilizationMethodEntry entry) async {
    if (entry.id == null) {
      await _client.from('instrument_sterilization_methods').insert(entry.toRow());
    } else {
      await _client.from('instrument_sterilization_methods').update(entry.toRow()).eq('id', entry.id!);
    }
  }

  Future<void> upsertTechnicalInfo(InstrumentTechnicalInfo info) async {
    if (info.id == null) {
      await _client.from('instrument_technical_info').insert(info.toRow());
    } else {
      await _client.from('instrument_technical_info').update(info.toRow()).eq('id', info.id!);
    }
  }

  Future<void> deleteMethod(String id) async {
    await _client.from('instrument_sterilization_methods').delete().eq('id', id);
  }

  /// Fichas técnicas que referencian un fabricante, para
  /// [ManufacturerDetailScreen] ("usado en"). RLS de `instrument_technical_info`
  /// ya limita lo privado (workspace) al grupo del usuario; el catálogo
  /// global es visible para todos.
  Future<List<InstrumentTechnicalInfo>> fetchTechnicalInfoForManufacturer(String manufacturerId) async {
    final rows =
        await _client.from('instrument_technical_info').select().eq('manufacturer_id', manufacturerId);
    return (rows as List<dynamic>)
        .map((r) => InstrumentTechnicalInfo.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
