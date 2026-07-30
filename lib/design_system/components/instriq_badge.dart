import 'package:flutter/material.dart';

import '../tokens.dart';

/// Estado de una versión de contenido (técnica, protocolo, bandeja...).
/// Coincide con los estados reales de `group_document_versions`/
/// `tray_versions` (ver supabase/schema_v5_group_document_versions.sql).
enum InstriqStatus { draft, inReview, published, archived }

/// Pill de estado con color por [InstriqStatus]. Acepta también un string
/// crudo (p. ej. viniendo directo de una fila de Supabase) vía
/// [InstriqBadge.fromLabel].
class InstriqBadge extends StatelessWidget {
  final String label;
  final Color color;

  const InstriqBadge({super.key, required this.label, required this.color});

  factory InstriqBadge.status(InstriqStatus status, String label) {
    final color = switch (status) {
      InstriqStatus.draft => InstriqColors.statusDraft,
      InstriqStatus.inReview => InstriqColors.statusInReview,
      InstriqStatus.published => InstriqColors.statusPublished,
      InstriqStatus.archived => InstriqColors.statusArchived,
    };
    return InstriqBadge(label: label, color: color);
  }

  factory InstriqBadge.fromLabel(String rawStatus, String label) {
    final status = switch (rawStatus) {
      'draft' => InstriqStatus.draft,
      'in_review' => InstriqStatus.inReview,
      'published' => InstriqStatus.published,
      'archived' => InstriqStatus.archived,
      _ => InstriqStatus.draft,
    };
    return InstriqBadge.status(status, label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.sm, vertical: InstriqSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, height: 1),
      ),
    );
  }
}
