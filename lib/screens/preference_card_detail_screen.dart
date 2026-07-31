import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatus;
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import '../widgets/category_icon.dart';
import 'preference_card_form_screen.dart';
import 'preference_card_version_history_screen.dart';
import 'surgeon_detail_screen.dart';

/// Vista de lectura de la versión publicada de una tarjeta de preferencia (o
/// el borrador propio si lo hay). Calcado de [TrayDetailScreen].
class PreferenceCardDetailScreen extends StatefulWidget {
  final PreferenceCard card;
  final WorkspaceRole? myRole;

  const PreferenceCardDetailScreen({super.key, required this.card, required this.myRole});

  @override
  State<PreferenceCardDetailScreen> createState() => _PreferenceCardDetailScreenState();
}

class _PreferenceCardDetailScreenState extends State<PreferenceCardDetailScreen> {
  late PreferenceCard _card;
  PreferenceCardVersion? _ownPendingDraft;
  Surgeon? _surgeon;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    try {
      await SurgeonService.instance.fetchForOrganization();
      final surgeonId = _card.publishedVersion?.surgeonId;
      _surgeon = surgeonId != null ? SurgeonService.instance.byId(surgeonId) : null;
      final versions = await PreferenceCardService.instance.fetchVersionHistory(_card.id);
      _ownPendingDraft = versions
          .where((v) =>
              v.authorId == userId &&
              (v.status == GroupDocumentVersionStatus.draft || v.status == GroupDocumentVersionStatus.inReview))
          .cast<PreferenceCardVersion?>()
          .firstWhere((_) => true, orElse: () => null);
    } catch (_) {
      _ownPendingDraft = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Instrument? _catalogFor(PreferenceCardItem item) {
    if (item.instrumentId == null) return null;
    for (final i in kInstruments) {
      if (i.id == item.instrumentId) return i;
    }
    return null;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PreferenceCardFormScreen(
          workspaceId: _card.workspaceId,
          existingCard: _card,
          existingDraft: _ownPendingDraft?.status == GroupDocumentVersionStatus.draft ? _ownPendingDraft : null,
        ),
      ),
    );
    if (saved == true && mounted) {
      final updated = await PreferenceCardService.instance.fetchCard(_card.id);
      setState(() => _card = updated);
      _load();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreferenceCardVersionHistoryScreen(card: _card, myRole: widget.myRole)),
    );
    _load();
  }

  /// Ver comentario de [PreferenceCardService.setValidatedBySurgeon]: es una
  /// anotación directa sobre la versión publicada, fuera del workflow de
  /// borrador/revisión.
  Future<void> _toggleValidated() async {
    final published = _card.publishedVersion;
    if (published == null) return;
    final newValue = !published.validatedBySurgeon;
    await PreferenceCardService.instance.setValidatedBySurgeon(published.id, newValue);
    setState(() {
      _card = _card.copyWith(publishedVersion: published.copyWith(validatedBySurgeon: newValue));
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final procedure = _card.publishedVersion?.procedureName ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCardTitle),
        content: Text(l10n.deleteCardBody(procedure, _surgeon?.name ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed == true) {
      await PreferenceCardService.instance.deleteCard(_card.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = _card.publishedVersion;
    final canEdit = widget.myRole?.canEdit ?? false;
    final canApprove = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(published?.procedureName ?? l10n.unpublished),
        actions: [
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
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _surgeon != null
                            ? InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SurgeonDetailScreen(surgeon: _surgeon!)),
                                ),
                                child: Text(
                                  _surgeon!.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(decoration: TextDecoration.underline),
                                ),
                              )
                            : Text('—', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (published.validatedBySurgeon)
                        Chip(
                          avatar: const Icon(Icons.verified, color: Colors.green, size: 18),
                          label: Text(l10n.validatedBySurgeon),
                        ),
                    ],
                  ),
                  if (canEdit) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _toggleValidated,
                      icon: Icon(published.validatedBySurgeon ? Icons.close : Icons.verified_outlined),
                      label: Text(published.validatedBySurgeon ? l10n.removeValidation : l10n.markValidatedBySurgeon),
                    ),
                  ],
                  if (published.generalNotes != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(padding: const EdgeInsets.all(12), child: Text(published.generalNotes!)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(l10n.instrumentsCountTitle(published.items.length),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...published.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final catalogInstrument = _catalogFor(item);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(item.customName),
                        subtitle: item.note != null ? Text(item.note!) : null,
                        trailing: catalogInstrument != null
                            ? InstrumentIcon(iconKey: catalogInstrument.icon, category: catalogInstrument.category, size: 40)
                            : null,
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
