import 'dart:math';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
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
    final cards = _cards;
    if (cards.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sin tarjetas')));
    }
    final card = cards[min(_index, cards.length - 1)];
    final learned = ProgressService.instance.isLearned(card.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          PopupMenuButton<InstrumentCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (c) => setState(() {
              _filter = c;
              _index = 0;
              _showBack = false;
            }),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
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
              Text('${_index + 1} / ${cards.length}'),
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
                _showBack ? 'Toca para ver el nombre' : 'Toca la tarjeta para ver el detalle',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Anterior'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Siguiente'),
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
                label: Text(learned ? 'Aprendido' : 'Marcar como aprendido'),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.description),
          const SizedBox(height: 12),
          Text('Uso', style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.use),
        ],
      ),
    );
  }
}
