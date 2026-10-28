import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/editorial_comment.dart';
import '../services/auth_service.dart';
import '../services/editorial_comment_service.dart';

/// Revisión colaborativa sobre contenido privado de grupo (técnica/protocolo,
/// bandeja, tarjeta de preferencia, instrumental personalizado) -- propuesta
/// de producto auditada esta sesión, confirmada como "existe para la
/// Biblioteca Pública pero no para espacios privados". Reutiliza
/// `editorial_comments`/[EditorialCommentService] tal cual (ver
/// supabase/schema_v57_private_content_review_comments.sql), sin tabla ni
/// RPC nuevos -- es la misma capacidad genérica `ref_type`/`ref_id`, solo con
/// más tipos permitidos.
///
/// A diferencia de `_EditorialCommentsScreen` (Biblioteca Pública, dentro de
/// `public_library_review_queue_screen.dart`), esta pantalla NO lleva
/// aprobar/rechazar -- esa acción ya existe en el flujo normal de cada
/// pantalla de detalle; aquí solo se propone/discute y se marca como
/// resuelto, nunca se publica nada desde este hilo.
class ContentCommentsScreen extends StatefulWidget {
  final String refType;
  final String refId;
  final String title;
  final bool canResolve;

  const ContentCommentsScreen({
    super.key,
    required this.refType,
    required this.refId,
    required this.title,
    required this.canResolve,
  });

  @override
  State<ContentCommentsScreen> createState() => _ContentCommentsScreenState();
}

class _ContentCommentsScreenState extends State<ContentCommentsScreen> {
  bool _loading = true;
  List<EditorialComment> _comments = [];
  final _newCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _comments = await EditorialCommentService.instance.fetchFor(widget.refType, widget.refId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addComment() async {
    final text = _newCommentController.text.trim();
    if (text.isEmpty) return;
    await EditorialCommentService.instance.addComment(widget.refType, widget.refId, text);
    _newCommentController.clear();
    _load();
  }

  Future<void> _toggleResolved(EditorialComment comment) async {
    await EditorialCommentService.instance.setResolved(comment.id, !comment.resolved);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = AuthService.instance.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(child: Text(l10n.editorialCommentsEmptyState))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final canToggle = widget.canResolve || comment.authorId == currentUserId;
                            return ListTile(
                              leading: Icon(
                                comment.resolved ? Icons.check_circle : Icons.comment_outlined,
                                color: comment.resolved ? Colors.green : null,
                              ),
                              title: Text(comment.body),
                              subtitle: Text(comment.authorDisplayName ?? l10n.deletedUserLabel),
                              trailing: canToggle
                                  ? TextButton(
                                      onPressed: () => _toggleResolved(comment),
                                      child: Text(
                                        comment.resolved ? l10n.reopenCommentAction : l10n.resolveCommentAction,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _newCommentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.editorialCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: _addComment, child: Text(l10n.editorialCommentSendAction)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
