import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/tray.dart';

void main() {
  group('InstrumentRefType', () {
    test('fromDb round-trips every dbValue', () {
      for (final type in InstrumentRefType.values) {
        expect(InstrumentRefTypeLabel.fromDb(type.dbValue), type);
      }
    });

    test('fromDb throws on an unknown value', () {
      expect(() => InstrumentRefTypeLabel.fromDb('unknown'), throwsArgumentError);
    });

    test('suture/drug/woundClosure are always fungible, catalog/custom are not by default', () {
      expect(InstrumentRefType.suture.isAlwaysFungible, isTrue);
      expect(InstrumentRefType.drug.isAlwaysFungible, isTrue);
      expect(InstrumentRefType.woundClosure.isAlwaysFungible, isTrue);
      expect(InstrumentRefType.catalog.isAlwaysFungible, isFalse);
      expect(InstrumentRefType.custom.isAlwaysFungible, isFalse);
    });
  });

  group('TrayItem.isFungible', () {
    test('a suture/drug/woundClosure item is always fungible regardless of id', () {
      expect(TrayItem(instrumentRefType: InstrumentRefType.suture, instrumentRefId: 'vicryl-2-0').isFungible(),
          isTrue);
      expect(TrayItem(instrumentRefType: InstrumentRefType.drug, instrumentRefId: 'lidocaina').isFungible(), isTrue);
      expect(
          TrayItem(instrumentRefType: InstrumentRefType.woundClosure, instrumentRefId: 'cera-osea').isFungible(),
          isTrue);
    });

    test('a catalog item is fungible only if its real category is consumibles', () {
      // 'electrobisturi' se recategorizó a consumibles (2026-11): es el lápiz
      // de un solo uso, nunca va a la caja metálica.
      expect(TrayItem(instrumentRefType: InstrumentRefType.catalog, instrumentRefId: 'electrobisturi').isFungible(),
          isTrue);
      // 'bisturi' (mango reutilizable) sigue siendo instrumental, no fungible.
      expect(TrayItem(instrumentRefType: InstrumentRefType.catalog, instrumentRefId: 'bisturi').isFungible(),
          isFalse);
    });

    test('a custom instrument defaults to non-fungible (no structured category yet)', () {
      expect(
          TrayItem(instrumentRefType: InstrumentRefType.custom, instrumentRefId: 'some-custom-id').isFungible(),
          isFalse);
    });

    test('an unknown catalog id defaults to non-fungible rather than crashing', () {
      expect(
          TrayItem(instrumentRefType: InstrumentRefType.catalog, instrumentRefId: 'no-existe').isFungible(),
          isFalse);
    });
  });

  group('TrayItem JSON round-trip', () {
    test('toJson/fromJson preserves the new ref types', () {
      for (final type in InstrumentRefType.values) {
        final item = TrayItem(instrumentRefType: type, instrumentRefId: 'x', expectedQty: 2, position: 'pos');
        final roundTripped = TrayItem.fromJson(item.toJson());
        expect(roundTripped.instrumentRefType, type);
        expect(roundTripped.instrumentRefId, 'x');
        expect(roundTripped.expectedQty, 2);
        expect(roundTripped.position, 'pos');
      }
    });
  });
}
