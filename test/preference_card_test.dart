import 'package:flutter_test/flutter_test.dart';

import 'package:instriq/models/group_document_version.dart';
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

  test('PreferenceCardVersion toRow includes the editable draft fields', () {
    const version = PreferenceCardVersion(
      id: 'version-1',
      cardId: 'card-1',
      versionNumber: 1,
      status: GroupDocumentVersionStatus.draft,
      surgeonId: 'surgeon-1',
      procedureName: 'Colecistectomía',
      items: [PreferenceCardItem(customName: 'Trócar')],
    );

    final row = version.toRow();

    expect(row['surgeon_id'], 'surgeon-1');
    expect(row['procedure_name'], 'Colecistectomía');
    expect(row['validated_by_surgeon'], false);
    // La cabecera (organization_id/workspace_id) ya no vive en la versión:
    // solo los campos que el formulario de borrador puede editar.
    expect(row.containsKey('organization_id'), false);
    expect(row.containsKey('workspace_id'), false);
  });

  test('PreferenceCard.fromRow resolves the nested published version', () {
    final row = {
      'id': 'card-1',
      'organization_id': 'hospital-1',
      'workspace_id': 'workspace-1',
      'created_by': 'user-1',
      'created_at': '2024-01-01T00:00:00Z',
      'published_version_id': 'version-1',
      'published_version': {
        'id': 'version-1',
        'card_id': 'card-1',
        'version_number': 1,
        'status': 'published',
        'surgeon_id': 'surgeon-1',
        'procedure_name': 'Colecistectomía',
        'items': [],
        'validated_by_surgeon': true,
      },
    };

    final card = PreferenceCard.fromRow(row);

    expect(card.workspaceId, 'workspace-1');
    expect(card.publishedVersion?.procedureName, 'Colecistectomía');
    expect(card.publishedVersion?.validatedBySurgeon, true);
    expect(card.publishedVersion?.status, GroupDocumentVersionStatus.published);
  });

  group('PreferenceCardVersion.copyWith validatedBySurgeon contract', () {
    const validated = PreferenceCardVersion(
      id: 'version-1',
      cardId: 'card-1',
      versionNumber: 1,
      status: GroupDocumentVersionStatus.published,
      procedureName: 'Colecistectomía',
      items: [PreferenceCardItem(customName: 'Trócar')],
      validatedBySurgeon: true,
    );

    test('editing items resets validatedBySurgeon to false', () {
      final edited = validated.copyWith(items: [const PreferenceCardItem(customName: 'Bisturí')]);
      expect(edited.validatedBySurgeon, false);
    });

    test('editing procedureName resets validatedBySurgeon to false', () {
      final edited = validated.copyWith(procedureName: 'Apendicectomía');
      expect(edited.validatedBySurgeon, false);
    });

    test('an explicit validatedBySurgeon passed alongside edited content is honored', () {
      final edited = validated.copyWith(
        items: [const PreferenceCardItem(customName: 'Bisturí')],
        validatedBySurgeon: true,
      );
      expect(edited.validatedBySurgeon, true);
    });

    test('editing unrelated fields (notes/comment) preserves validatedBySurgeon', () {
      final edited = validated.copyWith(generalNotes: 'Nota nueva');
      expect(edited.validatedBySurgeon, true);
    });

    test('toggling validatedBySurgeon alone (no content change) works as before', () {
      final toggled = validated.copyWith(validatedBySurgeon: false);
      expect(toggled.validatedBySurgeon, false);
      expect(toggled.items, validated.items);
      expect(toggled.procedureName, validated.procedureName);
    });
  });
}
