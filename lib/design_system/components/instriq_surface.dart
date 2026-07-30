import 'package:flutter/material.dart';

import '../tokens.dart';

/// Reemplazo de `Card`: borde de 1px + radio de token, sin sombra Material.
class InstriqSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius radius;

  const InstriqSurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = InstriqRadius.mdRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: radius,
        border: Border.all(color: scheme.outline),
      ),
      child: child,
    );
  }
}
