import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../screens/activity_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_hub_screen.dart';
import 'app_shell.dart';

/// `AppRoot` nunca exige login: la ruta inicial entra directo al shell, sin
/// ningún `redirect` que gatee por sesión (ver screens/app_root.dart).
///
/// Cada rama del `IndexedStack` lleva su propio `Navigator` (un
/// `navigatorKey` por `StatefulShellBranch`), así el `Navigator.push` normal
/// que ya usan las 33 pantallas existentes sigue funcionando sin cambios
/// dentro de cada destino.
final _homeBranchKey = GlobalKey<NavigatorState>();
final _searchBranchKey = GlobalKey<NavigatorState>();
final _libraryBranchKey = GlobalKey<NavigatorState>();
final _activityBranchKey = GlobalKey<NavigatorState>();
final _profileBranchKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(GlobalKey<NavigatorState> rootNavigatorKey) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/inicio',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeBranchKey,
            routes: [
              GoRoute(path: '/inicio', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchBranchKey,
            routes: [
              GoRoute(path: '/buscar', builder: (context, state) => const CatalogScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _libraryBranchKey,
            routes: [
              GoRoute(path: '/biblioteca', builder: (context, state) => const LibraryScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _activityBranchKey,
            routes: [
              GoRoute(path: '/actividad', builder: (context, state) => const ActivityScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileBranchKey,
            routes: [
              GoRoute(path: '/perfil', builder: (context, state) => const ProfileHubScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Metadatos de los 5 destinos fijos, compartidos entre `NavigationBar`
/// (< 840px) y `NavigationRail` (>= 840px) en [AppShell].
class AppDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;

  const AppDestination({required this.icon, required this.selectedIcon, required this.label});
}

const appDestinations = [
  AppDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: _homeLabel,
  ),
  AppDestination(
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    label: _searchLabel,
  ),
  AppDestination(
    icon: Icons.local_library_outlined,
    selectedIcon: Icons.local_library,
    label: _libraryLabel,
  ),
  AppDestination(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    label: _activityLabel,
  ),
  AppDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: _profileLabel,
  ),
];

String _homeLabel(AppLocalizations l10n) => l10n.navHome;
String _searchLabel(AppLocalizations l10n) => l10n.navSearch;
String _libraryLabel(AppLocalizations l10n) => l10n.navLibrary;
String _activityLabel(AppLocalizations l10n) => l10n.navActivity;
String _profileLabel(AppLocalizations l10n) => l10n.navProfile;
