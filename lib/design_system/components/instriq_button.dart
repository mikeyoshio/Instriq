import 'package:flutter/material.dart';

import '../tokens.dart';

enum InstriqButtonVariant { primary, secondary, text }

/// Botón propio flat: sin elevación Material por defecto, borde sutil en la
/// variante secundaria. Los tres estilos comparten el mismo radio de token.
class InstriqButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final InstriqButtonVariant variant;
  final IconData? icon;

  const InstriqButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = InstriqButtonVariant.primary,
    this.icon,
  });

  const InstriqButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : variant = InstriqButtonVariant.secondary;

  const InstriqButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : variant = InstriqButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: InstriqSpacing.sm),
              Text(label),
            ],
          );

    return switch (variant) {
      InstriqButtonVariant.primary => FilledButton(onPressed: onPressed, child: child),
      InstriqButtonVariant.secondary => OutlinedButton(onPressed: onPressed, child: child),
      InstriqButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };
  }
}
