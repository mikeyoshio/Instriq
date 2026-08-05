import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_entity_usage_list.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/manufacturer.dart';
import '../services/sterilization_service.dart';
import '../utils/ref_resolver.dart';

/// Ficha mínima de un fabricante: solo navegación inversa (qué instrumentos
/// lo referencian en su ficha técnica), sin edición — se llega aquí tocando
/// el chip de fabricante en [InstrumentDetailScreen], nunca desde un menú
/// propio.
class ManufacturerDetailScreen extends StatelessWidget {
  final Manufacturer manufacturer;

  const ManufacturerDetailScreen({super.key, required this.manufacturer});

  Future<List<ResolvedRef>> _load() async {
    final infos =
        await SterilizationService.instance.fetchTechnicalInfoForManufacturer(manufacturer.id);
    final resolved = <ResolvedRef>[];
    for (final info in infos) {
      final ref = await resolveRef(info.instrumentRefType, info.instrumentRefId);
      if (ref != null) resolved.add(ref);
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final website = manufacturer.website;
    return Scaffold(
      appBar: AppBar(title: Text(manufacturer.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (website != null && website.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InstriqSpacing.lg,
                InstriqSpacing.lg,
                InstriqSpacing.lg,
                0,
              ),
              child: InkWell(
                onTap: () => launchUrl(Uri.parse(website)),
                child: Text(
                  website,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InstriqSpacing.lg,
              InstriqSpacing.lg,
              InstriqSpacing.lg,
              0,
            ),
            child: Text(l10n.usedInSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: InstriqAsyncView<List<ResolvedRef>>(
              load: _load,
              errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
              retryLabel: l10n.retry,
              isEmpty: (data) => data.isEmpty,
              emptyBuilder: (context) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(InstriqSpacing.xl),
                  child: Text(l10n.usedInEmptyState, textAlign: TextAlign.center),
                ),
              ),
              builder: (context, usedIn) => InstriqEntityUsageList(
                sections: [
                  EntityUsageSection(
                    label: null,
                    rows: usedIn
                        .map((ref) => EntityUsageRow(
                              icon: Icons.precision_manufacturing_outlined,
                              title: ref.title,
                              onTap: () => navigateToResolvedRef(context, ref),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
