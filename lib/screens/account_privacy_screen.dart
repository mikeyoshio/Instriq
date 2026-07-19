import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      setState(() => _exportError = 'No se pudo generar la exportación: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyExport() async {
    if (_exportedJson == null) return;
    await Clipboard.setData(ClipboardData(text: _exportedJson!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copiado al portapapeles')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final email = AuthService.instance.currentUser?.email;
    if (_confirmEmailController.text.trim().toLowerCase() != email?.toLowerCase()) {
      setState(() => _deleteError = 'El email no coincide con el de tu cuenta.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esto es irreversible. Se borran tus datos personales; el contenido que hayas '
          'creado o aprobado se conserva para tu equipo, mostrado como "Usuario eliminado".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar definitivamente'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta y privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Exportar mis datos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Descarga una copia de los datos que guarda Instriq sobre tu cuenta.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: const Text('Generar exportación'),
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
              label: const Text('Copiar'),
            ),
          ],
          const SizedBox(height: 32),
          Text('Eliminar mi cuenta', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Se borran tus datos personales (perfil, email). El contenido que hayas creado o '
            'aprobado se conserva para tu equipo, anonimizado como "Usuario eliminado". Si eres '
            'propietaria/o de un grupo con más miembros, primero debes transferir la propiedad '
            'desde Administrar grupo.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmEmailController,
            decoration: InputDecoration(
              labelText: 'Escribe tu email para confirmar',
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
            label: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }
}
