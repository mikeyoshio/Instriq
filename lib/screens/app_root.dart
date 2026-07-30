import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Carga el estado de sesión/hospital (si lo hay) una vez antes de pintar
/// [child] — el shell de navegación real, construido en main.dart a partir
/// del router (ver navigation/router.dart). Nunca exige login — el catálogo,
/// flashcards, quiz y progreso funcionan como invitado. Solo "Mi hospital"
/// pide conectar.
class AppRoot extends StatefulWidget {
  final Widget child;

  const AppRoot({super.key, required this.child});

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
      // Sin MaterialApp propio alrededor todavía (el de [child] es el
      // definitivo), así que este spinner necesita el suyo para tener
      // Directionality/localizations mínimas mientras carga.
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return widget.child;
  }
}
