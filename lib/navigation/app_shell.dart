import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import 'router.dart';
import 'work_mode_header.dart';

/// Shell de navegación de los 4 destinos fijos (2.0: Hoy · Buscar · Mi
/// equipo · Aprender). `navigationShell` viene de
/// `StatefulShellRoute.indexedStack`: conserva el estado y el `Navigator`
/// anidado de cada rama al cambiar de destino. Ya no hay pestañas ocultas
/// por rol (la antigua "Actividad" se repartió entre Hoy y Perfil), así que
/// el índice de la UI es el índice de la rama.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Volver a un destino ya seleccionado resetea su pila de navegación
      // anidada, igual que el comportamiento habitual de un bottom nav.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // WorkModeHeader depende del perfil (se oculta sin hospital).
    return ValueListenableBuilder<int>(
      valueListenable: ProfileService.instance.profileRevision,
      builder: (context, _, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= InstriqBreakpoints.tablet;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in appDestinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      const WorkModeHeader(),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          body: Column(
            children: [
              const WorkModeHeader(),
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              for (final d in appDestinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label(l10n),
                ),
            ],
          ),
        );
      },
    );
  }
}
