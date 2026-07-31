import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatus;
import '../models/specialty_entity.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import 'specialty_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'tray_form_screen.dart';
import 'tray_version_history_screen.dart';

/// Vista de lectura de la versión publicada de una bandeja (o el borrador
/// propio si lo hay). Calcado de [GroupDocumentDetailScreen].
class TrayDetailScreen extends StatefulWidget {
  final Tray tray;
  final WorkspaceRole? myRole;

  const TrayDetailScreen({super.key, required this.tray, required this.myRole});

  @override
  State<TrayDetailScreen> createState() => _TrayDetailScreenState();
}

class _TrayDetailScreenState extends State<TrayDetailScreen> {
  static const String _refType = 'tray';

  late Tray _tray;
  TrayVersion? _ownPendingDraft;
  List<CustomInstrument> _customInstruments = [];
  final Map<String, String> _photoUrls = {};
  bool _loading = true;
  bool _isFavorite = false;
  SpecialtyEntity? _specialty;
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _tray = widget.tray;
    _load();
    _loadSpecialty();
    _loadTags();
    if (AuthService.instance.currentUser != null) {
      RecentActivityService.instance.recordView(_refType, _tray.id);
      UsageAnalyticsService.instance.recordView(_refType, _tray.id);
      _loadFavoriteState();
    }
  }

  Future<void> _loadSpecialty() async {
    final specialtyId = _tray.publishedVersion?.specialtyId;
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
      final tags = await TagService.instance.fetchTagsFor(_refType, _tray.id);
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (_) {
      // Sin bloquear la ficha si falla: las etiquetas son metadato accesorio.
    }
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.instance.isFavorite(_refType, _tray.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(_refType, _tray.id);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    try {
      await CustomInstrumentService.instance.fetchForWorkspace(_tray.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
      final versions = await TrayService.instance.fetchVersionHistory(_tray.id);
      _ownPendingDraft = versions
          .where((v) =>
              v.authorId == userId &&
              (v.status == GroupDocumentVersionStatus.draft || v.status == GroupDocumentVersionStatus.inReview))
          .cast<TrayVersion?>()
          .firstWhere((_) => true, orElse: () => null);
      final published = _tray.publishedVersion;
      if (published != null) {
        for (final path in published.photoPaths) {
          _photoUrls[path] = await TrayService.instance.getPhotoUrl(path);
        }
      }
    } catch (_) {
      _ownPendingDraft = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TrayFormScreen(
          workspaceId: _tray.workspaceId,
          existingTray: _tray,
          existingDraft: _ownPendingDraft?.status == GroupDocumentVersionStatus.draft ? _ownPendingDraft : null,
        ),
      ),
    );
    if (saved == true && mounted) {
      final updated = await TrayService.instance.fetchTray(_tray.id);
      setState(() => _tray = updated);
      _load();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrayVersionHistoryScreen(tray: _tray, myRole: widget.myRole),
      ),
    );
    _load();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _tray.publishedVersion?.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTrayTitle),
        content: Text(l10n.deleteTrayConfirmBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed == true) {
      await TrayService.instance.deleteTray(_tray.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = _tray.publishedVersion;
    final canEdit = widget.myRole?.canEdit ?? false;
    final canApprove = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(published?.name ?? l10n.unpublished),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_ownPendingDraft != null) ...[
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
                  if (published.description != null) ...[
                    Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(published.description!, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 20),
                  ],
                  if (published.items.isNotEmpty) ...[
                    Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...published.items.map((item) => Card(
                          child: ListTile(
                            leading: Icon(
                              item.instrumentRefType == InstrumentRefType.catalog
                                  ? Icons.build_outlined
                                  : Icons.precision_manufacturing_outlined,
                            ),
                            title: Text(item.resolveName(_customInstruments)),
                            trailing: Text(l10n.expectedQtyValue(item.expectedQty)),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],
                  if (published.photoPaths.isNotEmpty) ...[
                    Text(l10n.trayPhotosLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: published.photoPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final url = _photoUrls[published.photoPaths[index]];
                          if (url == null) return const SizedBox(width: 120, height: 120);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (published.observations != null) ...[
                    Text(l10n.trayObservationsLabel, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(published.observations!, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ],
              ],
            ),
    );
  }
}
