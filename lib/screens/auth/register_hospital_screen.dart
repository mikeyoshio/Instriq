import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/professional_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/professional_profile_picker.dart';

class RegisterHospitalScreen extends StatefulWidget {
  const RegisterHospitalScreen({super.key});

  @override
  State<RegisterHospitalScreen> createState() => _RegisterHospitalScreenState();
}

class _RegisterHospitalScreenState extends State<RegisterHospitalScreen> {
  final _nameController = TextEditingController();
  final _adminNameController = TextEditingController();
  Set<ProfessionalProfile> _selectedProfiles = {};
  bool _loading = false;
  String? _error;
  String? _createdCode;

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.groupNameRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hospital = await ProfileService.instance.registerHospital(
        name: name,
        displayName: _adminNameController.text.trim(),
      );
      if (_selectedProfiles.isNotEmpty) {
        await ProfileService.instance.setProfessionalProfiles(_selectedProfiles);
      }
      setState(() => _createdCode = hospital.inviteCode);
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : l10n.registerError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_createdCode != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.groupCreatedTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.groupCreatedBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SelectableText(
                _createdCode!,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ownerHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createMyGroup)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.createGroupExplainer),
              const SizedBox(height: 20),
              TextField(
                controller: _adminNameController,
                decoration: InputDecoration(
                  labelText: l10n.yourNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.groupNameFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.professionalProfileSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(l10n.professionalProfileSectionSubtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              ProfessionalProfilePicker(
                selected: _selectedProfiles,
                onChanged: (next) => setState(() => _selectedProfiles = next),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.registerGroupButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
