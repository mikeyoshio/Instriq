import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class RegisterHospitalScreen extends StatefulWidget {
  const RegisterHospitalScreen({super.key});

  @override
  State<RegisterHospitalScreen> createState() => _RegisterHospitalScreenState();
}

class _RegisterHospitalScreenState extends State<RegisterHospitalScreen> {
  final _nameController = TextEditingController();
  final _adminNameController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _createdCode;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Indica el nombre del grupo');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hospital = await ProfileService.instance.registerHospital(
        name: name,
        displayName: _adminNameController.text.trim(),
      );
      setState(() => _createdCode = hospital.inviteCode);
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : 'Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdCode != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grupo creado')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Tu grupo ya está registrado. Comparte este código con tu equipo para que se unan:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SelectableText(
                _createdCode!,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Como creadora, eres la administradora: podrás regenerar este código o quitar miembros desde "Administrar grupo".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crear mi grupo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Un grupo puede ser un hospital, un bloque quirúrgico, un servicio, un equipo de '
                'instrumentistas o un centro de formación. Se generará un código de invitación único '
                'para que tu equipo se una.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _adminNameController,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Registrar grupo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
