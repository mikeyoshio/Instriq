import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument.dart';
import '../models/specialty_entity.dart';
import '../models/tag.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/tag_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/offline_banner.dart';
import 'group_document_form_screen.dart';
import 'group_document_version_history_screen.dart';
import 'instrument_detail_screen.dart';
import 'specialty_detail_screen.dart';
import 'tag_detail_screen.dart';

class GroupDocumentDetailScreen extends StatefulWidget {
  final GroupDocument document;
  final WorkspaceRole? myRole;

  const GroupDocumentDetailScreen({super.key, required this.document, required this.myRole});

  @override
  State<GroupDocumentDetailScreen> createState() => _GroupDocumentDetailScreenState();
}

class _GroupDocumentDetailScreenState extends State<GroupDocumentDetailScreen> {
  static const String _refType = 'group_document';

  late GroupDocument _document;
  GroupDocumentVersion? _ownPendingDraft;
  bool _loadingHistory = true;
  bool _isFavorite = false;
  SpecialtyEntity? _specialty;
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _loadOwnDraft();
    _loadSpecialty();
    _loadTags();
    if (AuthService.instance.currentUser != null) {
      RecentActivityService.instance.recordView(_refType, _document.id);
      _loadFavoriteState();
    }
  }

  Future<void> _loadSpecialty() async {
    final specialtyId = _document.publishedVersion?.specialtyId;
    if (specialtyId == null) return;
    final specialties = await SpecialtyService.instance.fetchAll();
    if (!mounted) return;
    SpecialtyEntity? found;
    for (final s in specialties) {
      if (s.id == specialtyId) {
        found = s;
        break;
      }
    }
    setState(() => _specialty = found);
  }

  Future<void> _loadTags() async {
    try {
      final tags = await TagService.instance.fetchTagsFor(_refType, _document.id);
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (_) {
      // Sin bloquear la ficha si falla: las etiquetas son metadato accesorio.
    }
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.instance.isFavorite(_refType, _document.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(_refType, _document.id);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _loadOwnDraft() async {
    final userId = AuthService.instance.currentUser?.id;
    try {
      final versions = await GroupDocumentService.instance.fetchVersionHistory(_document.id);
      _ownPendingDraft = versions
          .where((v) =>
              v.authorId == userId &&
              (v.status == GroupDocumentVersionStatus.draft ||
                  v.status == GroupDocumentVersionStatus.inReview))
          .cast<GroupDocumentVersion?>()
          .firstWhere((_) => true, orElse: () => null);
    } catch (_) {
      _ownPendingDraft = null;
    }
    if (mounted) setState(() => _loadingHistory = false);
  }

  /// Agrupa los pasos por categoría, en el orden de primera aparición
  /// (no alfabético). Los pasos sin categoría van bajo una clave `null`
  /// que se muestra como "General"/"Sin categoría".
  List<MapEntry<String?, List<ProtocolStep>>> _groupedSteps(List<ProtocolStep> steps) {
    final order = <String?>[];
    final byCategory = <String?, List<ProtocolStep>>{};
    for (final step in steps) {
      final key = step.category;
      if (!byCategory.containsKey(key)) {
        order.add(key);
        byCategory[key] = [];
      }
      byCategory[key]!.add(step);
    }
    return order.map((key) => MapEntry(key, byCategory[key]!)).toList();
  }

  Instrument? _instrumentFor(String id) {
    for (final i in kInstruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupDocumentFormScreen(
          kind: _document.kind,
          workspaceId: _document.workspaceId,
          existingDocument: _document,
          existingDraft: _ownPendingDraft?.status == GroupDocumentVersionStatus.draft
              ? _ownPendingDraft
              : null,
        ),
      ),
    );
    if (saved == true && mounted) {
      await GroupDocumentService.instance.fetchDocuments(_document.kind, _document.workspaceId);
      final updated = GroupDocumentService.instance.documentById(_document.id);
      setState(() => _document = updated ?? _document);
      _loadOwnDraft();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDocumentVersionHistoryScreen(document: _document, myRole: widget.myRole),
      ),
    );
    _loadOwnDraft();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _document.publishedVersion?.title ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteKindTitle(_document.kind.label.toLowerCase())),
        content: Text(l10n.deleteDocConfirmBody(title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed == true) {
      await GroupDocumentService.instance.deleteDocument(_document.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = _document.publishedVersion;
    final canEdit = widget.myRole?.canEdit ?? false;
    final canApprove = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(published?.title ?? l10n.unpublished),
        actions: [
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
              tooltip: l10n.favoriteToggleTooltip,
              onPressed: _toggleFavorite,
            ),
          IconButton(icon: const Icon(Icons.history), onPressed: _openHistory, tooltip: l10n.historyTooltip),
          if (canEdit) IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          if (canApprove) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_loadingHistory && _ownPendingDraft != null) ...[
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.pending_actions),
                title: Text(
                  _ownPendingDraft!.status == GroupDocumentVersionStatus.inReview
                      ? l10n.pendingReviewTitle
                      : l10n.pendingDraftTitle,
                ),
                subtitle: Text(l10n.pendingDraftSubtitle),
                trailing: _ownPendingDraft!.pendingSync ? const PendingSyncChip() : null,
                onTap: _edit,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (published == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.docNotPublishedYet),
            )
          else ...[
            if (_specialty != null || published.specialty != null) ...[
              _specialty != null
                  ? InputChip(
                      label: Text(_specialty!.label),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SpecialtyDetailScreen(specialty: _specialty!)),
                      ),
                    )
                  : Chip(label: Text(published.specialty!)),
              const SizedBox(height: 16),
            ],
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags
                    .map((tag) => InputChip(
                          label: Text(tag.name),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TagDetailScreen(tag: tag)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (published.content != null) ...[
              Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(published.content!, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
            ],
            if (published.steps.isNotEmpty) ...[
              Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._groupedSteps(published.steps).expand((group) {
                final categoryLabel = group.key ?? l10n.stepsUncategorizedGroup;
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(categoryLabel, style: Theme.of(context).textTheme.labelLarge),
                  ),
                  ...group.value.asMap().entries.map((entry) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${entry.key + 1}')),
                        title: Text(entry.value.text),
                      ),
                    );
                  }),
                ];
              }),
              const SizedBox(height: 20),
            ],
            if (published.relatedInstrumentIds.isNotEmpty) ...[
              Text(l10n.relatedInstrumentsLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.relatedInstrumentIds.map((id) {
                final instrument = _instrumentFor(id);
                if (instrument == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 40),
                    title: Text(instrument.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: instrument)),
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
