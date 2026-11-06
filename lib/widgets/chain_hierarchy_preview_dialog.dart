import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Ajuda visual senzilla ("Com quedaria?") que mostra el wizard de creació
/// d'organització (`group_entry_screen.dart`) abans de triar entre seu única
/// o cadena amb diverses seus. Deliberadament plana (icones + fletxes de
/// text), no una il·lustració -- és una pantalla funcional, no de màrqueting.
Future<void> showChainHierarchyPreviewDialog(BuildContext context, {required bool isChain}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.chainHierarchyPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isChain) ...[
              _HierarchyLevel(icon: Icons.corporate_fare, label: l10n.chainHierarchyGroupLevel1),
              const _HierarchyArrow(),
              _HierarchyLevel(icon: Icons.local_hospital_outlined, label: l10n.chainHierarchyGroupLevel2),
              const _HierarchyArrow(),
              _HierarchyLevel(icon: Icons.groups_outlined, label: l10n.chainHierarchyGroupLevel3),
              const SizedBox(height: 16),
              Text(l10n.chainHierarchyGroupNote, style: Theme.of(dialogContext).textTheme.bodySmall),
            ] else ...[
              _HierarchyLevel(icon: Icons.local_hospital_outlined, label: l10n.chainHierarchySoloLevel1),
              const _HierarchyArrow(),
              _HierarchyLevel(icon: Icons.groups_outlined, label: l10n.chainHierarchySoloLevel2),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

class _HierarchyLevel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HierarchyLevel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _HierarchyArrow extends StatelessWidget {
  const _HierarchyArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Icon(Icons.arrow_downward, size: 18, color: Theme.of(context).colorScheme.outline),
    );
  }
}
