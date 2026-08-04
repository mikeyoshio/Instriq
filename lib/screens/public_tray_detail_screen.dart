import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/public_tray.dart';

/// Vista de lectura d'una safata publicada a la Biblioteca Pública -- oberta
/// a tothom, inclosos convidats. Mateixes limitacions que
/// [PublicDocumentDetailScreen]: sense adopció encara.
class PublicTrayDetailScreen extends StatelessWidget {
  final PublicTray tray;

  const PublicTrayDetailScreen({super.key, required this.tray});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = tray.publishedVersion;
    return Scaffold(
      appBar: AppBar(title: Text(version?.name ?? l10n.auditDocumentUntitledLabel)),
      body: version == null
          ? Center(child: Text(l10n.publicLibraryEmptyState))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
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
                ],
              ),
            ),
    );
  }
}
