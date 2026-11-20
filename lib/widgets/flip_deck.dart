import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'deck_gestures.dart';

/// Baralla de targetes de repàs: (etiqueta, anvers, revers). Es gira tocant
/// la targeta. Per reiniciar-la amb unes altres targetes, canvia-li la `key`.
class FlipDeck extends StatefulWidget {
  final List<(String, String, String)> cards;

  const FlipDeck({super.key, required this.cards});

  @override
  State<FlipDeck> createState() => _FlipDeckState();
}

class _FlipDeckState extends State<FlipDeck> {
  int _index = 0;
  bool _showBack = false;

  void _go(int delta) => setState(() {
        _showBack = false;
        _index = (_index + delta + widget.cards.length) % widget.cards.length;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cards = widget.cards;
    if (cards.isEmpty) return Center(child: Text(l10n.noCards));
    final (tag, front, back) = cards[min(_index, cards.length - 1)];
    return Column(
      children: [
        Text(l10n.cardCounter(_index + 1, cards.length)),
        const SizedBox(height: 12),
        Expanded(
          child: DeckGestures(
            onNext: () => _go(1),
            onPrevious: () => _go(-1),
            onFlip: () => setState(() => _showBack = !_showBack),
            child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _showBack = !_showBack),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag.isNotEmpty) ...[Chip(label: Text(tag)), const SizedBox(height: 16)],
                      Text(front, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (_showBack)
                        Text(back, style: theme.textTheme.bodyLarge)
                      else
                        Text(l10n.tapToFlip, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.outlined(onPressed: () => _go(-1), icon: const Icon(Icons.arrow_back)),
            IconButton.outlined(onPressed: () => _go(1), icon: const Icon(Icons.arrow_forward)),
          ],
        ),
      ],
    );
  }
}
