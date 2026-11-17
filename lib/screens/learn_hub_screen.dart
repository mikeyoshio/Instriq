import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../navigation/profile_button.dart';
import '../services/progress_service.dart';
import 'learn_screen.dart';
import 'learning_path_screen.dart';
import 'progress_screen.dart';

/// Pestanya "Aprèn" (2.0): la ruta guiada, la pràctica (flashcards i
/// qüestionaris) i el progrés propi, junts. Abans estaven repartits entre
/// Dreceres d'Inici i Perfil.
class LearnHubScreen extends StatefulWidget {
  const LearnHubScreen({super.key});

  @override
  State<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends State<LearnHubScreen> {
  (int, int)? _pathProgress;

  @override
  void initState() {
    super.initState();
    _loadPathProgress();
  }

  Future<void> _loadPathProgress() async {
    final progress = await LearningPathScreen.progress();
    if (mounted) setState(() => _pathProgress = progress);
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // El progrés (ruta i instruments apresos) pot haver canviat.
    await _loadPathProgress();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final path = _pathProgress;
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLearn), actions: const [ProfileButton()]),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(InstriqSpacing.xl),
            children: [
              InstriqListItem(
                icon: Icons.route_outlined,
                title: l10n.learningPathTitle,
                subtitle: path != null && path.$1 > 0
                    ? l10n.learningPathProgress(path.$1, path.$2)
                    : l10n.learningPathSubtitle,
                onTap: () => _push(const LearningPathScreen()),
              ),
              const SizedBox(height: InstriqSpacing.sm),
              InstriqListItem(
                icon: Icons.school,
                title: l10n.learnTitle,
                subtitle: l10n.learnSubtitle,
                onTap: () => _push(const LearnScreen()),
              ),
              const SizedBox(height: InstriqSpacing.sm),
              InstriqListItem(
                icon: Icons.bar_chart,
                title: l10n.myProgressTitle,
                subtitle: progress.learnedCount > 0
                    ? l10n.myProgressLearnedCount(progress.learnedCount, progress.totalCount)
                    : l10n.myProgressSubtitle,
                onTap: () => _push(const ProgressScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
