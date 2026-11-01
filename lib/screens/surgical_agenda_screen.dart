import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/surgical_slot.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/surgeon_service.dart';
import '../services/surgical_slot_service.dart';
import '../utils/relative_date_label.dart';
import '../widgets/surgical_agenda_ics_dialog.dart';
import 'surgical_slot_form_screen.dart';

/// Lista de la agenda quirúrgica de un espacio, agrupada por día. Calcada de
/// [TraysScreen]; va directa al formulario al tocar una fila (ver
/// `kind-spinning-comet.md`: sin pantalla de detalle separada).
class SurgicalAgendaScreen extends StatefulWidget {
  final Workspace workspace;
  final WorkspaceRole? myRole;

  const SurgicalAgendaScreen({super.key, required this.workspace, required this.myRole});

  @override
  State<SurgicalAgendaScreen> createState() => _SurgicalAgendaScreenState();
}

class _SurgicalAgendaScreenState extends State<SurgicalAgendaScreen> {
  bool _loading = true;
  String? _error;
  List<SurgicalSlot> _slots = [];

  bool get canEdit => widget.myRole?.canEdit == true;

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
    try {
      final results = await Future.wait([
        SurgicalSlotService.instance.fetchForWorkspace(widget.workspace.id),
        SurgeonService.instance.fetchForOrganization(),
      ]);
      _slots = results[0] as List<SurgicalSlot>;
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm(BuildContext context, {SurgicalSlot? existingSlot}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SurgicalSlotFormScreen(
          workspaceId: widget.workspace.id,
          existingSlot: existingSlot,
          myRole: widget.myRole,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.surgicalAgendaTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.surgicalAgendaTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.surgicalAgendaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: l10n.surgicalAgendaIcsLinkAction,
            onPressed: () => showSurgicalAgendaIcsDialog(context),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: _slots.isEmpty
              ? Center(child: Text(l10n.surgicalAgendaEmptyState, textAlign: TextAlign.center))
              : _buildList(context, l10n),
        ),
      ),
    );
  }

  /// Items planos en el mismo `ListView.builder` -- un `DateTime` (medianoche
  /// local) es cabecera de día, un `SurgicalSlot` es fila. Los slots ya llegan
  /// ordenados por `startsAt` desde el servicio, así que basta con insertar
  /// una cabecera cada vez que cambia el día local.
  Widget _buildList(BuildContext context, AppLocalizations l10n) {
    final items = <Object>[];
    DateTime? lastDay;
    for (final slot in _slots) {
      final start = slot.startsAt.toLocal();
      final day = DateTime(start.year, start.month, start.day);
      if (lastDay == null || day != lastDay) {
        items.add(day);
        lastDay = day;
      }
      items.add(slot);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              relativeDateLabel(item, todayLabel: l10n.dateLabelToday, tomorrowLabel: l10n.dateLabelTomorrow),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        }
        final slot = item as SurgicalSlot;
        return _buildSlotCard(context, l10n, slot);
      },
    );
  }

  Widget _buildSlotCard(BuildContext context, AppLocalizations l10n, SurgicalSlot slot) {
    final surgeonName = SurgeonService.instance.byId(slot.surgeonId)?.name ?? '?';
    final cancelled = slot.status == SurgicalSlotStatus.cancelled;
    final subtitleParts = <String>[
      _formatTimeRange(slot.startsAt.toLocal(), slot.endsAt.toLocal()),
      if (slot.procedureName != null && slot.procedureName!.isNotEmpty) slot.procedureName!,
      if (slot.location != null && slot.location!.isNotEmpty) slot.location!,
    ];

    return Card(
      child: ListTile(
        title: Text(
          surgeonName,
          style: cancelled ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
        ),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: cancelled
            ? Chip(
                label: Text(l10n.surgicalSlotCancelSlotAction),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _openForm(context, existingSlot: slot),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    String hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${hm(start)}–${hm(end)}';
  }
}
