import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../services/reminder_service.dart';
import '../widgets/category_icon.dart';

/// Sesión de repaso de un único instrumento, lanzada contextualmente desde su
/// propia ficha (EPIC 8 · Contextual Learning) — no un quiz de opción
/// múltiple ni una lista de tarjetas: mostrar la ficha → "¿lo sabías?" →
/// [ProgressService.recordReviewResult] reprograma la caja Leitner y cierra.
/// Visualmente calcado de `flashcards_screen.dart` (tarjeta que se voltea),
/// deliberadamente sin reutilizar ese widget: es un flujo distinto (una sola
/// tarjeta, sin navegación entre instrumentos).
class ReviewSessionScreen extends StatefulWidget {
  final Instrument instrument;

  const ReviewSessionScreen({super.key, required this.instrument});

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  bool _showBack = false;
  bool _saving = false;

  Future<void> _answer(bool correct) async {
    setState(() => _saving = true);
    await ProgressService.instance.recordReviewResult(widget.instrument.id, correct);
    await ReminderService.instance.refresh();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final instrument = widget.instrument;
    final box = ProgressService.instance.boxFor(instrument.id);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewSessionTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(l10n.reviewSessionBoxLabel(box), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _showBack
                              ? _ReviewCardBack(key: const ValueKey('back'), instrument: instrument)
                              : _ReviewCardFront(key: const ValueKey('front'), instrument: instrument),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showBack ? l10n.tapToSeeName : l10n.tapCardToSeeDetail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(l10n.reviewSessionPrompt, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _answer(false),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.reviewSessionNo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _answer(true),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.reviewSessionYes),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCardFront extends StatelessWidget {
  final Instrument instrument;

  const _ReviewCardFront({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 100),
        const SizedBox(height: 20),
        Text(
          instrument.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _ReviewCardBack extends StatelessWidget {
  final Instrument instrument;

  const _ReviewCardBack({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.description.forLanguageCode(languageCode)),
          const SizedBox(height: 12),
          Text(l10n.useLabel, style: Theme.of(context).textTheme.labelLarge),
          Text(instrument.use.forLanguageCode(languageCode)),
        ],
      ),
    );
  }
}
