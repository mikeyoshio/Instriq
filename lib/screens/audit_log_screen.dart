import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/audit_entry.dart';
import '../services/audit_service.dart';

/// Log de auditoría: quién hizo qué y cuándo sobre acciones sensibles del
/// grupo (aprobar/rechazar contenido, crear/borrar documentos, cambios de
/// rol, transferencia de propiedad). Solo accesible para admin/owner del
/// hospital (la RLS de `audit_log` ya lo garantiza en el servidor).
///
/// Pantalla standalone: de momento no está enlazada desde ninguna navegación
/// existente. Para abrirla:
/// `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditLogScreen()));`
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, this.organizationId, this.workspaceId});

  final String? organizationId;
  final String? workspaceId;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _loading = true;
  String? _error;
  List<AuditEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _entries = await AuditService.instance.fetchAuditLog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
      );
    } catch (e) {
      _error = 'No se pudo cargar el registro de auditoría: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de auditoría'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(padding: const EdgeInsets.all(24), child: Text(_error!)),
                    ],
                  )
                : _entries.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Todavía no hay ninguna acción registrada.'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) => _AuditEntryTile(entry: _entries[index]),
                      ),
      ),
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.entry});

  final AuditEntry entry;

  static const _actionLabels = <String, String>{
    'document_version_approved': 'Versión aprobada',
    'document_version_rejected': 'Versión rechazada',
    'document_created': 'Documento creado',
    'document_deleted': 'Documento eliminado',
    'workspace_member_role_changed': 'Rol de miembro cambiado',
    'hospital_ownership_transferred': 'Propiedad del grupo transferida',
  };

  static const _actionIcons = <String, IconData>{
    'document_version_approved': Icons.check_circle_outline,
    'document_version_rejected': Icons.cancel_outlined,
    'document_created': Icons.note_add_outlined,
    'document_deleted': Icons.delete_outline,
    'workspace_member_role_changed': Icons.manage_accounts_outlined,
    'hospital_ownership_transferred': Icons.swap_horiz,
    'user_signed_in': Icons.login,
  };

  /// `user_signed_in` es la única acción con etiqueta vía l10n (resto de
  /// entradas de este mapa son texto fijo en castellano, gap ya existente en
  /// esta pantalla — no se toca aquí, solo la etiqueta nueva sigue la regla
  /// del proyecto de que todo string nuevo va por los 3 arb).
  String _actionLabel(BuildContext context) {
    if (entry.action == 'user_signed_in') {
      return AppLocalizations.of(context)!.auditActionUserSignedIn;
    }
    return _actionLabels[entry.action] ?? entry.action;
  }

  IconData get _icon => _actionIcons[entry.action] ?? Icons.history;

  /// Texto descriptivo de sobre qué entidad fue la acción, a partir de
  /// `metadata`/`entity_type`.
  String? get _entityDescription {
    final metadata = entry.metadata;
    switch (entry.entityType) {
      case 'group_document_version':
        final title = metadata['title'] as String?;
        return (title != null && title.isNotEmpty) ? title : 'Documento sin título';
      case 'group_document':
        final title = metadata['title'] as String?;
        final kind = metadata['kind'] as String?;
        final kindLabel = kind == 'protocol' ? 'Protocolo' : (kind == 'technique' ? 'Técnica quirúrgica' : null);
        if (title != null && title.isNotEmpty) return title;
        return kindLabel;
      case 'workspace_member':
        final previousRole = metadata['previous_role'] as String?;
        final newRole = metadata['new_role'] as String?;
        if (newRole == null) return 'Acceso quitado (antes: ${_roleLabel(previousRole)})';
        if (previousRole == null) return 'Asignado como ${_roleLabel(newRole)}';
        return '${_roleLabel(previousRole)} → ${_roleLabel(newRole)}';
      case 'hospital':
        return 'Propietaria/o del grupo';
      default:
        return null;
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'reader':
        return 'Lector';
      case 'editor':
        return 'Editor';
      case 'approver':
        return 'Aprobador';
      case 'administrator':
        return 'Administrador';
      default:
        return 'sin rol';
    }
  }

  String get _who => entry.actorId == null ? 'Usuario eliminado' : (entry.actorDisplayName ?? 'Usuario eliminado');

  String _when(DateTime? createdAt) {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final description = _entityDescription;
    return Card(
      child: ListTile(
        leading: Icon(_icon),
        title: Text(_actionLabel(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              const SizedBox(height: 2),
              Text(description),
            ],
            const SizedBox(height: 2),
            Text(
              '$_who · ${_when(entry.createdAt)}'
              '${entry.workspaceName != null ? ' · ${entry.workspaceName}' : ''}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        isThreeLine: description != null,
      ),
    );
  }
}
