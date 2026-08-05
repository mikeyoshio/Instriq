import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/public_document.dart';
import '../models/public_tray.dart';
import 'public_entity_form_screen.dart' show PublicEntityKind, PublicEntityKindX;

/// Vista de lectura d'una tècnica/protocol o safata publicada a la
/// Biblioteca Pública -- oberta a tothom, inclosos convidats. Deliberadament
/// nomes lectura en aquest tram: adoptar-la com a versió local d'una
/// organització depèn de com s'apliqui en detall ADR-001
/// (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md), encara no fet.
class PublicEntityDetailScreen extends StatelessWidget {
  final PublicEntityKind entityKind;
  final PublicDocument? document;
  final PublicTray? tray;

  PublicEntityDetailScreen.document({super.key, required PublicDocument document})
      : entityKind = document.kind == DocumentKind.protocol ? PublicEntityKind.protocol : PublicEntityKind.technique,
        document = document,
        tray = null;

  const PublicEntityDetailScreen.tray({super.key, required this.tray})
      : entityKind = PublicEntityKind.tray,
        document = null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTray = entityKind.isTray;
    final documentVersion = document?.publishedVersion;
    final trayVersion = tray?.publishedVersion;
    final title = isTray ? trayVersion?.name : documentVersion?.title;
    final hasVersion = isTray ? trayVersion != null : documentVersion != null;

    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.auditDocumentUntitledLabel)),
      body: !hasVersion
          ? Center(child: Text(l10n.publicLibraryEmptyState))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: isTray
                    ? _trayContent(context, l10n, trayVersion!)
                    : _documentContent(context, l10n, documentVersion!),
              ),
            ),
    );
  }

  List<Widget> _documentContent(BuildContext context, AppLocalizations l10n, PublicDocumentVersion version) {
    return [
      if (version.content != null && version.content!.isNotEmpty) ...[
        Text(version.content!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
      if (version.steps.isNotEmpty) ...[
        Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < version.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 14, child: Text('${i + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (version.steps[i].category != null)
                        Text(version.steps[i].category!, style: Theme.of(context).textTheme.labelMedium),
                      Text(version.steps[i].text, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ];
  }

  List<Widget> _trayContent(BuildContext context, AppLocalizations l10n, PublicTrayVersion version) {
    return [
      if (version.description != null && version.description!.isNotEmpty) ...[
        Text(version.description!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
      Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (version.items.isEmpty) Text(l10n.trayNoItemsYet),
      for (final item in version.items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.build_outlined),
          title: Text(item.resolveName(const [])),
          subtitle: item.position != null ? Text(item.position!) : null,
        ),
      if (version.observations != null && version.observations!.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(l10n.sterilizationObservationsLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(version.observations!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ];
  }
}
