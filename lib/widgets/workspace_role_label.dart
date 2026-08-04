import '../l10n/app_localizations.dart';
import '../models/workspace_role.dart';

/// Mismo criterio que `sterilizationMethodValueLabel`/`WorkModePicker.labelFor`:
/// la etiqueta vive fuera del modelo (necesita `AppLocalizations`, que un
/// getter de modelo no puede resolver) — sustituye al antiguo
/// `WorkspaceRoleLabel.label` (hardcodeado en castellano).
String workspaceRoleLabel(AppLocalizations l10n, WorkspaceRole role) {
  switch (role) {
    case WorkspaceRole.reader:
      return l10n.workspaceRoleReaderLabel;
    case WorkspaceRole.editor:
      return l10n.workspaceRoleEditorLabel;
    case WorkspaceRole.approver:
      return l10n.workspaceRoleApproverLabel;
    case WorkspaceRole.administrator:
      return l10n.workspaceRoleAdministratorLabel;
  }
}
