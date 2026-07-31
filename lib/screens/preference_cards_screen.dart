import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/preference_card.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import 'preference_card_detail_screen.dart';
import 'preference_card_form_screen.dart';

/// Lista de tarjetas de preferencia de un espacio, agrupadas por cirujano
/// (resuelto desde la versión publicada de cada tarjeta). Calcado en el
/// manejo de cabecera+versión de [TraysScreen] — incluye el estado "sin
/// publicar" para tarjetas cuyo primer borrador todavía no se ha aprobado.
class PreferenceCardsScreen extends StatefulWidget {
  final Workspace workspace;
  final WorkspaceRole? myRole;

  const PreferenceCardsScreen({super.key, required this.workspace, required this.myRole});

  @override
  State<PreferenceCardsScreen> createState() => _PreferenceCardsScreenState();
}

class _PreferenceCardsScreenState extends State<PreferenceCardsScreen> {
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        PreferenceCardService.instance.fetchCards(widget.workspace.id),
        SurgeonService.instance.fetchForOrganization(),
      ]);
    } catch (e) {
      _error = l10n.preferenceCardsLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Nombre a mostrar para agrupar/buscar, resuelto contra el caché de
  /// [SurgeonService] ya cargado en [_load] — nunca vacío para que el
  /// agrupado tenga una clave estable incluso sin cirujano asignado.
  String _surgeonLabel(AppLocalizations l10n, PreferenceCard card) {
    final surgeonId = card.publishedVersion?.surgeonId;
    if (surgeonId == null) return l10n.noSurgeonAssignedLabel;
    return SurgeonService.instance.byId(surgeonId)?.name ?? l10n.noSurgeonAssignedLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preferenceCardsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preferenceCardsTitle)),
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

    final cards = PreferenceCardService.instance.cardsOfWorkspace(widget.workspace.id).where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return _surgeonLabel(l10n, c).toLowerCase().contains(q) ||
          (c.publishedVersion?.procedureName ?? '').toLowerCase().contains(q);
    }).toList();

    final bySurgeon = <String, List<PreferenceCard>>{};
    for (final c in cards) {
      bySurgeon.putIfAbsent(_surgeonLabel(l10n, c), () => []).add(c);
    }
    final surgeons = bySurgeon.keys.toList()..sort();

    final canEdit = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferenceCardsTitle)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PreferenceCardFormScreen(workspaceId: widget.workspace.id),
                  ),
                );
                if (saved == true) _load();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.newCardLabel),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchSurgeonProcedureHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: surgeons.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.noCardsYet, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: surgeons.length,
                    itemBuilder: (context, index) {
                      final surgeon = surgeons[index];
                      final surgeonCards = bySurgeon[surgeon]!;
                      return Card(
                        child: ExpansionTile(
                          leading: const Icon(Icons.person),
                          title: Text(surgeon, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(l10n.procedureCount(surgeonCards.length)),
                          children: surgeonCards.map((card) {
                            final published = card.publishedVersion;
                            return ListTile(
                              title: Text(published?.procedureName ?? l10n.unpublished),
                              subtitle: Text(l10n.instrumentsCount(published?.items.length ?? 0)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (published?.validatedBySurgeon ?? false)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.verified, color: Colors.green, size: 18),
                                    ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PreferenceCardDetailScreen(card: card, myRole: widget.myRole),
                                  ),
                                );
                                _load();
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
