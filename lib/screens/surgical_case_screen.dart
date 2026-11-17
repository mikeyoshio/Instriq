import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_surface.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/procedure.dart';
import '../models/surgical_slot.dart';
import '../models/workspace_role.dart';
import '../services/procedure_service.dart';
import '../services/surgeon_service.dart';
import '../services/surgical_slot_service.dart';
import '../utils/relative_date_label.dart';
import '../widgets/procedure_content_view.dart';
import 'procedure_detail_screen.dart';
import 'surgical_slot_form_screen.dart';

class _CaseData {
  final SurgicalSlot slot;
  final Procedure? procedure;
  final ProcedureContent content;

  const _CaseData(this.slot, this.procedure, this.content);
}

/// Pàgina d'un cas (2.0-alfa): una cita de l'agenda amb tot el que cal per
/// preparar-la en un sol lloc. El que porta la pròpia cita (safata, tècnica,
/// targeta d'aquell dia) va primer; el procediment enllaçat completa la resta
/// (regla [caseItemIds]). Mai dades de pacient: només dades operatives.
class SurgicalCaseScreen extends StatefulWidget {
  final SurgicalSlot slot;
  final WorkspaceRole? myRole;

  const SurgicalCaseScreen({super.key, required this.slot, required this.myRole});

  @override
  State<SurgicalCaseScreen> createState() => _SurgicalCaseScreenState();
}

class _SurgicalCaseScreenState extends State<SurgicalCaseScreen> {
  final _viewKey = GlobalKey<InstriqAsyncViewState<_CaseData>>();
  late SurgicalSlot _slot = widget.slot;
  Procedure? _procedure;

  Future<_CaseData> _load() async {
    final slot = await SurgicalSlotService.instance.fetchById(_slot.id) ?? _slot;
    final procedure = slot.procedureId == null ? null : await ProcedureService.instance.fetchById(slot.procedureId!);
    final content = await resolveProcedureContent(
      workspaceId: slot.workspaceId,
      trayIds: caseItemIds(fromSlot: slot.trayId, fromProcedure: procedure?.idsOf(ProcedureItemType.tray) ?? const []),
      documentIds: caseItemIds(
          fromSlot: slot.documentId, fromProcedure: procedure?.idsOf(ProcedureItemType.groupDocument) ?? const []),
      cardIds: caseItemIds(
          fromSlot: slot.preferenceCardId, fromProcedure: procedure?.idsOf(ProcedureItemType.preferenceCard) ?? const []),
    );
    if (mounted) {
      setState(() {
        _slot = slot;
        _procedure = procedure;
      });
    }
    return _CaseData(slot, procedure, content);
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SurgicalSlotFormScreen(workspaceId: _slot.workspaceId, existingSlot: _slot, myRole: widget.myRole),
      ),
    );
    if (changed == true) _viewKey.currentState?.reload();
  }

  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _procedure?.name ??
        (_slot.procedureName?.isNotEmpty == true ? _slot.procedureName! : l10n.surgicalCaseTitle);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.myRole?.canEdit == true)
            IconButton(icon: const Icon(Icons.edit_outlined), tooltip: l10n.surgicalCaseEditAction, onPressed: _edit),
        ],
      ),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: InstriqAsyncView<_CaseData>(
            key: _viewKey,
            load: _load,
            errorMessage: (e) => l10n.genericError(e.toString()),
            retryLabel: l10n.retry,
            builder: (context, data) => ListView(
              padding: const EdgeInsets.all(InstriqSpacing.lg),
              children: [
                _header(context, l10n, data.slot),
                if (data.procedure != null) ...[
                  const SizedBox(height: InstriqSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.medical_services_outlined),
                      label: Text(l10n.surgicalSlotViewProcedure),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProcedureDetailScreen(
                          procedureId: data.procedure!.id,
                          workspaceId: data.slot.workspaceId,
                          myRole: widget.myRole,
                        ),
                      )),
                    ),
                  ),
                ],
                if (data.content.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: InstriqSpacing.xl),
                    child: Text(l10n.surgicalCaseNothingLinked, textAlign: TextAlign.center),
                  )
                else
                  ProcedureContentView(content: data.content, myRole: widget.myRole),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, SurgicalSlot slot) {
    final theme = Theme.of(context);
    final start = slot.startsAt.toLocal();
    final day = DateTime(start.year, start.month, start.day);
    final cancelled = slot.status == SurgicalSlotStatus.cancelled;
    final surgeon = SurgeonService.instance.byId(slot.surgeonId)?.name;

    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: InstriqSpacing.sm),
          child: Row(children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: InstriqSpacing.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ]),
        );

    return InstriqSurface(
      child: Padding(
        padding: const EdgeInsets.all(InstriqSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  '${relativeDateLabel(day, todayLabel: l10n.dateLabelToday, tomorrowLabel: l10n.dateLabelTomorrow)} · '
                  '${_hm(start)}–${_hm(slot.endsAt.toLocal())}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (cancelled)
                Chip(
                  label: Text(l10n.surgicalCaseCancelledLabel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
            ]),
            if (surgeon != null) line(Icons.person_outline, surgeon),
            if (slot.location?.isNotEmpty == true) line(Icons.meeting_room_outlined, slot.location!),
            if (slot.notes?.isNotEmpty == true) line(Icons.sticky_note_2_outlined, slot.notes!),
          ],
        ),
      ),
    );
  }
}
