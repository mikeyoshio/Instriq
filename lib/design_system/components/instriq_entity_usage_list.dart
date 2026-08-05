import 'package:flutter/material.dart';

import '../tokens.dart';
import 'instriq_list_item.dart';
import 'instriq_section_header.dart';

/// Fila ya preparada por el punto de llamada — icono, título, subtítulo y
/// acción de toque — nunca resuelta dentro de este componente.
class EntityUsageRow {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const EntityUsageRow({required this.icon, required this.title, this.subtitle, this.onTap});
}

/// Grupo de [EntityUsageRow] con etiqueta opcional. `label == null` renderiza
/// las filas sin [InstriqSectionHeader] (caso "lista plana", sin secciones).
class EntityUsageSection {
  final String? label;
  final List<EntityUsageRow> rows;

  const EntityUsageSection({this.label, required this.rows});
}

/// Lista de retroenlaces "qué usa/referencia esta entidad", agrupada
/// opcionalmente en secciones. Puramente presentacional: no hace fetch ni
/// resolución de refs — eso lo hace cada punto de llamada
/// (`manufacturer_detail_screen.dart`, `tag_detail_screen.dart`,
/// `surgeon_detail_screen.dart`, `specialty_detail_screen.dart`), que pasa
/// aquí el resultado ya preparado.
class InstriqEntityUsageList extends StatelessWidget {
  final List<EntityUsageSection> sections;

  const InstriqEntityUsageList({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final section in sections) {
      if (section.rows.isEmpty) continue;
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: InstriqSpacing.xl));
      }
      if (section.label != null) {
        children.add(InstriqSectionHeader(section.label!));
        children.add(const SizedBox(height: InstriqSpacing.sm));
      }
      for (var i = 0; i < section.rows.length; i++) {
        if (i > 0) children.add(const SizedBox(height: InstriqSpacing.sm));
        final row = section.rows[i];
        children.add(InstriqListItem(
          icon: row.icon,
          title: row.title,
          subtitle: row.subtitle,
          onTap: row.onTap,
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.all(InstriqSpacing.lg),
      children: children,
    );
  }
}
