import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/surgical_slot.dart';

void main() {
  group('SurgicalSlotStatus', () {
    test('fromDb round-trips every dbValue', () {
      for (final status in SurgicalSlotStatus.values) {
        expect(SurgicalSlotStatusLabel.fromDb(status.dbValue), status);
      }
    });

    test('fromDb throws on an unknown value', () {
      expect(() => SurgicalSlotStatusLabel.fromDb('deleted'), throwsArgumentError);
    });
  });

  group('SurgicalSlot.fromRow', () {
    test('parses a full row (links, cancellation fields all present)', () {
      final slot = SurgicalSlot.fromRow({
        'id': 'slot-1',
        'organization_id': 'org-1',
        'workspace_id': 'ws-1',
        'surgeon_id': 'surgeon-1',
        'preference_card_id': 'card-1',
        'document_id': 'doc-1',
        'tray_id': 'tray-1',
        'procedure_name': 'Hernioplastia inguinal',
        'location': 'Quirófano 3',
        'starts_at': '2026-11-10T09:00:00Z',
        'ends_at': '2026-11-10T11:00:00Z',
        'notes': 'Avisar a esterilización con antelación',
        'status': 'cancelled',
        'created_by': 'user-a',
        'created_at': '2026-11-01T08:00:00Z',
        'cancelled_by': 'user-b',
        'cancelled_at': '2026-11-05T12:00:00Z',
        'cancellation_reason': 'Reprogramada a petición del cirujano',
      });

      expect(slot.status, SurgicalSlotStatus.cancelled);
      expect(slot.preferenceCardId, 'card-1');
      expect(slot.documentId, 'doc-1');
      expect(slot.trayId, 'tray-1');
      expect(slot.startsAt, DateTime.parse('2026-11-10T09:00:00Z'));
      expect(slot.endsAt, DateTime.parse('2026-11-10T11:00:00Z'));
      expect(slot.cancelledBy, 'user-b');
      expect(slot.cancellationReason, 'Reprogramada a petición del cirujano');
    });

    test('optional fields are all null for a freshly created (scheduled) slot', () {
      final slot = SurgicalSlot.fromRow({
        'id': 'slot-2',
        'organization_id': 'org-1',
        'workspace_id': 'ws-1',
        'surgeon_id': 'surgeon-2',
        'starts_at': '2026-11-12T09:00:00Z',
        'ends_at': '2026-11-12T10:00:00Z',
        'status': 'scheduled',
      });

      expect(slot.status, SurgicalSlotStatus.scheduled);
      expect(slot.preferenceCardId, isNull);
      expect(slot.documentId, isNull);
      expect(slot.trayId, isNull);
      expect(slot.procedureName, isNull);
      expect(slot.location, isNull);
      expect(slot.notes, isNull);
      expect(slot.cancelledBy, isNull);
      expect(slot.cancelledAt, isNull);
      expect(slot.cancellationReason, isNull);
    });
  });
}
