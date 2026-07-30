import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/specialty_entity.dart';
import '../models/tag.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/tag_service.dart';
import 'custom_instrument_form_screen.dart';
import 'specialty_detail_screen.dart';
import 'tag_detail_screen.dart';

/// Vista de lectura de un instrumento personalizado: sus variantes con foto
/// (vía signed URL, el bucket es privado) y el disclaimer de licencia
/// SIEMPRE visible junto a cada foto — nunca opcional ni escondido.
class CustomInstrumentDetailScreen extends StatefulWidget {
  final CustomInstrument instrument;
  final WorkspaceRole? myRole;

  const CustomInstrumentDetailScreen({super.key, required this.instrument, required this.myRole});

  @override
  State<CustomInstrumentDetailScreen> createState() => _CustomInstrumentDetailScreenState();
}

class _CustomInstrumentDetailScreenState extends State<CustomInstrumentDetailScreen> {
  static const String _refType = 'custom';

  late CustomInstrument _instrument;
  final Map<String, String> _photoUrls = {};
  bool _loadingPhotos = true;
  bool _isFavorite = false;
  SpecialtyEntity? _specialty;
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _instrument = widget.instrument;
    _loadPhotos();
    _loadSpecialty();
    _loadTags();
    if (AuthService.instance.currentUser != null) {
      RecentActivityService.instance.recordView(_refType, _instrument.id);
      _loadFavoriteState();
    }
  }

  Future<void> _loadSpecialty() async {
    final specialtyId = _instrument.specialtyId;
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
      final tags = await TagService.instance.fetchTagsFor(_refType, _instrument.id);
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (_) {
      // Sin bloquear la ficha si falla: las etiquetas son metadato accesorio.
    }
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.instance.isFavorite(_refType, _instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(_refType, _instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _loadPhotos() async {
    for (final variant in _instrument.variants) {
      final path = variant.photoPath;
      if (path == null) continue;
      try {
        _photoUrls[variant.id] = await CustomInstrumentService.instance.getVariantPhotoUrl(path);
      } catch (_) {
        // Sin foto disponible (p.ej. sin conexión) — se muestra sin imagen.
      }
    }
    if (mounted) setState(() => _loadingPhotos = false);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCustomInstrumentTitle),
        content: Text(l10n.deleteCustomInstrumentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    await CustomInstrumentService.instance.delete(_instrument.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = widget.myRole?.canEdit ?? false;
    final canDelete = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_instrument.name),
        actions: [
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
              tooltip: l10n.favoriteToggleTooltip,
              onPressed: _toggleFavorite,
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CustomInstrumentFormScreen(
                      workspaceId: _instrument.workspaceId,
                      existingInstrument: _instrument,
                    ),
                  ),
                );
                if (saved == true) {
                  final refreshed = CustomInstrumentService.instance.byId(_instrument.id);
                  if (refreshed != null && mounted) {
                    setState(() {
                      _instrument = refreshed;
                      _loadingPhotos = true;
                    });
                    _loadPhotos();
                    _loadSpecialty();
                  }
                }
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_instrument.category != null || _specialty != null || _instrument.specialty != null)
              Wrap(
                spacing: 8,
                children: [
                  if (_instrument.category != null) Chip(label: Text(_instrument.category!)),
                  if (_specialty != null)
                    InputChip(
                      label: Text(_specialty!.label),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SpecialtyDetailScreen(specialty: _specialty!)),
                      ),
                    )
                  else if (_instrument.specialty != null)
                    Chip(label: Text(_instrument.specialty!)),
                ],
              ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
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
            ],
            const SizedBox(height: 12),
            if (_instrument.description != null) ...[
              Text(_instrument.description!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (_instrument.useText != null) ...[
              Text(l10n.customInstrumentUseLabel, style: Theme.of(context).textTheme.titleSmall),
              Text(_instrument.useText!),
              const SizedBox(height: 12),
            ],
            if (_instrument.tip != null) ...[
              Text(l10n.customInstrumentTipLabel, style: Theme.of(context).textTheme.titleSmall),
              Text(_instrument.tip!),
              const SizedBox(height: 12),
            ],
            const Divider(height: 32),
            Text(l10n.customInstrumentVariantsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_instrument.variants.isEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text(l10n.noVariantsYet))
            else
              ..._instrument.variants.map((variant) => _VariantTile(
                    variant: variant,
                    photoUrl: _photoUrls[variant.id],
                    loading: _loadingPhotos,
                  )),
          ],
        ),
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final CustomInstrumentVariant variant;
  final String? photoUrl;
  final bool loading;

  const _VariantTile({required this.variant, required this.photoUrl, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = variant.photoPath != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: loading
                        ? const SizedBox(
                            width: 72,
                            height: 72,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (photoUrl != null
                            ? Image.network(
                                photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              )
                            : const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.image_not_supported_outlined),
                              )),
                  )
                else
                  const CircleAvatar(radius: 36, child: Icon(Icons.build_circle_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (variant.note != null) Text(variant.note!),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.customPhotoDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
