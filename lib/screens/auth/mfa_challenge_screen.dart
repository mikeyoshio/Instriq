import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'mfa_setup_screen.dart';

/// Segon pas de l'inici de sessió per a qui té la verificació en dos passos
/// activada. No es pot tancar enrere: o codi correcte o tancar la sessió.
/// L'obre main.dart quan la sessió és aal1 però el compte té factor (aal2).
class MfaChallengeScreen extends StatefulWidget {
  const MfaChallengeScreen({super.key});

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = l10n.mfaInvalidCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final factor = AuthService.instance.currentUser?.factors
          ?.firstWhere((f) => f.factorType == FactorType.totp && f.status == FactorStatus.verified);
      await AuthService.instance.mfa.challengeAndVerify(factorId: factor!.id, code: code);
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.code == 'mfa_verification_failed' ? l10n.mfaInvalidCode : l10n.genericError(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = l10n.genericError(e.toString()));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.mfaTitle), automaticallyImplyLeading: false),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(l10n.mfaChallengeBody, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  MfaCodeField(controller: _codeController, onSubmitted: _busy ? null : _verify),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _busy ? null : _verify, child: Text(l10n.mfaVerify)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _signOut, child: Text(l10n.signOut)),
                  const SizedBox(height: 16),
                  Text(l10n.mfaLostDevice, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
