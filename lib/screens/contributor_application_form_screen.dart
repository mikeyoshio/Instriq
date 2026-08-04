import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';

/// Formulari de candidatura de col·laborador (EPIC 9, primer tram). Un cop
/// enviat queda `pending` fins que l'Editorial Board el revisi -- mai
/// s'aprova sol (docs/EPIC_COMMUNITY_GOVERNANCE.md §1).
class ContributorApplicationFormScreen extends StatefulWidget {
  const ContributorApplicationFormScreen({super.key});

  @override
  State<ContributorApplicationFormScreen> createState() => _ContributorApplicationFormScreenState();
}

class _ContributorApplicationFormScreenState extends State<ContributorApplicationFormScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final _countryController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _professionalRoleController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _linkedinUrlController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _publicationsController = TextEditingController();
  final _motivationController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController(text: AuthService.instance.currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _organizationNameController.dispose();
    _professionalRoleController.dispose();
    _yearsExperienceController.dispose();
    _linkedinUrlController.dispose();
    _certificationsController.dispose();
    _publicationsController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _motivationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contributorFormRequiredFieldsError)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ContributorService.instance.submitApplication(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        organizationName:
            _organizationNameController.text.trim().isEmpty ? null : _organizationNameController.text.trim(),
        professionalRole:
            _professionalRoleController.text.trim().isEmpty ? null : _professionalRoleController.text.trim(),
        yearsExperience: int.tryParse(_yearsExperienceController.text.trim()),
        linkedinUrl: _linkedinUrlController.text.trim().isEmpty ? null : _linkedinUrlController.text.trim(),
        certifications: _certificationsController.text.trim().isEmpty ? null : _certificationsController.text.trim(),
        publicationsOrTeaching:
            _publicationsController.text.trim().isEmpty ? null : _publicationsController.text.trim(),
        motivationLetter: _motivationController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contributorFormSubmitError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributorApplicationTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.contributorApplicationIntro, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: l10n.contributorFullNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.contributorEmailLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _countryController,
                decoration: InputDecoration(labelText: l10n.contributorCountryLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _organizationNameController,
                decoration: InputDecoration(labelText: l10n.contributorOrganizationNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _professionalRoleController,
                decoration: InputDecoration(labelText: l10n.contributorProfessionalRoleLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearsExperienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.contributorYearsExperienceLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkedinUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: l10n.contributorLinkedinLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _certificationsController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.contributorCertificationsLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _publicationsController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.contributorPublicationsLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivationController,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.contributorMotivationLabel),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(l10n.contributorSubmitApplicationAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
