import 'package:flutter/material.dart';

import '../models/group_document.dart';
import '../models/workspace.dart';
import 'group_document_list_screen.dart';
import 'preference_cards_screen.dart';

/// Colecciones disponibles dentro de un espacio: técnicas, protocolos y
/// tarjetas de preferencia. El instrumental (catálogo) es global y no
/// cuelga de ningún espacio.
class WorkspaceDetailScreen extends StatelessWidget {
  final Workspace workspace;

  const WorkspaceDetailScreen({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workspace.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (workspace.description != null) ...[
              Text(workspace.description!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
            ],
            _CollectionCard(
              icon: Icons.menu_book_outlined,
              title: 'Técnicas quirúrgicas',
              subtitle: 'Documenta cómo trabaja tu equipo, paso a paso',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GroupDocumentListScreen(kind: DocumentKind.technique, workspace: workspace),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CollectionCard(
              icon: Icons.fact_check_outlined,
              title: 'Protocolos',
              subtitle: 'Checklists y protocolos internos del espacio',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GroupDocumentListScreen(kind: DocumentKind.protocol, workspace: workspace),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CollectionCard(
              icon: Icons.assignment_ind,
              title: 'Tarjetas de preferencia',
              subtitle: 'Instrumental específico por cirujano y procedimiento',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PreferenceCardsScreen(workspace: workspace)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
