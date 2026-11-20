import 'package:flutter/material.dart';

import '../tokens.dart';
import 'instriq_surface.dart';

/// Fila de navegación estándar: icono (o miniatura) + título + subtítulo
/// opcional + chevron. Base de todas las listas de la app: Inicio, Omnihub,
/// Catálogo, Aprender, guías, escalas, Perfil…
class InstriqListItem extends StatelessWidget {
  final IconData? icon;

  /// Sustituye al icono (p. ej. la miniatura de un instrumento).
  final Widget? leading;
  final String title;

  /// Distintivos pequeños junto al título ("Nou", "sense foto"…).
  final List<Widget> titleBadges;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InstriqListItem({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.titleBadges = const [],
    this.subtitle,
    this.onTap,
    this.trailing,
  }) : assert(icon != null || leading != null);

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
              leading ?? Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(width: InstriqSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titleBadges.isEmpty)
                      Text(title, style: textTheme.titleMedium)
                    else
                      Wrap(
                        spacing: InstriqSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [Text(title, style: textTheme.titleMedium), ...titleBadges],
                      ),
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
