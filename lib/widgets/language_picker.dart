import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

/// Diálogo de selección de idioma (català/castellano/inglés), persistido en
/// el dispositivo vía [LocaleService]. Compartido entre `ProfileHubScreen`
/// (icono "Idioma") y `OnboardingScreen` (splash de bienvenida): mismo
/// diálogo exacto, evita duplicar las 3 opciones en dos sitios.
/// Cada idioma escrit en la seva pròpia llengua: qui no entén l'idioma
/// actual de l'app ha de poder trobar el seu.
const kLanguageEndonyms = {'ca': 'Català', 'es': 'Español', 'en': 'English'};

Future<void> pickLanguage(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final current = LocaleService.instance.locale.value.languageCode;
  final locale = await showDialog<Locale>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.languageDialogTitle),
      children: [
        for (final MapEntry(key: code, value: name) in kLanguageEndonyms.entries)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, Locale(code)),
            child: Row(
              children: [
                Expanded(child: Text(name)),
                if (code == current) Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary),
              ],
            ),
          ),
      ],
    ),
  );
  if (locale != null) await LocaleService.instance.setLocale(locale);
}
