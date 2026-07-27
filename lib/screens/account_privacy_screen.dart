import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';

/// Derechos GDPR sobre la cuenta propia: exportar los datos personales y
/// eliminar la cuenta. Disponible siempre que haya sesión, pertenezca o no
/// a un grupo — el derecho no depende de eso.
class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  bool _exporting = false;
  String? _exportedJson;
  String? _exportError;

  bool _deleting = false;
  String? _deleteError;
  final _confirmEmailController = TextEditingController();

  @override
  void dispose() {
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _exportError = null;
    });
    try {
      final data = await AccountService.instance.exportMyData();
      const encoder = JsonEncoder.withIndent('  ');
      setState(() => _exportedJson = encoder.convert(data));
    } catch (e) {
      setState(() => _exportError = AppLocalizations.of(context)!.exportError(e.toString()));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyExport() async {
    if (_exportedJson == null) return;
    await Clipboard.setData(ClipboardData(text: _exportedJson!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final email = AuthService.instance.currentUser?.email;
    if (_confirmEmailController.text.trim().toLowerCase() != email?.toLowerCase()) {
      setState(() => _deleteError = l10n.emailMismatch);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _deleteError = null;
    });
    try {
      await AccountService.instance.deleteMyAccount();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _deleteError = '$e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountPrivacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.exportMyDataTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.exportMyDataBody),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: Text(l10n.generateExport),
          ),
          if (_exportError != null) ...[
            const SizedBox(height: 8),
            Text(_exportError!, style: const TextStyle(color: Colors.red)),
          ],
          if (_exportedJson != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(_exportedJson!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _copyExport,
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.copy),
            ),
          ],
          const SizedBox(height: 32),
          Text(l10n.deleteMyAccountTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.deleteAccountBody),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmEmailController,
            decoration: InputDecoration(
              labelText: l10n.confirmEmailLabel,
              hintText: AuthService.instance.currentUser?.email,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_deleteError != null) ...[
            Text(_deleteError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleting ? null : _confirmDelete,
            icon: _deleting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.deleteMyAccountTitle),
          ),
        ],
      ),
    );
  }
}
