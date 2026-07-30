import 'package:flutter_test/flutter_test.dart';

import 'package:instriq/models/preference_card.dart';

void main() {
  test('PreferenceCardItem round-trips through JSON', () {
    const item = PreferenceCardItem(
      instrumentId: 'bisturi',
      customName: 'Bisturí',
      note: 'Hoja nº 15',
    );

    final restored = PreferenceCardItem.fromJson(item.toJson());

    expect(restored.instrumentId, item.instrumentId);
    expect(restored.customName, item.customName);
    expect(restored.note, item.note);
  });

  test('PreferenceCard toRow includes hospital scoping', () {
    const card = PreferenceCard(
      id: 'card-1',
      workspaceId: 'workspace-1',
      surgeonId: 'surgeon-1',
      procedureName: 'Colecistectomía',
      items: [PreferenceCardItem(customName: 'Trócar')],
    );

    final row = card.toRow(organizationId: 'hospital-1');

    expect(row['organization_id'], 'hospital-1');
    expect(row['workspace_id'], 'workspace-1');
    expect(row['surgeon_id'], 'surgeon-1');
    expect(row['validated'], false);
  });
}
