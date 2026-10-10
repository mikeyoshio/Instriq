import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/workspace_resolver.dart';
import 'auth/hospital_connect_flow.dart';
import 'custom_instruments_screen.dart';
import 'group_document_list_screen.dart';
import 'preference_cards_screen.dart';
import 'public_library_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Índice a las colecciones del grupo: bandejas, técnicas, protocolos,
/// fichas de preferencia e instrumental personalizado viven todas dentro de
/// un espacio de trabajo (ver `WorkspaceDetailScreen`). Cada entrada aquí
/// resuelve directamente a qué espacio ir (mismo criterio que
/// `showCreateContentSheet`, salvo que aquí cualquier rol -- no solo
/// `canEdit` -- basta para ver la colección) y navega directo a esa
/// pantalla; antes las 4 entradas llamaban todas a `_openWorkspaces` sin
/// distinción, así que con un único espacio (el caso típico) tocar
/// cualquiera de ellas llevaba siempre al mismo índice genérico en vez de a
/// lo que el título prometía.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool get _isConnected =>
      AuthService.instance.currentUser != null && ProfileService.instance.hasHospital;

  @override
  void initState() {
    super.initState();
    // Misma razón que en home_screen.dart: esta pantalla vive en su propia
    // rama del shell, así que cerrar sesión desde Perfil no la reconstruye
    // por sí solo sin este listener.
    ProfileService.instance.profileRevision.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService.instance.profileRevision.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openWorkspaces() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
    );
    setState(() {});
  }

  /// Resuelve el espacio (cualquier rol basta para ver una colección, a
  /// diferencia de `showCreateContentSheet` que exige `canEdit`) y navega
  /// directo a la pantalla de esa colección, sin pasar por el índice
  /// genérico de `WorkspaceDetailScreen`.
  Future<void> _openCollection(Widget Function(ResolvedWorkspace) buildScreen) async {
    final l10n = AppLocalizations.of(context)!;
    final resolved = await resolveWorkspace(
      context,
      isEligible: (role) => true,
      noWorkspaceMessage: l10n.libraryNoWorkspaceAccess,
      chooseWorkspaceTitle: l10n.createContentChooseWorkspace,
    );
    if (resolved == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => buildScreen(resolved)));
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
        child: InstriqResponsiveContent(
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
                      onTap: () => _openCollection(
                        (r) => TraysScreen(workspace: r.workspace, myRole: r.role),
                      ),
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.menu_book_outlined,
                      title: l10n.techniquesTitle,
                      subtitle: l10n.techniquesSubtitle,
                      onTap: () => _openCollection(
                        (r) => GroupDocumentListScreen(
                          kind: DocumentKind.technique,
                          workspace: r.workspace,
                          myRole: r.role,
                        ),
                      ),
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.fact_check_outlined,
                      title: l10n.protocolsTitle,
                      subtitle: l10n.protocolsSubtitle,
                      onTap: () => _openCollection(
                        (r) => GroupDocumentListScreen(
                          kind: DocumentKind.protocol,
                          workspace: r.workspace,
                          myRole: r.role,
                        ),
                      ),
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.assignment_ind_outlined,
                      title: l10n.preferenceCardsTitle,
                      subtitle: l10n.preferenceCardsSubtitle,
                      onTap: () => _openCollection(
                        (r) => PreferenceCardsScreen(workspace: r.workspace, myRole: r.role),
                      ),
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.precision_manufacturing_outlined,
                      title: l10n.customInstrumentsTitle,
                      subtitle: l10n.customInstrumentsSubtitle,
                      onTap: () => _openCollection(
                        (r) => CustomInstrumentsScreen(workspaceId: r.workspace.id, myRole: r.role),
                      ),
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
      ),
    );
  }
}
