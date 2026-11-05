import 'package:flutter/material.dart';

import '../data/sterilization_reference_data.dart';
import '../l10n/app_localizations.dart';
import '../widgets/sterilization_method_label.dart';
import 'sterilization_reference_detail_screen.dart';

/// Llistat del catàleg de referència "Esterilització i reprocessat".
/// Deliberadament sense cerca ni chips de filtre (a diferència de
/// `DrugCatalogScreen`): són només 6 entrades fixes, una per cada valor de
/// `SterilizationMethod`, no calen.
class SterilizationReferenceCatalogScreen extends StatelessWidget {
  const SterilizationReferenceCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sterilizationReferenceCatalogTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kSterilizationMethodReferences.length,
        itemBuilder: (context, index) {
          final reference = kSterilizationMethodReferences[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: Text(sterilizationMethodValueLabel(l10n, reference.method)),
              subtitle: reference.aliases.isEmpty ? null : Text(reference.aliases.join(', ')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SterilizationReferenceDetailScreen(reference: reference)),
              ),
            ),
          );
        },
      ),
    );
  }
}
