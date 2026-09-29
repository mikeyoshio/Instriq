import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/instrument.dart' show InstrumentCategoryLabel;
import '../models/public_document.dart';
import '../models/public_instrument.dart';
import '../models/public_tray.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';
import '../services/profile_service.dart';
import '../services/public_document_service.dart';
import '../services/public_instrument_service.dart';
import '../services/public_tray_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import '../utils/public_content_locale_label.dart';
import 'contributor_public_profile_screen.dart';
import 'public_entity_form_screen.dart';
import 'tray_form_screen.dart';

/// Vista de lectura d'una tècnica/protocol o safata publicada a la
/// Biblioteca Pública -- oberta a tothom, inclosos convidats. Les bandejas
/// (només, de moment) es poden "adoptar" com a punt de partida d'una bandeja
/// pròpia -- ADR-001 §0 / EPIC 9 "adopció d'organització sobre contingut
/// públic" (ver schema_v42_tray_adoption.sql): primer candidat real segons
/// el propi ADR §8, tècniques/targetes queden per a una ronda futura.
class PublicEntityDetailScreen extends StatelessWidget {
  final PublicEntityKind entityKind;
  final PublicDocument? document;
  final PublicTray? tray;
  final PublicInstrument? instrument;

  PublicEntityDetailScreen.document({super.key, required PublicDocument document})
      : entityKind = document.kind == DocumentKind.protocol ? PublicEntityKind.protocol : PublicEntityKind.technique,
        document = document,
        tray = null,
        instrument = null;

  const PublicEntityDetailScreen.tray({super.key, required this.tray})
      : entityKind = PublicEntityKind.tray,
        document = null,
        instrument = null;

