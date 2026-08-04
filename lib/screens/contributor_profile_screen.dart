import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contributor_profile.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';
import '../widgets/tag_picker.dart';

/// Perfil de col·laborador (EPIC 9, primer tram). Nomes visible un cop la
/// candidatura ha estat aprovada -- `ContributorService.instance.myProfile`.
/// Privadesa per defecte: `isPublic`/`showOrganization` comencen a `false`
/// (docs/EPIC_COMMUNITY_GOVERNANCE.md §2.3).
class ContributorProfileScreen extends StatefulWidget {
  const ContributorProfileScreen({super.key});

  @override
  State<ContributorProfileScreen> createState() => _ContributorProfileScreenState();
}

class _ContributorProfileScreenState extends State<ContributorProfileScreen> {
  final _tagPickerKey = GlobalKey<TagPickerState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late bool _showOrganization;
  late bool _isPublic;
  bool _saving = false;

  ContributorProfile? get _profile => ContributorService.instance.myProfile;

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _displayNameController = TextEditingController(text: profile?.publicDisplayName ?? '');
    _bioController = TextEditingController(text: profile?.publicBio ?? '');
    _showOrganization = profile?.showOrganization ?? false;
    _isPublic = profile?.isPublic ?? false;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ContributorService.instance.updateMyProfile(
        publicDisplayName: _displayNameController.text.trim().isEmpty ? '' : _displayNameController.text.trim(),
        publicBio: _bioController.text.trim(),
        showOrganization: _showOrganization,
        isPublic: _isPublic,
      );
      await _tagPickerKey.currentState?.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contributorProfileSavedSnackbar)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contributorProfileSaveError(e.toString()))));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = _profile;
    final userId = AuthService.instance.currentUser?.id;
    if (profile == null || userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.contributorProfileTitle)),
        body: Center(child: Text(l10n.contributorProfileNotFound)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributorProfileTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text(_levelLabel(l10n, profile.level))),
              const SizedBox(height: 20),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.contributorPublicDisplayNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.contributorPublicBioLabel),
              ),
              const SizedBox(height: 16),
              Text(l10n.contributorCollaborationAreasLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TagPicker(key: _tagPickerKey, refType: 'contributor', refId: userId),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.contributorIsPublicLabel),
                subtitle: Text(l10n.contributorIsPublicSubtitle),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.contributorShowOrganizationLabel),
                value: _showOrganization,
                onChanged: (value) => setState(() => _showOrganization = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.saveAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
