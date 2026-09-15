import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

/// Diálogo de selección de idioma (català/castellano/inglés), persistido en
/// el dispositivo vía [LocaleService]. Compartido entre `ProfileHubScreen`
/// (icono "Idioma") y `OnboardingScreen` (splash de bienvenida): mismo
/// diálogo exacto, evita duplicar las 3 opciones en dos sitios.
Future<void> pickLanguage(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final locale = await showDialog<Locale>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.languageDialogTitle),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, const Locale('ca')),
          child: Text(l10n.languageCatalan),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, const Locale('es')),
          child: Text(l10n.languageSpanish),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, const Locale('en')),
          child: Text(l10n.languageEnglish),
        ),
      ],
    ),
  );
  if (locale != null) await LocaleService.instance.setLocale(locale);
}
