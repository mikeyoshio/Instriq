import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_badge.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument_incident.dart';
import '../services/instrument_incident_service.dart';
import '../services/profile_service.dart';
import '../services/workspace_service.dart';
import '../widgets/instrument_incident_dialogs.dart';
import '../widgets/instrument_incident_label.dart';

/// Cola CAPA agregada de toda la organización (ISO 9001 8.7/10.2): antes,
/// una incidencia solo era visible desde la ficha concreta del instrumento al
/// que estaba enlazada, sin ningún listado conjunto. La lectura sigue siendo
/// transparente para cualquier miembro (misma política de `select` de
/// siempre), las acciones de resolver/verificar se gatean con
/// `isAdmin || canApproveAnyWorkspace` -- el chequeo real vive en los RPC
/// (`resolve_instrument_incident`/`verify_instrument_incident`), esto es solo
/// la misma conveniencia de UI que ya usa `_buildIncidentCard` en las fichas
/// de instrumento.
class IncidentCapaQueueScreen extends StatefulWidget {
  const IncidentCapaQueueScreen({super.key});

  @override
  State<IncidentCapaQueueScreen> createState() => _IncidentCapaQueueScreenState();
}

class _IncidentCapaQueueScreenState extends State<IncidentCapaQueueScreen> {
  final _asyncViewKey = GlobalKey<InstriqAsyncViewState<List<InstrumentIncident>>>();
  Map<String, String> _workspaceNameById = {};

  Future<List<InstrumentIncident>> _load() async {
    if (WorkspaceService.instance.workspaces.isEmpty) {
      try {
        await WorkspaceService.instance.fetchWorkspaces();
      } catch (_) {
        // Nombres de espacio: solo cosmético, no bloquea la cola si falla.
      }
    }
    _workspaceNameById = {for (final w in WorkspaceService.instance.workspaces) w.id: w.name};
    return InstrumentIncidentService.instance.fetchForOrganization();
  }

  void _reload() => _asyncViewKey.currentState?.reload();

  String _formatShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Widget _buildIncidentCard(BuildContext context, AppLocalizations l10n, InstrumentIncident incident, bool canAct) {
    final severityColor = switch (incident.severity) {
      IncidentSeverity.low => Colors.green,
      IncidentSeverity.medium => Colors.orange,
      IncidentSeverity.high => Colors.red,
    };
    final statusColor = switch (incident.status) {
      IncidentStatus.open => Theme.of(context).colorScheme.error,
      IncidentStatus.resolved => Colors.orange,
      IncidentStatus.verified => Colors.green,
    };
    final workspaceLabel =
        incident.workspaceId != null ? _workspaceNameById[incident.workspaceId] : l10n.incidentOrganizationScopeLabel;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                InstriqBadge(label: incidentSeverityValueLabel(l10n, incident.severity), color: severityColor),
                InstriqBadge(label: incidentStatusValueLabel(l10n, incident.status), color: statusColor),
                if (workspaceLabel != null)
                  Text(workspaceLabel, style: Theme.of(context).textTheme.bodySmall),
                if (incident.createdAt != null)
                  Text(_formatShortDate(incident.createdAt!), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${incident.instrumentRefType}/${incident.instrumentRefId}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(incident.description, style: Theme.of(context).textTheme.bodyMedium),
            if (incident.rootCause != null && incident.rootCause!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${l10n.rootCauseLabel}: ${incident.rootCause}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (incident.correctiveAction != null && incident.correctiveAction!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.correctiveActionLabel}: ${incident.correctiveAction}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (canAct && incident.status == IncidentStatus.open) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showResolveIncidentDialog(context, incident, onDone: _reload),
                  child: Text(l10n.resolveIncidentAction),
                ),
              ),
            ],
            if (canAct && incident.status == IncidentStatus.resolved) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showVerifyIncidentDialog(context, incident, onDone: _reload),
                  child: Text(l10n.verifyIncidentAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAct = ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incidentCapaQueueTitle)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: InstriqAsyncView<List<InstrumentIncident>>(
            key: _asyncViewKey,
            load: _load,
            errorMessage: (e) => l10n.genericError(e.toString()),
            retryLabel: l10n.retry,
            isEmpty: (data) => data.isEmpty,
            emptyBuilder: (context) => Center(
              child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.incidentCapaQueueEmptyState)),
            ),
            builder: (context, incidents) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) => _buildIncidentCard(context, l10n, incidents[index], canAct),
            ),
          ),
        ),
      ),
    );
  }
}
