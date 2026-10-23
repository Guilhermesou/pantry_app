import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  final dateA = DateTime(2026, 10, 25), dateB = DateTime(2026, 11, 15);
  PantryStore create() => PantryStore(
    MemoryRepository(),
    AppData(
      products: [
        Product(id: 'p', name: 'Leite', closed: 5, opened: [.5]),
      ],
    ),
  );

  test(
    'old data loads without inventing expiry dates and roundtrips version three',
    () {
      for (final version in [1, 2]) {
        final json = AppData.example().toJson()..['version'] = version;
        for (final product in json['products'] as List) {
          product.remove('lots');
          product.remove('openedLotIds');
        }
        final data = AppData.fromJson(json);
        expect(data.product('milk')!.closed, 1);
        expect(data.product('milk')!.lots, isEmpty);
        expect(data.product('milk')!.openedLotIds, [null]);
        expect(data.toJson()['version'], 3);
      }
    },
  );
  test(
    'assigning dates partitions existing quantities without receiving stock again',
    () async {
      final store = create();
      await store.assignExpiry('p', 2, dateA);
      await store.assignExpiry('p', 3, dateB);
      final p = store.data.product('p')!;
      expect(p.closed, 5);
      expect(p.available, 5.5);
      expect(p.undatedClosed, 0);
      expect(p.activeLots.map((e) => e.closed), [2, 3]);
      expect(store.data.copy().product('p')!.nearestExpiry, dateA);
      await expectLater(store.assignExpiry('p', 1, dateB), throwsStateError);
      expect(store.data.product('p')!.closed, 5);
    },
  );
  test(
    'opening needs a lot choice when multiple dated lots exist and preserves expiry',
    () async {
      final store = create();
      await store.assignExpiry('p', 2, dateA);
      await store.assignExpiry('p', 3, dateB);
      await expectLater(store.openPackage('p'), throwsStateError);
      final selected = store.data.product('p')!.activeLots.last.id;
      await store.openPackage('p', lotId: selected);
      final p = store.data.product('p')!;
      expect(p.closed, 4);
      expect(p.available, 5.5);
      expect(p.lot(selected)!.closed, 2);
      expect(p.lot(p.openedLotIds.last)!.expiry, dateB);
      await store.setLevel('p', 1, .25);
      expect(store.data.product('p')!.openedLotIds.last, selected);
    },
  );
  test(
    'finishing and undoing an open package preserve its date and metadata',
    () async {
      final store = create();
      await store.assignExpiry('p', 5, dateA);
      await store.openPackage('p');
      final lotId = store.data.product('p')!.openedLotIds.last;
      await store.setLevel('p', 1, 0);
      expect(store.data.product('p')!.openedLotIds, [null]);
      await store.restoreOpened('p', .25, lotId);
      expect(store.data.product('p')!.opened, [.5, .25]);
      expect(store.data.product('p')!.openedLotIds.last, lotId);
      expect(store.data.copy().product('p')!.available, 4.75);
    },
  );
  test('removing a validity keeps closed and opened stock unchanged', () async {
    final store = create();
    await store.assignExpiry('p', 3, dateA);
    final id = store.data.product('p')!.lots.single.id;
    await store.openPackage('p', lotId: id);
    await store.assignExpiry('p', 0, null, lotId: id);
    final p = store.data.product('p')!;
    expect(p.closed, 4);
    expect(p.available, 5.5);
    expect(p.lots, isEmpty);
    expect(p.openedLotIds, [null, null]);
  });
  test(
    'an opened package can have a date without changing other packages',
    () async {
      final store = create();
      await store.assignOpenedExpiry('p', 0, dateA);
      final p = store.data.product('p')!;
      expect(p.opened, [.5]);
      expect(p.closed, 5);
      expect(p.nearestExpiry, dateA);
      await store.assignOpenedExpiry('p', 0, null);
      expect(store.data.product('p')!.nearestExpiry, isNull);
    },
  );
  test(
    'discard affects only the selected lot including its open packages',
    () async {
      final store = create();
      await store.assignExpiry('p', 2, dateA);
      await store.assignExpiry('p', 2, dateB);
      final id = store.data.product('p')!.activeLots.first.id;
      await store.openPackage('p', lotId: id);
      await store.discardLot('p', id);
      final p = store.data.product('p')!;
      expect(p.closed, 3);
      expect(p.opened, [.5]);
      expect(p.openedLotIds, [null]);
      expect(p.activeLots.single.expiry, dateB);
      expect(p.undatedClosed, 1);
      expect(store.data.events.first.title, 'Lote descartado');
      await expectLater(store.discardLot('p', id), throwsStateError);
    },
  );
  test(
    'checkout and receipts create new dated lots and persist dates in backup',
    () async {
      final store = create();
      await store.change(
        (d) => d.list.add(
          ShoppingItem(
            id: 's',
            name: 'Leite',
            productId: 'p',
            quantity: 2,
            checked: true,
            expiry: dateA,
          ),
        ),
      );
      await store.checkout();
      await store.importReceipt([
        ReceiptLine(name: 'LEIT', productId: 'p', quantity: 3, expiry: dateB),
      ], 'receipt');
      final p = store.data.copy().product('p')!;
      expect(p.closed, 10);
      expect(p.undatedClosed, 5);
      expect(p.activeLots.map((e) => e.expiry), [dateA, dateB]);
    },
  );
  test(
    'failed writes roll back lot quantities and opening references',
    () async {
      final repo = MemoryRepository();
      final store = PantryStore(
        repo,
        AppData(
          products: [Product(id: 'p', name: 'Leite', closed: 2)],
        ),
      );
      await store.assignExpiry('p', 2, dateA);
      repo.fail = true;
      await expectLater(store.openPackage('p'), throwsStateError);
      final p = store.data.product('p')!;
      expect(p.closed, 2);
      expect(p.lots.single.closed, 2);
      expect(p.opened, isEmpty);
      await expectLater(
        store.discardLot('p', p.lots.single.id),
        throwsStateError,
      );
      expect(store.data.product('p')!.closed, 2);
    },
  );
  test('attention boundaries use calendar days and ignore empty lots', () {
    final now = DateTime(2026, 10, 22, 23, 59);
    final p = Product(
      id: 'p',
      name: 'Leite',
      closed: 2,
      lots: [
        StockLot(id: 'a', closed: 1, expiry: DateTime(2026, 10, 29)),
        StockLot(id: 'b', closed: 1, expiry: DateTime(2026, 10, 30)),
      ],
    );
    expect(p.needsExpiryAttention(now), true);
    expect(expiryLabel(DateTime(2026, 10, 22), now), 'Vence hoje');
    expect(expiryLabel(DateTime(2026, 10, 23), now), 'Vence amanhã');
    expect(expiryLabel(DateTime(2026, 10, 21), now), startsWith('Vencido'));
    p.lots.first.closed = 0;
    expect(p.needsExpiryAttention(now), false);
    expect(() => parseDateOnly('2026-02-30'), throwsFormatException);
  });
  test('invalid lots and dangling open references are rejected', () {
    for (final product in [
      Product(
        id: 'p',
        name: 'A',
        closed: 1,
        lots: [StockLot(id: 'a', closed: 2, expiry: dateA)],
      ),
      Product(id: 'p', name: 'A', opened: [.5], openedLotIds: ['missing']),
      Product(id: 'p', name: 'A', opened: [.5], openedLotIds: []),
    ]) {
      expect(
        () => AppData(products: [product]).validate(),
        throwsFormatException,
      );
    }
  });
}
