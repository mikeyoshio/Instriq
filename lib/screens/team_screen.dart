import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../navigation/profile_button.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/workspace_resolver.dart';
import 'auth/hospital_connect_flow.dart';
import 'custom_instruments_screen.dart';
import 'group_document_list_screen.dart';
import 'group_network_screen.dart';
import 'preference_cards_screen.dart';
import 'procedures_screen.dart';
import 'public_library_screen.dart';
import 'surgical_agenda_screen.dart';
import 'team_progress_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Pestanya "El meu equip" (2.0, abans "Biblioteca"): a dalt, la Biblioteca
/// Pública (contingut de la comunitat que qualsevol equip pot adoptar, i
/// que dona contingut a qui encara no té grup); a sota, tot el contingut del
/// grup. Cada col·lecció viu dins d'un espai de treball: es resol a quin
/// espai anar (qualsevol rol basta per veure-la) i s'hi navega directe.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool get _isConnected => AuthService.instance.currentUser != null && ProfileService.instance.hasHospital;

  @override
  void initState() {
    super.initState();
    // Aquesta pantalla viu a la seva pròpia branca del shell: tancar sessió
    // des de Perfil no la reconstrueix sense aquest listener.
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

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _openCollection(Widget Function(ResolvedWorkspace) buildScreen) async {
    final l10n = AppLocalizations.of(context)!;
    final resolved = await resolveWorkspace(
      context,
      isEligible: (role) => true,
      noWorkspaceMessage: l10n.libraryNoWorkspaceAccess,
      chooseWorkspaceTitle: l10n.createContentChooseWorkspace,
    );
    if (resolved == null || !mounted) return;
    await _push(buildScreen(resolved));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ProfileService.instance;

    Widget item(IconData icon, String title, String? subtitle, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
          child: InstriqListItem(icon: icon, title: title, subtitle: subtitle, onTap: onTap),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTeam), actions: const [ProfileButton()]),
      body: SafeArea(
        child: InstriqResponsiveContent(
          // ListView (no SingleChildScrollView): dins el Center de
          // InstriqResponsiveContent, un contingut curt quedava centrat en
          // vertical amb un buit gran a dalt.
          child: ListView(
              padding: const EdgeInsets.all(InstriqSpacing.xl),
              children: [
                // Biblioteca Pública (EPIC 9): sempre visible, també sense
                // grup -- contingut de comunitat, ortogonal a les
                // organitzacions (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md).
                InstriqSectionHeader(l10n.publicLibraryTitle),
                const SizedBox(height: InstriqSpacing.md),
                item(Icons.public, l10n.publicLibraryTitle, null, () => _push(const PublicLibraryScreen())),
                const SizedBox(height: InstriqSpacing.lg),
                if (_isConnected) ...[
                  InstriqSectionHeader(l10n.libraryCollectionsHeader),
                  const SizedBox(height: InstriqSpacing.md),
                  item(Icons.medical_services_outlined, l10n.proceduresTitle, l10n.proceduresSubtitle,
                      () => _openCollection((r) => ProceduresScreen(workspace: r.workspace, myRole: r.role))),
                  item(Icons.event_available_outlined, l10n.surgicalAgendaTitle, l10n.surgicalAgendaSubtitle,
                      () => _openCollection((r) => SurgicalAgendaScreen(workspace: r.workspace, myRole: r.role))),
                  item(Icons.inventory_2_outlined, l10n.traysTitle, l10n.traysSubtitle,
                      () => _openCollection((r) => TraysScreen(workspace: r.workspace, myRole: r.role))),
                  item(
                      Icons.menu_book_outlined,
                      l10n.techniquesTitle,
                      l10n.techniquesSubtitle,
                      () => _openCollection((r) => GroupDocumentListScreen(
                          kind: DocumentKind.technique, workspace: r.workspace, myRole: r.role))),
                  item(
                      Icons.fact_check_outlined,
                      l10n.protocolsTitle,
                      l10n.protocolsSubtitle,
                      () => _openCollection((r) => GroupDocumentListScreen(
                          kind: DocumentKind.protocol, workspace: r.workspace, myRole: r.role))),
                  item(Icons.assignment_ind_outlined, l10n.preferenceCardsTitle, l10n.preferenceCardsSubtitle,
                      () => _openCollection((r) => PreferenceCardsScreen(workspace: r.workspace, myRole: r.role))),
                  item(
                      Icons.precision_manufacturing_outlined,
                      l10n.customInstrumentsTitle,
                      l10n.customInstrumentsSubtitle,
                      () => _openCollection(
                          (r) => CustomInstrumentsScreen(workspaceId: r.workspace.id, myRole: r.role))),
                  const SizedBox(height: InstriqSpacing.lg),
                  InstriqSectionHeader(l10n.myGroup),
                  const SizedBox(height: InstriqSpacing.md),
                  item(Icons.workspaces_outlined, l10n.spacesTitle,
                      profile.organizationName ?? l10n.spacesSubtitleDefault, () => _push(const WorkspaceListScreen())),
                  if (profile.hasGroup)
                    item(Icons.hub_outlined, l10n.groupNetworkTitle, l10n.groupNetworkSubtitle,
                        () => _push(const GroupNetworkScreen())),
                  if (profile.isAdmin || profile.canApproveAnyWorkspace)
                    item(Icons.groups_outlined, l10n.homeTeamProgressTitle, null,
                        () => _push(const TeamProgressScreen())),
                ] else
                  item(Icons.groups_outlined, l10n.connectGroupTitle, l10n.connectGroupSubtitle,
                      () => _push(const HospitalConnectFlow())),
              ],
          ),
        ),
      ),
    );
  }
}
