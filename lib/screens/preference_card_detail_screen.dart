import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../models/workspace_role.dart';
import '../services/preference_card_service.dart';
import '../widgets/category_icon.dart';
import 'preference_card_form_screen.dart';

class PreferenceCardDetailScreen extends StatefulWidget {
  final PreferenceCard card;
  final WorkspaceRole? myRole;

  const PreferenceCardDetailScreen({super.key, required this.card, required this.myRole});

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
      MaterialPageRoute(
        builder: (_) => PreferenceCardFormScreen(workspaceId: _card.workspaceId, existingCard: _card),
      ),
    );
    if (saved == true) {
      final updated = PreferenceCardService.instance.cards.firstWhere((c) => c.id == _card.id);
      setState(() => _card = updated);
    }
  }

  Future<void> _toggleValidated() async {
    final newValue = !_card.validated;
    await PreferenceCardService.instance.setValidated(_card.id, newValue);
    setState(() => _card = _card.copyWith(validated: newValue));
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
    final canEdit = widget.myRole?.canEdit ?? false;
    final canApprove = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_card.procedureName),
        actions: [
          if (canEdit) IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          if (canApprove) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_card.surgeonName, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (_card.validated)
                const Chip(
                  avatar: Icon(Icons.verified, color: Colors.green, size: 18),
                  label: Text('Validado por el cirujano'),
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleValidated,
              icon: Icon(_card.validated ? Icons.close : Icons.verified_outlined),
              label: Text(_card.validated ? 'Quitar validación' : 'Marcar como validado por el cirujano'),
            ),
          ],
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
