import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../home_screen.dart';
import 'join_hospital_screen.dart';
import 'welcome_screen.dart';

/// Decide qué pantalla mostrar según el estado de sesión y de hospital del usuario.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasSession = false;
  bool _hasHospital = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    AuthService.instance.authStateChanges.listen((_) => _refresh());
  }

  String? _error;

  Future<void> _refresh() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasSession = false;
          _hasHospital = false;
          _error = null;
        });
      }
      return;
    }
    try {
      await ProfileService.instance.loadProfile();
      if (mounted) {
        setState(() {
          _loading = false;
          _hasSession = true;
          _hasHospital = ProfileService.instance.hasHospital;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar tu perfil: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _refresh();
                  },
                  child: const Text('Reintentar'),
                ),
                TextButton(
                  onPressed: () => AuthService.instance.signOut(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_hasSession) return const WelcomeScreen();
    if (!_hasHospital) return const JoinHospitalScreen();
    return const HomeScreen();
  }
}
