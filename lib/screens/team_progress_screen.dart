import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../services/progress_service.dart';
import '../services/team_service.dart';
import 'team_quiz_management_screen.dart';

/// Progreso de aprendizaje del equipo de residentes/alumnos de quien
/// supervisa (modo Docente) -- ver [TeamService.fetchTeamMemberProgress] /
/// `team_learning_progress` (schema_v54_team_learning_progress.sql). Solo
/// alcanzable tras pasar el gate `isAdmin || canApproveAnyWorkspace` en quien
/// llama (home_screen.dart / home_dashboard_panel.dart); la propia función
/// RPC repite ese mismo chequeo del lado del servidor, que es el límite de
/// seguridad real, no este gate de UI.
class TeamProgressScreen extends StatefulWidget {
  const TeamProgressScreen({super.key});

  @override
  State<TeamProgressScreen> createState() => _TeamProgressScreenState();
}

class _TeamProgressScreenState extends State<TeamProgressScreen> {
  bool _loadingTeams = true;
  String? _error;
  List<Team> _teams = [];
  Team? _selectedTeam;

  bool _loadingProgress = false;
  List<TeamMemberProgress> _progress = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loadingTeams = true;
      _error = null;
    });
    try {
      _teams = await TeamService.instance.fetchTeams();
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loadingTeams = false);
    if (_teams.isNotEmpty) await _loadProgress(_teams.first);
  }

  Future<void> _loadProgress(Team team) async {
    setState(() {
      _selectedTeam = team;
      _loadingProgress = true;
      _error = null;
    });
    try {
      _progress = await TeamService.instance.fetchTeamMemberProgress(team.id);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loadingProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamProgressScreenTitle),
        actions: [
          if (_selectedTeam != null)
            IconButton(
              icon: const Icon(Icons.quiz_outlined),
              tooltip: l10n.teamQuizzesTitle(_selectedTeam!.name),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TeamQuizManagementScreen(team: _selectedTeam!)),
              ),
            ),
        ],
      ),
      body: _loadingTeams
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noTeamsYet)))
              : InstriqResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Text(l10n.teamProgressPickTeamLabel, style: Theme.of(context).textTheme.labelLarge),
                      ),
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
                                onSelected: (_) => _loadProgress(team),
                              ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))))
                      else if (_loadingProgress)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: _progress.isEmpty
                              ? Center(child: Text(l10n.teamProgressEmptyTeamState))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _progress.length,
                                  itemBuilder: (context, index) {
                                    final member = _progress[index];
                                    final total = ProgressService.instance.totalCount;
                                    final quizBest = member.quizBestScores['general'] ?? 0;
                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.person_outline),
                                        title: Text(member.displayName?.isNotEmpty == true
                                            ? member.displayName!
                                            : l10n.noName),
                                        subtitle: Text(
                                          '${l10n.teamProgressLearnedLabel}: ${member.learnedCount}/$total  ·  '
                                          '${l10n.teamProgressDueLabel}: ${member.dueCount}  ·  '
                                          '${l10n.teamProgressQuizLabel}: $quizBest',
                                        ),
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
