import 'dart:convert';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
String normalized(String value) =>
    value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
String money(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
double? parseAmount(String value) {
  var text = value.replaceAll('R\$', '').replaceAll(' ', '').trim();
  if (text.contains(',')) text = text.replaceAll('.', '').replaceAll(',', '.');
  final number = double.tryParse(text);
  return number != null && number.isFinite && number >= 0 ? number : null;
}

enum Priority {
  essential('Essencial'),
  flexible('Se couber'),
  later('Pode esperar');

  const Priority(this.label);
  final String label;
}

const categories = ['Alimentos', 'Bebidas', 'Higiene', 'Limpeza', 'Outros'];
const locations = [
  'Despensa',
  'Geladeira',
  'Freezer',
  'Banheiro',
  'Lavanderia',
];
const levelNames = ['Acabou', 'Cerca de ¼', 'Metade', 'Cerca de ¾', 'Cheio'];

DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);
String dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
DateTime parseDateOnly(String text) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    throw const FormatException('Data inválida.');
  }
  final date = DateTime.parse(text);
  if (date.year < 1900 || date.year > 2200 || dateOnly(date) != text) {
    throw const FormatException('Data inválida.');
  }
  return date;
}

int daysUntil(DateTime date, DateTime now) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
String expiryLabel(DateTime date, DateTime now) {
  final days = daysUntil(date, now);
  if (days < 0) return 'Vencido · ${displayDate(date)}';
  if (days == 0) return 'Vence hoje';
  if (days == 1) return 'Vence amanhã';
  return 'Vence em $days dias';
}

class StockLot {
  StockLot({required this.id, required this.closed, required this.expiry});
  String id;
  int closed;
  DateTime expiry;
  Map<String, dynamic> toJson() => {
    'id': id,
    'closed': closed,
    'expiry': dateOnly(expiry),
  };
  factory StockLot.fromJson(Map<String, dynamic> j) => StockLot(
    id: j['id'],
    closed: j['closed'],
    expiry: parseDateOnly(j['expiry']),
  );
}

class Product {
  Product({
    required this.id,
    required this.name,
    this.brand = '',
    this.pack = '',
    this.barcode = '',
    this.category = 'Alimentos',
    this.location = 'Despensa',
    this.photo = '',
    this.remotePhoto = '',
    this.closed = 0,
    List<double>? opened,
    List<StockLot>? lots,
    List<String?>? openedLotIds,
    this.minimum = 1,
    this.lastPrice = 0,
    this.source = '',
  }) : opened = opened ?? [],
       lots = lots ?? [],
       openedLotIds =
           openedLotIds ??
           List<String?>.filled(opened?.length ?? 0, null, growable: true);
  String id,
      name,
      brand,
      pack,
      barcode,
      category,
      location,
      photo,
      remotePhoto,
      source;
  int closed;
  List<double> opened;
  List<StockLot> lots;
  List<String?> openedLotIds;
  int get undatedClosed =>
      closed - lots.fold(0, (sum, lot) => sum + lot.closed);
  StockLot? lot(String? id) {
    for (final lot in lots) {
      if (lot.id == id) return lot;
    }
    return null;
  }

