import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/procedure.dart';
import '../models/workspace_role.dart';
import '../services/procedure_service.dart';
import '../widgets/procedure_content_view.dart';
import 'procedure_form_screen.dart';

/// Pàgina d'un procediment: tot el que cal per a la intervenció en un sol
/// lloc -- safates (amb accés directe a preparar-les), tècniques/protocols i
/// preferències de cada cirurgià.
class ProcedureDetailScreen extends StatefulWidget {
  final String procedureId;
  final String workspaceId;
  final WorkspaceRole? myRole;

  const ProcedureDetailScreen({
    super.key,
    required this.procedureId,
    required this.workspaceId,
    required this.myRole,
  });

  @override
  State<ProcedureDetailScreen> createState() => _ProcedureDetailScreenState();
}

class _ProcedureDetailScreenState extends State<ProcedureDetailScreen> {
  final _viewKey = GlobalKey<InstriqAsyncViewState<(Procedure, ProcedureContent)?>>();
  Procedure? _procedure;

  Future<(Procedure, ProcedureContent)?> _load() async {
    final procedure = await ProcedureService.instance.fetchById(widget.procedureId);
    if (mounted) setState(() => _procedure = procedure);
    if (procedure == null) return null;
    final content = await resolveProcedureContent(
      workspaceId: widget.workspaceId,
      trayIds: procedure.idsOf(ProcedureItemType.tray),
      documentIds: procedure.idsOf(ProcedureItemType.groupDocument),
      cardIds: procedure.idsOf(ProcedureItemType.preferenceCard),
    );
    return (procedure, content);
  }

  Future<void> _edit(Procedure procedure) async {
    final result = await Navigator.of(context).push<ProcedureFormResult>(
      MaterialPageRoute(builder: (_) => ProcedureFormScreen(workspaceId: widget.workspaceId, existing: procedure)),
    );
    if (!mounted) return;
    if (result == ProcedureFormResult.archived) {
      Navigator.of(context).pop();
    } else if (result == ProcedureFormResult.saved) {
      _viewKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final procedure = _procedure;
    return Scaffold(
      appBar: AppBar(
        title: Text(procedure?.name ?? l10n.proceduresTitle),
        actions: [
          if (procedure != null && widget.myRole?.canEdit == true)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.procedureEdit,
              onPressed: () => _edit(procedure),
            ),
        ],
      ),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: InstriqAsyncView<(Procedure, ProcedureContent)?>(
            key: _viewKey,
            load: _load,
            errorMessage: (e) => l10n.genericError(e.toString()),
            retryLabel: l10n.retry,
            // null = arxivat o sense accés (la RLS no el retorna).
            isEmpty: (data) => data == null,
            emptyBuilder: (_) => Center(child: Text(l10n.proceduresEmptyState, textAlign: TextAlign.center)),
            builder: (context, data) {
              final (procedure, content) = data!;
              return ListView(
                padding: const EdgeInsets.all(InstriqSpacing.lg),
                children: [
                  if (procedure.description != null && procedure.description!.isNotEmpty)
                    Text(procedure.description!, style: Theme.of(context).textTheme.bodyLarge),
                  if (content.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: InstriqSpacing.xl),
                      child: Text(l10n.procedureNothingLinked, textAlign: TextAlign.center),
                    )
                  else
                    ProcedureContentView(content: content, myRole: widget.myRole),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
