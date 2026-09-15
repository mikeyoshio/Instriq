import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/invitation.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/workspace_role_label.dart';
import 'sign_in_screen.dart';

/// Pantalla que abre el enlace de una invitación por email
/// (`/invite/:token`, ver schema_v41_invitations.sql). Ruta de nivel
/// superior, fuera del shell de navegación (ver `router.dart`): quien llega
/// aquí puede no tener sesión todavía. Deliberadamente su propio formulario
/// mínimo (nombre + contraseña, con el correo ya fijado por la invitación) en
/// vez de reutilizar [GroupEntryScreen]: esa pantalla resuelve unirse con
/// código/crear grupo, un flujo distinto que no encaja con "ya sé a qué
/// espacio y con qué rol me uno".
class AcceptInvitationScreen extends StatefulWidget {
  final String token;

  const AcceptInvitationScreen({super.key, required this.token});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _declined = false;
  InvitationPreview? _preview;
  String? _loadError;
  String? _actionError;

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      _preview = await InvitationService.instance.preview(widget.token);
    } catch (e) {
      if (mounted) _loadError = AppLocalizations.of(context)!.acceptInviteLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createAccountAndAccept() async {
    final l10n = AppLocalizations.of(context)!;
    if (_preview == null || _passwordController.text.isEmpty) return;
    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      await AuthService.instance.signUp(email: _preview!.email, password: _passwordController.text);
      await _accept();
    } catch (e) {
      if (mounted) setState(() => _actionError = l10n.genericError(e.toString()));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _goSignIn() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
    if (mounted && AuthService.instance.currentUser != null) {
      await _accept();
    }
  }

  Future<void> _accept() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      await ProfileService.instance.acceptInvitation(widget.token, displayName: _nameController.text.trim());
      if (mounted) context.go('/inicio');
    } catch (e) {
      if (mounted) setState(() => _actionError = l10n.genericError(e.toString()));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _actionError = null;
    });
    try {
      await InvitationService.instance.decline(widget.token);
      if (mounted) setState(() => _declined = true);
    } catch (e) {
      if (mounted) setState(() => _actionError = l10n.genericError(e.toString()));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.acceptInviteAppBarTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(child: _buildBody(context, l10n)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(_loadError!, textAlign: TextAlign.center),
        ],
      );
    }
    final preview = _preview!;
    if (_declined) {
      return _buildMessage(Icons.check_circle_outline, l10n.acceptInviteDeclinedBody);
    }
    switch (preview.status) {
      case InvitationStatus.accepted:
        return _buildMessage(Icons.check_circle_outline, l10n.acceptInviteAlreadyAcceptedBody);
      case InvitationStatus.revoked:
        return _buildMessage(Icons.block_outlined, l10n.acceptInviteRevokedBody);
      case InvitationStatus.expired:
        return _buildMessage(Icons.hourglass_disabled_outlined, l10n.acceptInviteExpiredBody);
      case InvitationStatus.pending:
        return _buildPending(context, l10n, preview);
    }
  }

  Widget _buildMessage(IconData icon, String body) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 16),
        Text(body, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildPending(BuildContext context, AppLocalizations l10n, InvitationPreview preview) {
    final loggedIn = AuthService.instance.currentUser != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mail_outline, size: 48),
        const SizedBox(height: 16),
        Text(l10n.acceptInviteHeading, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          l10n.acceptInviteBody(
            preview.invitedByName?.isNotEmpty == true ? preview.invitedByName! : preview.organizationName,
            preview.workspaceName,
            preview.organizationName,
            workspaceRoleLabel(l10n, preview.role),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_actionError != null) ...[
          Text(_actionError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 12),
        ],
        if (loggedIn) ...[
          FilledButton(
            onPressed: _submitting ? null : _accept,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.acceptInviteAcceptButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _submitting ? null : _decline,
            child: Text(l10n.acceptInviteDeclineButton),
          ),
        ] else ...[
          Text(l10n.acceptInviteCreateAccountIntro, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            controller: TextEditingController(text: preview.email),
            decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.yourNameLabel, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.passwordMinChars, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _createAccountAndAccept,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.acceptInviteCreateAccountButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : _goSignIn,
            child: Text(l10n.acceptInviteAlreadyHaveAccount),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : _decline,
            child: Text(l10n.acceptInviteDeclineButton),
          ),
        ],
      ],
    );
  }
}
