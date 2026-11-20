import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navegació d'un mall de targetes: lliscar a esquerra/dreta, i al teclat
/// fletxes (anterior/següent) i espai (girar). Per a qui repassa d'una mà
/// al mòbil o amb el teclat a l'ordinador.
class DeckGestures extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onFlip;
  final Widget child;

  const DeckGestures({super.key, required this.onNext, required this.onPrevious, required this.onFlip, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): onNext,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): onPrevious,
        const SingleActivator(LogicalKeyboardKey.space): onFlip,
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -250) onNext();
            if (v > 250) onPrevious();
          },
          child: child,
        ),
      ),
    );
  }
}
