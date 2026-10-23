import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'package:despensa/services.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  test(
    'receipt import adds stock and subtracts only purchased linked quantities',
    () async {
      final data = AppData.example();
      final store = PantryStore(MemoryRepository(), data);
      await store.importReceipt([
        ReceiptLine(
          name: 'LEIT INT',
          productId: 'milk',
          quantity: 2,
          unitPrice: 5.49,
        ),
        ReceiptLine(name: 'Ignored', selected: false),
      ], 'receipt-a');
      expect(store.data.product('milk')!.closed, 3);
      expect(
        store.data.list.firstWhere((e) => e.productId == 'milk').quantity,
        4,
      );
      expect(store.data.events.single.total, 10.98);
      expect(store.data.products.length, 4);
      await expectLater(
        store.importReceipt([
          ReceiptLine(name: 'Milk', productId: 'milk'),
        ], 'receipt-a'),
        throwsStateError,
      );
      expect(store.data.product('milk')!.closed, 3);
    },
  );
  test('failed import does not claim fingerprint or change stock', () async {
    final repo = MemoryRepository()..fail = true;
    final store = PantryStore(repo, AppData.example());
    await expectLater(
      store.importReceipt([
        ReceiptLine(name: 'Leite', productId: 'milk', quantity: 3),
      ], 'receipt-a'),
      throwsStateError,
    );
    expect(store.data.receipts, isEmpty);
    expect(store.data.product('milk')!.closed, 1);
    repo.fail = false;
    await store.importReceipt([
      ReceiptLine(name: 'Leite', productId: 'milk', quantity: 3),
    ], 'receipt-a');
    expect(store.data.product('milk')!.closed, 4);
  });
  test(
    'empty invalid and unchecked receipt selections cannot create stock',
    () async {
      final store = PantryStore(MemoryRepository(), AppData());
      for (final lines in [
        <ReceiptLine>[],
        [ReceiptLine(name: 'A', selected: false)],
        [ReceiptLine(name: 'A', unitPrice: -1)],
        [ReceiptLine(name: '')],
      ]) {
        await expectLater(store.importReceipt(lines, 'bad'), throwsStateError);
      }
      expect(store.data.products, isEmpty);
      expect(store.data.receipts, isEmpty);
    },
  );
  test(
    'catalog handles missing products and includes an identifying user agent',
    () async {
      final client = MockClient((request) async {
        if (request.url.host != 'world.openfoodfacts.org') {
          return http.Response('{}', 404);
        }
        expect(request.url.path, '/api/v3/product/7891234567890.json');
        expect(request.url.queryParameters['product_type'], 'all');
        expect(request.headers['User-Agent'], contains('DespensaPersonal'));
        return http.Response(
          jsonEncode({
            'product': {
              'product_name': 'Arroz',
              'quantity': '1 kg',
              'brands': 'Marca',
            },
          }),
          200,
        );
      });
      final catalog = CatalogService(client: client);
      final product = await catalog.lookup('7891234567890');
      expect(product!.name, 'Arroz');
      expect(product.pack, '1 kg');
      expect(product.barcode, '7891234567890');
      expect(product.source, 'Open Food Facts');
      catalog.close();
      final missing = CatalogService(
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      expect(await missing.lookup('7891234567890'), isNull);
      missing.close();
    },
  );
  test('catalog falls back to other sources in priority order', () async {
    final hosts = <String>[];
    http.Response reply(http.Request request) {
      hosts.add(request.url.host);
      return switch (request.url.host) {
        'api.cosmos.bluesoft.com.br' => http.Response(
          jsonEncode({
            'description': 'ACHOCOLATADO EM PO',
            'brand': {'name': 'Marca BR'},
            'thumbnail': 'https://cosmos.example/a.png',
          }),
          200,
        ),
        'api.upcitemdb.com' => http.Response(
          jsonEncode({
            'items': [
              {
                'title': 'Chocolate drink',
                'images': ['http://x/a.jpg'],
              },
            ],
          }),
          200,
        ),
        _ => http.Response('{}', 404),
      };
    }

    final withToken = CatalogService(
      client: MockClient((request) async {
        if (request.url.host == 'api.cosmos.bluesoft.com.br') {
          expect(request.headers['X-Cosmos-Token'], 'secret');
        }
        return reply(request);
      }),
      cosmosToken: 'secret',
    );
    final cosmos = await withToken.lookup('7898366933086');
    expect(cosmos!.name, 'ACHOCOLATADO EM PO');
    expect(cosmos.brand, 'Marca BR');
    expect(cosmos.source, 'Cosmos Bluesoft');

    hosts.clear();
    final withoutToken = CatalogService(
      client: MockClient((request) async => reply(request)),
    );
    final upc = await withoutToken.lookup('7898366933086');
    expect(hosts, isNot(contains('api.cosmos.bluesoft.com.br')));
    expect(upc!.name, 'Chocolate drink');
    expect(upc.source, 'UPCitemdb');
    expect(upc.remotePhoto, isEmpty, reason: 'iOS blocks plain http images');
  });
  test('catalog names the Open Facts base and reports a full outage', () async {
    final beauty = CatalogService(
      client: MockClient(
        (request) async => request.url.host == 'world.openfoodfacts.org'
            ? http.Response(
                jsonEncode({
                  'product': {
                    'product_name': 'Creme dental',
                    'product_type': 'beauty',
                  },
                }),
                200,
              )
            : http.Response('{}', 404),
      ),
    );
    expect((await beauty.lookup('6920354822193'))!.source, 'Open Beauty Facts');
    final offline = CatalogService(
      client: MockClient((_) async => http.Response('', 503)),
    );
    await expectLater(offline.lookup('6920354822193'), throwsA(anything));
    final partial = CatalogService(
      client: MockClient(
        (request) async => request.url.host == 'api.upcitemdb.com'
            ? http.Response('{"code":"EXCEED_LIMIT"}', 429)
            : http.Response('{}', 404),
      ),
    );
    expect(await partial.lookup('6920354822193'), isNull);
  });
}
