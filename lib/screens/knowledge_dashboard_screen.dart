import 'package:flutter/material.dart';

import '../design_system/components/instriq_badge.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/hospital_content_stats.dart';
import '../models/usage_stats.dart';
import '../services/analytics_service.dart';
import '../services/profile_service.dart';
import '../services/usage_analytics_service.dart';
import '../utils/ref_resolver.dart';

/// Dashboard agregado de COBERTURA DE CONOCIMIENTO DOCUMENTADO por
/// especialidad (Fase E, version minima/realista), mas — desde Fase D (2/2,
/// ver supabase/schema_v23_usage_analytics.sql) — la seccion de USO REAL
/// (`_UsageSection` mas abajo): que se consulta, que se busca, que busqueda
/// no encuentra nada y cuantos borradores propios tiene cada persona
/// pendientes. El progreso de aprendizaje (flashcards/quiz) sigue viviendo
/// solo en shared_preferences local de cada dispositivo (ver
/// lib/services/progress_service.dart) y no aparece aqui. Lo que la primera
/// seccion de esta pantalla muestra es cuanto contenido tiene documentado el
/// hospital — cuantas tecnicas/protocolos estan publicados frente a
/// pendientes de revision por especialidad, y totales de espacios/miembros —
/// no cuanto se lee; la seccion de uso, mas abajo, es la que si mide lectura.
///
/// Pantalla standalone: todavia no esta enlazada desde ningun otro screen
/// (home_screen.dart u otro) a proposito, para no chocar con cambios en
/// paralelo. Clase: [KnowledgeDashboardScreen].
class KnowledgeDashboardScreen extends StatefulWidget {
  const KnowledgeDashboardScreen({super.key});

  @override
  State<KnowledgeDashboardScreen> createState() => _KnowledgeDashboardScreenState();
}

class _KnowledgeDashboardScreenState extends State<KnowledgeDashboardScreen> {
  bool _loading = true;
  String? _error;
  HospitalContentStats? _stats;

