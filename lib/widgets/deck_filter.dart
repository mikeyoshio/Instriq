import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument.dart';

/// Filtre d'un mall d'estudi: per bloc funcional (categoria) o per
/// especialitat. Compartit per Flashcards i Qüestionari.
class DeckFilter {
  final InstrumentCategory? category;
  final Specialty? specialty;

  const DeckFilter({this.category, this.specialty});

  static const all = DeckFilter();

  bool get isAll => category == null && specialty == null;

  bool matches(Instrument i) =>
      (category == null || i.category == category) && (specialty == null || i.specialty == specialty);

  String label(AppLocalizations l10n) =>
      category?.label(l10n) ?? specialty?.label(l10n) ?? l10n.allSpecialtiesLabel;

  @override
  bool operator ==(Object other) => other is DeckFilter && other.category == category && other.specialty == specialty;

  @override
  int get hashCode => Object.hash(category, specialty);
}

class DeckFilterButton extends StatelessWidget {
  final DeckFilter value;
  final ValueChanged<DeckFilter> onChanged;

  const DeckFilterButton({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    PopupMenuItem<DeckFilter> header(String text) => PopupMenuItem<DeckFilter>(
          enabled: false,
          height: 32,
          child: Text(text.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.1)),
        );
    PopupMenuItem<DeckFilter> item(DeckFilter f) => CheckedPopupMenuItem<DeckFilter>(
          value: f,
          checked: f == value,
          child: Text(f.label(l10n)),
        );
    return PopupMenuButton<DeckFilter>(
      icon: Badge(isLabelVisible: !value.isAll, child: const Icon(Icons.filter_list)),
      tooltip: l10n.deckFilterTooltip,
      onSelected: onChanged,
      itemBuilder: (context) => [
        item(DeckFilter.all),
        header(l10n.deckByBlock),
        for (final c in InstrumentCategory.values) item(DeckFilter(category: c)),
        header(l10n.deckBySpecialty),
        for (final s in Specialty.values) item(DeckFilter(specialty: s)),
      ],
    );
  }
}
