import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../services/team_quiz_service.dart';
import '../services/team_service.dart';
import 'quiz_screen.dart';

/// Cuestionarios de equipo que cualquier miembro de la organización puede
/// hacer (ver supabase/schema_v60_team_quizzes.sql) -- lado "tomar", el
/// opuesto de [TeamQuizManagementScreen] (crear/borrar, solo supervisores).
/// Mismo picker de equipo por `ChoiceChip` que team_progress_screen.dart.
class TeamQuizzesScreen extends StatefulWidget {
  const TeamQuizzesScreen({super.key});

  @override
  State<TeamQuizzesScreen> createState() => _TeamQuizzesScreenState();
}

class _TeamQuizzesScreenState extends State<TeamQuizzesScreen> {
  bool _loadingTeams = true;
  List<Team> _teams = [];
  Team? _selectedTeam;

  bool _loadingQuizzes = false;
  List<TeamQuiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    _teams = await TeamService.instance.fetchTeams();
    if (mounted) setState(() => _loadingTeams = false);
    if (_teams.isNotEmpty) await _loadQuizzes(_teams.first);
  }

  Future<void> _loadQuizzes(Team team) async {
    setState(() {
      _selectedTeam = team;
      _loadingQuizzes = true;
    });
    _quizzes = await TeamQuizService.instance.fetchForTeam(team.id);
    if (mounted) setState(() => _loadingQuizzes = false);
  }

  Future<void> _take(TeamQuiz quiz) async {
    final pool = kInstruments.where((i) => quiz.instrumentIds.contains(i.id)).toList();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(pool: pool, scopeKey: quiz.scopeKey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamQuizzesMenuTitle)),
      body: _loadingTeams
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noTeamsYet)))
              : InstriqResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final team in _teams)
                              ChoiceChip(
                                label: Text(team.name),
                                selected: _selectedTeam?.id == team.id,
                                onSelected: (_) => _loadQuizzes(team),
                              ),
                          ],
                        ),
                      ),
                      if (_loadingQuizzes)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: _quizzes.isEmpty
                              ? Center(child: Text(l10n.noTeamQuizzesYet))
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
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => _take(quiz),
                                      ),
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
