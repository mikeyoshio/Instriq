import '../l10n/app_localizations.dart';

/// Nom localitzat de l'idioma d'una peça de contingut de la Biblioteca
/// Pública (`locale` a `public_documents`/`public_trays`/
/// `public_instruments`, schema_v50) -- compartit entre la fitxa de detall
/// i els llistats perquè cap dels dos mostri el codi ISO cru (`ca`/`es`/
/// `en`) sense traduir.
String publicContentLocaleLabel(AppLocalizations l10n, String locale) => switch (locale) {
      'ca' => l10n.languageCatalan,
      'es' => l10n.languageSpanish,
      'en' => l10n.languageEnglish,
      _ => locale,
    };
