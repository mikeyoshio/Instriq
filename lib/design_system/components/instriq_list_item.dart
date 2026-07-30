import 'package:flutter/material.dart';

import '../tokens.dart';
import 'instriq_surface.dart';

/// Fila de navegación estándar: icono + título + subtítulo opcional +
/// chevron. Base de Inicio, Biblioteca, Actividad y Perfil.
class InstriqListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InstriqListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InstriqSurface(
      child: InkWell(
        borderRadius: InstriqRadius.mdRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(InstriqSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(width: InstriqSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: InstriqSpacing.xs),
                      Text(subtitle!, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: InstriqSpacing.sm),
              trailing ?? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
