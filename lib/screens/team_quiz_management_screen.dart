import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../services/team_quiz_service.dart';
import 'create_team_quiz_screen.dart';

/// Gestión de cuestionarios de un equipo (crear/borrar) -- ver
/// supabase/schema_v60_team_quizzes.sql. Alcanzable desde
/// team_progress_screen.dart, mismo gate de supervisor que esa pantalla; la
/// policy RLS de insert/delete repite el chequeo del lado del servidor.
class TeamQuizManagementScreen extends StatefulWidget {
  final Team team;

  const TeamQuizManagementScreen({super.key, required this.team});

  @override
  State<TeamQuizManagementScreen> createState() => _TeamQuizManagementScreenState();
}

class _TeamQuizManagementScreenState extends State<TeamQuizManagementScreen> {
  bool _loading = true;
  List<TeamQuiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _quizzes = await TeamQuizService.instance.fetchForTeam(widget.team.id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateTeamQuizScreen(teamId: widget.team.id)),
    );
    if (created == true) _load();
  }

  Future<void> _delete(TeamQuiz quiz) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTeamQuizTitle),
        content: Text(quiz.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    await TeamQuizService.instance.delete(quiz.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamQuizzesTitle(widget.team.name))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l10n.createTeamQuizTitle),
      ),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _quizzes.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noTeamQuizzesYet)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.quiz_outlined),
                            title: Text(quiz.title),
                            subtitle: Text(l10n.teamQuizInstrumentCount(quiz.instrumentIds.length)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(quiz),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
