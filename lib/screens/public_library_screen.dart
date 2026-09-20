import 'package:flutter/material.dart';

import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/contributor_application.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/instrument.dart' show InstrumentCategoryLabel;
import '../models/public_document.dart';
import '../models/public_instrument.dart';
import '../models/public_tray.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';
import '../services/public_document_service.dart';
import '../services/public_instrument_service.dart';
import '../services/public_tray_service.dart';
import 'auth/sign_in_screen.dart';
import 'contributor_application_form_screen.dart';
import 'public_entity_detail_screen.dart';
import 'public_entity_form_screen.dart';
import 'public_library_review_queue_screen.dart';

/// Biblioteca Pública (EPIC 9, segon tram): tècniques/protocols i safates
/// mantingudes per la comunitat, obertes a tothom (també convidats -- RLS
/// de `public_documents`/`public_trays` és `using (true)`). Independent de
/// si l'usuari està connectat a cap hospital -- per això no viu dins de
/// `LibraryScreen` (que sí ho exigeix), sinó com a accés propi.
class PublicLibraryScreen extends StatefulWidget {
  const PublicLibraryScreen({super.key});

  @override
  State<PublicLibraryScreen> createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  bool get _canContribute => ContributorService.instance.myProfile != null;
  bool get _canReview => ContributorService.instance.isEditorialBoard;

  // El perfil de colaborador solo se carga hoy desde profile_hub_screen.dart
  // (Perfil) — sin este initState, alguien ya aprobado como colaborador que
  // entra directo a la Biblioteca Pública (p. ej. desde un enlace) vería el
  // botón de proponer contenido oculto hasta visitar Perfil una vez.
  bool _loadingContributorState = true;
  ContributorApplication? _lastApplication;

  @override
  void initState() {
    super.initState();
    _loadContributorState();
  }

  Future<void> _loadContributorState() async {
    if (AuthService.instance.currentUser == null) {
      if (mounted) setState(() => _loadingContributorState = false);
      return;
    }
    try {
      await ContributorService.instance.loadMyProfile();
      _lastApplication = ContributorService.instance.myProfile == null
          ? await ContributorService.instance.fetchMyLatestApplication()
          : null;
    } catch (_) {
      // El banner de contribución es un extra: si falla la carga, la
      // Biblioteca Pública sigue funcionando igual, solo sin ese aviso.
    }
    if (mounted) setState(() => _loadingContributorState = false);
  }

