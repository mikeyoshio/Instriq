import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/manufacturer.dart';
import '../services/sterilization_service.dart';
import '../utils/ref_resolver.dart';

/// Ficha mínima de un fabricante: solo navegación inversa (qué instrumentos
/// lo referencian en su ficha técnica), sin edición — se llega aquí tocando
/// el chip de fabricante en [InstrumentDetailScreen], nunca desde un menú
/// propio.
class ManufacturerDetailScreen extends StatefulWidget {
  final Manufacturer manufacturer;

  const ManufacturerDetailScreen({super.key, required this.manufacturer});

  @override
  State<ManufacturerDetailScreen> createState() => _ManufacturerDetailScreenState();
}

class _ManufacturerDetailScreenState extends State<ManufacturerDetailScreen> {
  bool _loading = true;
  List<ResolvedRef> _usedIn = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final infos =
          await SterilizationService.instance.fetchTechnicalInfoForManufacturer(widget.manufacturer.id);
      final resolved = <ResolvedRef>[];
      for (final info in infos) {
        final ref = await resolveRef(info.instrumentRefType, info.instrumentRefId);
        if (ref != null) resolved.add(ref);
      }
      if (!mounted) return;
      setState(() {
        _usedIn = resolved;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final website = widget.manufacturer.website;
    return Scaffold(
      appBar: AppBar(title: Text(widget.manufacturer.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (website != null && website.isNotEmpty) ...[
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(website)),
                    child: Text(
                      website,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(l10n.usedInSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_usedIn.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.usedInEmptyState),
                  )
                else
                  ..._usedIn.map((ref) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.precision_manufacturing_outlined),
                          title: Text(ref.title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => navigateToResolvedRef(context, ref),
                        ),
                      )),
              ],
            ),
    );
  }
}
