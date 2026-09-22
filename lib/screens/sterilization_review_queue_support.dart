import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/instruments_data.dart';
import '../models/instrument_sterilization.dart';

/// Recuento de la cola de métodos/fichas técnicas que SÍ es accionable desde
/// `ReviewQueueScreen` (`organization_id` no nulo) -- las filas de catálogo
/// global (`organization_id` nulo) exigen Editorial Board y solo se ven/
/// resuelven desde `GlobalCatalogReviewQueueScreen`. Sin este filtro, el
/// recuento agregado de "Bústia de revisió" (`home_dashboard_panel.dart`,
/// `review_inbox_screen.dart`) infla el número con propuestas que un admin
/// de espacio corriente no puede ver ni actuar desde esa pantalla -- bug
/// real encontrado en una pasada de verificación en vivo (2026-09-22): dos
/// cambios de catálogo global quedaron sumando al contador sin ninguna fila
/// visible en la cola, ni pista de por qué.
Future<int> countOrgScopedSterilizationReviewItems(
  List<SterilizationMethodVersion> methodQueue,
  List<InstrumentTechnicalInfoVersion> infoQueue,
) async {
  final methodHeaders = await fetchMethodHeaders(methodQueue.map((v) => v.methodId).toSet().toList());
  final infoHeaders = await fetchTechnicalInfoHeaders(infoQueue.map((v) => v.infoId).toSet().toList());
  final methodCount = methodQueue.where((v) => methodHeaders[v.methodId]?.organizationId != null).length;
  final infoCount = infoQueue.where((v) => infoHeaders[v.infoId]?.organizationId != null).length;
  return methodCount + infoCount;
}

/// Datos mínimos de la cabecera (`instrument_sterilization_methods`/
/// `instrument_technical_info`) que las colas de revisión de EPIC 3 · Bloc B
/// necesitan y que la propia versión pendiente no lleva: a qué
/// instrumento/espacio pertenece y si es global (`organization_id` null) o
/// de organización. No se añade a [SterilizationService] porque ese fichero
/// es de otra tarea en paralelo (Fase 3 · Bloc A) en este mismo momento --
/// consulta directa vía Supabase, mismo patrón que
/// `CommunityPhotosReviewScreen`/`TrayService.fetchWorkspaceNamesForTrays`.
class SterilizationHeaderInfo {
  final String id;
  final String? organizationId;
  final String instrumentRefType;
  final String instrumentRefId;
  final String? workspaceName;

  const SterilizationHeaderInfo({
    required this.id,
    required this.organizationId,
    required this.instrumentRefType,
    required this.instrumentRefId,
    required this.workspaceName,
  });

  bool get isGlobal => organizationId == null;

  factory SterilizationHeaderInfo.fromRow(Map<String, dynamic> row) {
    final workspaceRow = row['workspaces'] as Map<String, dynamic>?;
    return SterilizationHeaderInfo(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      workspaceName: workspaceRow?['name'] as String?,
    );
  }
}

const String _headerSelect = 'id, organization_id, instrument_ref_type, instrument_ref_id, workspaces(name)';

/// Cabeceras de `instrument_sterilization_methods` para los [methodIds]
/// indicados (batch, para no hacer una consulta por fila de la cola).
Future<Map<String, SterilizationHeaderInfo>> fetchMethodHeaders(List<String> methodIds) async {
  if (methodIds.isEmpty) return {};
  final rows = await Supabase.instance.client
      .from('instrument_sterilization_methods')
      .select(_headerSelect)
      .inFilter('id', methodIds);
  return {
    for (final r in (rows as List<dynamic>))
      (r as Map<String, dynamic>)['id'] as String: SterilizationHeaderInfo.fromRow(r),
  };
}

/// Ver [fetchMethodHeaders] -- mismo criterio, entidad distinta.
Future<Map<String, SterilizationHeaderInfo>> fetchTechnicalInfoHeaders(List<String> infoIds) async {
  if (infoIds.isEmpty) return {};
  final rows =
      await Supabase.instance.client.from('instrument_technical_info').select(_headerSelect).inFilter('id', infoIds);
  return {
    for (final r in (rows as List<dynamic>))
      (r as Map<String, dynamic>)['id'] as String: SterilizationHeaderInfo.fromRow(r),
  };
}

/// Cabecera completa (con su versión publicada resuelta) de un método de
/// esterilización, para poder abrir el diff desde la cola de revisión.
Future<SterilizationMethodEntry> fetchMethodEntryWithPublished(String methodId) async {
  final row = await Supabase.instance.client
      .from('instrument_sterilization_methods')
      .select('*, published_version:published_version_id(*)')
      .eq('id', methodId)
      .single();
  return SterilizationMethodEntry.fromRow(row);
}

/// Ver [fetchMethodEntryWithPublished] -- mismo criterio, entidad distinta.
Future<InstrumentTechnicalInfo> fetchTechnicalInfoWithPublished(String infoId) async {
  final row = await Supabase.instance.client
      .from('instrument_technical_info')
      .select('*, published_version:published_version_id(*)')
      .eq('id', infoId)
      .single();
  return InstrumentTechnicalInfo.fromRow(row);
}

/// Nombre del instrumento para mostrar en la fila de la cola: si es de
/// catálogo, resuelto en memoria contra [kInstruments] (coste cero, ya
/// cargado); si es personalizado, consulta directa a `custom_instruments`
/// (puede no resolver si el usuario no tiene acceso al espacio de ese
/// instrumento -- en ese caso el punto de llamada cae al ref id, igual que
/// `CommunityPhotosReviewScreen` con las fotos de comunidad).
Future<Map<String, String>> resolveInstrumentNames(Iterable<SterilizationHeaderInfo> headers) async {
  final names = <String, String>{};
  final customIds = <String>{};
  for (final h in headers) {
    if (h.instrumentRefType == 'catalog') {
      for (final instrument in kInstruments) {
        if (instrument.id == h.instrumentRefId) {
          names[h.instrumentRefId] = instrument.name;
          break;
        }
      }
    } else {
      customIds.add(h.instrumentRefId);
    }
  }
  if (customIds.isNotEmpty) {
    try {
      final rows = await Supabase.instance.client
          .from('custom_instruments')
          .select('id, name')
          .inFilter('id', customIds.toList());
      for (final r in (rows as List<dynamic>)) {
        final row = r as Map<String, dynamic>;
        names[row['id'] as String] = row['name'] as String;
      }
    } catch (_) {
      // RLS puede impedir ver instrumentos personalizados de otro espacio: se
      // muestra el ref id, no bloquea la cola.
    }
  }
  return names;
}
