import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/hospital.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class ManageHospitalScreen extends StatefulWidget {
  const ManageHospitalScreen({super.key});

  @override
  State<ManageHospitalScreen> createState() => _ManageHospitalScreenState();
}

class _ManageHospitalScreenState extends State<ManageHospitalScreen> {
  bool _loading = true;
  bool _regenerating = false;
  List<HospitalMember> _members = [];
  String? _error;

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
      _members = await ProfileService.instance.fetchMembers();
    } catch (e) {
      _error = l10n.manageMembersLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _regenerateCode() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regenerateCodeTitle),
        content: Text(l10n.regenerateCodeBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.regenerate)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _regenerating = true);
    try {
      await ProfileService.instance.regenerateInviteCode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _transferOwnership(HospitalMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transferOwnershipTitle),
        content: Text(
          l10n.transferOwnershipBody(
            member.displayName?.isNotEmpty == true ? member.displayName! : l10n.thisPerson,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.transfer)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.transferOwnership(member.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  Future<void> _removeMember(HospitalMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFromHospitalTitle),
        content: Text(
          l10n.removeMemberBody(
            member.displayName?.isNotEmpty == true ? member.displayName! : l10n.thisPerson,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.removeMember(member.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ProfileService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageGroupTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(profile.organizationName ?? '', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.inviteCodeLabel, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          SelectableText(
                            profile.inviteCode ?? '—',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _regenerating ? null : _regenerateCode,
                            icon: _regenerating
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh),
                            label: Text(l10n.regenerateCodeTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.membersCountTitle(_members.length), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  ..._members.map((m) {
                    final isMe = m.id == AuthService.instance.currentUser?.id;
                    final isOwner = m.id == profile.ownerId;
                    final canTransferTo = profile.isOwner && m.isAdmin && !isMe;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          isMe
                              ? l10n.memberNameWithYou(
                                  m.displayName?.isNotEmpty == true ? m.displayName! : l10n.noName)
                              : (m.displayName?.isNotEmpty == true ? m.displayName! : l10n.noName),
                        ),
                        subtitle: (isOwner || m.isAdmin)
                            ? Text([
                                if (isOwner) l10n.ownerLabel,
                                if (m.isAdmin) l10n.adminLabel,
                              ].join(' · '))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canTransferTo)
                              IconButton(
                                icon: const Icon(Icons.workspace_premium_outlined),
                                tooltip: l10n.transferOwnershipTitle,
                                onPressed: () => _transferOwnership(m),
                              ),
                            if (!isMe && !m.isAdmin)
                              IconButton(
                                icon: const Icon(Icons.person_remove_outlined),
                                tooltip: l10n.removeMemberTooltip,
                                onPressed: () => _removeMember(m),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
