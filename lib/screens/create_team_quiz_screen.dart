import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/team_quiz_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';

/// Formulario de creación de un cuestionario de equipo (ver
/// supabase/schema_v60_team_quizzes.sql) -- título + lista de instrumentos
/// de catálogo, añadidos de uno en uno con [CatalogPickerSheet] (mismo
/// patrón ya usado en group_document_form_screen.dart para instrumental
/// relacionado, reutilizado tal cual).
class CreateTeamQuizScreen extends StatefulWidget {
  final String teamId;

  const CreateTeamQuizScreen({super.key, required this.teamId});

  @override
  State<CreateTeamQuizScreen> createState() => _CreateTeamQuizScreenState();
}

class _CreateTeamQuizScreenState extends State<CreateTeamQuizScreen> {
  final _titleController = TextEditingController();
  final List<String> _instrumentIds = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Instrument? _instrumentById(String id) {
    for (final i in kInstruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _addInstrument() async {
    final selected = await showModalBottomSheet<Instrument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CatalogPickerSheet(),
    );
    if (selected != null && !_instrumentIds.contains(selected.id)) {
      setState(() => _instrumentIds.add(selected.id));
    }
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty && _instrumentIds.isNotEmpty && !_saving;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await TeamQuizService.instance.create(widget.teamId, _titleController.text.trim(), _instrumentIds);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTeamQuizTitle),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveAction),
          ),
        ],
      ),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.teamQuizTitleLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              Text(l10n.teamQuizInstrumentsLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_instrumentIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.teamQuizNoInstrumentsYet),
                ),
              ..._instrumentIds.map((id) {
                final instrument = _instrumentById(id);
                return ListTile(
                  leading: instrument != null
                      ? InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 32)
                      : const Icon(Icons.help_outline),
                  title: Text(instrument?.name.forLanguageCode(languageCode) ?? id),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _instrumentIds.remove(id)),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addInstrument,
                icon: const Icon(Icons.add),
                label: Text(l10n.addAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
