import 'package:flutter_test/flutter_test.dart';

import 'package:instriq/models/workspace_role.dart';

/// Matriz completa canEdit/canApprove/isAdministrator por rol -- las tres
/// son expresiones booleanas escritas a mano, no derivadas unas de otras,
/// así que un futuro cambio que olvide listar `administrator` en una de las
/// tres cadenas de OR rompería en silencio el acceso de edición/aprobación
/// para admins (o al revés) sin ningún error de compilación (hallazgo de
/// auditoría de cara a la v1.0).
void main() {
  test('WorkspaceRole.canEdit/canApprove/isAdministrator matrix', () {
    final expected = <WorkspaceRole, (bool canEdit, bool canApprove, bool isAdministrator)>{
      WorkspaceRole.reader: (false, false, false),
      WorkspaceRole.editor: (true, false, false),
      WorkspaceRole.approver: (true, true, false),
      WorkspaceRole.administrator: (true, true, true),
    };

    for (final role in WorkspaceRole.values) {
      final (expectedEdit, expectedApprove, expectedAdmin) = expected[role]!;
      expect(role.canEdit, expectedEdit, reason: '$role.canEdit');
      expect(role.canApprove, expectedApprove, reason: '$role.canApprove');
      expect(role.isAdministrator, expectedAdmin, reason: '$role.isAdministrator');
    }
  });

  test('WorkspaceRole.fromDb round-trips every dbValue', () {
    for (final role in WorkspaceRole.values) {
      expect(WorkspaceRoleLabel.fromDb(role.dbValue), role);
    }
  });

  test('WorkspaceRole.fromDb returns null for unknown/null input', () {
    expect(WorkspaceRoleLabel.fromDb(null), isNull);
    expect(WorkspaceRoleLabel.fromDb('not_a_role'), isNull);
  });
}
