import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/work_mode.dart';

void main() {
  group('sectionPriorityOrder', () {
    test('every work mode (and the no-preference default) is pairwise distinct', () {
      final orders = <String, List<String>>{
        'default': sectionPriorityOrder(null),
        for (final mode in WorkMode.values) mode.name: sectionPriorityOrder(mode),
      };
      final seen = <String, List<String>>{};
      for (final entry in orders.entries) {
        final key = entry.value.join(',');
        final clashWith = seen[key];
        expect(
          clashWith,
          isNull,
          reason: '"${entry.key}" produces the exact same section order as a mode already seen for $key',
        );
        seen[key] = entry.value;
      }
    });

    test('every order is a permutation of the same 9 sections', () {
      const expectedSections = {
        'photo', 'specialty', 'aliases', 'description', 'use', 'tip', 'sterilization', 'technical', 'usedIn',
      };
      for (final mode in WorkMode.values) {
        expect(sectionPriorityOrder(mode).toSet(), expectedSections, reason: 'WorkMode.${mode.name}');
      }
      expect(sectionPriorityOrder(null).toSet(), expectedSections);
    });
  });
}
