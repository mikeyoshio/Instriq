import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../home_screen.dart';

class JoinHospitalScreen extends StatefulWidget {
  const JoinHospitalScreen({super.key});

  @override
  State<JoinHospitalScreen> createState() => _JoinHospitalScreenState();
}

class _JoinHospitalScreenState extends State<JoinHospitalScreen> {
  final _codeController = TextEditingController();
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
      final hospital = await ProfileService.instance.joinHospitalWithCode(code);
      if (hospital == null) {
        setState(() => _error = 'Código de invitación no válido');
      } else if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = 'Error al unirse: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse a un hospital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Introduce el código de invitación de tu hospital para acceder a las tarjetas de preferencia compartidas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
