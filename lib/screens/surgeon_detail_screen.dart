import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_entity_usage_list.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../services/preference_card_service.dart';
import '../services/workspace_service.dart';
import 'preference_card_detail_screen.dart';

/// Ficha mínima de un cirujano: solo navegación inversa (qué tarjetas de
/// preferencia lo referencian), sin edición — se llega aquí tocando el chip
/// del cirujano en [PreferenceCardDetailScreen], nunca desde un menú propio.
class SurgeonDetailScreen extends StatelessWidget {
  final Surgeon surgeon;

  const SurgeonDetailScreen({super.key, required this.surgeon});

  Future<List<PreferenceCard>> _load() {
    return PreferenceCardService.instance.fetchForSurgeon(surgeon.id);
  }

  Future<void> _openCard(BuildContext context, PreferenceCard card) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(card.workspaceId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreferenceCardDetailScreen(card: card, myRole: myRole)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(surgeon.name)),
      body: InstriqAsyncView<List<PreferenceCard>>(
        load: _load,
        errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
        retryLabel: l10n.retry,
        builder: (context, cards) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InstriqSpacing.lg,
                InstriqSpacing.lg,
                InstriqSpacing.lg,
                0,
              ),
              child: Text(
                l10n.preferenceCardsCountTitle(cards.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(InstriqSpacing.xl),
                        child: Text(l10n.surgeonNoCardsEmptyState, textAlign: TextAlign.center),
                      ),
                    )
                  : InstriqEntityUsageList(
                      sections: [
                        EntityUsageSection(
                          label: null,
                          rows: cards
                              .map((card) => EntityUsageRow(
                                    icon: Icons.assignment_outlined,
                                    title: card.publishedVersion?.procedureName ?? l10n.unpublished,
                                    subtitle: l10n
                                        .instrumentsCount(card.publishedVersion?.items.length ?? 0),
                                    onTap: () => _openCard(context, card),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
