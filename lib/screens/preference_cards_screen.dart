import 'package:flutter/material.dart';

import '../models/preference_card.dart';
import '../services/preference_card_service.dart';
import 'preference_card_detail_screen.dart';
import 'preference_card_form_screen.dart';

class PreferenceCardsScreen extends StatefulWidget {
  const PreferenceCardsScreen({super.key});

  @override
  State<PreferenceCardsScreen> createState() => _PreferenceCardsScreenState();
}

class _PreferenceCardsScreenState extends State<PreferenceCardsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
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
            MaterialPageRoute(builder: (_) => const PreferenceCardFormScreen()),
          );
          if (saved == true) setState(() {});
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
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PreferenceCardDetailScreen(card: card),
                                  ),
                                );
                                setState(() {});
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
