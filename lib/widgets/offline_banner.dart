import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Aviso discreto de "sin conexión, mostrando la última versión sincronizada".
/// Mismo patrón visual que el resto de banners informativos de la app (ver
/// `_HonestyBanner` en knowledge_dashboard_screen.dart): una Card con el
/// color de superficie del tema, no un color de alerta — no es un error, es
/// información.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.offlineBannerMessage, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip pequeño para marcar un elemento (borrador, tarjeta...) creado o
/// editado sin conexión y que todavía no se ha subido al servidor.
class PendingSyncChip extends StatelessWidget {
  const PendingSyncChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Chip(
      avatar: const Icon(Icons.sync_problem, size: 16),
      label: Text(l10n.pendingSyncBadge, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
