import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/instruments_data.dart';
import 'package:instriq/data/perioperative_guides_data.dart';
import 'package:instriq/data/surgical_positions_data.dart';

void main() {
  final ids = kInstruments.map((i) => i.id).toSet();

  test('catalog ids are unique', () => expect(ids.length, kInstruments.length));

  test('positions and guides only link to existing catalog items', () {
    final links = [
      for (final p in kSurgicalPositions) ...p.relatedItems,
      for (final g in kPerioperativeGuides) ...g.relatedItems,
    ];
    expect(links.where((id) => !ids.contains(id)), isEmpty);
  });
}
