import 'package:flutter/material.dart';

import '../tokens.dart';

enum InstriqAnswerState { idle, correct, wrong, other }

/// Opció de resposta de qüestionari (Quiz, ECG, "Quina postura?"…).
/// Encert i error es marquen sempre amb icona + vora + fons, mai només amb
/// color: un usuari daltònic ha de poder distingir-los igual.
class InstriqAnswerOption extends StatelessWidget {
  final String label;
  final InstriqAnswerState state;
  final VoidCallback? onPressed;

  const InstriqAnswerOption({super.key, required this.label, required this.state, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? bg, Color? fg, Color? border, IconData? icon) = switch (state) {
      InstriqAnswerState.correct => (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary, Icons.check_circle),
      InstriqAnswerState.wrong => (scheme.errorContainer, scheme.onErrorContainer, scheme.error, Icons.cancel),
      _ => (null, null, null, null),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border != null ? BorderSide(color: border, width: 2) : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: InstriqSpacing.lg),
        ),
        // Un cop respost, la resta d'opcions no fan res (però es llegeixen bé).
        onPressed: state == InstriqAnswerState.idle ? onPressed : () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: InstriqSpacing.sm),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
