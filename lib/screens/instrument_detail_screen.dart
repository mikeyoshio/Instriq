import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';

class InstrumentDetailScreen extends StatefulWidget {
  final Instrument instrument;

  const InstrumentDetailScreen({super.key, required this.instrument});

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final instrument = widget.instrument;
    final learned = ProgressService.instance.isLearned(instrument.id);

    return Scaffold(
      appBar: AppBar(title: Text(instrument.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: instrument.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        instrument.image!.url,
                        height: 200,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: InstrumentIcon(
                                iconKey: instrument.icon,
                                category: instrument.category,
                                size: 120,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => InstrumentIcon(
                          iconKey: instrument.icon,
                          category: instrument.category,
                          size: 120,
                        ),
                      ),
                    )
                  : InstrumentIcon(
                      iconKey: instrument.icon,
                      category: instrument.category,
                      size: 120,
                    ),
            ),
            if (instrument.image != null) ...[
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(instrument.image!.sourceUrl)),
                  child: Text(
                    'Foto: ${instrument.image!.attribution} · ${instrument.image!.license}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(decoration: TextDecoration.underline),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(instrument.specialty.label)),
                Chip(label: Text(instrument.category.label)),
              ],
            ),
            const SizedBox(height: 16),
            if (instrument.aliases.isNotEmpty) ...[
              Text('También conocido como', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(instrument.aliases.join(', ')),
              const SizedBox(height: 16),
            ],
            Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(instrument.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Uso principal', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(instrument.use, style: Theme.of(context).textTheme.bodyLarge),
            if (instrument.tip != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text(instrument.tip!)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(learned ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(learned ? 'Aprendido' : 'Marcar como aprendido'),
                onPressed: () async {
                  await ProgressService.instance.toggleLearned(instrument.id);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
