import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'package:despensa/services.dart';

class MemoryRepository implements DataRepository {
  AppData saved = AppData();
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<AppData> load() async => saved.copy();
  @override
  Future<void> save(AppData data) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('disk full');
    saved = data.copy();
  }
}

void main() {
  test(
    'opening a package preserves total and levels drive approximate availability',
    () async {
      final store = PantryStore(
        MemoryRepository(),
        AppData(
          products: [Product(id: 'p', name: 'Arroz', closed: 2)],
        ),
      );
      await store.openPackage('p');
      expect(store.data.product('p')!.closed, 1);
      expect(store.data.product('p')!.opened, [1.0]);
      expect(store.data.product('p')!.available, 2);
      await store.setLevel('p', 0, .25);
      expect(store.data.product('p')!.available, 1.25);
      await store.setLevel('p', 0, 0);
      expect(store.data.product('p')!.opened, isEmpty);
      await store.openPackage('p');
      await expectLater(store.openPackage('p'), throwsStateError);
      expect(store.data.product('p')!.closed, 0);
    },
  );
  test(
    'checkout moves checked purchases once and preserves unpurchased list',
    () async {
      final repo = MemoryRepository();
      final d = AppData.example();
      d.list[0].checked = true;
      final store = PantryStore(repo, d);
      final before = d.product('milk')!.closed;
      await store.checkout();
      expect(store.data.product('milk')!.closed, before + 6);
      expect(store.data.list.length, 2);
      expect(store.data.events.first.total, closeTo(32.94, .001));
      await expectLater(store.checkout(), throwsStateError);
      expect((await repo.load()).product('milk')!.closed, before + 6);
    },
  );
  test(
    'saving failure rolls back stock list history and releases lock',
    () async {
      final repo = MemoryRepository()..fail = true;
      final d = AppData.example();
      d.list.first.checked = true;
      final store = PantryStore(repo, d);
      await expectLater(store.checkout(), throwsStateError);
      expect(store.data.product('milk')!.closed, 1);
      expect(store.data.list.length, 3);
      expect(store.data.events, isEmpty);
      expect(store.busy, isFalse);
    },
  );
  test('concurrent actions cannot double checkout', () async {
    final repo = MemoryRepository()..gate = Completer<void>();
    final d = AppData.example();
    d.list.first.checked = true;
    final store = PantryStore(repo, d);
    final first = store.checkout();
    await expectLater(store.checkout(), throwsStateError);
    repo.gate!.complete();
    await first;
    expect(store.data.product('milk')!.closed, 7);
  });
  test('deferred items do not spend planned budget', () {
    final d = AppData(
      list: [
        ShoppingItem(id: 'a', name: 'A', quantity: 2, price: 10),
        ShoppingItem(id: 'b', name: 'B', price: 500, priority: Priority.later),
      ],
    );
    expect(d.planned, 20);
  });
  test(
    'Brazilian prices and receipt quantities are parsed without counting total',
    () {
      expect(parseAmount('1.234,56'), 1234.56);
      expect(parseAmount('-2'), isNull);
      expect(parseAmount('NaN'), isNull);
      final lines = ReceiptParser.parse(
        'ARROZ INTEGRAL 8,90\nLEITE INTEGRAL 2 x 5,49 10,98\nTOTAL 19,88\nCARTÃO 19,88',
      );
      expect(lines.length, 2);
      expect(lines[1].name, 'LEITE INTEGRAL');
      expect(lines[1].quantity, 2);
      expect(lines[1].unitPrice, 5.49);
    },
  );
  test(
    'receipt fingerprints ignore whitespace and use fiscal key when present',
    () {
      expect(
        ReceiptParser.fingerprint('Arroz 8,90\nTotal 8,90'),
        ReceiptParser.fingerprint(' arroz   8,90 total 8,90 '),
      );
      final key = List.filled(44, '1').join();
      expect(
        ReceiptParser.fingerprint('A $key'),
        ReceiptParser.fingerprint('Outro texto $key'),
      );
    },
  );
  test(
    'backup roundtrip and validation reject invalid quantities and duplicates',
    () {
      final d = AppData.example();
      expect(AppData.fromJson(d.toJson()).product('rice')!.opened, [.5]);
      final json = d.toJson();
      (json['products'] as List).first['closed'] = -1;
      expect(() => AppData.fromJson(json), throwsFormatException);
    },
  );
}
