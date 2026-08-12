import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/contributor_service.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/profile_service.dart';
import '../services/public_document_service.dart';
import '../services/public_tray_service.dart';
import '../services/sterilization_service.dart';
import '../services/tray_service.dart';
import 'contributor_review_queue_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'public_library_review_queue_screen.dart';

class _InboxCounts {
  final int? groupContent;
  final int? contributorApplications;
  final int? publicLibrary;

  const _InboxCounts({this.groupContent, this.contributorApplications, this.publicLibrary});

  int get total => (groupContent ?? 0) + (contributorApplications ?? 0) + (publicLibrary ?? 0);
}

/// Punt d'entrada únic a les 3 cues de revisió que abans vivien separades
/// sense consciència mútua (docs/BACKLOG.md Nivell 2, pendent §16): canvis de
/// grup (tècniques/protocols/safates/targetes/esterilització), candidatures
/// de col·laboradors, i contingut de la Biblioteca Pública. Cada fila es
/// mostra només si l'usuari actual té el permís corresponent -- no hi ha cap
/// permís únic que cobreixi les 3 (veure el gate de cada fila), així que
/// aquesta pantalla és accessible des de dos llocs diferents (Activitat i
/// Perfil) i mostra les mateixes files independentment de per on s'hi arribi.
class ReviewInboxScreen extends StatelessWidget {
  const ReviewInboxScreen({super.key});

  bool get _canSeeGroupContent =>
      ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;

  bool get _canSeeCommunityQueues => ContributorService.instance.isEditorialBoard;

  Future<_InboxCounts> _load() async {
    final results = await Future.wait([
      if (_canSeeGroupContent)
        Future.wait([
          GroupDocumentService.instance.fetchReviewQueue(),
          TrayService.instance.fetchReviewQueue(),
          PreferenceCardService.instance.fetchReviewQueue(),
          SterilizationService.instance.fetchMethodReviewQueue(),
          SterilizationService.instance.fetchTechnicalInfoReviewQueue(),
        ]).then((lists) => lists.fold<int>(0, (sum, l) => sum + l.length))
      else
        Future.value(null),
      if (_canSeeCommunityQueues)
        ContributorService.instance.fetchPendingApplications().then((l) => l.length)
      else
        Future.value(null),
      if (_canSeeCommunityQueues)
        Future.wait([
          PublicDocumentService.instance.fetchReviewQueue(),
          PublicTrayService.instance.fetchReviewQueue(),
        ]).then((lists) => lists.fold<int>(0, (sum, l) => sum + l.length))
      else
        Future.value(null),
    ]);
    return _InboxCounts(
      groupContent: results[0],
      contributorApplications: results[1],
      publicLibrary: results[2],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewInboxTitle)),
      body: InstriqAsyncView<_InboxCounts>(
        load: _load,
        errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
        retryLabel: l10n.retry,
        builder: (context, counts) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(InstriqSpacing.lg),
            children: [
              if (counts.groupContent != null)
                _InboxRow(
                  icon: Icons.rate_review_outlined,
                  title: l10n.reviewQueueTitle,
                  subtitle: l10n.reviewQueueSubtitle,
                  count: counts.groupContent!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReviewQueueScreen()),
                  ),
                ),
              if (counts.contributorApplications != null) ...[
                const SizedBox(height: InstriqSpacing.sm),
                _InboxRow(
                  icon: Icons.fact_check_outlined,
                  title: l10n.contributorReviewQueueTitle,
                  count: counts.contributorApplications!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContributorReviewQueueScreen()),
                  ),
                ),
              ],
              if (counts.publicLibrary != null) ...[
                const SizedBox(height: InstriqSpacing.sm),
                _InboxRow(
                  icon: Icons.public_outlined,
                  title: l10n.publicLibraryReviewQueueTitle,
                  count: counts.publicLibrary!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PublicLibraryReviewQueueScreen()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onTap;

  const _InboxRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InstriqListItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: _CountBadge(count: count),
      onTap: onTap,
    );
  }
}

/// Petit indicador numèric -- no hi havia cap patró de badge numèric al
/// Design System (només `InstriqBadge` d'estat draft/in_review/published),
/// així que es queda com a widget privat d'aquesta pantalla fins que un
/// segon ús real en justifiqui la generalització.
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isZero = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isZero ? scheme.surfaceContainerHighest : scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isZero ? scheme.onSurfaceVariant : scheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
