import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/models.dart';
import 'package:despensa/services.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  test('version one data migrates without changing stock or list', () {
    final legacy = AppData.example().toJson()..['version'] = 1;
    legacy.remove('receiptAliases');
    final migrated = AppData.fromJson(legacy);
    expect(migrated.receiptAliases, isEmpty);
    expect(migrated.product('milk')!.closed, 1);
    expect(migrated.list.length, 3);
    expect(migrated.toJson()['version'], 3);
  });

  test(
    'only a confirmed import learns the original receipt description',
    () async {
      final repository = MemoryRepository();
      final store = PantryStore(repository, AppData.example());
      final line = ReceiptLine(name: ' LEIT   INT ', productId: 'milk');
      line.name = 'Nome corrigido na revisão';
      expect(store.data.receiptAliases, isEmpty);
      await store.importReceipt([line], 'a');
      final restored = await repository.load();
      expect(restored.receiptAliases, {'leit int': 'milk'});
      final next = ReceiptLine(name: 'LEIT INT');
      ReceiptMatcher.prepare([next], restored);
      expect(next.productId, 'milk');
      expect(next.matchSource, ReceiptMatchSource.memory);
    },
  );

  test('similar names are a suggestion and cannot select a product', () {
    final line = ReceiptLine(name: 'LEIT INT');
    ReceiptMatcher.prepare([line], AppData.example());
    expect(line.productId, isNull);
    expect(line.suggestedProductId, 'milk');
    expect(line.matchSource, ReceiptMatchSource.similarName);
  });

  test(
    'ambiguous prefixes and conflicting package numbers have no suggestion',
    () {
      final data = AppData(
        products: [
          Product(id: 'a', name: 'Leite integral 1 L'),
          Product(id: 'b', name: 'Leite integral 2 L'),
        ],
      );
      final ambiguous = ReceiptLine(name: 'LEIT INT');
      ReceiptMatcher.prepare([ambiguous], data);
      expect(ambiguous.suggestedProductId, isNull);
      final differentSize = ReceiptLine(name: 'LEIT INT 3 L');
      ReceiptMatcher.prepare([differentSize], data);
      expect(differentSize.suggestedProductId, isNull);
      final generic = ReceiptLine(name: 'LEITE');
      ReceiptMatcher.prepare([generic], data);
      expect(generic.suggestedProductId, isNull);
    },
  );

  test(
    'a correction updates memory but opt-out forgets an old association',
    () async {
      final store = PantryStore(
        MemoryRepository(),
        AppData.example()..receiptAliases['leit int'] = 'milk',
      );
      await store.importReceipt([
        ReceiptLine(name: 'LEIT INT', productId: 'coffee'),
      ], 'a');
      expect(store.data.receiptAliases['leit int'], 'coffee');
      await store.importReceipt([
        ReceiptLine(name: 'LEIT INT', productId: 'milk', remember: false),
      ], 'b');
      expect(store.data.receiptAliases, isEmpty);
    },
  );

  test(
    'unselected descriptions are not learned and conflicting ones are forgotten',
    () async {
      final store = PantryStore(
        MemoryRepository(),
        AppData.example()..receiptAliases['item'] = 'milk',
      );
      await store.importReceipt([
        ReceiptLine(name: 'ITEM', productId: 'milk'),
        ReceiptLine(name: ' item ', productId: 'coffee'),
        ReceiptLine(name: 'IGNORE', productId: 'rice', selected: false),
      ], 'a');
      expect(store.data.receiptAliases, isEmpty);
    },
  );

  test(
    'new products can be recognized next time after the user confirms',
    () async {
      final store = PantryStore(MemoryRepository(), AppData());
      final line = ReceiptLine(name: 'SAB VEG 90G')..name = 'Sabonete vegetal';
      await store.importReceipt([line], 'a');
      final next = ReceiptLine(name: 'SAB VEG 90G');
      ReceiptMatcher.prepare([next], store.data);
      expect(next.productId, store.data.products.single.id);
      expect(store.data.products.single.name, 'Sabonete vegetal');
    },
  );

  test(
    'save failure and repeated receipt do not change learned associations',
    () async {
      final repo = MemoryRepository()..fail = true;
      final store = PantryStore(repo, AppData.example());
      await expectLater(
        store.importReceipt([
          ReceiptLine(name: 'LEIT INT', productId: 'milk'),
        ], 'a'),
        throwsStateError,
      );
      expect(store.data.receiptAliases, isEmpty);
      repo.fail = false;
      await store.importReceipt([
        ReceiptLine(name: 'LEIT INT', productId: 'milk'),
      ], 'a');
      await expectLater(
        store.importReceipt([
          ReceiptLine(name: 'LEIT INT', productId: 'coffee'),
        ], 'a'),
        throwsStateError,
      );
      expect(store.data.receiptAliases, {'leit int': 'milk'});
    },
  );

  test(
    'deleting a product cleans learned links while forgetting preserves stock',
    () async {
      final data = AppData.example()
        ..receiptAliases.addAll({'leit int': 'milk', 'cafe': 'coffee'});
      final store = PantryStore(MemoryRepository(), data);
      await store.forgetReceiptAlias(' CAFE ');
      expect(store.data.product('coffee')!.available, .25);
      await store.removeProduct('milk');
      expect(store.data.receiptAliases, isEmpty);
      expect(store.data.list.first.productId, isNull);
      expect(store.data.copy().products.length, 3);
    },
  );

  test(
    'backup replacement restores aliases and rejects dangling references',
    () async {
      final backup = AppData.example()..receiptAliases['leit int'] = 'milk';
      final restored = AppData.fromJson(backup.toJson());
      final store = PantryStore(MemoryRepository(), AppData());
      await store.replace(restored);
      expect(store.data.receiptAliases, {'leit int': 'milk'});
      final invalid = backup.toJson()..['receiptAliases'] = {'x': 'deleted'};
      expect(() => AppData.fromJson(invalid), throwsFormatException);
      await store.replace(AppData(onboarded: true));
      expect(store.data.receiptAliases, isEmpty);
    },
  );
}
