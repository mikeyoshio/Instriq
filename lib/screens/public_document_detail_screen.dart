import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/public_document.dart';

/// Vista de lectura d'una tècnica/protocol publicat a la Biblioteca Pública
/// -- oberta a tothom, inclosos convidats. Deliberadament nomes lectura en
/// aquest tram: adoptar-la com a versió local d'una organització depèn de
/// com s'apliqui en detall ADR-001 (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md),
/// encara no fet.
class PublicDocumentDetailScreen extends StatelessWidget {
  final PublicDocument document;

  const PublicDocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = document.publishedVersion;
    return Scaffold(
      appBar: AppBar(title: Text(version?.title ?? l10n.auditDocumentUntitledLabel)),
      body: version == null
          ? Center(child: Text(l10n.publicLibraryEmptyState))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
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
                ],
              ),
            ),
    );
  }
}