  List<StockLot> get activeLots =>
      lots
          .where((lot) => lot.closed > 0 || openedLotIds.contains(lot.id))
          .toList()
        ..sort((a, b) => a.expiry.compareTo(b.expiry));
  DateTime? get nearestExpiry =>
      activeLots.isEmpty ? null : activeLots.first.expiry;
  bool needsExpiryAttention(DateTime now) =>
      activeLots.any((lot) => daysUntil(lot.expiry, now) <= 7);
  double minimum, lastPrice;
  double get available =>
      closed + opened.fold(0.0, (sum, level) => sum + level);
  bool get low => available < minimum;
  String get stockLabel =>
      '$closed ${closed == 1 ? 'fechado' : 'fechados'}${opened.isEmpty ? '' : ' · ${opened.length} ${opened.length == 1 ? 'aberto' : 'abertos'}'}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'pack': pack,
    'barcode': barcode,
    'category': category,
    'location': location,
    'photo': photo,
    'remotePhoto': remotePhoto,
    'closed': closed,
    'opened': opened,
    'lots': lots.map((lot) => lot.toJson()).toList(),
    'openedLotIds': openedLotIds,
    'minimum': minimum,
    'lastPrice': lastPrice,
    'source': source,
  };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'],
    brand: j['brand'] ?? '',
    pack: j['pack'] ?? '',
    barcode: j['barcode'] ?? '',
    category: j['category'] ?? 'Alimentos',
    location: j['location'] ?? 'Despensa',
    photo: j['photo'] ?? '',
    remotePhoto: j['remotePhoto'] ?? '',
    closed: j['closed'] ?? 0,
    opened: (j['opened'] as List? ?? [])
        .map((e) => (e as num).toDouble())
        .toList(),
    lots: (j['lots'] as List? ?? []).map((e) => StockLot.fromJson(e)).toList(),
    openedLotIds: j['openedLotIds'] == null
        ? null
        : List<String?>.from(j['openedLotIds']),
    minimum: (j['minimum'] as num? ?? 1).toDouble(),
    lastPrice: (j['lastPrice'] as num? ?? 0).toDouble(),
    source: j['source'] ?? '',
  );
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.name,
    this.productId,
    this.quantity = 1,
    this.price = 0,
    this.priority = Priority.essential,
    this.checked = false,
    this.expiry,
  });
  String id, name;
  String? productId;
  int quantity;
  double price;
  Priority priority;
  bool checked;
  DateTime? expiry;
  double get total => quantity * price;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'productId': productId,
    'quantity': quantity,
    'price': price,
    'priority': priority.index,
    'checked': checked,
    'expiry': expiry == null ? null : dateOnly(expiry!),
  };
  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
    id: j['id'],
    name: j['name'],
    productId: j['productId'],
    quantity: j['quantity'],
    price: (j['price'] as num).toDouble(),
    priority: Priority.values[j['priority']],
    checked: j['checked'],
    expiry: j['expiry'] == null ? null : parseDateOnly(j['expiry']),
  );
}

class StockEvent {
  StockEvent({
    required this.id,
    required this.title,
    required this.detail,
    required this.date,
    this.total = 0,
    this.kind = 'stock',
  });
  final String id, title, detail, kind;
  final DateTime date;
  final double total;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'detail': detail,
    'date': date.toIso8601String(),
    'total': total,
    'kind': kind,
  };
  factory StockEvent.fromJson(Map<String, dynamic> j) => StockEvent(
    id: j['id'],
    title: j['title'],
    detail: j['detail'],
    date: DateTime.parse(j['date']),
    total: (j['total'] as num).toDouble(),
    kind: j['kind'],
  );
}

