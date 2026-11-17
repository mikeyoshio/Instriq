import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/profile_hub_screen.dart';

/// Accés a Perfil des de la barra superior de les 4 pestanyes (2.0: Perfil
/// ja no és pestanya). S'obre al navigator arrel, per sobre del shell.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: AppLocalizations.of(context)!.navProfile,
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ProfileHubScreen()),
      ),
    );
  }
}
