import 'package:flutter/material.dart';

import '../models/hospital_content_stats.dart';
import '../services/analytics_service.dart';
import '../services/profile_service.dart';

/// Dashboard agregado de COBERTURA DE CONOCIMIENTO DOCUMENTADO por
/// especialidad (Fase E, version minima/realista).
///
/// IMPORTANTE — esto no es un dashboard de uso/engagement: no existe hoy
/// ningun tracking server-side de que tecnica o protocolo se consulta mas.
/// El progreso de aprendizaje (flashcards/quiz) vive solo en
/// shared_preferences local de cada dispositivo (ver
/// lib/services/progress_service.dart). Lo que esta pantalla muestra es
/// cuanto contenido tiene documentado el hospital — cuantas
/// tecnicas/protocolos estan publicados frente a pendientes de revision por
/// especialidad, y totales de espacios/miembros — no cuanto se lee.
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

  @override
  void initState() {
    super.initState();
    _load();
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
                  onRefresh: _load,
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
                    ],
                  ),
                ),
    );
  }
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
                'no cuánto se consulta o se usa. No hay datos de uso disponibles hoy.',
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
