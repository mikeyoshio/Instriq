import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contributor_application.dart';
import '../services/contributor_service.dart';

/// Cola de revisió de candidatures de col·laborador, visible nomes per
/// l'Editorial Board (`ContributorService.instance.isEditorialBoard`).
/// Cap candidatura s'aprova automàticament (docs/EPIC_COMMUNITY_GOVERNANCE.md §1).
class ContributorReviewQueueScreen extends StatefulWidget {
  const ContributorReviewQueueScreen({super.key});

  @override
  State<ContributorReviewQueueScreen> createState() => _ContributorReviewQueueScreenState();
}

class _ContributorReviewQueueScreenState extends State<ContributorReviewQueueScreen> {
  bool _loading = true;
  String? _error;
  List<ContributorApplication> _queue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _queue = await ContributorService.instance.fetchPendingApplications();
    } catch (e) {
      _error = l10n.reviewQueueLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(ContributorApplication application) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ContributorService.instance.reviewApplication(application.id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contributorApplicationApprovedSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.approveError(e.toString()))));
      }
    }
  }

  Future<void> _reject(ContributorApplication application) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectChangeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.rejectReasonLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.reject)),
        ],
      ),
    );
    if (notes == null) return;
    try {
      await ContributorService.instance.reviewApplication(application.id, false, notes: notes.isEmpty ? null : notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contributorApplicationRejectedSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rejectError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributorReviewQueueTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _queue.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPendingReviews)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _queue.length,
                      itemBuilder: (context, index) {
                        final application = _queue[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(application.fullName, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(application.email, style: Theme.of(context).textTheme.labelMedium),
                                if (application.professionalRole != null) ...[
                                  const SizedBox(height: 4),
                                  Text(application.professionalRole!, style: Theme.of(context).textTheme.bodySmall),
                                ],
                                const SizedBox(height: 8),
                                Text(application.motivationLetter, style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Spacer(),
                                    TextButton(onPressed: () => _reject(application), child: Text(l10n.reject)),
                                    const SizedBox(width: 8),
                                    FilledButton(onPressed: () => _approve(application), child: Text(l10n.approve)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
