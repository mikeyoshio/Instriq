import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/org_type.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/chain_hierarchy_preview_dialog.dart';
import '../../widgets/send_feedback_dialog.dart';
import 'sign_in_screen.dart';

enum _Mode { choose, join, create }

/// "Cadena" (NO "grup" -- aquesta pantalla ja fa servir "grup" per a
/// l'organització mateixa, p. ex. `l10n.createMyGroup`): si una organització
/// forma part d'una xarxa de diverses seus (tipus Quirón), o és una seu
/// única per ara. Veure schema_v65_hospital_groups.sql.
enum _ChainScope { solo, newChain, joinChain }

/// Pantalla única que sustituye a WelcomeScreen + SignUpScreen +
/// JoinHospitalScreen + RegisterHospitalScreen: resuelve de entrada la
/// decisión unir-se/crear-se (sense la pregunta incoherent que feia
/// WelcomeScreen) i inclou el registre (email+contrasenya) dins del mateix
/// formulari quan encara no hi ha sessió, en lloc de forçar un pas separat.
class GroupEntryScreen extends StatefulWidget {
  final bool hasSessionAlready;
  final VoidCallback onCompleted;

  const GroupEntryScreen({
    super.key,
    required this.hasSessionAlready,
    required this.onCompleted,
  });

  @override
  State<GroupEntryScreen> createState() => _GroupEntryScreenState();
}

class _GroupEntryScreenState extends State<GroupEntryScreen> {
  _Mode _mode = _Mode.choose;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _chainNameController = TextEditingController();
  final _chainCodeController = TextEditingController();

