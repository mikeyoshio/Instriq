import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/instrument_incident.dart';

void main() {
  group('IncidentStatus', () {
    test('fromDb round-trips every dbValue', () {
      for (final status in IncidentStatus.values) {
        expect(IncidentStatusLabel.fromDb(status.dbValue), status);
      }
    });

    test('fromDb throws on an unknown value', () {
      expect(() => IncidentStatusLabel.fromDb('closed'), throwsArgumentError);
    });
  });

  group('InstrumentIncident.fromRow', () {
    test('parses the full CAPA shape (resolved + verified fields, tray link)', () {
      final incident = InstrumentIncident.fromRow({
        'id': 'incident-1',
        'instrument_ref_type': 'catalog',
        'instrument_ref_id': 'pinza-kocher',
        'organization_id': 'org-1',
        'workspace_id': 'ws-1',
        'severity': 'high',
        'status': 'verified',
        'description': 'La punta está doblada',
        'resolution_notes': 'Sustituida por una nueva',
        'root_cause': 'Desgaste por uso prolongado',
        'corrective_action': 'Retirada del inventario y reemplazo',
        'reported_by': 'user-a',
        'resolved_by': 'user-b',
        'resolved_at': '2026-10-20T10:00:00Z',
        'verified_by': 'user-c',
        'verified_at': '2026-10-21T10:00:00Z',
        'verification_notes': 'Confirmado en la siguiente sesión de preparación',
        'tray_preparation_session_id': 'session-1',
        'created_at': '2026-10-19T09:00:00Z',
      });

      expect(incident.status, IncidentStatus.verified);
      expect(incident.severity, IncidentSeverity.high);
      expect(incident.rootCause, 'Desgaste por uso prolongado');
      expect(incident.correctiveAction, 'Retirada del inventario y reemplazo');
      expect(incident.verifiedBy, 'user-c');
      expect(incident.verifiedAt, DateTime.parse('2026-10-21T10:00:00Z'));
      expect(incident.verificationNotes, 'Confirmado en la siguiente sesión de preparación');
      expect(incident.trayPreparationSessionId, 'session-1');
    });

    test('CAPA fields are all null for a freshly reported (open) incident', () {
      final incident = InstrumentIncident.fromRow({
        'id': 'incident-2',
        'instrument_ref_type': 'custom',
        'instrument_ref_id': 'custom-1',
        'organization_id': 'org-1',
        'workspace_id': null,
        'severity': 'low',
        'status': 'open',
        'description': 'Falta una pieza',
      });

      expect(incident.status, IncidentStatus.open);
      expect(incident.workspaceId, isNull);
      expect(incident.rootCause, isNull);
      expect(incident.correctiveAction, isNull);
      expect(incident.verifiedBy, isNull);
      expect(incident.verifiedAt, isNull);
      expect(incident.trayPreparationSessionId, isNull);
    });
  });
}
