import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/preference_card.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../screens/group_document_detail_screen.dart';
import '../screens/preference_card_detail_screen.dart';
import '../screens/tray_detail_screen.dart';
import '../screens/tray_preparation_or_mode_screen.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import '../services/tray_service.dart';

/// Contingut d'una intervenció ja resolt: compartit per la pàgina del
/// procediment i la del cas (cita de l'agenda), que mostren el mateix.
class ProcedureContent {
  final List<Tray> trays;
  final List<GroupDocument> documents;
  final List<PreferenceCard> cards;

  const ProcedureContent({required this.trays, required this.documents, required this.cards});

  bool get isEmpty => trays.isEmpty && documents.isEmpty && cards.isEmpty;
}

/// Resol ids a contingut publicat de l'espai, en l'ordre donat. S'ometen els
/// que ja no existeixin o encara no tinguin cap versió publicada (un
/// procediment o una cita no han d'ensenyar esborranys a qui prepara).
Future<ProcedureContent> resolveProcedureContent({
  required String workspaceId,
  required List<String> trayIds,
  required List<String> documentIds,
  required List<String> cardIds,
}) async {
  await Future.wait([
    TrayService.instance.fetchTrays(workspaceId),
    GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspaceId),
    GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspaceId),
    PreferenceCardService.instance.fetchCards(workspaceId),
    SurgeonService.instance.fetchForOrganization(),
  ]);
  return ProcedureContent(
    trays: [
      for (final id in trayIds)
        if (TrayService.instance.trayById(id) case final t? when t.publishedVersion != null) t,
    ],
    documents: [
      for (final id in documentIds)
        if (GroupDocumentService.instance.documentById(id) case final d? when d.publishedVersion != null) d,
    ],
    cards: [
      for (final id in cardIds)
        if (PreferenceCardService.instance.cardById(id) case final c? when c.publishedVersion != null) c,
    ],
  );
}

class ProcedureContentView extends StatelessWidget {
  final ProcedureContent content;
  final WorkspaceRole? myRole;

  const ProcedureContentView({super.key, required this.content, required this.myRole});

  Future<void> _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[];

    void section(String title, List<Widget> items) {
      if (items.isEmpty) return;
      children
        ..add(const SizedBox(height: InstriqSpacing.lg))
        ..add(InstriqSectionHeader(title))
        ..add(const SizedBox(height: InstriqSpacing.sm));
      for (final item in items) {
        children
          ..add(item)
          ..add(const SizedBox(height: InstriqSpacing.sm));
      }
    }

    section(l10n.traysTitle, [
      for (final tray in content.trays)
        InstriqListItem(
          icon: Icons.inventory_2_outlined,
          title: tray.publishedVersion!.name,
          onTap: () => _push(context, TrayDetailScreen(tray: tray, myRole: myRole)),
          trailing: TextButton(
            onPressed: () => _push(context, TrayPreparationOrModeScreen(tray: tray)),
            child: Text(l10n.prepareTrayAction),
          ),
        ),
    ]);
    section(l10n.procedureDocumentsSection, [
      for (final doc in content.documents)
        InstriqListItem(
          icon: doc.kind == DocumentKind.technique ? Icons.menu_book_outlined : Icons.fact_check_outlined,
          title: doc.publishedVersion!.title,
          subtitle: doc.kind == DocumentKind.technique ? l10n.techniquesTitle : l10n.protocolsTitle,
          onTap: () => _push(context, GroupDocumentDetailScreen(document: doc, myRole: myRole)),
        ),
    ]);
    section(l10n.preferenceCardsTitle, [
      for (final card in content.cards)
        InstriqListItem(
          icon: Icons.assignment_ind_outlined,
          title: card.publishedVersion!.procedureName,
          subtitle: SurgeonService.instance.byId(card.publishedVersion!.surgeonId ?? '')?.name,
          onTap: () => _push(context, PreferenceCardDetailScreen(card: card, myRole: myRole)),
        ),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
