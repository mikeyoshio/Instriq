import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/suture.dart';
import '../services/group_document_service.dart';
import '../services/knowledge_link_service.dart';
import 'group_document_detail_screen.dart';

/// Fitxa d'una sutura del catàleg. Deliberadament sense esterilització/fitxa
/// tècnica (és consumible d'un sol ús, no reutilitzable) ni favorits/quiz
/// (fora d'abast en aquesta primera passada) -- però amb la mateixa secció
/// "Usat a" que instruments/safates, via `knowledge_links` (`to_type='suture'`).
class SutureDetailScreen extends StatefulWidget {
  final Suture suture;

  const SutureDetailScreen({super.key, required this.suture});

  @override
  State<SutureDetailScreen> createState() => _SutureDetailScreenState();
}

class _SutureDetailScreenState extends State<SutureDetailScreen> {
  static const String _refType = 'suture';

  bool _loadingUsedIn = true;
  List<GroupDocument> _usedInDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadUsedIn();
  }

  Future<void> _loadUsedIn() async {
    try {
      final links = await KnowledgeLinkService.instance.fetchRelatedTo(_refType, widget.suture.id);
      final usedInDocuments = <GroupDocument>[];
      for (final link in links) {
        if (link.fromType == 'group_document') {
          try {
            usedInDocuments.add(await GroupDocumentService.instance.fetchDocument(link.fromId));
          } catch (_) {
            // Enllaç obsolet (document esborrat sense netejar a temps): s'omet.
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _usedInDocuments = usedInDocuments;
        _loadingUsedIn = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUsedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suture = widget.suture;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(suture.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(suture.material.label)),
                Chip(label: Text(suture.gauge)),
                Chip(label: Text(suture.needleType.label)),
                Chip(label: Text(suture.absorbable ? l10n.sutureAbsorbable : l10n.sutureNonAbsorbable)),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(suture.description.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(suture.use.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            if (suture.tip != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text(suture.tip!.forLanguageCode(languageCode))),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 32),
            Text(l10n.knowledgeGraphUsedInTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loadingUsedIn)
              const Center(child: CircularProgressIndicator())
            else if (_usedInDocuments.isEmpty)
              Text(l10n.knowledgeGraphUsedInEmptyState, style: Theme.of(context).textTheme.bodyMedium)
            else
              ..._usedInDocuments.map((doc) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(doc.publishedVersion?.title ?? doc.id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDocumentDetailScreen(document: doc, myRole: null),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
