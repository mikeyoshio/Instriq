import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'join_hospital_screen.dart';
import 'welcome_screen.dart';

/// Flujo para conectar con (o crear) el hospital del usuario. Se empuja
/// desde el Home cuando alguien pulsa "Mi hospital" sin estar conectado, y
/// se cierra solo (pop) en cuanto detecta sesión + hospital, devolviendo el
/// control a quien lo empujó.
class HospitalConnectFlow extends StatefulWidget {
  const HospitalConnectFlow({super.key});

  @override
  State<HospitalConnectFlow> createState() => _HospitalConnectFlowState();
}

class _HospitalConnectFlowState extends State<HospitalConnectFlow> {
  bool _loading = true;
  bool _hasSession = false;
  bool _hasHospital = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    AuthService.instance.authStateChanges.listen((_) => _refresh());
  }

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
        final connected = ProfileService.instance.hasHospital;
        setState(() {
          _loading = false;
          _hasSession = true;
          _hasHospital = connected;
          _error = null;
        });
        if (connected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
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
    if (_loading || (_hasSession && _hasHospital)) {
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_hasSession) return const WelcomeScreen();
    return const JoinHospitalScreen();
  }
}
