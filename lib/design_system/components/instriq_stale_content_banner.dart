import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../tokens.dart';

/// Aviso cuando la versión publicada lleva mucho tiempo sin revisarse: hasta
/// ahora todo contenido publicado se veía igual de "vigente" tuviera 2 días o
/// 2 años (hallazgo de la auditoría de producto de 2026-09). Componente
/// genérico reutilizado en técnicas/protocolos, bandejas y tarjetas de
/// preferencia -- las tres comparten `approvedAt` en su versión publicada.
///
/// No es un error ni bloquea nada: es un recordatorio para quien mantiene el
/// contenido de que quizá convenga revisarlo, nada más.
class InstriqStaleContentBanner extends StatelessWidget {
  final DateTime? approvedAt;
  final Duration threshold;

  static const defaultThreshold = Duration(days: 365);

  const InstriqStaleContentBanner({
    super.key,
    required this.approvedAt,
    this.threshold = defaultThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final approvedAt = this.approvedAt;
    if (approvedAt == null) return const SizedBox.shrink();

    final age = DateTime.now().difference(approvedAt);
    if (age < threshold) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final months = (age.inDays / 30).floor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: InstriqSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(InstriqSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? InstriqColors.statusInReview.withValues(alpha: 0.16)
              : InstriqColors.statusInReview.withValues(alpha: 0.1),
          borderRadius: InstriqRadius.mdRadius,
          border: Border.all(color: InstriqColors.statusInReview.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_toggle_off, color: InstriqColors.statusInReview, size: 20),
            const SizedBox(width: InstriqSpacing.sm),
            Expanded(
              child: Text(
                l10n.staleContentWarning(months),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
