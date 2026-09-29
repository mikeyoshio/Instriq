import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Lanza la carga del estado de sesión/hospital (si lo hay) sin bloquear la
/// primera pintura de [child] — el shell de navegación real, construido en
/// main.dart a partir del router (ver navigation/router.dart). Nunca exige
/// login — el catálogo, flashcards, quiz y progreso funcionan como invitado.
/// Solo "Mi hospital" pide conectar. `AppShell` ya escucha
/// `ProfileService.instance.profileRevision` (ver app_shell.dart) y se
/// reconstruye solo en cuanto `loadProfile()` termine, igual que ya hace tras
/// `joinHospitalWithCode` — así que no hace falta un spinner propio aquí
/// esperando esa misma llamada antes de pintar nada.
class AppRoot extends StatefulWidget {
  final Widget child;

  const AppRoot({super.key, required this.child});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    if (AuthService.instance.currentUser != null) {
      ProfileService.instance.loadProfile().catchError((_) {
        // Si falla, el usuario simplemente entra como invitado y puede
        // reintentar conectar su hospital desde el menú.
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
