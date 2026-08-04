import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'auth/hospital_connect_flow.dart';
import 'public_library_screen.dart';
import 'workspace_list_screen.dart';

/// Índice a las colecciones del grupo: bandejas, documentos/protocolos,
/// fichas de preferencia e instrumental personalizado viven todas dentro de
/// un espacio de trabajo (ver `WorkspaceDetailScreen`), así que cada entrada
/// aquí enlaza con [WorkspaceListScreen] — no existe hoy un atajo directo a
/// "todas las técnicas" sin pasar antes por elegir el espacio.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool get _isConnected =>
      AuthService.instance.currentUser != null && ProfileService.instance.hasHospital;

  Future<void> _openWorkspaces() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
    );
    setState(() {});
  }

  Future<void> _openHospitalConnectFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HospitalConnectFlow()),
    );
    setState(() {});
  }

  Future<void> _openPublicLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PublicLibraryScreen()),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLibrary)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Biblioteca Pública (EPIC 9): sempre visible, no exigeix
              // hospital connectat -- és contingut de comunitat, ortogonal
              // al model d'organitzacions (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md).
              InstriqSectionHeader(l10n.publicLibraryTitle),
              const SizedBox(height: InstriqSpacing.md),
              InstriqListItem(
                icon: Icons.public,
                title: l10n.publicLibraryTitle,
                onTap: _openPublicLibrary,
              ),
              const SizedBox(height: InstriqSpacing.xl),
              ..._isConnected
                ? [
                    InstriqSectionHeader(l10n.libraryCollectionsHeader),
                    const SizedBox(height: InstriqSpacing.md),
                    InstriqListItem(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.traysTitle,
                      subtitle: l10n.traysSubtitle,
                      onTap: _openWorkspaces,
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.menu_book_outlined,
                      title: l10n.libraryDocumentsTitle,
                      subtitle: l10n.libraryDocumentsSubtitle,
                      onTap: _openWorkspaces,
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.assignment_ind_outlined,
                      title: l10n.preferenceCardsTitle,
                      subtitle: l10n.preferenceCardsSubtitle,
                      onTap: _openWorkspaces,
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.precision_manufacturing_outlined,
                      title: l10n.customInstrumentsTitle,
                      subtitle: l10n.customInstrumentsSubtitle,
                      onTap: _openWorkspaces,
                    ),
                    const SizedBox(height: InstriqSpacing.xl),
                    InstriqSectionHeader(l10n.myGroup),
                    const SizedBox(height: InstriqSpacing.md),
                    InstriqListItem(
                      icon: Icons.workspaces_outlined,
                      title: l10n.spacesTitle,
                      subtitle: ProfileService.instance.organizationName ?? l10n.spacesSubtitleDefault,
                      onTap: _openWorkspaces,
                    ),
                  ]
                : [
                    InstriqListItem(
                      icon: Icons.groups_outlined,
                      title: l10n.connectGroupTitle,
                      subtitle: l10n.connectGroupSubtitle,
                      onTap: _openHospitalConnectFlow,
                    ),
                  ],
            ],
          ),
        ),
      ),
    );
  }
}
