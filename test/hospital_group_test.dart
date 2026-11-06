import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/hospital_group.dart';

void main() {
  group('HospitalGroup.fromRow', () {
    test('parses a full row', () {
      final group = HospitalGroup.fromRow({
        'id': 'g1',
        'name': 'Quirón',
        'group_code': 'ABCD1234',
      });
      expect(group.id, 'g1');
      expect(group.name, 'Quirón');
      expect(group.groupCode, 'ABCD1234');
    });

    test('defaults missing optional-looking fields to empty strings rather than crashing', () {
      final group = HospitalGroup.fromRow({'id': 'g1'});
      expect(group.name, '');
      expect(group.groupCode, '');
    });
  });
}
