import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../services/preference_card_service.dart';
import '../services/workspace_service.dart';
import 'preference_card_detail_screen.dart';

/// Ficha mínima de un cirujano: solo navegación inversa (qué tarjetas de
/// preferencia lo referencian), sin edición — se llega aquí tocando el chip
/// del cirujano en [PreferenceCardDetailScreen], nunca desde un menú propio.
class SurgeonDetailScreen extends StatefulWidget {
  final Surgeon surgeon;

  const SurgeonDetailScreen({super.key, required this.surgeon});

  @override
  State<SurgeonDetailScreen> createState() => _SurgeonDetailScreenState();
}

class _SurgeonDetailScreenState extends State<SurgeonDetailScreen> {
  bool _loading = true;
  List<PreferenceCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await PreferenceCardService.instance.fetchForSurgeon(widget.surgeon.id);
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCard(PreferenceCard card) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(card.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreferenceCardDetailScreen(card: card, myRole: myRole)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.surgeon.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.instrumentsCountTitle(_cards.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.noCardsYet, textAlign: TextAlign.center),
                  )
                else
                  ..._cards.map((card) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.assignment_outlined),
                          title: Text(card.publishedVersion?.procedureName ?? l10n.unpublished),
                          subtitle: Text(l10n.instrumentsCount(card.publishedVersion?.items.length ?? 0)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openCard(card),
                        ),
                      )),
              ],
            ),
    );
  }
}
