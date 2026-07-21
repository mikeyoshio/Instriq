import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'sign_up_screen.dart';

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
      // HospitalConnectFlow reacciona al cambio de sesión y se refresca solo.
      if (mounted) Navigator.of(context).pop();
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 64),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password, border: const OutlineInputBorder()),
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              ),
              child: Text(l10n.noAccountSignUp),
            ),
            TextButton(
              onPressed: _forgotPassword,
              child: Text(l10n.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
