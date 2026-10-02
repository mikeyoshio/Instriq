import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../data/instruments_data.dart';
import '../models/group_document.dart' show DocumentKind;
import 'auth_service.dart';
import 'group_document_service.dart';
import 'preference_card_service.dart';
import 'public_document_service.dart';
import 'public_instrument_service.dart';
import 'public_tray_service.dart';
import 'tray_service.dart';
import 'workspace_service.dart';

/// Informa a la UI de en quin pas va la descàrrega ([downloadForOfflineUse])
/// i quants elements porta fets d'aquest pas concret, perquè es pugui
/// mostrar una barra de progrés real en comptes d'un simple "carregant...".
class OfflineDownloadProgress {
  final String stepLabel;
  final int done;
  final int total;

  const OfflineDownloadProgress({required this.stepLabel, required this.done, required this.total});
}

class OfflineDownloadResult {
  final int documentsCached;
  final int traysCached;
  final int preferenceCardsCached;
  final int publicItemsCached;
  final int imagesCached;
  final int imagesFailed;

  const OfflineDownloadResult({
    required this.documentsCached,
    required this.traysCached,
    required this.preferenceCardsCached,
    required this.publicItemsCached,
    required this.imagesCached,
    required this.imagesFailed,
  });
}

/// Precàrrega deliberada de tot el que calgui per fer servir l'app sense
/// connexió, en comptes de confiar només en la caché passiva (es desa el que
/// ja s'ha vist en línia). Pensada per executar-se amb l'app en primer pla i
/// connexió activa, des d'un botó explícit ("Descarrega per a ús sense
/// connexió" a Perfil) -- no s'executa mai sola en segon pla.
///
/// Abast d'aquesta primera versió (documentat explícitament, no una omissió):
/// cobreix el catàleg global (text ja empaquetat a l'app + totes les fotos),
/// tota la Biblioteca Pública (tècniques/protocols/safates/instrumental,
/// text + fotos d'instrumental públic) i, si hi ha sessió iniciada, el text
/// de tècniques/protocols/safates/targetes de preferència de cada espai de
/// treball propi, més les fotos de les safates pròpies. FORA D'ABAST
/// deliberat: fotos d'instrumental personalitzat de l'equip i d'esterilització
/// (es consulten sempre des d'una fitxa concreta, no hi ha un llistat
/// massiu a recórrer sense afegir molta complexitat nova) -- queden amb el
/// mateix criteri de caché passiva d'avui.
class OfflineDownloadService {
  OfflineDownloadService._();
  static final OfflineDownloadService instance = OfflineDownloadService._();

  final CacheManager _imageCache = DefaultCacheManager();

  Future<OfflineDownloadResult> downloadForOfflineUse({
    void Function(OfflineDownloadProgress progress)? onProgress,
  }) async {
    var imagesCached = 0;
    var imagesFailed = 0;

    Future<void> cacheImage(String url) async {
      try {
        await _imageCache.getSingleFile(url);
        imagesCached++;
      } catch (_) {
        imagesFailed++;
      }
    }

    void report(String stepLabel, int done, int total) {
      onProgress?.call(OfflineDownloadProgress(stepLabel: stepLabel, done: done, total: total));
    }

    // 1. Fotos del catàleg global -- el text ja va empaquetat a l'app, no cal
    // xarxa per a ell, només per a les imatges de Wikimedia Commons.
    final catalogImageUrls = kInstruments.map((i) => i.image?.url).whereType<String>().toList();
    for (var i = 0; i < catalogImageUrls.length; i++) {
      report('Catàleg d\'instrumental', i, catalogImageUrls.length);
      await cacheImage(catalogImageUrls[i]);
    }

    // 2. Biblioteca Pública (text, obert a tothom sense sessió).
    report('Biblioteca Pública', 0, 1);
    final techniques = await PublicDocumentService.instance.fetchPublished(DocumentKind.technique);
    final protocols = await PublicDocumentService.instance.fetchPublished(DocumentKind.protocol);
    final publicTrays = await PublicTrayService.instance.fetchPublished();
    final publicInstruments = await PublicInstrumentService.instance.fetchPublished();
    final publicItemsCached = techniques.length + protocols.length + publicTrays.length + publicInstruments.length;

    final publicPhotoPaths =
        publicInstruments.map((i) => i.publishedVersion?.photoPath).whereType<String>().toList();
    for (var i = 0; i < publicPhotoPaths.length; i++) {
      report('Instrumental de la Biblioteca Pública (fotos)', i, publicPhotoPaths.length);
      await cacheImage(PublicInstrumentService.instance.photoUrl(publicPhotoPaths[i]));
    }

    var documentsCached = techniques.length + protocols.length;
    var traysCached = 0;
    var preferenceCardsCached = 0;

    // 3. Contingut propi de l'organització, si hi ha sessió iniciada.
    if (AuthService.instance.currentUser != null) {
      await WorkspaceService.instance.fetchWorkspaces();
      final workspaces = WorkspaceService.instance.workspaces;
      for (var w = 0; w < workspaces.length; w++) {
        final workspace = workspaces[w];
        report('Espai: ${workspace.name}', w, workspaces.length);
        await GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspace.id);
        await GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspace.id);
        await TrayService.instance.fetchTrays(workspace.id);
        await PreferenceCardService.instance.fetchCards(workspace.id);

        documentsCached += GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspace.id).length +
            GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspace.id).length;
        final trays = TrayService.instance.traysOfWorkspace(workspace.id);
        traysCached += trays.length;
        preferenceCardsCached += PreferenceCardService.instance.cardsOfWorkspace(workspace.id).length;

        final trayPhotoPaths = trays.expand((t) => t.publishedVersion?.photoPaths ?? const <String>[]).toList();
        for (var i = 0; i < trayPhotoPaths.length; i++) {
          report('Safates de ${workspace.name} (fotos)', i, trayPhotoPaths.length);
          try {
            final url = await TrayService.instance.getPhotoUrl(trayPhotoPaths[i]);
            await cacheImage(url);
          } catch (_) {
            imagesFailed++;
          }
        }
      }
    }

    return OfflineDownloadResult(
      documentsCached: documentsCached,
      traysCached: traysCached,
      preferenceCardsCached: preferenceCardsCached,
      publicItemsCached: publicItemsCached,
      imagesCached: imagesCached,
      imagesFailed: imagesFailed,
    );
  }
}
