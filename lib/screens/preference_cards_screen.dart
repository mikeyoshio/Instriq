import 'package:flutter/material.dart';

import '../models/preference_card.dart';
import '../models/workspace.dart';
import '../services/preference_card_service.dart';
import 'preference_card_detail_screen.dart';
import 'preference_card_form_screen.dart';

class PreferenceCardsScreen extends StatefulWidget {
  final Workspace workspace;

  const PreferenceCardsScreen({super.key, required this.workspace});

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PreferenceCardService.instance.fetchCards(widget.workspace.id);
    } catch (e) {
      _error = 'No se pudieron cargar las tarjetas: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarjetas de preferencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarjetas de preferencia')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    final cards = PreferenceCardService.instance.cards.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.surgeonName.toLowerCase().contains(q) ||
          c.procedureName.toLowerCase().contains(q);
    }).toList();

    final bySurgeon = <String, List<PreferenceCard>>{};
    for (final c in cards) {
      bySurgeon.putIfAbsent(c.surgeonName, () => []).add(c);
    }
    final surgeons = bySurgeon.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas de preferencia')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => PreferenceCardFormScreen(workspaceId: widget.workspace.id)),
          );
          if (saved == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarjeta'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por cirujano o procedimiento...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: surgeons.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aún no hay tarjetas de preferencia. Crea la primera con el botón +.',
                        textAlign: TextAlign.center,
                      ),
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
                          subtitle: Text('${surgeonCards.length} procedimiento(s)'),
                          children: surgeonCards.map((card) {
                            return ListTile(
                              title: Text(card.procedureName),
                              subtitle: Text('${card.items.length} instrumentos'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (card.validated)
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
                                    builder: (_) => PreferenceCardDetailScreen(card: card),
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
