import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Tecles 1-4 per triar resposta i Intro per passar a la següent pregunta.
class InstriqAnswerShortcuts extends StatelessWidget {
  final int count;
  final void Function(int index) onPick;
  final VoidCallback? onNext;
  final Widget child;

  const InstriqAnswerShortcuts({super.key, required this.count, required this.onPick, this.onNext, required this.child});

  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < count && i < _digits.length; i++) SingleActivator(_digits[i]): () => onPick(i),
        if (onNext != null) const SingleActivator(LogicalKeyboardKey.enter): onNext!,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