  // Estado separado del bloque de cobertura de arriba a propósito: son dos
  // RPCs distintas (hospital_content_stats vs organization_usage_stats) que
  // pueden tardar/fallar de forma independiente — no tiene sentido que un
  // fallo en una bloquee a la otra.
  bool _usageLoading = true;
  String? _usageError;
  UsageStats? _usageStats;
  List<_ResolvedViewCount> _resolvedViews = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() {
      _usageLoading = true;
      _usageError = null;
    });
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      setState(() => _usageLoading = false);
      return;
    }
    try {
      final stats = await UsageAnalyticsService.instance.fetchStats(organizationId);
      // Contenido borrado entretanto se omite en silencio (ver resolveRef) —
      // nunca crashear el dashboard por una fila de analítica que apunta a
      // algo que ya no existe.
      final resolvedViews = <_ResolvedViewCount>[];
      for (final v in stats.topViewed) {
        final resolved = await resolveRef(v.refType, v.refId);
        if (resolved != null) {
          resolvedViews.add(_ResolvedViewCount(ref: resolved, viewCount: v.viewCount));
        }
      }
      if (!mounted) return;
      setState(() {
        _usageStats = stats;
        _resolvedViews = resolvedViews;
        _usageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usageError = e.toString();
        _usageLoading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      setState(() {
        _loading = false;
        _error = 'Tu usuario no pertenece a ningún grupo todavía.';
      });
      return;
    }
    try {
      final stats = await AnalyticsService.instance.fetchHospitalContentStats(organizationId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la cobertura de conocimiento: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Cobertura de conocimiento')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => Future.wait([_load(), _loadUsage()]),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const _HonestyBanner(),
                      const SizedBox(height: 20),
                      Text('Totales del grupo', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _TotalsCard(stats: _stats!),
                      const SizedBox(height: 24),
                      Text('Por especialidad', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Técnicas y protocolos documentados, ordenado por nº publicado.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      if (_stats!.bySpecialty.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Todavía no hay técnicas ni protocolos documentados en este grupo.'),
                        )
                      else
                        _SpecialtyList(stats: _stats!.bySpecialty),
                      const SizedBox(height: 24),
                      Text(l10n.usageSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l10n.usageSectionSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      _UsageSection(
                        loading: _usageLoading,
                        error: _usageError,
                        stats: _usageStats,
                        resolvedViews: _resolvedViews,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ResolvedViewCount {
  final ResolvedRef ref;
  final int viewCount;

  const _ResolvedViewCount({required this.ref, required this.viewCount});
}

class _HonestyBanner extends StatelessWidget {
  const _HonestyBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Esto mide cuánto conocimiento tiene documentado el grupo, '
                'no cuánto se consulta o se usa — para eso, ver la sección "Uso" más abajo.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final HospitalContentStats stats;

  const _TotalsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final roles = stats.membersByRole;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(label: 'Espacios de trabajo', value: stats.workspacesCount.toString()),
            _StatRow(label: 'Tarjetas de preferencia', value: stats.preferenceCardsCount.toString()),
            const Divider(height: 24),
            Text('Miembros por rol', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _StatRow(label: 'Administradores', value: roles.administrator.toString()),
            _StatRow(label: 'Aprobadores (en algún espacio)', value: roles.approver.toString()),
            _StatRow(label: 'Editores (en algún espacio)', value: roles.editor.toString()),
            _StatRow(label: 'Lectores (en algún espacio)', value: roles.reader.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SpecialtyList extends StatelessWidget {
  final List<SpecialtyContentStats> stats;

  const _SpecialtyList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxPublished = stats
        .map((s) => s.publishedCount)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      children: stats.map((s) {
        final ratio = maxPublished == 0 ? 0.0 : s.publishedCount / maxPublished;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.specialty, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${s.publishedCount} publicada${s.publishedCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (s.draftReviewCount > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '· ${s.draftReviewCount} pendiente${s.draftReviewCount == 1 ? '' : 's'} de revisión',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Sección "Uso" (ver comentario de clase de [KnowledgeDashboardScreen]):
/// estado propio de carga/error, para no bloquearla con el de cobertura de
/// arriba — mismo patrón visual (loading/error/lista) que el resto de la
/// pantalla, solo que dividido en 4 sub-bloques.
class _UsageSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final UsageStats? stats;
  final List<_ResolvedViewCount> resolvedViews;

  const _UsageSection({
    required this.loading,
    required this.error,
    required this.stats,
    required this.resolvedViews,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.usageLoadError(error!), style: const TextStyle(color: Colors.red)),
      );
    }
    final data = stats;
    if (data == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UsageSubsection(
          title: l10n.usageTopViewedTitle,
          emptyLabel: l10n.usageEmptyState,
          rows: resolvedViews
              .map((v) => InstriqListItem(
                    icon: Icons.visibility_outlined,
                    title: v.ref.title,
                    trailing: Text(l10n.usageViewCountLabel(v.viewCount)),
                    onTap: () => navigateToResolvedRef(context, v.ref),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _UsageSubsection(
          title: l10n.usageTopSearchesTitle,
          emptyLabel: l10n.usageEmptyState,
          rows: data.topSearches
              .map((q) => InstriqListItem(
                    icon: Icons.search,
                    title: q.query,
                    trailing: Text(l10n.usageSearchCountLabel(q.searchCount)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        // Tratamiento visual más prominente a propósito (InstriqBadge con
        // tono de aviso en vez de texto plano): es la sección más accionable
        // para un admin — le dice qué contenido falta, no solo qué se usa.
        _UsageSubsection(
          title: l10n.usageZeroResultSearchesTitle,
          emptyLabel: l10n.usageEmptyState,
          rows: data.zeroResultSearches
              .map((q) => InstriqListItem(
                    icon: Icons.search_off,
                    title: q.query,
                    trailing: InstriqBadge(
                      label: l10n.usageSearchCountLabel(q.searchCount),
                      color: InstriqColors.statusInReview,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _UsageSubsection(
          title: l10n.usagePendingDraftsTitle,
          emptyLabel: l10n.usageEmptyState,
          rows: data.pendingDraftsByPerson
              .map((p) => InstriqListItem(
                    icon: Icons.edit_note_outlined,
                    title: p.displayName,
                    trailing: Text(l10n.usageDraftCountLabel(p.draftCount)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _UsageSubsection extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final List<Widget> rows;

  const _UsageSubsection({required this.title, required this.emptyLabel, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyLabel, style: TextStyle(color: Colors.grey[600])),
          )
        else
          for (final row in rows) ...[
            row,
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
