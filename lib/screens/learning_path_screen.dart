import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/workspace.dart';
import '../services/profile_service.dart';
import '../services/workspace_service.dart';
import 'auth/hospital_connect_flow.dart';
import 'catalog_screen.dart';
import 'flashcards_screen.dart';
import 'public_library_screen.dart';
import 'quiz_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Claves de persistencia local de cada paso -- usadas tal cual como String
/// en `SharedPreferences` (mismo backend que [ProgressService] en modo
/// invitado, ya dependencia del proyecto -- no hace falta tabla nueva en
/// Supabase: nadie necesita ver esta checklist desde otro dispositivo ni el
/// equipo necesita verla de nadie más).
enum _StepId { catalog, flashcards, quiz, publicLibrary, joinTeam, trays }

/// Ruta de aprendizaje guiada (inspirada en Periop 101/"The Stitch" de
/// AORN): no es contenido nuevo, solo secuencia pantallas que ya existen en
/// un orden con sentido para quien empieza de cero en Instriq, con un
/// checklist de progreso puramente local.
///
/// Los pasos "Únete a un equipo" y "Conoce las bandejas de tu equipo" son
/// mutuamente excluyentes según [ProfileService.hasHospital]: sin hospital
/// solo tiene sentido pedir que se una a uno; con hospital ya no hay nada
/// que "unirse", así que ese paso se sustituye por el acceso real a bandejas.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  static const _prefsKey = 'learning_path_completed_steps';

  SharedPreferences? _prefs;
  Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getStringList(_prefsKey) ?? <String>[]).toSet();
    // "Únete a un equipo" no navega a una pantalla propia que marcar al
    // volver -- tener hospital asignado ya es la señal real de que se hizo.
    if (ProfileService.instance.hasHospital) {
      completed.add(_StepId.joinTeam.name);
    }
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _completed = completed;
    });
    await prefs.setStringList(_prefsKey, completed.toList());
  }

  Future<void> _markDone(_StepId step) async {
    if (_completed.contains(step.name)) return;
    final updated = {..._completed, step.name};
    setState(() => _completed = updated);
    await _prefs?.setStringList(_prefsKey, updated.toList());
  }

  Future<void> _openStep(_StepId step, Widget Function() builder) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder()));
    if (!mounted) return;
    await _markDone(step);
  }

  /// Mismo patrón que `_openWorkspaceCollection` de home_screen.dart: con un
  /// único espacio se salta directo a sus bandejas; con 0 o 2+, se abre el
  /// selector de espacios. Inline aquí (no se extrae como helper compartido)
  /// porque esta pantalla solo navega a una colección de grupo, no a cinco.
  Future<void> _openTrays() async {
    await WorkspaceService.instance.fetchWorkspaces();
    final workspaces = WorkspaceService.instance.workspaces;
    if (!mounted) return;
    if (workspaces.length == 1) {
      final Workspace workspace = workspaces.first;
      final myRole = await WorkspaceService.instance.fetchMyRole(workspace.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TraysScreen(workspace: workspace, myRole: myRole)),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
      );
    }
    if (!mounted) return;
    await _markDone(_StepId.trays);
  }

  /// A diferencia del resto de pasos, "volver" de este flujo no basta por sí
  /// solo: solo cuenta como hecho si de verdad queda `hasHospital == true`
  /// (igual que el chequeo de [_load] al abrir la pantalla) -- cancelar el
  /// flujo no debe marcarlo como completado.
  Future<void> _openJoinTeam() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HospitalConnectFlow()),
    );
    if (!mounted) return;
    if (ProfileService.instance.hasHospital) {
      await _markDone(_StepId.joinTeam);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasHospital = ProfileService.instance.hasHospital;

    final steps = <_Step>[
      _Step(
        id: _StepId.catalog,
        icon: Icons.menu_book,
        title: l10n.learningPathCatalogTitle,
        subtitle: l10n.learningPathCatalogSubtitle,
        onTap: () => _openStep(_StepId.catalog, () => const CatalogScreen()),
      ),
      _Step(
        id: _StepId.flashcards,
        icon: Icons.style_outlined,
        title: l10n.learningPathFlashcardsTitle,
        subtitle: l10n.learningPathFlashcardsSubtitle,
        onTap: () => _openStep(_StepId.flashcards, () => const FlashcardsScreen()),
      ),
      _Step(
        id: _StepId.quiz,
        icon: Icons.quiz_outlined,
        title: l10n.learningPathQuizTitle,
        subtitle: l10n.learningPathQuizSubtitle,
        onTap: () => _openStep(_StepId.quiz, () => const QuizScreen()),
      ),
      _Step(
        id: _StepId.publicLibrary,
        icon: Icons.public,
        title: l10n.learningPathPublicLibraryTitle,
        subtitle: l10n.learningPathPublicLibrarySubtitle,
        onTap: () => _openStep(_StepId.publicLibrary, () => const PublicLibraryScreen()),
      ),
      if (hasHospital)
        _Step(
          id: _StepId.trays,
          icon: Icons.inventory_2_outlined,
          title: l10n.learningPathTraysTitle,
          subtitle: l10n.learningPathTraysSubtitle,
          onTap: _openTrays,
        )
      else
        _Step(
          id: _StepId.joinTeam,
          icon: Icons.groups_outlined,
          title: l10n.learningPathJoinTeamTitle,
          subtitle: l10n.learningPathJoinTeamSubtitle,
          onTap: _openJoinTeam,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learningPathTitle)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView.separated(
            padding: const EdgeInsets.all(InstriqSpacing.lg),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: InstriqSpacing.sm),
            itemBuilder: (context, index) {
              final step = steps[index];
              final done = _completed.contains(step.id.name);
              return InstriqListItem(
                icon: step.icon,
                title: step.title,
                subtitle: step.subtitle,
                onTap: step.onTap,
                trailing: done
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Step {
  final _StepId id;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Step({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
