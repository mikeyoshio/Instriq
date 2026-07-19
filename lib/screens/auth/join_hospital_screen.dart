import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
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
  bool _loading = false;
  String? _error;

  Future<void> _join() async {
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
        setState(() => _error = 'Código de invitación no válido');
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Error al unirse: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instriq'),
        leading: _mode == _Mode.join
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _mode = _Mode.choose),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.groups_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          'Conecta con tu grupo',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Únete con el código de tu grupo, o créalo si eres la primera persona en darlo de alta.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _mode = _Mode.join),
            icon: const Icon(Icons.vpn_key),
            label: const Text('Conectarme con un código'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goRegister,
            icon: const Icon(Icons.add_business),
            label: const Text('Crear mi grupo'),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.vpn_key, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Introduce el código de invitación de tu grupo.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tu nombre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            border: OutlineInputBorder(),
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
            onPressed: _loading ? null : _join,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Unirse'),
          ),
        ),
      ],
    );
  }
}
