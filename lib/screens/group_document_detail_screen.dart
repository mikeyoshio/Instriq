import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/instruments_data.dart';
import '../data/sutures_data.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/group_document_video.dart';
import '../models/instrument.dart';
import '../models/instrument_sterilization.dart';
import '../models/preference_card.dart';
import '../models/specialty_entity.dart';
import '../models/suture.dart';
import '../models/tag.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/group_document_video_service.dart';
import '../services/manufacturer_service.dart';
import '../services/preference_card_service.dart';
import '../services/profile_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/sterilization_service.dart';
import '../services/surgeon_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sterilization_method_label.dart';
import 'group_document_form_screen.dart';
import 'group_document_version_history_screen.dart';
import 'instrument_detail_screen.dart';
import 'preference_card_detail_screen.dart';
import 'specialty_detail_screen.dart';
import 'suture_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'tray_detail_screen.dart';

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
  Map<String, List<SterilizationMethodEntry>> _instrumentMethods = {};
  Map<String, InstrumentTechnicalInfo?> _instrumentTechnicalInfo = {};
  List<PreferenceCard> _preferenceCards = [];
  List<CustomInstrument> _customInstruments = [];
  bool _loadingVideos = true;
  List<GroupDocumentVideo> _videos = [];

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _loadOwnDraft();
    _loadSpecialty();
    _loadTags();
    _loadTrays();
    _loadClinicalWorkspaceData();
    _loadVideos();
    if (AuthService.instance.currentUser != null) {
      RecentActivityService.instance.recordView(_refType, _document.id);
      UsageAnalyticsService.instance.recordView(_refType, _document.id);
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

  Future<void> _loadTrays() async {
    try {
      await Future.wait([
        TrayService.instance.fetchTrays(_document.workspaceId),
        CustomInstrumentService.instance.fetchForWorkspace(_document.workspaceId),
      ]);
      if (!mounted) return;
      setState(() => _customInstruments = CustomInstrumentService.instance.instruments);
    } catch (_) {
      // Sin bloquear la ficha si falla: se muestra el id crudo como fallback.
    }
  }

  /// Esterilización/ficha técnica de cada instrumento relacionado, y las
  /// tarjetas de preferencia del espacio — EPIC 2 · Clinical Workspace.
  /// `related_instrument_ids` solo contiene ids de catálogo (el selector de
  /// la técnica solo ofrece catálogo), así que no hace falta resolver
  /// instrumental personalizado aquí. El N de instrumentos relacionados por
  /// técnica es pequeño: un fetch por id es el mismo criterio ya aceptado en
  /// el resto de la app (no se justifica una RPC de bulk como en EPIC 5,
  /// pensada para "todo el catálogo").
  Future<void> _loadClinicalWorkspaceData() async {
    final relatedIds = _document.publishedVersion?.relatedInstrumentIds ?? const <String>[];
    final methods = <String, List<SterilizationMethodEntry>>{};
    final technicalInfo = <String, InstrumentTechnicalInfo?>{};
    for (final id in relatedIds) {
      try {
        methods[id] = await SterilizationService.instance.fetchMethods('catalog', id);
        technicalInfo[id] = await SterilizationService.instance.fetchTechnicalInfo('catalog', id);
      } catch (_) {
        // Metadato accesorio: un instrumento fallando no bloquea el resto de la ficha.
      }
    }
    try {
      // No hace falta guardar la lista devuelta: ManufacturerService.byId lee
      // de su propio caché interno, calentado por este fetchAll.
      await ManufacturerService.instance.fetchAll();
    } catch (_) {
      // Metadato accesorio: no bloquea el resto de la ficha si falla.
    }
    var preferenceCards = <PreferenceCard>[];
    try {
      await Future.wait([
        PreferenceCardService.instance.fetchCards(_document.workspaceId),
        SurgeonService.instance.fetchForOrganization(),
      ]);
      preferenceCards = PreferenceCardService.instance.cardsOfWorkspace(_document.workspaceId);
    } catch (_) {
      // Metadato accesorio: no bloquea el resto de la ficha si falla.
    }
    if (!mounted) return;
    setState(() {
      _instrumentMethods = methods;
      _instrumentTechnicalInfo = technicalInfo;
      _preferenceCards = preferenceCards;
    });
  }

  String? _instrumentSummary(AppLocalizations l10n, String instrumentId) {
    final methods = _instrumentMethods[instrumentId] ?? const [];
    final info = _instrumentTechnicalInfo[instrumentId];
    final methodValues = methods.map((m) => m.publishedVersion?.method).whereType<SterilizationMethod>();
    final manufacturerId = info?.publishedVersion?.manufacturerId;
    final parts = <String>[
      if (methodValues.isNotEmpty) methodValues.map((m) => sterilizationMethodValueLabel(l10n, m)).join(', '),
      if (manufacturerId != null) ManufacturerService.instance.byId(manufacturerId)?.name ?? '',
    ]..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String _surgeonLabel(AppLocalizations l10n, PreferenceCard card) {
    final surgeonId = card.publishedVersion?.surgeonId;
    if (surgeonId == null) return l10n.noSurgeonAssignedLabel;
    return SurgeonService.instance.byId(surgeonId)?.name ?? l10n.noSurgeonAssignedLabel;
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
      _ownPendingDraft = (versions
              .where((v) =>
                  v.authorId == userId &&
                  (v.status == GroupDocumentVersionStatus.draft ||
                      v.status == GroupDocumentVersionStatus.inReview))
              .toList()
            ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber)))
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

  Suture? _sutureFor(String id) {
    for (final s in kSutures) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await GroupDocumentVideoService.instance.fetchForDocument(_document.id);
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loadingVideos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVideos = false);
    }
  }

  Future<void> _openAddVideoDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addVideoDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(labelText: l10n.videoTitleLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(labelText: l10n.videoUrlLabel),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: (titleController.text.trim().isEmpty || urlController.text.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: Text(l10n.addVideoAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await GroupDocumentVideoService.instance.submit(
        groupDocumentId: _document.id,
        workspaceId: _document.workspaceId,
        title: titleController.text.trim(),
        url: urlController.text.trim(),
      );
      if (mounted) {
        setState(() => _loadingVideos = true);
        await _loadVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  Future<void> _approveVideo(GroupDocumentVideo video) async {
    if (video.id == null) return;
    await GroupDocumentVideoService.instance.approve(video.id!);
    setState(() => _loadingVideos = true);
    await _loadVideos();
  }

  Future<void> _rejectVideo(GroupDocumentVideo video) async {
    if (video.id == null) return;
    await GroupDocumentVideoService.instance.reject(video.id!);
    setState(() => _loadingVideos = true);
    await _loadVideos();
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
          if (canEdit) IconButton(icon: const Icon(Icons.edit), tooltip: l10n.editTooltip, onPressed: _edit),
          if (canApprove)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: l10n.deleteTooltip, onPressed: _delete),
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
            Builder(builder: (context) {
              final canReport = AuthService.instance.currentUser != null;
              final canModerate = ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
              final visibleVideos =
                  canModerate ? _videos : _videos.where((v) => v.status == VideoStatus.approved).toList();
              if (!canReport && visibleVideos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.videosLabel, style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        if (canReport)
                          TextButton.icon(
                            onPressed: _openAddVideoDialog,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addVideoAction),
                          ),
                      ],
                    ),
                    if (_loadingVideos)
                      const Center(child: CircularProgressIndicator())
                    else if (visibleVideos.isEmpty)
                      Text(l10n.noVideosYet, style: Theme.of(context).textTheme.bodyMedium)
                    else
                      ...visibleVideos.map((video) => Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.play_circle_outline),
                                  title: Text(video.title),
                                  subtitle: video.status == VideoStatus.pending
                                      ? Text(l10n.videoPendingLabel)
                                      : null,
                                  onTap: () => launchUrl(Uri.parse(video.url)),
                                ),
                                if (canModerate && video.status == VideoStatus.pending)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _rejectVideo(video),
                                          child: Text(l10n.reject),
                                        ),
                                        FilledButton(
                                          onPressed: () => _approveVideo(video),
                                          child: Text(l10n.approve),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )),
                  ],
                ),
              );
            }),
            if (published.relatedInstrumentIds.isNotEmpty) ...[
              Text(l10n.relatedInstrumentsLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.relatedInstrumentIds.map((id) {
                final instrument = _instrumentFor(id);
                if (instrument == null) return const SizedBox.shrink();
                final summary = _instrumentSummary(l10n, id);
                return Card(
                  child: ListTile(
                    leading: InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 40),
                    title: Text(instrument.name),
                    subtitle: summary != null ? Text(summary) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: instrument)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            if (published.relatedSutureIds.isNotEmpty) ...[
              Text(l10n.relatedSuturesLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.relatedSutureIds.map((id) {
                final suture = _sutureFor(id);
                if (suture == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.line_style),
                    title: Text(suture.name),
                    subtitle: Text(suture.material.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SutureDetailScreen(suture: suture)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            if (published.relatedTrayIds.isNotEmpty) ...[
              Text(l10n.relatedTraysLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.relatedTrayIds.map((id) {
                final tray = TrayService.instance.trayById(id);
                if (tray == null) return const SizedBox.shrink();
                final items = tray.publishedVersion?.items ?? const [];
                return Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(tray.publishedVersion?.name ?? id),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: l10n.openTrayTooltip,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: widget.myRole)),
                      ),
                    ),
                    children: items.isEmpty
                        ? [Padding(padding: const EdgeInsets.all(12), child: Text(l10n.trayNoItemsYet))]
                        : items.map((item) {
                            return ListTile(
                              dense: true,
                              title: Text(item.resolveName(_customInstruments)),
                              subtitle: item.position != null ? Text(item.position!) : null,
                              trailing: Text(l10n.expectedQtyValue(item.expectedQty)),
                            );
                          }).toList(),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            if (published.consumables.isNotEmpty) ...[
              Text(l10n.consumablesLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.consumables.map((item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_outlined),
                      title: Text(item.quantity == null || item.quantity!.isEmpty
                          ? item.name
                          : '${item.name} · ${item.quantity}'),
                      subtitle: item.notes != null && item.notes!.isNotEmpty ? Text(item.notes!) : null,
                    ),
                  )),
              const SizedBox(height: 20),
            ],
            if (published.patientPositioning != null && published.patientPositioning!.isNotEmpty) ...[
              Text(l10n.patientPositioningLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(published.patientPositioning!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
            ],
            if (published.anesthesiaNotes != null && published.anesthesiaNotes!.isNotEmpty) ...[
              Text(l10n.anesthesiaNotesLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(published.anesthesiaNotes!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
            ],
            if (_preferenceCards.isNotEmpty) ...[
              Text(l10n.workspacePreferenceCardsLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._preferenceCards.map((card) {
                final cardPublished = card.publishedVersion;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(cardPublished?.procedureName ?? l10n.unpublished),
                    subtitle: Text(_surgeonLabel(l10n, card)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PreferenceCardDetailScreen(card: card, myRole: widget.myRole),
                      ),
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