  const PublicEntityDetailScreen.instrument({super.key, required this.instrument})
      : entityKind = PublicEntityKind.instrument,
        document = null,
        tray = null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTray = entityKind.isTray;
    final isInstrument = entityKind.isInstrument;
    final documentVersion = document?.publishedVersion;
    final trayVersion = tray?.publishedVersion;
    final instrumentVersion = instrument?.publishedVersion;
    final title = isTray ? trayVersion?.name : (isInstrument ? instrumentVersion?.name : documentVersion?.title);
    final hasVersion = isTray ? trayVersion != null : (isInstrument ? instrumentVersion != null : documentVersion != null);
    final authorId = isTray ? trayVersion?.authorId : (isInstrument ? instrumentVersion?.authorId : documentVersion?.authorId);
    final translationGroupId = isTray ? tray?.translationGroupId : (isInstrument ? instrument?.translationGroupId : document?.translationGroupId);
    final sourceId = isTray ? tray?.id : (isInstrument ? instrument?.id : document?.id);
    final currentLocale = isTray ? tray?.locale : (isInstrument ? instrument?.locale : document?.locale);

    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.auditDocumentUntitledLabel)),
      body: !hasVersion
          ? Center(child: Text(l10n.publicLibraryEmptyState))
          : SafeArea(
              child: InstriqResponsiveContent(
                child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (translationGroupId != null && sourceId != null && currentLocale != null) ...[
                    _TranslationBar(
                      entityKind: entityKind,
                      translationGroupId: translationGroupId,
                      sourceId: sourceId,
                      currentLocale: currentLocale,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (isTray) ...[
                    _AdoptTrayButton(tray: tray!),
                    const SizedBox(height: 20),
                  ],
                  ...isInstrument
                      ? _instrumentContent(context, l10n, instrumentVersion!)
                      : isTray
                          ? _trayContent(context, l10n, trayVersion!)
                          : _documentContent(context, l10n, documentVersion!),
                  if (authorId != null) ...[
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(l10n.contributorPublicProfileTitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContributorPublicProfileScreen(userId: authorId),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ),
            ),
    );
  }

  List<Widget> _documentContent(BuildContext context, AppLocalizations l10n, PublicDocumentVersion version) {
    return [
      if (version.content != null && version.content!.isNotEmpty) ...[
        Text(version.content!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
      if (version.steps.isNotEmpty) ...[
        Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < version.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 14, child: Text('${i + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (version.steps[i].category != null)
                        Text(version.steps[i].category!, style: Theme.of(context).textTheme.labelMedium),
                      Text(version.steps[i].text, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ];
  }

  List<Widget> _trayContent(BuildContext context, AppLocalizations l10n, PublicTrayVersion version) {
    return [
      if (version.description != null && version.description!.isNotEmpty) ...[
        Text(version.description!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
      ],
      Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (version.items.isEmpty) Text(l10n.trayNoItemsYet),
      for (final item in version.items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.build_outlined),
          title: Text(item.resolveName(const [], languageCode: Localizations.localeOf(context).languageCode)),
          subtitle: item.position != null ? Text(item.position!) : null,
        ),
      if (version.observations != null && version.observations!.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(l10n.sterilizationObservationsLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(version.observations!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ];
  }

  List<Widget> _instrumentContent(BuildContext context, AppLocalizations l10n, PublicInstrumentVersion version) {
    return [
      if (version.photoPath != null) ...[
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: PublicInstrumentService.instance.photoUrl(version.photoPath!),
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.publicInstrumentPhotoDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 16),
      ],
      if (version.category != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            children: [Chip(label: Text(version.category!.label(l10n)))],
          ),
        ),
      if (version.description != null && version.description!.isNotEmpty) ...[
        Text(version.description!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
      ],
      if (version.useText != null && version.useText!.isNotEmpty) ...[
        Text(l10n.customInstrumentUseLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(version.useText!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
      ],
      if (version.tip != null && version.tip!.isNotEmpty) ...[
        Text(l10n.customInstrumentTipLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(version.tip!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ];
  }
}

/// Fila de traduccions d'aquest contingut (schema_v50): xips per a cada
/// idioma ja publicat (tocar-ne un navega a aquella variant) i, si qui mira
/// és col·laborador actiu, un menú per proposar-ne una que encara no
/// existeixi -- mai generada a màquina, sempre un esborrany real que passa
/// pel mateix cicle de revisió que qualsevol altra proposta.
class _TranslationBar extends StatefulWidget {
  final PublicEntityKind entityKind;
  final String translationGroupId;
  final String sourceId;
  final String currentLocale;

  const _TranslationBar({
    required this.entityKind,
    required this.translationGroupId,
    required this.sourceId,
    required this.currentLocale,
  });

  @override
  State<_TranslationBar> createState() => _TranslationBarState();
}

class _TranslationBarState extends State<_TranslationBar> {
  static const _locales = ['ca', 'es', 'en'];

  bool _loading = true;
  Map<String, dynamic> _byLocale = {};
  bool _proposing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<dynamic> siblings;
      if (widget.entityKind.isTray) {
        siblings = await PublicTrayService.instance.fetchTranslations(widget.translationGroupId);
      } else if (widget.entityKind.isInstrument) {
        siblings = await PublicInstrumentService.instance.fetchTranslations(widget.translationGroupId);
      } else {
        siblings = await PublicDocumentService.instance.fetchTranslations(widget.translationGroupId);
      }
      _byLocale = {
        for (final s in siblings) (s.locale as String): s,
      };
    } catch (_) {
      // Barra auxiliar: si falla, simplement no es mostren xips, no bloqueja la fitxa.
    }
    if (mounted) setState(() => _loading = false);
  }


  void _openSibling(dynamic entity) {
    final Widget screen;
    if (widget.entityKind.isTray) {
      screen = PublicEntityDetailScreen.tray(tray: entity as PublicTray);
    } else if (widget.entityKind.isInstrument) {
      screen = PublicEntityDetailScreen.instrument(instrument: entity as PublicInstrument);
    } else {
      screen = PublicEntityDetailScreen.document(document: entity as PublicDocument);
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _proposeTranslation(String locale) async {
    setState(() => _proposing = true);
    try {
      if (widget.entityKind.isTray) {
        final newId = await PublicTrayService.instance.proposeTranslation(widget.sourceId, locale);
        final draft = await PublicTrayService.instance.fetchDraftVersion(newId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicEntityFormScreen.tray(trayId: newId, draft: draft),
        ));
      } else if (widget.entityKind.isInstrument) {
        final newId = await PublicInstrumentService.instance.proposeTranslation(widget.sourceId, locale);
        final draft = await PublicInstrumentService.instance.fetchDraftVersion(newId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicEntityFormScreen.instrument(instrumentId: newId, draft: draft),
        ));
      } else {
        final newId = await PublicDocumentService.instance.proposeTranslation(widget.sourceId, locale);
        final draft = await PublicDocumentService.instance.fetchDraftVersion(newId);
        if (!mounted) return;
        final kind = widget.entityKind == PublicEntityKind.protocol ? DocumentKind.protocol : DocumentKind.technique;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicEntityFormScreen.document(kind: kind, documentId: newId, draft: draft),
        ));
      }
      if (mounted) setState(() => _proposing = false);
    } catch (e) {
      if (mounted) {
        setState(() => _proposing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translationProposeError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox.shrink();
    final canContribute = ContributorService.instance.myProfile != null;
    final missing = _locales.where((l) => !_byLocale.containsKey(l)).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final locale in _locales)
          if (_byLocale.containsKey(locale))
            ChoiceChip(
              label: Text(publicContentLocaleLabel(l10n, locale)),
              selected: locale == widget.currentLocale,
              onSelected: locale == widget.currentLocale ? null : (_) => _openSibling(_byLocale[locale]),
            ),
        if (canContribute && missing.isNotEmpty)
          _proposing
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : PopupMenuButton<String>(
                  onSelected: _proposeTranslation,
                  itemBuilder: (context) => [
                    for (final locale in missing)
                      PopupMenuItem(value: locale, child: Text(publicContentLocaleLabel(l10n, locale))),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.translate, size: 18),
                    label: Text(l10n.proposeTranslationAction),
                  ),
                ),
      ],
    );
  }
}

/// Su propio widget con estado (en vez de convertir toda la pantalla, que es
/// [StatelessWidget]) solo para no perder esa simplicidad por un único botón
/// que necesita su propio spinner de carga.
class _AdoptTrayButton extends StatefulWidget {
  final PublicTray tray;

  const _AdoptTrayButton({required this.tray});

  @override
  State<_AdoptTrayButton> createState() => _AdoptTrayButtonState();
}

class _AdoptTrayButtonState extends State<_AdoptTrayButton> {
  bool _loading = false;

  /// Igual que `_openWorkspaceCollection` en `home_screen.dart`: si solo hay
  /// un espacio, se salta el selector; si hay varios, se elige con una hoja
  /// simple (no hace falta la pantalla completa de `WorkspaceListScreen`,
  /// pensada para navegar contenido, no para elegir-y-volver).
  Future<String?> _pickWorkspaceId(AppLocalizations l10n) async {
    await WorkspaceService.instance.fetchWorkspaces();
    final workspaces = WorkspaceService.instance.workspaces;
    if (workspaces.isEmpty) return null;
    if (workspaces.length == 1) return workspaces.first.id;
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.workspaceLabel, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final w in workspaces) ListTile(title: Text(w.name), onTap: () => Navigator.pop(ctx, w.id)),
          ],
        ),
      ),
    );
  }

  Future<void> _adopt() async {
    final l10n = AppLocalizations.of(context)!;
    if (!ProfileService.instance.hasHospital) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adoptNoWorkspaceError)));
      return;
    }
    final workspaceId = await _pickWorkspaceId(l10n);
    if (workspaceId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final draft = await TrayService.instance.adoptPublicTray(publicTrayId: widget.tray.id, workspaceId: workspaceId);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TrayFormScreen(workspaceId: workspaceId, existingDraft: draft)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (AuthService.instance.currentUser == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _adopt,
        icon: _loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined),
        label: Text(l10n.adoptTrayAction),
      ),
    );
  }
}
