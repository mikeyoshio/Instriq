import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, OAuthProvider;

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<OAuthProvider> _providers = const [];
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    AuthService.instance.enabledOAuthProviders().then((p) {
      if (mounted) setState(() => _providers = p);
    });
    // Tant amb contrasenya com amb Google/Microsoft/Apple (que a l'app nativa
    // torna del navegador per l'enllaç instriq://) la sessió arriba aquí.
    _authSub = AuthService.instance.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _oauth(OAuthProvider provider) async {
    setState(() => _error = null);
    try {
      await AuthService.instance.signInWithOAuth(provider);
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.signInError(e.toString()));
    }
  }

  static String _providerLabel(OAuthProvider p) => switch (p.name) {
        'google' => 'Google',
        'azure' => 'Microsoft',
        _ => 'Apple',
      };

  static IconData _providerIcon(OAuthProvider p) => switch (p.name) {
        'google' => Icons.g_mobiledata,
        'azure' => Icons.window,
        _ => Icons.apple,
      };

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: _emailController.text.trim());
        return AlertDialog(
          title: Text(l10n.forgotDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.sendLink),
            ),
          ],
        );
      },
    );
    if (email == null || email.isEmpty) return;
    try {
      await AuthService.instance.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.forgotSnackbar)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Avisa al navegador / gestor de contrasenyes que l'inici ha anat bé:
      // és el que fa aparèixer "Desar contrasenya" a Chrome, Edge i iOS.
      TextInput.finishAutofillContext();
      // El pop el fa el listener de signedIn (initState).
      // HospitalConnectFlow reacciona al cambio de sesión y se refresca solo.
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.signInError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: Center(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medical_services, size: 64),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _signIn(),
                    decoration: InputDecoration(labelText: l10n.password, border: const OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.enter),
              ),
            ),
            TextButton(
              onPressed: _forgotPassword,
              child: Text(l10n.forgotPassword),
            ),
            if (_providers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l10n.signInOr)),
                const Expanded(child: Divider()),
              ]),
              for (final p in _providers) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _oauth(p),
                    icon: Icon(_providerIcon(p)),
                    label: Text(l10n.signInWithProvider(_providerLabel(p))),
                  ),
                ),
              ],
            ],
          ],
        ),
        ),
      ),
    );
  }
}
