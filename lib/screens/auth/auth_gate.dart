import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../home_screen.dart';
import 'join_hospital_screen.dart';
import 'sign_in_screen.dart';

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

  Future<void> _refresh() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasSession = false;
          _hasHospital = false;
        });
      }
      return;
    }
    await ProfileService.instance.loadProfile();
    if (mounted) {
      setState(() {
        _loading = false;
        _hasSession = true;
        _hasHospital = ProfileService.instance.hasHospital;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasSession) return const SignInScreen();
    if (!_hasHospital) return const JoinHospitalScreen();
    return const HomeScreen();
  }
}
