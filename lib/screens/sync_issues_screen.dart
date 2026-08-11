import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/sync_queue_service.dart';

/// ADR-003 (`docs/ADR_003_OFFLINE_STRATEGY.md`, punto 4): panel de avisos
/// para las operaciones que `SyncQueueService` descartó de la cola offline
/// por un error de negocio (no de red) -- p. ej. alguien más ya aprobó o
/// rechazó el mismo borrador mientras estábamos sin conexión. Hasta ahora
/// esos `SyncFailure` se acumulaban en `SyncQueueService.instance.failures`
/// sin que nadie los viera; esta pantalla es esa vista.
class SyncIssuesScreen extends StatelessWidget {
  const SyncIssuesScreen({super.key});

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncIssuesTitle),
        actions: [
          ValueListenableBuilder<List<SyncFailure>>(
            valueListenable: SyncQueueService.instance.failures,
            builder: (context, failures, _) {
              if (failures.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: SyncQueueService.instance.clearAll,
                child: Text(l10n.syncIssuesClearAll),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<SyncFailure>>(
          valueListenable: SyncQueueService.instance.failures,
          builder: (context, failures, _) {
            if (failures.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.syncIssuesEmptyState,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: failures.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final failure = failures[index];
                return Card(
                  child: ExpansionTile(
                    leading: Icon(Icons.sync_problem, color: Theme.of(context).colorScheme.error),
                    title: Text(failure.description),
                    subtitle: Text(_formatTimestamp(failure.occurredAt)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.syncIssuesDismiss,
                      onPressed: () => SyncQueueService.instance.dismiss(failure),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            failure.error,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
