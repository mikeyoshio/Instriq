import 'dart:math';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  InstrumentCategory? _filter;
  int _index = 0;
  bool _showBack = false;

  List<Instrument> get _cards => _filter == null
      ? kInstruments
      : kInstruments.where((i) => i.category == _filter).toList();

  void _next() {
    setState(() {
      _showBack = false;
      _index = (_index + 1) % _cards.length;
    });
  }

  void _prev() {
    setState(() {
      _showBack = false;
      _index = (_index - 1 + _cards.length) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = _cards;
    if (cards.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.noCards)));
    }
    final card = cards[min(_index, cards.length - 1)];
    final learned = ProgressService.instance.isLearned(card.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.flashcardsTitle),
        actions: [
          PopupMenuButton<InstrumentCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (c) => setState(() {
              _filter = c;
              _index = 0;
              _showBack = false;
            }),
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.allCategoriesLabel)),
              ...InstrumentCategory.values.map(
                (c) => PopupMenuItem(value: c, child: Text(c.label)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(l10n.cardCounter(_index + 1, cards.length)),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _showBack
                              ? _CardBack(key: const ValueKey('back'), instrument: card)
                              : _CardFront(key: const ValueKey('front'), instrument: card),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showBack ? l10n.tapToSeeName : l10n.tapCardToSeeDetail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(l10n.previous),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(l10n.next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await ProgressService.instance.toggleLearned(card.id);
                  setState(() {});
                },
                icon: Icon(learned ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(learned ? l10n.learned : l10n.markAsLearned),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final Instrument instrument;

  const _CardFront({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 100),
        const SizedBox(height: 20),
        Text(
          instrument.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(instrument.category.label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  final Instrument instrument;

  const _CardBack({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.description.forLanguageCode(languageCode)),
          const SizedBox(height: 12),
          Text(l10n.useLabel, style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.use.forLanguageCode(languageCode)),
        ],
      ),
    );
  }
}
