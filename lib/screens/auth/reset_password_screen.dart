import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

/// Se muestra cuando Supabase detecta un enlace de recuperación de contraseña
/// (AuthChangeEvent.passwordRecovery). Permite fijar una contraseña nueva.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.length < 6) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.updatePassword(_passwordController.text);
      setState(() => _done = true);
    } catch (e) {
      setState(() => _error = l10n.updatePasswordError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPasswordTitle), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _done
              ? [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(l10n.passwordUpdated, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(l10n.continueLabel),
                  ),
                ]
              : [
                  Text(
                    l10n.enterNewPasswordBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: l10n.newPasswordTitle, border: const OutlineInputBorder()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.save),
                  ),
                ],
        ),
      ),
    );
  }
}
