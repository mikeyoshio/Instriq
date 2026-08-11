import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/workspace_role.dart';
import '../services/custom_instrument_service.dart';
import 'custom_instrument_detail_screen.dart';
import 'custom_instrument_form_screen.dart';

/// Lista del instrumental personalizado del workspace. Aparte y nunca
/// mezclado con el catálogo global — es contenido privado de este equipo
/// (ver supabase/schema_v13_custom_instruments.sql).
class CustomInstrumentsScreen extends StatefulWidget {
  final String workspaceId;
  final WorkspaceRole? myRole;

  const CustomInstrumentsScreen({super.key, required this.workspaceId, required this.myRole});

  @override
  State<CustomInstrumentsScreen> createState() => _CustomInstrumentsScreenState();
}

class _CustomInstrumentsScreenState extends State<CustomInstrumentsScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';

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
      await CustomInstrumentService.instance.fetchForWorkspace(widget.workspaceId);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.customInstrumentsLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.customInstrumentsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.customInstrumentsTitle)),
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

    final instruments = CustomInstrumentService.instance.instruments
        .where((i) => _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final canEdit = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customInstrumentsTitle)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CustomInstrumentFormScreen(workspaceId: widget.workspaceId),
                  ),
                );
                if (saved == true) _load();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.newCustomInstrumentLabel),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.customInstrumentNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: instruments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.customInstrumentsEmptyState, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: instruments.length,
                    itemBuilder: (context, index) {
                      final instrument = instruments[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.build_circle_outlined)),
                          title: Text(instrument.name),
                          subtitle: instrument.category != null ? Text(instrument.category!) : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomInstrumentDetailScreen(
                                  instrument: instrument,
                                  myRole: widget.myRole,
                                ),
                              ),
                            );
                            _load();
                          },
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
