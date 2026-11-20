import 'package:flutter/material.dart';

/// Label en mayúsculas con letter-spacing, usado para separar grupos de
/// [InstriqListItem] dentro de una pantalla índice.
class InstriqSectionHeader extends StatelessWidget {
  final String label;

  const InstriqSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    // Encapçalament per al lector de pantalla (navegable per títols), amb el
    // text en minúscules perquè no el lletregi.
    return Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
        ),
      ),
    );
  }
}
