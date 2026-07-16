import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../services/preference_card_service.dart';
import '../widgets/category_icon.dart';
import 'preference_card_form_screen.dart';

class PreferenceCardDetailScreen extends StatefulWidget {
  final PreferenceCard card;

  const PreferenceCardDetailScreen({super.key, required this.card});

  @override
  State<PreferenceCardDetailScreen> createState() => _PreferenceCardDetailScreenState();
}

class _PreferenceCardDetailScreenState extends State<PreferenceCardDetailScreen> {
  late PreferenceCard _card;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  Instrument? _catalogFor(PreferenceCardItem item) {
    if (item.instrumentId == null) return null;
    for (final i in kInstruments) {
      if (i.id == item.instrumentId) return i;
    }
    return null;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PreferenceCardFormScreen(existingCard: _card)),
    );
    if (saved == true) {
      final updated = PreferenceCardService.instance.cards.firstWhere((c) => c.id == _card.id);
      setState(() => _card = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text('¿Eliminar la tarjeta de ${_card.procedureName} de ${_card.surgeonName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await PreferenceCardService.instance.deleteCard(_card.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_card.procedureName),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(_card.surgeonName, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          if (_card.generalNotes != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_card.generalNotes!),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Instrumental (${_card.items.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._card.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final catalogInstrument = _catalogFor(item);
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(item.customName),
                subtitle: item.note != null ? Text(item.note!) : null,
                trailing: catalogInstrument != null
                    ? InstrumentIcon(
                        iconKey: catalogInstrument.icon,
                        category: catalogInstrument.category,
                        size: 40,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
