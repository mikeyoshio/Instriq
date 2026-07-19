import 'package:flutter/material.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _members = await ProfileService.instance.fetchMembers();
    } catch (e) {
      _error = 'No se pudieron cargar los miembros: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _regenerateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerar código'),
        content: const Text(
          'El código actual dejará de funcionar. Tendrás que compartir el nuevo con quien aún no se haya unido.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerar')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _regenerating = true);
    try {
      await ProfileService.instance.regenerateInviteCode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _removeMember(HospitalMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar del hospital'),
        content: Text(
          '¿Quitar a ${member.displayName?.isNotEmpty == true ? member.displayName : 'esta persona'} del grupo? Perderá acceso al contenido compartido.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.removeMember(member.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar grupo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(profile.hospitalName ?? '', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código de invitación', style: Theme.of(context).textTheme.labelLarge),
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
                            label: const Text('Regenerar código'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Miembros (${_members.length})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  ..._members.map((m) {
                    final isMe = m.id == AuthService.instance.currentUser?.id;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          (m.displayName?.isNotEmpty == true ? m.displayName! : 'Sin nombre') +
                              (isMe ? ' (tú)' : ''),
                        ),
                        subtitle: m.isAdmin ? const Text('Administradora') : null,
                        trailing: isMe || m.isAdmin
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: () => _removeMember(m),
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
