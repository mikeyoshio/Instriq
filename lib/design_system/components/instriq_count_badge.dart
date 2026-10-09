import 'package:flutter/material.dart';

/// Pequeño indicador numérico (p. ej. número de elementos pendientes, o de
/// filtros activos). Antes vivía como widget privado de `review_inbox_screen.dart`
/// -- promovido aquí al Design System en su segundo uso real (ver
/// `catalog_screen.dart`), tal como invitaba su propio comentario original.
class InstriqCountBadge extends StatelessWidget {
  final int count;

  const InstriqCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isZero = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isZero ? scheme.surfaceContainerHighest : scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isZero ? scheme.onSurfaceVariant : scheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
