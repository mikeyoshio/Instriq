import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/procedure.dart';
import 'package:instriq/models/surgical_slot.dart';

void main() {
  group('Procedure.fromRow', () {
    test('reads fields and sorts embedded items by position', () {
      final p = Procedure.fromRow({
        'id': 'p1',
        'organization_id': 'o1',
        'workspace_id': 'w1',
        'specialty_id': 's1',
        'name': 'Colecistectomia laparoscòpica',
        'description': 'Desc',
        'updated_at': '2026-11-17T10:00:00Z',
        'procedure_items': [
          {'item_type': 'preference_card', 'item_id': 'c1', 'position': 2},
          {'item_type': 'tray', 'item_id': 't1', 'position': 0},
          {'item_type': 'group_document', 'item_id': 'd1', 'position': 1},
        ],
      });
      expect(p.name, 'Colecistectomia laparoscòpica');
      expect(p.specialtyId, 's1');
      expect(p.items.map((i) => i.itemId), ['t1', 'd1', 'c1']);
      expect(p.idsOf(ProcedureItemType.tray), ['t1']);
      expect(p.idsOf(ProcedureItemType.preferenceCard), ['c1']);
    });

    test('tolerates rows without embedded items or optional fields', () {
      final p = Procedure.fromRow({'id': 'p1', 'organization_id': 'o1', 'workspace_id': 'w1', 'name': 'X'});
      expect(p.items, isEmpty);
      expect(p.specialtyId, isNull);
      expect(p.updatedAt, isNull);
    });
  });

  group('ProcedureItemType', () {
    test('db values round-trip and match schema_v68 check constraint', () {
      for (final t in ProcedureItemType.values) {
        expect(ProcedureItemTypeDb.fromDb(t.dbValue), t);
      }
      expect(ProcedureItemType.values.map((t) => t.dbValue).toSet(), {'tray', 'group_document', 'preference_card'});
    });

    test('unknown db value throws', () {
      expect(() => ProcedureItemTypeDb.fromDb('drug'), throwsArgumentError);
    });

    test('toRpc carries type and id', () {
      expect(const ProcedureItem(type: ProcedureItemType.tray, itemId: 't1').toRpc(),
          {'item_type': 'tray', 'item_id': 't1'});
    });
  });

  group('caseItemIds (slot overrides first, procedure completes)', () {
    test('slot item first, no duplicate', () {
      expect(caseItemIds(fromSlot: 't2', fromProcedure: ['t1', 't2']), ['t2', 't1']);
    });

    test('no slot item: procedure items as-is', () {
      expect(caseItemIds(fromSlot: null, fromProcedure: ['t1']), ['t1']);
    });

    test('slot item only', () {
      expect(caseItemIds(fromSlot: 't9', fromProcedure: const []), ['t9']);
    });
  });

  test('SurgicalSlot.fromRow reads procedure_id', () {
    final slot = SurgicalSlot.fromRow({
      'id': 's1',
      'organization_id': 'o1',
      'workspace_id': 'w1',
      'surgeon_id': 'sg1',
      'starts_at': '2026-11-17T08:00:00Z',
      'ends_at': '2026-11-17T10:00:00Z',
      'status': 'scheduled',
      'procedure_id': 'p1',
    });
    expect(slot.procedureId, 'p1');
  });
}