  bool _loading = false;
  String? _error;
  OrgType _orgType = OrgType.hospital;
  _ChainScope _chainScope = _ChainScope.solo;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _groupNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _chainNameController.dispose();
    _chainCodeController.dispose();
    super.dispose();
  }

  void _setMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _goSignIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
    // SignInScreen ja fa pop() en èxit; si ara hi ha sessió, refresquem
    // HospitalConnectFlow perquè torni a mostrar aquesta pantalla amb
    // hasSessionAlready: true.
    if (mounted && AuthService.instance.currentUser != null) {
      widget.onCompleted();
    }
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!widget.hasSessionAlready) {
        try {
          await AuthService.instance.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (e) {
          setState(() => _error = l10n.signUpError(e.toString()));
          return;
        }
      }
      final hospital = await ProfileService.instance
          .joinHospitalWithCode(code, displayName: _nameController.text.trim());
      if (hospital == null) {
        setState(() => _error = l10n.invalidInviteCode);
      } else {
        widget.onCompleted();
      }
    } catch (e) {
      setState(() => _error = l10n.joinError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.groupNameRequired);
      return;
    }
    final chainName = _chainNameController.text.trim();
    final chainCode = _chainCodeController.text.trim();
    if (_chainScope == _ChainScope.newChain && chainName.isEmpty) {
      setState(() => _error = l10n.chainNameRequired);
      return;
    }
    if (_chainScope == _ChainScope.joinChain && chainCode.isEmpty) {
      setState(() => _error = l10n.chainCodeRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!widget.hasSessionAlready) {
        try {
          await AuthService.instance.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (e) {
          setState(() => _error = l10n.signUpError(e.toString()));
          return;
        }
      }
      final hospital = await ProfileService.instance.registerHospital(
        name: name,
        displayName: _nameController.text.trim(),
        orgType: _orgType.dbValue,
        newChainName: _chainScope == _ChainScope.newChain ? chainName : null,
        existingChainCode: _chainScope == _ChainScope.joinChain ? chainCode : null,
      );
      if (!mounted) return;
      await _showCreatedDialog(hospital.inviteCode, chainCode: hospital.groupCode);
      if (mounted) widget.onCompleted();
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : l10n.registerError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreatedDialog(String code, {String? chainCode}) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.groupCreatedTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.groupCreatedBody),
              const SizedBox(height: 16),
              _CodeBlock(
                code: code,
                style: Theme.of(dialogContext)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
                copiedLabel: l10n.copiedToClipboard,
              ),
              const SizedBox(height: 12),
              Text(l10n.ownerHint),
              if (chainCode != null) ...[
                const Divider(height: 32),
                Text(l10n.chainCreatedCodeTitle, style: Theme.of(dialogContext).textTheme.labelLarge),
                const SizedBox(height: 8),
                _CodeBlock(
                  code: chainCode,
                  style: Theme.of(dialogContext)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
                  copiedLabel: l10n.copiedToClipboard,
                ),
                const SizedBox(height: 8),
                Text(l10n.chainCreatedCodeBody, style: Theme.of(dialogContext).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _mode == _Mode.choose,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _setMode(_Mode.choose);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: widget.hasSessionAlready
              ? [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: l10n.signOut,
                    onPressed: () => AuthService.instance.signOut(),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (_mode) {
              _Mode.choose => _buildChoice(context, l10n),
              _Mode.join => _buildJoinForm(context, l10n),
              _Mode.create => _buildCreateForm(context, l10n),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChoice(BuildContext context, AppLocalizations l10n) {
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
        Text(l10n.joinChooseBody, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _setMode(_Mode.join),
            icon: const Icon(Icons.vpn_key),
            label: Text(l10n.connectWithCode),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _setMode(_Mode.create),
            icon: const Icon(Icons.add_business),
            label: Text(l10n.createMyGroup),
          ),
        ),
        if (!widget.hasSessionAlready) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: _goSignIn,
            child: Text(l10n.alreadyHaveAccount),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.vpn_key, size: 56),
        const SizedBox(height: 16),
        Text(l10n.enterInviteCodeBody, textAlign: TextAlign.center),
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
        if (!widget.hasSessionAlready) ..._buildCredentialsFields(l10n),
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

  Widget _buildCreateForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.createGroupExplainer),
        const SizedBox(height: 20),
        Text(l10n.orgTypeQuestion, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrgType.values.map((type) {
            return ChoiceChip(
              label: Text(type.label(l10n)),
              selected: _orgType == type,
              onSelected: (_) => setState(() => _orgType = type),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(l10n.chainScopeQuestion, style: Theme.of(context).textTheme.labelLarge),
            ),
            TextButton(
              onPressed: () => showChainHierarchyPreviewDialog(context, isChain: _chainScope != _ChainScope.solo),
              child: Text(l10n.chainHierarchyPreviewLink),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.chainScopeSolo),
              selected: _chainScope == _ChainScope.solo,
              onSelected: (_) => setState(() => _chainScope = _ChainScope.solo),
            ),
            ChoiceChip(
              label: Text(l10n.chainScopeNew),
              selected: _chainScope == _ChainScope.newChain,
              onSelected: (_) => setState(() => _chainScope = _ChainScope.newChain),
            ),
            ChoiceChip(
              label: Text(l10n.chainScopeJoin),
              selected: _chainScope == _ChainScope.joinChain,
              onSelected: (_) => setState(() => _chainScope = _ChainScope.joinChain),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          switch (_chainScope) {
            _ChainScope.solo => l10n.chainScopeSoloHelp,
            _ChainScope.newChain => l10n.chainScopeNewHelp,
            _ChainScope.joinChain => l10n.chainScopeJoinHelp,
          },
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_chainScope == _ChainScope.solo) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => showSendFeedbackDialog(context),
            child: Text(l10n.contactUsForChainUpgrade),
          ),
        ],
        if (_chainScope == _ChainScope.newChain) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _chainNameController,
            decoration: InputDecoration(
              labelText: l10n.chainNameFieldLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (_chainScope == _ChainScope.joinChain) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _chainCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.chainCodeFieldLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.yourNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _groupNameController,
          decoration: InputDecoration(
            labelText: l10n.groupNameFieldLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (!widget.hasSessionAlready) ..._buildCredentialsFields(l10n),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _create,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.create),
        ),
      ],
    );
  }

  List<Widget> _buildCredentialsFields(AppLocalizations l10n) {
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration:
            InputDecoration(labelText: l10n.passwordMinChars, border: const OutlineInputBorder()),
      ),
    ];
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final TextStyle? style;
  final String copiedLabel;

  const _CodeBlock({required this.code, required this.style, required this.copiedLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SelectableText(code, style: style),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copiedLabel)));
          },
        ),
      ],
    );
  }
}
