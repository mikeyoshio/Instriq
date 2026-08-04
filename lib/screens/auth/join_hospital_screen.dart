import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/work_mode.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/work_mode_picker.dart';
import 'register_hospital_screen.dart';

enum _Mode { choose, join }

class JoinHospitalScreen extends StatefulWidget {
  const JoinHospitalScreen({super.key});

  @override
  State<JoinHospitalScreen> createState() => _JoinHospitalScreenState();
}

class _JoinHospitalScreenState extends State<JoinHospitalScreen> {
  _Mode _mode = _Mode.choose;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  WorkMode? _selectedWorkMode;
  bool _loading = false;
  String? _error;

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hospital = await ProfileService.instance
          .joinHospitalWithCode(code, displayName: _nameController.text.trim());
      if (hospital == null) {
        setState(() => _error = l10n.invalidInviteCode);
      } else if (mounted) {
        final navigator = Navigator.of(context);
        if (_selectedWorkMode != null) {
          await ProfileService.instance.setActiveWorkMode(_selectedWorkMode);
        }
        if (mounted) navigator.pop();
      }
    } catch (e) {
      setState(() => _error = l10n.joinError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterHospitalScreen()),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        leading: _mode == _Mode.join
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.backTooltip,
                onPressed: () => setState(() => _mode = _Mode.choose),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _mode == _Mode.choose ? _buildChoice(context) : _buildJoinForm(context),
        ),
      ),
    );
  }

  Widget _buildChoice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.groups_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          l10n.connectGroupTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.joinChooseBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _mode = _Mode.join),
            icon: const Icon(Icons.vpn_key),
            label: Text(l10n.connectWithCode),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goRegister,
            icon: const Icon(Icons.add_business),
            label: Text(l10n.createMyGroup),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.vpn_key, size: 56),
        const SizedBox(height: 16),
        Text(
          l10n.enterInviteCodeBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.yourNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l10n.inviteCodeLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.workModeOnboardingQuestion, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.professionalProfileSectionSubtitle, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        WorkModePicker(
          selected: _selectedWorkMode,
          onChanged: (next) => setState(() => _selectedWorkMode = next),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _join,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.join),
          ),
        ),
      ],
    );
  }
}