class AppData {
  AppData({
    List<Product>? products,
    List<ShoppingItem>? list,
    List<StockEvent>? events,
    Set<String>? receipts,
    Map<String, String>? receiptAliases,
    this.budget = 0,
    this.onboarded = false,
    this.demo = false,
  }) : products = products ?? [],
       list = list ?? [],
       events = events ?? [],
       receipts = receipts ?? {},
       receiptAliases = receiptAliases ?? {};
  List<Product> products;
  List<ShoppingItem> list;
  List<StockEvent> events;
  Set<String> receipts;
  Map<String, String> receiptAliases;
  double budget;
  bool onboarded, demo;
  double get planned => list
      .where((e) => e.priority != Priority.later)
      .fold(0, (s, e) => s + e.total);
  double get cart =>
      list.where((e) => e.checked).fold(0, (s, e) => s + e.total);
  Product? product(String? id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Product? byBarcode(String code) {
    if (code.isEmpty) return null;
    for (final p in products) {
      if (p.barcode == code) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'version': 3,
    'products': products.map((e) => e.toJson()).toList(),
    'list': list.map((e) => e.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'receipts': receipts.toList(),
    'receiptAliases': receiptAliases,
    'budget': budget,
    'onboarded': onboarded,
    'demo': demo,
  };
  factory AppData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1 && j['version'] != 2 && j['version'] != 3) {
      throw const FormatException('Versão de backup incompatível.');
    }
    final data = AppData(
      products: (j['products'] as List)
          .map((e) => Product.fromJson(e))
          .toList(),
      list: (j['list'] as List).map((e) => ShoppingItem.fromJson(e)).toList(),
      events: (j['events'] as List).map((e) => StockEvent.fromJson(e)).toList(),
      receipts: Set<String>.from(j['receipts']),
      receiptAliases: j['version'] == 1
          ? {}
          : Map<String, String>.from(j['receiptAliases'] as Map),
      budget: (j['budget'] as num).toDouble(),
      onboarded: j['onboarded'] == true,
      demo: j['demo'] == true,
    );
    data.validate();
    return data;
  }
  void validate() {
    final ids = <String>{};
    final codes = <String>{};
    for (final p in products) {
      if (!categories.contains(p.category) ||
          !locations.contains(p.location) ||
          !ids.add(p.id) ||
          p.name.trim().isEmpty ||
          p.closed < 0 ||
          !p.minimum.isFinite ||
          p.minimum < 0 ||
          !p.lastPrice.isFinite ||
          p.lastPrice < 0 ||
          p.opened.any((e) => !e.isFinite || e <= 0 || e > 1) ||
          (p.barcode.isNotEmpty && !codes.add(p.barcode))) {
        throw const FormatException('Produto inválido.');
      }
      final lotIds = <String>{};
      if (p.lots.any(
            (lot) =>
                lot.id.isEmpty ||
                !lotIds.add(lot.id) ||
                lot.closed < 0 ||
                lot.expiry.year < 1900 ||
                lot.expiry.year > 2200,
          ) ||
          p.undatedClosed < 0 ||
          p.openedLotIds.length != p.opened.length ||
          p.openedLotIds.any((id) => id != null && !lotIds.contains(id))) {
        throw const FormatException('Lote de estoque inválido.');
      }
    }
    final itemIds = <String>{};
    for (final entry in receiptAliases.entries) {
      if (entry.key.isEmpty ||
          entry.key != normalized(entry.key) ||
          !ids.contains(entry.value)) {
        throw const FormatException('Associação de cupom inválida.');
      }
    }
    for (final item in list) {
      if (!itemIds.add(item.id) ||
          item.name.trim().isEmpty ||
          item.quantity < 1 ||
          (item.expiry != null &&
              (item.expiry!.year < 1900 || item.expiry!.year > 2200)) ||
          !item.price.isFinite ||
          item.price < 0 ||
          (item.productId != null && !ids.contains(item.productId))) {
        throw const FormatException('Item de lista inválido.');
      }
    }
    if (!budget.isFinite || budget < 0) {
      throw const FormatException('Orçamento inválido.');
    }
  }

  AppData copy() => AppData.fromJson(jsonDecode(jsonEncode(toJson())));
  factory AppData.example() => AppData(
    onboarded: true,
    demo: true,
    budget: 600,
    products: [
      Product(
        id: 'rice',
        name: 'Arroz integral',
        brand: 'Tio João',
        pack: '1 kg',
        closed: 2,
        opened: [.5],
        minimum: 2,
        lastPrice: 8.90,
      ),
      Product(
        id: 'milk',
        name: 'Leite integral',
        pack: '1 L',
        category: 'Bebidas',
        location: 'Geladeira',
        closed: 1,
        opened: [.25],
        minimum: 3,
        lastPrice: 5.49,
      ),
      Product(
        id: 'coffee',
        name: 'Café moído',
        pack: '250 g',
        opened: [.25],
        minimum: 1,
        lastPrice: 18.90,
      ),
      Product(
        id: 'soap',
        name: 'Sabonete',
        pack: '90 g',
        category: 'Higiene',
        location: 'Banheiro',
        closed: 3,
        minimum: 2,
        lastPrice: 3.20,
      ),
    ],
    list: [
      ShoppingItem(
        id: 'l1',
        name: 'Leite integral',
        productId: 'milk',
        quantity: 6,
        price: 5.49,
      ),
      ShoppingItem(
        id: 'l2',
        name: 'Café moído',
        productId: 'coffee',
        quantity: 2,
        price: 18.90,
      ),
      ShoppingItem(
        id: 'l3',
        name: 'Banana',
        quantity: 1,
        price: 7.90,
        priority: Priority.flexible,
      ),
    ],
  );
}

class ReceiptLine {
  ReceiptLine({
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
    this.productId,
    this.selected = true,
    String? originalName,
    this.remember = true,
    this.expiry,
  }) : originalName = originalName ?? name;
  final String originalName;
  String name;
  int quantity;
  double unitPrice;
  String? productId;
  bool selected;
  bool remember;
  DateTime? expiry;
  String? suggestedProductId;
  ReceiptMatchSource? matchSource;
}

enum ReceiptMatchSource { memory, exactName, similarName, manual }
