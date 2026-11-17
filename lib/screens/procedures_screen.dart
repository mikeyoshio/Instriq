import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/procedure.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/procedure_service.dart';
import 'procedure_detail_screen.dart';
import 'procedure_form_screen.dart';

/// Procediments d'un espai (2.0-alfa). Cada procediment agrupa la safata, la
/// tècnica/protocol i les preferències de cada cirurgià d'una intervenció.
class ProceduresScreen extends StatefulWidget {
  final Workspace workspace;
  final WorkspaceRole? myRole;

  const ProceduresScreen({super.key, required this.workspace, required this.myRole});

  @override
  State<ProceduresScreen> createState() => _ProceduresScreenState();
}

class _ProceduresScreenState extends State<ProceduresScreen> {
  final _listKey = GlobalKey<InstriqAsyncViewState<List<Procedure>>>();

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.proceduresTitle)),
      floatingActionButton: widget.myRole?.canEdit == true
          ? FloatingActionButton.extended(
              onPressed: () => _open(ProcedureFormScreen(workspaceId: widget.workspace.id)),
              icon: const Icon(Icons.add),
              label: Text(l10n.procedureNew),
            )
          : null,
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: InstriqAsyncView<List<Procedure>>(
            key: _listKey,
            load: () => ProcedureService.instance.fetchForWorkspace(widget.workspace.id),
            errorMessage: (e) => l10n.genericError(e.toString()),
            retryLabel: l10n.retry,
            isEmpty: (list) => list.isEmpty,
            emptyBuilder: (_) => Center(
              child: Padding(
                padding: const EdgeInsets.all(InstriqSpacing.xl),
                child: Text(l10n.proceduresEmptyState, textAlign: TextAlign.center),
              ),
            ),
            builder: (context, procedures) => ListView.separated(
              padding: const EdgeInsets.all(InstriqSpacing.lg),
              itemCount: procedures.length,
              separatorBuilder: (_, __) => const SizedBox(height: InstriqSpacing.sm),
              itemBuilder: (context, i) {
                final procedure = procedures[i];
                return InstriqListItem(
                  icon: Icons.medical_services_outlined,
                  title: procedure.name,
                  subtitle: procedure.description,
                  onTap: () => _open(ProcedureDetailScreen(
                    procedureId: procedure.id,
                    workspaceId: widget.workspace.id,
                    myRole: widget.myRole,
                  )),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
