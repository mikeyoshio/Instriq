import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import 'category_icon.dart';

/// Fila d'instrument del catàleg: miniatura, nom, "Especialitat · Categoria".
/// La mateixa a Omnihub i al Catàleg, perquè un resultat es reconegui igual
/// on sigui.
class InstrumentListTile extends StatelessWidget {
  final Instrument instrument;
  final VoidCallback? onTap;

  /// Foto a mostrar; per defecte la verificada del catàleg.
  final String? thumbnailUrl;
  final List<Widget> titleBadges;
  final Widget? trailing;

  /// Substitueix "Especialitat · Categoria" (p. ex. la pista de «No confondre amb»).
  final String? subtitle;

  const InstrumentListTile({
    super.key,
    required this.instrument,
    this.onTap,
    this.thumbnailUrl,
    this.titleBadges = const [],
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final url = thumbnailUrl ?? instrument.image?.url;
    final fallback = InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 48);
    return InstriqListItem(
      leading: url == null
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheWidth: (48 * MediaQuery.of(context).devicePixelRatio).round(),
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
            ),
      title: instrument.name.forLanguageCode(languageCode),
      titleBadges: titleBadges,
      subtitle: subtitle ?? '${instrument.specialty.label(l10n)} · ${instrument.category.label(l10n)}',
      trailing: trailing,
      onTap: onTap,
    );
  }
}
