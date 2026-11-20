import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

/// Verificació en dos passos (TOTP) opcional: activar-la amb una app
/// d'autenticació o desactivar-la. El codi es demana en iniciar sessió a
/// MfaChallengeScreen, i la base de dades l'exigeix (schema_v71).
class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Factor? _verified;
  AuthMFAEnrollResponse? _enrolling;

  GoTrueMFAApi get _mfa => AuthService.instance.mfa;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final factors = await _mfa.listFactors();
      if (mounted) setState(() => _verified = factors.totp.firstOrNull);
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.genericError(e.toString()));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = e.code == 'mfa_verification_failed' ? l10n.mfaInvalidCode : l10n.genericError(e.message));
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.genericError(e.toString()));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _start() => _run(() async {
        // Un intent anterior a mitges deixa un factor sense verificar: fora.
        final factors = await _mfa.listFactors();
        for (final f in factors.all.where((f) => f.status != FactorStatus.verified)) {
          await _mfa.unenroll(f.id);
        }
        final res = await _mfa.enroll(issuer: 'Instriq');
        if (mounted) setState(() => _enrolling = res);
      });

  Future<void> _verify() => _run(() async {
        final code = _codeController.text.trim();
        if (code.length != 6) throw AuthException('', code: 'mfa_verification_failed');
        await _mfa.challengeAndVerify(factorId: _enrolling!.id, code: code);
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mfaEnabledSnack)));
        _codeController.clear();
        _enrolling = null;
        await _load();
      });

  Future<void> _disable() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mfaTitle),
        content: Text(l10n.mfaDisableConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.mfaDisable)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _mfa.unenroll(_verified!.id);
      // Treu el nivell aal2 del token actual: sense factors ja no cal.
      await AuthService.instance.refreshSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mfaDisabledSnack)));
      setState(() => _verified = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mfaTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._buildBody(l10n),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n) {
    if (_verified != null) {
      return [
        const Icon(Icons.verified_user, size: 56, color: InstriqColors.statusPublished),
        const SizedBox(height: 16),
        Text(l10n.mfaEnabledBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: _busy ? null : _disable, child: Text(l10n.mfaDisable)),
      ];
    }
    final totp = _enrolling?.totp;
    if (totp == null) {
      return [
        const Icon(Icons.shield_outlined, size: 56),
        const SizedBox(height: 16),
        Text(l10n.mfaIntro, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _start, child: Text(l10n.mfaEnable)),
      ];
    }
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    return [
      Text(l10n.mfaScanStep),
      const SizedBox(height: 16),
      Center(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: SizedBox.square(dimension: 200, child: CustomPaint(painter: _QrPainter(totp.uri))),
        ),
      ),
      if (isMobile) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(totp.uri), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.mfaOpenApp),
        ),
      ],
      const SizedBox(height: 12),
      Text(l10n.mfaSecretLabel, style: Theme.of(context).textTheme.bodySmall),
      Row(
        children: [
          Expanded(child: SelectableText(totp.secret, style: const TextStyle(fontFamily: 'monospace'))),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: totp.secret));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
            },
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(l10n.mfaCodeStep),
      const SizedBox(height: 12),
      MfaCodeField(controller: _codeController, onSubmitted: _busy ? null : _verify),
      const SizedBox(height: 16),
      FilledButton(onPressed: _busy ? null : _verify, child: Text(l10n.mfaVerify)),
    ];
  }
}

/// Camp del codi de 6 xifres, compartit amb MfaChallengeScreen. oneTimeCode
/// deixa que iOS / el gestor de contrasenyes l'ompli sol.
class MfaCodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const MfaCodeField({super.key, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 8),
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.mfaCodeLabel,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// QR dibuixat en local amb el paquet qr (ja hi era via pdf): l'URI conté
/// el secret, així que no surt mai cap a cap servei de QR extern.
class _QrPainter extends CustomPainter {
  final QrImage _qr;

  _QrPainter(String data) : _qr = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _qr.moduleCount;
    final paint = Paint()..color = Colors.black;
    for (var y = 0; y < _qr.moduleCount; y++) {
      for (var x = 0; x < _qr.moduleCount; x++) {
        if (_qr.isDark(y, x)) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => false;
}
