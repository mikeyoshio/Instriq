import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/public_document.dart';
import '../models/public_instrument.dart';
import '../models/public_tray.dart';
import '../services/auth_service.dart';
import '../services/public_document_service.dart';
import '../services/public_instrument_service.dart';
import '../services/public_tray_service.dart';
import 'public_entity_form_screen.dart';

String _statusLabel(AppLocalizations l10n, PublicContentStatus status) {
  switch (status) {
    case PublicContentStatus.draft:
      return l10n.contentStatusDraftLabel;
    case PublicContentStatus.inReview:
      return l10n.contentStatusInReviewLabel;
    case PublicContentStatus.published:
      return l10n.contentStatusPublishedLabel;
    case PublicContentStatus.archived:
      return l10n.contentStatusArchivedLabel;
  }
}

/// Les meves propostes a la Biblioteca Pública, sigui quin sigui l'estat --
/// abans no hi havia cap manera de retrobar un esborrany propi (ni una
/// candidatura rebutjada, que torna a `draft` amb el `comment` de qui
/// revisa) un cop es sortia del formulari. Nomes el `draft` es editable
/// (mateix criteri que `public_*_versions_update_own_draft`); la resta
/// nomes mostra l'estat i, si n'hi ha, el comentari de la darrera revisió.
class MyPublicContributionsScreen extends StatelessWidget {
  const MyPublicContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myPublicSubmissionsTitle),
          bottom: TabBar(tabs: [
            Tab(text: l10n.techniquesTitle),
            Tab(text: l10n.traysTitle),
            Tab(text: l10n.publicLibraryInstrumentsTab),
          ]),
        ),
        body: const TabBarView(children: [_MyDocuments(), _MyTrays(), _MyInstruments()]),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final PublicContentStatus status;
  final String? comment;
  final VoidCallback? onTap;

  const _SubmissionRow({
    required this.icon,
    required this.title,
    required this.status,
    this.comment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = status == PublicContentStatus.inReview
        ? l10n.submissionPendingReviewNote
        : (comment != null && comment!.isNotEmpty ? comment : null);
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Chip(label: Text(_statusLabel(l10n, status)), visualDensity: VisualDensity.compact),
        onTap: onTap,
      ),
    );
  }
}

class _MyDocuments extends StatefulWidget {
  const _MyDocuments();

  @override
  State<_MyDocuments> createState() => _MyDocumentsState();
}

class _MyDocumentsState extends State<_MyDocuments> {
  bool _loading = true;
  String? _error;
  List<PublicDocumentVersion> _versions = [];

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
      final userId = AuthService.instance.currentUser?.id;
      _versions = userId == null ? [] : await PublicDocumentService.instance.fetchMine(userId);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openDraft(PublicDocumentVersion version) async {
    final document = await PublicDocumentService.instance.fetchDocument(version.documentId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicEntityFormScreen.document(kind: document.kind, documentId: version.documentId, draft: version),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    if (_versions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.myPublicSubmissionsEmptyState)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index];
          return _SubmissionRow(
            icon: Icons.menu_book_outlined,
            title: version.title ?? l10n.auditDocumentUntitledLabel,
            status: version.status,
            comment: version.comment,
            onTap: version.status == PublicContentStatus.draft ? () => _openDraft(version) : null,
          );
        },
      ),
    );
  }
}

class _MyTrays extends StatefulWidget {
  const _MyTrays();

  @override
  State<_MyTrays> createState() => _MyTraysState();
}

class _MyTraysState extends State<_MyTrays> {
  bool _loading = true;
  String? _error;
  List<PublicTrayVersion> _versions = [];

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
      final userId = AuthService.instance.currentUser?.id;
      _versions = userId == null ? [] : await PublicTrayService.instance.fetchMine(userId);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openDraft(PublicTrayVersion version) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicEntityFormScreen.tray(trayId: version.trayId, draft: version)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    if (_versions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.myPublicSubmissionsEmptyState)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index];
          return _SubmissionRow(
            icon: Icons.inventory_2_outlined,
            title: version.name ?? l10n.auditDocumentUntitledLabel,
            status: version.status,
            comment: version.comment,
            onTap: version.status == PublicContentStatus.draft ? () => _openDraft(version) : null,
          );
        },
      ),
    );
  }
}

class _MyInstruments extends StatefulWidget {
  const _MyInstruments();

  @override
  State<_MyInstruments> createState() => _MyInstrumentsState();
}

class _MyInstrumentsState extends State<_MyInstruments> {
  bool _loading = true;
  String? _error;
  List<PublicInstrumentVersion> _versions = [];

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
      final userId = AuthService.instance.currentUser?.id;
      _versions = userId == null ? [] : await PublicInstrumentService.instance.fetchMine(userId);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openDraft(PublicInstrumentVersion version) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicEntityFormScreen.instrument(instrumentId: version.instrumentId, draft: version),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    if (_versions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.myPublicSubmissionsEmptyState)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index];
          return _SubmissionRow(
            icon: Icons.precision_manufacturing_outlined,
            title: version.name ?? l10n.auditDocumentUntitledLabel,
            status: version.status,
            comment: version.comment,
            onTap: version.status == PublicContentStatus.draft ? () => _openDraft(version) : null,
          );
        },
      ),
    );
  }
}