  Future<void> _openContributorApplicationForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContributorApplicationFormScreen()),
    );
    if (mounted) {
      setState(() => _loadingContributorState = true);
      _loadContributorState();
    }
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
    if (mounted) {
      setState(() => _loadingContributorState = true);
      _loadContributorState();
    }
  }

  Future<void> _proposeDocument(DocumentKind kind) async {
    final documentId = await PublicDocumentService.instance.createDraft(kind);
    final draft = await PublicDocumentService.instance.fetchDraftVersion(documentId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicEntityFormScreen.document(kind: kind, documentId: documentId, draft: draft),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _proposeTray() async {
    final trayId = await PublicTrayService.instance.createDraft();
    final draft = await PublicTrayService.instance.fetchDraftVersion(trayId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicEntityFormScreen.tray(trayId: trayId, draft: draft)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _proposeInstrument() async {
    final instrumentId = await PublicInstrumentService.instance.createDraft();
    final draft = await PublicInstrumentService.instance.fetchDraftVersion(instrumentId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicEntityFormScreen.instrument(instrumentId: instrumentId, draft: draft),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.publicLibraryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.techniquesTitle),
              Tab(text: l10n.traysTitle),
              Tab(text: l10n.publicLibraryInstrumentsTab),
            ],
          ),
          actions: [
            if (_canReview)
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: l10n.publicLibraryReviewQueueTitle,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PublicLibraryReviewQueueScreen())),
              ),
          ],
        ),
        body: Column(
          children: [
            if (!_loadingContributorState && !_canContribute)
              _ContributeBanner(
                signedIn: AuthService.instance.currentUser != null,
                application: _lastApplication,
                onApply: _openContributorApplicationForm,
                onSignIn: _openSignIn,
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _PublicDocumentList(canContribute: _canContribute, onPropose: _proposeDocument),
                  _PublicTrayList(canContribute: _canContribute, onPropose: _proposeTray),
                  _PublicInstrumentList(canContribute: _canContribute, onPropose: _proposeInstrument),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso para quien todavía no puede usar el botón "Proponer" (visible solo
/// si `canContribute`, ver `_PublicDocumentList`/`_PublicTrayList`): sin este
/// banner, alguien que no es colaborador solo veía una biblioteca de solo
/// lectura, sin ninguna pista de que candidatarse es posible ni de dónde
/// hacerlo — el único enlace a `ContributorApplicationFormScreen` vivía en
/// Perfil, ajeno a la Biblioteca Pública. Reutiliza el mismo texto y los
/// mismos 4 estados (colaborador/pendiente/rechazado/nadie) que ya usa la
/// sección "Comunidad Instriq" de profile_hub_screen.dart — aquí solo
/// aparecen los 3 que no son "ya colaborador", que ya se filtran arriba.
class _ContributeBanner extends StatelessWidget {
  final bool signedIn;
  final ContributorApplication? application;
  final VoidCallback onApply;
  final VoidCallback onSignIn;

  const _ContributeBanner({
    required this.signedIn,
    required this.application,
    required this.onApply,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String title;
    final String subtitle;
    final String? actionLabel;
    final VoidCallback? onAction;
    if (!signedIn) {
      title = l10n.contributorSignInToProposeTitle;
      subtitle = l10n.contributorBecomeSubtitle;
      actionLabel = l10n.signInTitle;
      onAction = onSignIn;
    } else if (application?.status == ContributorApplicationStatus.pending) {
      title = l10n.contributorApplicationPendingTitle;
      subtitle = l10n.contributorApplicationPendingSubtitle;
      actionLabel = null;
      onAction = null;
    } else if (application?.status == ContributorApplicationStatus.rejected) {
      title = l10n.contributorApplicationRejectedTitle;
      subtitle = application?.reviewNotes ?? l10n.contributorApplicationRejectedSubtitle;
      actionLabel = l10n.contributorBecomeAction;
      onAction = onApply;
    } else {
      title = l10n.contributorBecomeAction;
      subtitle = l10n.contributorBecomeSubtitle;
      actionLabel = l10n.contributorBecomeAction;
      onAction = onApply;
    }
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(
          InstriqSpacing.lg, InstriqSpacing.md, InstriqSpacing.lg, InstriqSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(InstriqSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: InstriqSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: InstriqSpacing.sm),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PublicDocumentList extends StatefulWidget {
  final bool canContribute;
  final ValueChanged<DocumentKind> onPropose;

  const _PublicDocumentList({required this.canContribute, required this.onPropose});

  @override
  State<_PublicDocumentList> createState() => _PublicDocumentListState();
}

class _PublicDocumentListState extends State<_PublicDocumentList> {
  bool _loading = true;
  String? _error;
  List<PublicDocument> _documents = [];

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
      final techniques = await PublicDocumentService.instance.fetchPublished(DocumentKind.technique);
      final protocols = await PublicDocumentService.instance.fetchPublished(DocumentKind.protocol);
      _documents = [...techniques, ...protocols];
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _documents.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.publicLibraryEmptyState)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          final version = document.publishedVersion;
                          return Card(
                            child: ListTile(
                              leading: Icon(document.kind == DocumentKind.protocol
                                  ? Icons.checklist_outlined
                                  : Icons.menu_book_outlined),
                              title: Text(version?.title ?? l10n.auditDocumentUntitledLabel),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.document(document: document)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: widget.canContribute
          ? FloatingActionButton.extended(
              onPressed: () async {
                final kind = await showModalBottomSheet<DocumentKind>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(l10n.techniquesTitle),
                          onTap: () => Navigator.pop(ctx, DocumentKind.technique),
                        ),
                        ListTile(
                          title: Text(l10n.protocolsTitle),
                          onTap: () => Navigator.pop(ctx, DocumentKind.protocol),
                        ),
                      ],
                    ),
                  ),
                );
                if (kind != null) widget.onPropose(kind);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.publicLibraryProposeAction),
            )
          : null,
    );
  }
}

class _PublicTrayList extends StatefulWidget {
  final bool canContribute;
  final VoidCallback onPropose;

  const _PublicTrayList({required this.canContribute, required this.onPropose});

  @override
  State<_PublicTrayList> createState() => _PublicTrayListState();
}

class _PublicTrayListState extends State<_PublicTrayList> {
  bool _loading = true;
  String? _error;
  List<PublicTray> _trays = [];

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
      _trays = await PublicTrayService.instance.fetchPublished();
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _trays.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.publicLibraryEmptyState)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _trays.length,
                        itemBuilder: (context, index) {
                          final tray = _trays[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(tray.publishedVersion?.name ?? l10n.auditDocumentUntitledLabel),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.tray(tray: tray)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: widget.canContribute
          ? FloatingActionButton.extended(
              onPressed: widget.onPropose,
              icon: const Icon(Icons.add),
              label: Text(l10n.publicLibraryProposeAction),
            )
          : null,
    );
  }
}

class _PublicInstrumentList extends StatefulWidget {
  final bool canContribute;
  final VoidCallback onPropose;

  const _PublicInstrumentList({required this.canContribute, required this.onPropose});

  @override
  State<_PublicInstrumentList> createState() => _PublicInstrumentListState();
}

class _PublicInstrumentListState extends State<_PublicInstrumentList> {
  bool _loading = true;
  String? _error;
  List<PublicInstrument> _instruments = [];

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
      _instruments = await PublicInstrumentService.instance.fetchPublished();
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _instruments.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.publicLibraryEmptyState)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _instruments.length,
                        itemBuilder: (context, index) {
                          final instrument = _instruments[index];
                          final version = instrument.publishedVersion;
                          final photoPath = version?.photoPath;
                          return Card(
                            child: ListTile(
                              leading: photoPath != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        PublicInstrumentService.instance.photoUrl(photoPath),
                                      ),
                                    )
                                  : const CircleAvatar(child: Icon(Icons.precision_manufacturing_outlined)),
                              title: Text(version?.name ?? l10n.auditDocumentUntitledLabel),
                              subtitle: version?.category != null ? Text(version!.category!.label(l10n)) : null,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.instrument(instrument: instrument)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: widget.canContribute
          ? FloatingActionButton.extended(
              onPressed: widget.onPropose,
              icon: const Icon(Icons.add),
              label: Text(l10n.publicLibraryProposeAction),
            )
          : null,
    );
  }
}
