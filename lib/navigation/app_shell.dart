import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import 'router.dart';
import 'work_mode_header.dart';

/// Breakpoint tablet: por debajo, bottom nav (`NavigationBar`); a partir de
/// aquí, rail fijo a la izquierda (`NavigationRail`). Mismo umbral que usa
/// Material 3 para "medium window size class".
const _tabletBreakpoint = 840.0;

/// Índice de la rama "Activitat" dentro de `appDestinations`/las 5 ramas de
/// `StatefulShellRoute.indexedStack` en `router.dart` (0 Inici, 1 Cercar,
/// 2 Biblioteca, 3 Activitat, 4 Perfil) — para quien no es admin ni approver
/// de ningún espacio, `ActivityScreen` solo muestra un texto de "sin acceso"
/// (callejón sin salida), así que aquí se oculta la pestaña en vez de
/// mostrarla vacía. Las ramas en sí no se tocan (go_router sigue teniendo
/// las 5), solo se filtra qué se muestra en el `NavigationBar`/`NavigationRail`.
const _activityBranchIndex = 3;

/// Shell de navegación de los destinos fijos. `navigationShell` viene de
/// `StatefulShellRoute.indexedStack`: conserva el estado y el `Navigator`
/// anidado de cada rama al cambiar de destino.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  List<int> _visibleBranchIndices() {
    // isAdmin (flag global) o canApproveAnyWorkspace (rol approver en algún
    // espacio, por fila de workspace_members) — ver profile_service.dart.
    final canAccessActivity =
        ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
    return [
      for (var i = 0; i < appDestinations.length; i++)
        if (i != _activityBranchIndex || canAccessActivity) i,
    ];
  }

  void _onDestinationSelected(List<int> visibleBranchIndices, int uiIndex) {
    final branchIndex = visibleBranchIndices[uiIndex];
    navigationShell.goBranch(
      branchIndex,
      // Volver a un destino ya seleccionado resetea su pila de navegación
      // anidada, igual que el comportamiento habitual de un bottom nav.
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProfileService.instance.profileRevision,
      builder: (context, _, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleBranchIndices = _visibleBranchIndices();
    final visibleDestinations = [for (final i in visibleBranchIndices) appDestinations[i]];
    // Si la rama activa está oculta (p.ej. se dejó de ser admin), cae a la
    // primera visible en vez de un índice fuera de rango.
    final selectedUiIndex = visibleBranchIndices.indexOf(navigationShell.currentIndex);
    final safeSelectedUiIndex = selectedUiIndex == -1 ? 0 : selectedUiIndex;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _tabletBreakpoint;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: safeSelectedUiIndex,
                  onDestinationSelected: (i) => _onDestinationSelected(visibleBranchIndices, i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in visibleDestinations)
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
            selectedIndex: safeSelectedUiIndex,
            onDestinationSelected: (i) => _onDestinationSelected(visibleBranchIndices, i),
            destinations: [
              for (final d in visibleDestinations)
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
