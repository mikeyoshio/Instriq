import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/group_sibling_organization.dart';

void main() {
  group('GroupSiblingOrganization.fromRow', () {
    test('parses a full row with only safe columns', () {
      final sibling = GroupSiblingOrganization.fromRow({
        'id': 'o2',
        'name': 'Quirón Teknon',
        'org_type': 'hospital',
      });
      expect(sibling.id, 'o2');
      expect(sibling.name, 'Quirón Teknon');
      expect(sibling.orgType, 'hospital');
    });

    test('defaults missing fields instead of crashing', () {
      final sibling = GroupSiblingOrganization.fromRow({'id': 'o2'});
      expect(sibling.name, '');
      expect(sibling.orgType, 'hospital');
    });
  });
}
