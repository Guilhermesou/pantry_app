import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class CatalogService {
  CatalogService({http.Client? client, this.cosmosToken = ''})
    : _client = client ?? http.Client();
  final http.Client _client;
  final String cosmosToken;
  static const _agent = 'DespensaPersonal/1.0 (private household inventory)';
  static const _openFactsNames = {
    'beauty': 'Open Beauty Facts',
    'petfood': 'Open Pet Food Facts',
    'product': 'Open Products Facts',
  };

  /// Asks every source at once and keeps the answer of the most trusted one.
  Future<Product?> lookup(String barcode) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) {
      throw const FormatException('Digite um código de 8 a 14 números.');
    }
    var failures = 0;
    final answers =
        [
              _openFacts(barcode),
              if (cosmosToken.isNotEmpty) _cosmos(barcode),
              _upcItemDb(barcode),
            ]
            .map(
              (answer) => answer
                  .timeout(const Duration(seconds: 12))
                  .then<Product?>(
                    (product) => product,
                    onError: (_) {
                      failures++;
                      return null;
                    },
                  ),
            )
            .toList();
    for (final answer in answers) {
      final product = await answer;
      if (product != null) return product;
    }
    if (failures == answers.length) {
      throw const HttpException('Catálogo indisponível agora.');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _get(
    Uri uri, {
    Map<String, String> headers = const {'User-Agent': _agent},
  }) async {
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 404 || response.statusCode == 400) return null;
    if (response.statusCode != 200) {
      throw const HttpException('Catálogo indisponível agora.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // product_type=all redirects to Open Beauty, Pet Food or Products Facts.
  Future<Product?> _openFacts(String barcode) async {
    final body = await _get(
      Uri.https('world.openfoodfacts.org', '/api/v3/product/$barcode.json', {
        'product_type': 'all',
        'fields':
            'product_name,product_name_pt,brands,quantity,image_front_small_url,product_type',
      }),
    );
    final product = body?['product'] as Map<String, dynamic>?;
    if (product == null) return null;
    return _product(
      barcode,
      product['product_name_pt'] ?? product['product_name'],
      brand: product['brands'],
      pack: product['quantity'],
      photo: product['image_front_small_url'],
      source: _openFactsNames[product['product_type']] ?? 'Open Food Facts',
    );
  }

  Future<Product?> _cosmos(String barcode) async {
    final body = await _get(
      Uri.https('api.cosmos.bluesoft.com.br', '/gtins/$barcode.json'),
      headers: {
        'X-Cosmos-Token': cosmosToken,
        'User-Agent': 'Cosmos-API-Request',
      },
    );
    if (body == null) return null;
    return _product(
      barcode,
      body['description'],
      brand: (body['brand'] as Map?)?['name'],
      photo: body['thumbnail'],
      source: 'Cosmos Bluesoft',
    );
  }

  Future<Product?> _upcItemDb(String barcode) async {
    final body = await _get(
      Uri.https('api.upcitemdb.com', '/prod/trial/lookup', {'upc': barcode}),
    );
    final items = body?['items'] as List?;
    if (items == null || items.isEmpty) return null;
    final item = items.first as Map<String, dynamic>;
    final images = item['images'] as List? ?? [];
    return _product(
      barcode,
      item['title'],
      brand: item['brand'],
      pack: item['size'],
      photo: images.isEmpty ? null : images.first,
      source: 'UPCitemdb',
    );
  }

  static Product? _product(
    String barcode,
    Object? name, {
    Object? brand,
    Object? pack,
    Object? photo,
    required String source,
  }) {
    final text = (name ?? '').toString().trim();
    if (text.isEmpty) return null;
    final image = (photo ?? '').toString();
    return Product(
      id: newId(),
      name: text,
      barcode: barcode,
      brand: (brand ?? '').toString().trim(),
      pack: (pack ?? '').toString().trim(),
      // iOS blocks plain http images.
      remotePhoto: image.startsWith('https://') ? image : '',
      source: source,
    );
  }

  void close() => _client.close();
}

Future<String?> pickProductPhoto(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1400,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  final directory = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/photos',
  );
  await directory.create(recursive: true);
  return (await File(
    picked.path,
  ).copy('${directory.path}/${newId()}.jpg')).path;
}

Future<String?> recognizeReceipt(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2400,
    imageQuality: 95,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  if (!Platform.isIOS) {
    throw UnsupportedError(
      'A leitura de fotos está disponível no iPhone. Cole o texto do cupom para continuar.',
    );
  }
  return const MethodChannel(
    'despensa/text_recognition',
  ).invokeMethod<String>('recognize', {'path': picked.path});
}

class ReceiptMatcher {
  static void prepare(List<ReceiptLine> lines, AppData data) {
    for (final line in lines) {
      if (line.productId != null) continue;
      line.suggestedProductId = null;
      line.matchSource = null;
      final remembered = data.product(
        data.receiptAliases[normalized(line.originalName)],
      );
      if (remembered != null) {
        line.productId = remembered.id;
        line.matchSource = ReceiptMatchSource.memory;
        continue;
      }
      final exact = data.products
          .where((p) => normalized(p.name) == normalized(line.name))
          .toList();
      if (exact.length == 1) {
        line.productId = exact.single.id;
        line.matchSource = ReceiptMatchSource.exactName;
        continue;
      }
      // Prefixes help with abbreviations, but never select an uncertain match.
      final candidates = data.products
          .where((p) => _similar(line.originalName, p.name))
          .toList();
      if (candidates.length == 1) {
        line.suggestedProductId = candidates.single.id;
        line.matchSource = ReceiptMatchSource.similarName;
      }
    }
  }

  static bool _similar(String description, String name) {
    final words = RegExp(r'[a-zà-ÿ0-9]+');
    List<String> tokens(String text) =>
        words.allMatches(normalized(text)).map((m) => m.group(0)!).toList();
    final from = tokens(description);
    final to = tokens(name);
    final digits = RegExp(r'^\d+$');
    final fromNumbers = from.where(digits.hasMatch).toSet();
    final toNumbers = to.where(digits.hasMatch).toSet();
    if (fromNumbers.isNotEmpty &&
        toNumbers.isNotEmpty &&
        (!fromNumbers.containsAll(toNumbers) ||
            !toNumbers.containsAll(fromNumbers))) {
      return false;
    }
    final significant = from
        .where((w) => w.length >= 3 && !digits.hasMatch(w))
        .toSet();
    if (significant.length < 2) return false;
    final available = to
        .where((w) => w.length >= 3 && !digits.hasMatch(w))
        .toList();
    var matches = 0;
    for (final word in significant) {
      final index = available.indexWhere(
        (w) => w.startsWith(word) || word.startsWith(w),
      );
      if (index >= 0) {
        matches++;
        available.removeAt(index);
      }
    }
    return matches >= 2 && matches / significant.length >= .75;
  }
}

class ReceiptParser {
  // Conservative candidates, always editable. This is not a fiscal XML parser.
  static List<ReceiptLine> parse(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final result = <ReceiptLine>[];
    final pricePattern = RegExp(r'(?:R\$\s*)?(\d{1,6}(?:\.\d{3})*,\d{2})');
    final skip = RegExp(
      r'^(total|subtotal|valor total|valor pago|troco|dinheiro|cart[aã]o|cnpj|cpf|endere[cç]o|chave|consumidor|tributos|desconto|qtd\.? total|forma de pagamento|nf[ce]|protocolo|consulta|https?://|data|hora|emiss[aã]o)',
      caseSensitive: false,
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (skip.hasMatch(line) || !RegExp(r'[a-zA-ZÀ-ÿ]{3}').hasMatch(line)) {
        continue;
      }
      final prices = pricePattern.allMatches(line).toList();
      var name = line;
      var price = 0.0;
      var quantity = 1;
      final qty = RegExp(r'(\d{1,3})\s*[xX×]\s*').firstMatch(line);
      if (qty != null) quantity = int.parse(qty.group(1)!).clamp(1, 999);
      if (prices.isNotEmpty) {
        price = parseAmount(prices.last.group(1)!)! / quantity;
        name = line
            .substring(0, prices.first.start)
            .replaceAll(RegExp(r'\s+\d{1,3}\s*[xX×].*$'), '')
            .trim();
      } else if (i + 1 < lines.length && !skip.hasMatch(lines[i + 1])) {
        final nextPrices = pricePattern.allMatches(lines[i + 1]).toList();
        if (nextPrices.isEmpty) continue;
        final nextQty = RegExp(
          r'^(\d{1,3})(?:[,.]0+)?\s*(?:UN|UND|X|×)\b',
          caseSensitive: false,
        ).firstMatch(lines[i + 1]);
        if (nextQty != null) {
          quantity = int.parse(nextQty.group(1)!).clamp(1, 999);
        }
        price = parseAmount(nextPrices.last.group(1)!)! / quantity;
        i++;
      } else {
        continue;
      }
      name = name
          .replaceFirst(RegExp(r'^\d{1,14}\s+'), '')
          .replaceAll(RegExp(r'[;|]+'), '')
          .trim();
      if (name.length >= 3) {
        result.add(
          ReceiptLine(name: name, quantity: quantity, unitPrice: price),
        );
      }
    }
    return result;
  }

  static String fingerprint(String text) {
    final digits = text.replaceAll(RegExp(r'\s'), '');
    final key = RegExp(r'\d{44}').firstMatch(digits);
    final canonical =
        key?.group(0) ?? normalized(text).replaceAll(RegExp(r'\s'), '');
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
