import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../models/workspace_role.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import '../widgets/category_icon.dart';
import 'preference_card_form_screen.dart';
import 'surgeon_detail_screen.dart';

class PreferenceCardDetailScreen extends StatefulWidget {
  final PreferenceCard card;
  final WorkspaceRole? myRole;

  const PreferenceCardDetailScreen({super.key, required this.card, required this.myRole});

  @override
  State<PreferenceCardDetailScreen> createState() => _PreferenceCardDetailScreenState();
}

class _PreferenceCardDetailScreenState extends State<PreferenceCardDetailScreen> {
  late PreferenceCard _card;
  Surgeon? _surgeon;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _loadSurgeon();
  }

  Future<void> _loadSurgeon() async {
    final surgeonId = _card.surgeonId;
    if (surgeonId == null) return;
    await SurgeonService.instance.fetchForOrganization();
    if (!mounted) return;
    setState(() => _surgeon = SurgeonService.instance.byId(surgeonId));
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCardTitle),
        content: Text(l10n.deleteCardBody(_card.procedureName, _surgeon?.name ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
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
    final l10n = AppLocalizations.of(context)!;
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
                child: _surgeon != null
                    ? InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SurgeonDetailScreen(surgeon: _surgeon!)),
                        ),
                        child: Text(
                          _surgeon!.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(decoration: TextDecoration.underline),
                        ),
                      )
                    : Text('—', style: Theme.of(context).textTheme.titleMedium),
              ),
              if (_card.validated)
                Chip(
                  avatar: const Icon(Icons.verified, color: Colors.green, size: 18),
                  label: Text(l10n.validatedBySurgeon),
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleValidated,
              icon: Icon(_card.validated ? Icons.close : Icons.verified_outlined),
              label: Text(_card.validated ? l10n.removeValidation : l10n.markValidatedBySurgeon),
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
          Text(l10n.instrumentsCountTitle(_card.items.length), style: Theme.of(context).textTheme.titleMedium),
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
