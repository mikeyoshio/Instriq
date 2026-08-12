import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/contributor_profile.dart';
import '../services/contributor_service.dart';

class _PublicProfileData {
  final ContributorProfile profile;
  final String? organizationName;
  final List<String> areaNames;
  final int publishedContributionCount;

  const _PublicProfileData({
    required this.profile,
    this.organizationName,
    required this.areaNames,
    required this.publishedContributionCount,
  });
}

/// Perfil públic (només lectura) d'un col·laborador -- oberta a tothom,
/// inclosos convidats (docs/EPIC_COMMUNITY_GOVERNANCE.md §8). `null` si el
/// perfil no és públic en comptes de mostrar-ne el contingut privat.
class ContributorPublicProfileScreen extends StatelessWidget {
  final String userId;

  const ContributorPublicProfileScreen({super.key, required this.userId});

  Future<_PublicProfileData?> _load() async {
    final profile = await ContributorService.instance.fetchPublicProfile(userId);
    if (profile == null) return null;
    final results = await Future.wait([
      profile.showOrganization
          ? ContributorService.instance.fetchPublicOrganizationName(userId)
          : Future.value(null),
      ContributorService.instance.fetchAreaNames(userId),
      ContributorService.instance.fetchPublishedContributionCount(userId),
    ]);
    return _PublicProfileData(
      profile: profile,
      organizationName: results[0] as String?,
      areaNames: results[1] as List<String>,
      publishedContributionCount: results[2] as int,
    );
  }

  String _levelLabel(AppLocalizations l10n, ContributorLevel level) {
    switch (level) {
      case ContributorLevel.contributor:
        return l10n.contributorLevelContributor;
      case ContributorLevel.reviewer:
        return l10n.contributorLevelReviewer;
      case ContributorLevel.editorialBoard:
        return l10n.contributorLevelEditorialBoard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributorPublicProfileTitle)),
      body: InstriqAsyncView<_PublicProfileData?>(
        load: _load,
        errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
        retryLabel: l10n.retry,
        isEmpty: (data) => data == null,
        emptyBuilder: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.all(InstriqSpacing.xl),
            child: Text(l10n.contributorPublicProfileNotFound, textAlign: TextAlign.center),
          ),
        ),
        builder: (context, data) {
          final profile = data!.profile;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(InstriqSpacing.lg),
              children: [
                Text(
                  (profile.publicDisplayName?.trim().isNotEmpty ?? false)
                      ? profile.publicDisplayName!
                      : l10n.contributorLevelContributor,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: InstriqSpacing.sm),
                Chip(label: Text(_levelLabel(l10n, profile.level))),
                if (data.organizationName != null) ...[
                  const SizedBox(height: InstriqSpacing.md),
                  Text(l10n.contributorOrganizationLabel, style: Theme.of(context).textTheme.labelMedium),
                  Text(data.organizationName!),
                ],
                if ((profile.publicBio ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: InstriqSpacing.md),
                  Text(profile.publicBio!, style: Theme.of(context).textTheme.bodyLarge),
                ],
                if (data.areaNames.isNotEmpty) ...[
                  const SizedBox(height: InstriqSpacing.md),
                  Text(l10n.contributorCollaborationAreasLabel, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: InstriqSpacing.xs),
                  Wrap(
                    spacing: InstriqSpacing.xs,
                    runSpacing: InstriqSpacing.xs,
                    children: data.areaNames.map((name) => Chip(label: Text(name))).toList(),
                  ),
                ],
                const SizedBox(height: InstriqSpacing.lg),
                Text(l10n.contributorPublishedContributionsLabel(data.publishedContributionCount)),
              ],
            ),
          );
        },
      ),
    );
  }
}
