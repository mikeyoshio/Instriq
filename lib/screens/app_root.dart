import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';

/// Raíz de la app: carga el estado de sesión/hospital (si lo hay) una vez y
/// entra directo al Home. Nunca exige login — el catálogo, flashcards, quiz
/// y progreso funcionan como invitado. Solo "Mi hospital" pide conectar.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (AuthService.instance.currentUser != null) {
      try {
        await ProfileService.instance.loadProfile();
      } catch (_) {
        // Si falla, el usuario simplemente entra como invitado y puede
        // reintentar conectar su hospital desde el menú.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const HomeScreen();
  }
}
