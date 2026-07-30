import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tag.dart';
import '../screens/tag_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/tag_service.dart';

/// Selector de etiquetas "autocompletar o crear" para una entidad concreta
/// (`ref_type`/`ref_id`), con las ya puestas como chips tocables.
///
/// No persiste nada por sí solo mientras se edita: el formulario que lo
/// embebe (`group_document_form_screen.dart`, `tray_form_screen.dart`, la
/// hoja de ficha técnica en `instrument_detail_screen.dart`) debe guardar
/// una [GlobalKey<TagPickerState>] y llamar a [TagPickerState.save] dentro
/// de su propio flujo de guardado — así el diff etiquetas añadidas/quitadas
/// se calcula una sola vez, junto con el resto del formulario, no en cada tap.
class TagPicker extends StatefulWidget {
  final String refType;
  final String refId;

  /// Null si lo etiquetado es global (instrumento de catálogo, fabricante,
  /// especialidad); el grupo actual si es privado (bandeja, documento...) —
  /// mismo criterio que [TagService.addTag].
  final String? organizationId;

  const TagPicker({super.key, required this.refType, required this.refId, this.organizationId});

  @override
  State<TagPicker> createState() => TagPickerState();
}

class TagPickerState extends State<TagPicker> {
  List<Tag> _tags = [];
  Set<String> _initialTagIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tags = await TagService.instance.fetchTagsFor(widget.refType, widget.refId);
      if (!mounted) return;
      setState(() {
        _tags = tags;
        _initialTagIds = tags.map((t) => t.id).toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Persiste el diff entre lo que había al cargar y lo que hay ahora en
  /// pantalla. Idempotente: puede llamarse aunque no haya cambios (no hace
  /// ninguna llamada de red en ese caso).
  Future<void> save() async {
    final currentIds = _tags.map((t) => t.id).toSet();
    final added = currentIds.difference(_initialTagIds);
    final removed = _initialTagIds.difference(currentIds);
    for (final tagId in added) {
      await TagService.instance.addTag(
        tagId: tagId,
        refType: widget.refType,
        refId: widget.refId,
        organizationId: widget.organizationId,
      );
    }
    for (final tagId in removed) {
      await TagService.instance.removeTag(tagId: tagId, refType: widget.refType, refId: widget.refId);
    }
    _initialTagIds = currentIds;
  }

  Future<void> _openAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    var options = <Tag>[];
    final selected = await showDialog<Tag>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addTagTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(hintText: l10n.tagNameHint),
                  onChanged: (value) async {
                    final results = await TagService.instance.searchByName(value);
                    setDialogState(() => options = results);
                  },
                ),
                const SizedBox(height: 8),
                for (final t in options)
                  ListTile(
                    dense: true,
                    title: Text(t.name),
                    onTap: () => Navigator.pop(ctx, t),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final tag = await TagService.instance.createOrGet(name);
                if (ctx.mounted) Navigator.pop(ctx, tag);
              },
              child: Text(l10n.addAction),
            ),
          ],
        ),
      ),
    );
    if (selected != null && !_tags.any((t) => t.id == selected.id)) {
      setState(() => _tags = [..._tags, selected]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    // Etiquetar exige sesión iniciada (RLS de `taggings` lo exige vía
    // created_by = auth.uid()) — invitados solo ven las que ya hay.
    final canEdit = AuthService.instance.currentUser != null;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final tag in _tags)
          InputChip(
            label: Text(tag.name),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TagDetailScreen(tag: tag)),
            ),
            onDeleted:
                canEdit ? () => setState(() => _tags = _tags.where((t) => t.id != tag.id).toList()) : null,
          ),
        if (canEdit)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l10n.addTagAction),
            onPressed: _openAddDialog,
          ),
      ],
    );
  }
}
