import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../models/tray.dart';
import '../screens/custom_instrument_detail_screen.dart';
import '../screens/group_document_detail_screen.dart';
import '../screens/instrument_detail_screen.dart';
import '../screens/tray_detail_screen.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';

/// Resuelve un par (ref_type, ref_id) — el formato crudo de `favorites`/
/// `recent_views` (ver supabase/schema_v18) — a un título humano y a los
/// datos necesarios para navegar a su ficha de detalle. Vive aparte de
/// [FavoriteEntry]/[RecentViewEntry] porque resolver el título exige
/// consultar el servicio dueño de ese tipo de contenido, no algo que quepa
/// en un modelo de datos puro.
class ResolvedRef {
  final String refType;
  final String refId;
  final String title;
  final String? workspaceId;
  final Object data;

  const ResolvedRef({
    required this.refType,
    required this.refId,
    required this.title,
    required this.workspaceId,
    required this.data,
  });
}

/// Devuelve null si el ref ya no existe (contenido borrado entretanto) o si
/// el tipo no se reconoce: el llamante debe omitirlo en silencio de la lista,
/// nunca crashear (favoritos/recientes son un atajo, no una fuente de verdad).
Future<ResolvedRef?> resolveRef(String refType, String refId) async {
  try {
    switch (refType) {
      case 'catalog':
        for (final instrument in kInstruments) {
          if (instrument.id == refId) {
            return ResolvedRef(
              refType: refType,
              refId: refId,
              title: instrument.name,
              workspaceId: null,
              data: instrument,
            );
          }
        }
        return null;
      case 'custom':
        final instrument = await CustomInstrumentService.instance.fetchById(refId);
        return ResolvedRef(
          refType: refType,
          refId: refId,
          title: instrument.name,
          workspaceId: instrument.workspaceId,
          data: instrument,
        );
      case 'group_document':
        final document = await GroupDocumentService.instance.fetchDocument(refId);
        final title = document.publishedVersion?.title;
        if (title == null) return null;
        return ResolvedRef(
          refType: refType,
          refId: refId,
          title: title,
          workspaceId: document.workspaceId,
          data: document,
        );
      case 'tray':
        final tray = await TrayService.instance.fetchTray(refId);
        final name = tray.publishedVersion?.name;
        if (name == null) return null;
        return ResolvedRef(
          refType: refType,
          refId: refId,
          title: name,
          workspaceId: tray.workspaceId,
          data: tray,
        );
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

/// Navega a la ficha de detalle del contenido resuelto. Para todo lo que no
/// sea catálogo, el rol efectivo del usuario en ese espacio se resuelve aquí
/// mismo (no se guarda en [ResolvedRef]: sería fácil que quedara obsoleto si
/// cambia entre que se listó el favorito/reciente y se toca).
Future<void> navigateToResolvedRef(BuildContext context, ResolvedRef ref) async {
  switch (ref.refType) {
    case 'catalog':
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: ref.data as Instrument)),
      );
      return;
    case 'custom':
      final myRole = await WorkspaceService.instance.fetchMyRole(ref.workspaceId!);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CustomInstrumentDetailScreen(instrument: ref.data as CustomInstrument, myRole: myRole),
        ),
      );
      return;
    case 'group_document':
      final myRole = await WorkspaceService.instance.fetchMyRole(ref.workspaceId!);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupDocumentDetailScreen(document: ref.data as GroupDocument, myRole: myRole),
        ),
      );
      return;
    case 'tray':
      final myRole = await WorkspaceService.instance.fetchMyRole(ref.workspaceId!);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: ref.data as Tray, myRole: myRole)),
      );
      return;
  }
}
