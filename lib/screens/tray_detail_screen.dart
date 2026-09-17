import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_stale_content_banner.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatus;
import '../models/specialty_entity.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/knowledge_link_service.dart';
import '../services/public_tray_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/pdf_export.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/offline_banner.dart';
import 'group_document_detail_screen.dart';
import 'specialty_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'tray_form_screen.dart';
import 'tray_preparation_or_mode_screen.dart';
import 'tray_preparation_sessions_screen.dart';
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
  List<GroupDocument> _usedInDocuments = [];

  /// true si el origen público de esta bandeja (ADR-001 / EPIC 9) ha
  /// publicado una versión distinta de la que se adoptó/actualizó por
  /// última vez. Solo tiene sentido comprobarlo cuando `syncStatus ==
  /// synced` -- una bandeja `customized` ya avisa de otra forma (ver
  /// `_buildUpstreamBanner`), e `independent` ya no recibe avisos por diseño.
  bool _upstreamHasNewerVersion = false;

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
    // Cada bloque es un fallo independiente: que uno falle (p.ej. una URL de
    // foto caducada) no debe anular un `_ownPendingDraft` ya calculado
    // correctamente en un bloque anterior -- ver docs/BACKLOG.md Nivell 3.
    try {
      await CustomInstrumentService.instance.fetchForWorkspace(_tray.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
    } catch (_) {
      // Instrumental personalizado es metadato accesorio del checklist: no bloquea el resto de la ficha.
    }
    try {
      final versions = await TrayService.instance.fetchVersionHistory(_tray.id);
      _ownPendingDraft = (versions
              .where((v) =>
                  v.authorId == userId &&
                  (v.status == GroupDocumentVersionStatus.draft || v.status == GroupDocumentVersionStatus.inReview))
              .toList()
            ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber)))
          .cast<TrayVersion?>()
          .firstWhere((_) => true, orElse: () => null);
    } catch (_) {
      _ownPendingDraft = null;
    }
    try {
      final published = _tray.publishedVersion;
      if (published != null) {
        for (final path in published.photoPaths) {
          _photoUrls[path] = await TrayService.instance.getPhotoUrl(path);
        }
      }
    } catch (_) {
      // Fallo al firmar una URL de foto (Storage temporalmente inaccesible): no bloquea el resto.
    }
    try {
      final links = await KnowledgeLinkService.instance.fetchRelatedTo('tray', _tray.id);
      final usedInDocuments = <GroupDocument>[];
      for (final link in links) {
        if (link.fromType != 'group_document') continue;
        try {
          usedInDocuments.add(await GroupDocumentService.instance.fetchDocument(link.fromId));
        } catch (_) {
          // Enlace obsoleto (documento borrado sin limpiar a tiempo): se omite.
        }
      }
      _usedInDocuments = usedInDocuments;
    } catch (_) {
      // Grafo de conocimiento es metadato accesorio: no bloquea el resto de la ficha.
    }
    try {
      final upstreamId = _tray.upstreamPublicTrayId;
      if (upstreamId != null && _tray.syncStatus == TraySyncStatus.synced) {
        final upstream = await PublicTrayService.instance.fetchTray(upstreamId);
        _upstreamHasNewerVersion = upstream.publishedVersionId != null &&
            upstream.publishedVersionId != _tray.upstreamAdoptedVersionId;
      } else {
        _upstreamHasNewerVersion = false;
      }
    } catch (_) {
      // Comprobación de staleness accesoria: no bloquea el resto de la ficha.
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

  Future<void> _exportPdf() async {
    final published = _tray.publishedVersion;
    if (published == null) return;
    final l10n = AppLocalizations.of(context)!;
    await exportTrayChecklistPdf(
      published: published,
      customInstruments: _customInstruments,
      specialtyLabel: _specialty?.label,
      l10n: l10n,
    );
  }

  Future<void> _prepare() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrayPreparationOrModeScreen(tray: _tray)),
    );
  }

  Future<void> _openPreparationHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrayPreparationSessionsScreen(tray: _tray, myRole: widget.myRole),
      ),
    );
  }

  Future<void> _duplicate() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final newDraft = await TrayService.instance.duplicateTray(_tray.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrayFormScreen(workspaceId: _tray.workspaceId, existingDraft: newDraft),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  /// "Actualitzar" (ADR-001 §4): trae el contenido actual del origen público
  /// al borrador propio en curso (o crea uno) -- nunca publica sola, sigue
  /// exigiendo "Enviar a revisión" como cualquier otro cambio.
  Future<void> _updateFromUpstream() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final newDraft = await TrayService.instance.updateFromUpstream(_tray.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrayFormScreen(workspaceId: _tray.workspaceId, existingDraft: newDraft),
        ),
      );
      if (mounted) {
        final updated = await TrayService.instance.fetchTray(_tray.id);
        setState(() => _tray = updated);
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  Future<void> _stopFollowing() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.trayStopFollowingConfirmTitle),
        content: Text(l10n.trayStopFollowingConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.trayStopFollowingAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TrayService.instance.stopFollowingUpstream(_tray.id);
      if (mounted) {
        final updated = await TrayService.instance.fetchTray(_tray.id);
        setState(() {
          _tray = updated;
          _upstreamHasNewerVersion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  String _syncStatusLabel(AppLocalizations l10n, TraySyncStatus status) {
    switch (status) {
      case TraySyncStatus.synced:
        return l10n.traySyncedLabel;
      case TraySyncStatus.customized:
        return l10n.trayCustomizedLabel;
      case TraySyncStatus.independent:
        return l10n.trayIndependentLabel;
    }
  }

  Color _syncStatusColor(TraySyncStatus status) {
    switch (status) {
      case TraySyncStatus.synced:
        return Colors.green;
      case TraySyncStatus.customized:
        return Colors.orange;
      case TraySyncStatus.independent:
        return Colors.grey;
    }
  }

  /// ADR-001 §4: los 3 estados visuales ("Sincronitzat"/"Personalitzat"/
  /// "Independent") nunca usan vocabulario de implementación ("fork",
  /// "branch", "merge") -- ni aquí ni en ningún texto de la UI.
  Widget _buildUpstreamBanner(BuildContext context, AppLocalizations l10n, bool canEdit) {
    final status = _tray.syncStatus;
    if (status == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public_outlined, size: 18, color: _syncStatusColor(status)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.trayUpstreamBadgeTooltip} · ${_syncStatusLabel(l10n, status)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              if (status == TraySyncStatus.synced && _upstreamHasNewerVersion) ...[
                const SizedBox(height: 8),
                Text(l10n.trayUpdateAvailableBanner, style: Theme.of(context).textTheme.bodyMedium),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(onPressed: _updateFromUpstream, child: Text(l10n.trayUpdateAction)),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _stopFollowing, child: Text(l10n.trayStopFollowingAction)),
                    ],
                  ),
                ],
              ] else if (status != TraySyncStatus.independent && canEdit) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: _stopFollowing, child: Text(l10n.trayStopFollowingAction)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
          if (published != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.exportPdfAction,
              onPressed: _exportPdf,
            ),
          if (canEdit) IconButton(icon: const Icon(Icons.edit), tooltip: l10n.editTooltip, onPressed: _edit),
          if (canApprove)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: l10n.deleteTooltip, onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : InstriqResponsiveContent(
              child: ListView(
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
                      trailing: _ownPendingDraft!.pendingSync ? const PendingSyncChip() : null,
                      onTap: _edit,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildUpstreamBanner(context, l10n, canEdit),
                InstriqStaleContentBanner(approvedAt: published?.approvedAt),
                if (published == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.docNotPublishedYet),
                  )
                else ...[
                  if (widget.myRole != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _prepare,
                            icon: const Icon(Icons.playlist_add_check_outlined),
                            label: Text(l10n.prepareTrayAction),
                          ),
                        ),
                        IconButton(
                          onPressed: _openPreparationHistory,
                          icon: const Icon(Icons.history_edu_outlined),
                          tooltip: l10n.trayPreparationHistoryLabel,
                        ),
                        if (canEdit)
                          IconButton(
                            onPressed: _duplicate,
                            icon: const Icon(Icons.copy_all_outlined),
                            tooltip: l10n.duplicateTrayAction,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
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
                            subtitle: item.position != null ? Text(item.position!) : null,
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
                    const SizedBox(height: 20),
                  ],
                  if (_usedInDocuments.isNotEmpty) ...[
                    Text(l10n.knowledgeGraphUsedInTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._usedInDocuments.map((doc) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(doc.publishedVersion?.title ?? doc.id),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDocumentDetailScreen(document: doc, myRole: widget.myRole),
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ],
            ),
            ),
    );
  }
}
