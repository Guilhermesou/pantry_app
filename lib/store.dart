import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

abstract class DataRepository {
  Future<AppData> load();
  Future<void> save(AppData data);
}

class LocalRepository implements DataRepository {
  Future<File> get _file async =>
      File('${(await getApplicationDocumentsDirectory()).path}/despensa.json');
  @override
  Future<AppData> load() async {
    final file = await _file;
    if (!await file.exists()) return AppData();
    return AppData.fromJson(jsonDecode(await file.readAsString()));
  }

  @override
  Future<void> save(AppData data) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(data.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}

class PantryStore extends ChangeNotifier {
  PantryStore(this.repository, this.data);
  final DataRepository repository;
  AppData data;
  bool busy = false;
  void refreshTime() => notifyListeners();
  Future<void> change(void Function(AppData draft) update) async {
    if (busy) throw StateError('Aguarde a operação anterior terminar.');
    busy = true;
    notifyListeners();
    try {
      final draft = data.copy();
      update(draft);
      draft.validate();
      await repository.save(draft);
      data = draft;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> replace(AppData replacement) => change((draft) {
    draft.products = replacement.products;
    draft.list = replacement.list;
    draft.events = replacement.events;
    draft.receipts = replacement.receipts;
    draft.receiptAliases = replacement.receiptAliases;
    draft.budget = replacement.budget;
    draft.onboarded = replacement.onboarded;
    draft.demo = replacement.demo;
  });
  Future<void> removeProduct(String id) => change((d) {
    d.products.removeWhere((p) => p.id == id);
    d.receiptAliases.removeWhere((_, productId) => productId == id);
    for (final item in d.list) {
      if (item.productId == id) item.productId = null;
    }
  });
  Future<void> forgetReceiptAlias(String description) => change((d) {
    d.receiptAliases.remove(normalized(description));
  });
  Future<void> openPackage(String id, {String? lotId}) => change((d) {
    final p = d.product(id)!;
    if (p.closed < 1) throw StateError('Não há embalagem fechada.');
    var source = p.lot(lotId);
    if (lotId != null && (source == null || source.closed == 0)) {
      throw StateError('Este lote não tem embalagem fechada.');
    }
    if (lotId == null && p.undatedClosed == 0) {
      final candidates = p.lots.where((lot) => lot.closed > 0).toList();
      if (candidates.length != 1) {
        throw StateError('Escolha qual lote você abriu.');
      }
      source = candidates.single;
    }
    if (source != null) source.closed--;
    p.closed--;
    p.opened.add(1);
    p.openedLotIds.add(source?.id);
    _event(d, 'Embalagem aberta', p.name);
  });

  /// Counts a package that was already open at home; nothing leaves the closed stock.
  Future<void> addOpened(String id) => change((d) {
    final p = d.product(id)!;
    p.opened.add(1);
    p.openedLotIds.add(null);
    _event(d, 'Embalagem aberta registrada', p.name);
  });
  Future<void> setLevel(String id, int index, double level) => change((d) {
    final p = d.product(id)!;
    if (level == 0) {
      p.opened.removeAt(index);
      p.openedLotIds.removeAt(index);
    } else {
      p.opened[index] = level;
    }
    _event(
      d,
      level == 0 ? 'Produto acabou' : 'Nível atualizado',
      '${p.name} · ${levelNames[(level * 4).round()]}',
    );
  });
  Future<void> restoreOpened(String id, double level, String? lotId) =>
      change((d) {
        final p = d.product(id);
        if (p == null) throw StateError('O produto foi removido.');
        p.opened.add(level);
        p.openedLotIds.add(p.lot(lotId)?.id);
        _event(d, 'Finalização desfeita', p.name);
      });
  Future<void> assignOpenedExpiry(String id, int index, DateTime? expiry) =>
      change((d) {
        final p = d.product(id)!;
        if (expiry == null) {
          p.openedLotIds[index] = null;
        } else {
          final date = calendarDate(expiry);
          var lot = p.lots.where((lot) => lot.expiry == date).firstOrNull;
          if (lot == null) {
            lot = StockLot(id: newId(), closed: 0, expiry: date);
            p.lots.add(lot);
          }
          p.openedLotIds[index] = lot.id;
        }
        _event(d, 'Validade do aberto ajustada', p.name);
      });
  Future<void> assignExpiry(
    String id,
    int quantity,
    DateTime? expiry, {
    String? lotId,
  }) => change((d) {
    final p = d.product(id)!;
    final existing = p.lot(lotId);
    if (lotId != null && existing == null) {
      throw StateError('Este lote não existe mais.');
    }
    if (expiry == null) {
      if (existing == null) throw StateError('Escolha uma validade.');
      p.lots.remove(existing);
      for (var i = 0; i < p.openedLotIds.length; i++) {
        if (p.openedLotIds[i] == lotId) p.openedLotIds[i] = null;
      }
      _event(d, 'Validade removida', p.name);
      return;
    }
    final maximum = p.undatedClosed + (existing?.closed ?? 0);
    if (quantity < 0 ||
        quantity > maximum ||
        (quantity == 0 &&
            (existing == null || !p.openedLotIds.contains(lotId)))) {
      throw StateError('Confira a quantidade disponível para este lote.');
    }
    if (existing == null) {
      p.lots.add(
        StockLot(id: newId(), closed: quantity, expiry: calendarDate(expiry)),
      );
    } else {
      existing.closed = quantity;
      existing.expiry = calendarDate(expiry);
    }
    _event(d, 'Validade anotada', '${p.name} · ${displayDate(expiry)}');
  });

  /// Packages already at home that were never counted, with their own date.
  Future<void> addLot(String id, int quantity, DateTime expiry) => change((d) {
    final p = d.product(id)!;
    if (quantity < 1) throw StateError('Informe ao menos uma embalagem.');
    _receive(p, quantity, expiry);
    _event(
      d,
      'Embalagens adicionadas',
      '${p.name} · $quantity · ${displayDate(expiry)}',
    );
  });
  Future<void> discardLot(String id, String lotId) => change((d) {
    final p = d.product(id)!;
    final lot = p.lot(lotId);
    if (lot == null) throw StateError('Este lote não existe mais.');
    final discarded =
        lot.closed + p.openedLotIds.where((id) => id == lotId).length;
    if (discarded == 0) throw StateError('Este lote já está vazio.');
    p.closed -= lot.closed;
    lot.closed = 0;
    for (var i = p.opened.length - 1; i >= 0; i--) {
      if (p.openedLotIds[i] == lotId) {
        p.opened.removeAt(i);
        p.openedLotIds.removeAt(i);
      }
    }
    _event(
      d,
      'Lote descartado',
      '${p.name} · $discarded embalagens · ${displayDate(lot.expiry)}',
    );
  });
  Future<void> addSuggestion(String id) => change((d) {
    if (d.list.any((e) => e.productId == id)) return;
    final p = d.product(id)!;
    d.list.add(
      ShoppingItem(
        id: newId(),
        name: p.name,
        productId: id,
        quantity: (p.minimum - p.available).ceil().clamp(1, 999),
        price: p.lastPrice,
      ),
    );
  });
  Future<void> checkout() => change((d) {
    final cart = d.list.where((e) => e.checked).toList();
    if (cart.isEmpty) throw StateError('Marque os itens que comprou.');
    var total = 0.0;
    for (final item in cart) {
      var p = d.product(item.productId);
      if (p == null) {
        // Generic list entries become products only at explicit confirmation.
        p = Product(id: 'p-${item.id}', name: item.name);
        d.products.add(p);
      }
      _receive(p, item.quantity, item.expiry);
      if (item.price > 0) p.lastPrice = item.price;
      total += item.total;
    }
    _event(
      d,
      'Compra guardada',
      cart.map((e) => '${e.quantity}× ${e.name}').join(' · '),
      total: total,
      kind: 'purchase',
    );
    d.list.removeWhere((e) => e.checked);
  });
  Future<void> importReceipt(
    List<ReceiptLine> lines,
    String fingerprint, {
    bool clearList = true,
  }) => change((d) {
    final selected = lines.where((e) => e.selected).toList();
    if (selected.isEmpty ||
        selected.any(
          (e) =>
              e.name.trim().isEmpty ||
              e.quantity < 1 ||
              !e.unitPrice.isFinite ||
              e.unitPrice < 0,
        )) {
      throw StateError('Confira os itens antes de importar.');
    }
    final total = selected.fold(
      0.0,
      (sum, e) => sum + e.quantity * e.unitPrice,
    );

    if (!d.receipts.add(fingerprint)) {
      throw StateError('Este cupom já foi importado.');
    }
    final purchased = <String, int>{};
    final associations = <String, Set<String>>{};
    final doNotRemember = <String>{};
    for (var i = 0; i < selected.length; i++) {
      final l = selected[i];
      var p = d.product(l.productId);
      if (l.productId != null && p == null) {
        throw StateError(
          'Um produto foi removido. Confira os vínculos novamente.',
        );
      }
      if (p == null) {
        p = Product(id: '${newId()}-$i', name: l.name.trim());
        d.products.add(p);
      }
      _receive(p, l.quantity, l.expiry);
      p.lastPrice = l.unitPrice;
      purchased[p.id] = (purchased[p.id] ?? 0) + l.quantity;
      final description = normalized(l.originalName);
      if (description.isNotEmpty) {
        (associations[description] ??= {}).add(p.id);
        if (!l.remember) doNotRemember.add(description);
      }
    }
    for (final entry in associations.entries) {
      if (entry.value.length == 1 && !doNotRemember.contains(entry.key)) {
        d.receiptAliases[entry.key] = entry.value.single;
      } else {
        // Conflicting or explicitly opted-out descriptions must not keep an old guess.
        d.receiptAliases.remove(entry.key);
      }
    }
    if (clearList) {
      for (final item in d.list.toList()) {
        final amount = purchased[item.productId] ?? 0;
        if (amount == 0) continue;
        if (amount >= item.quantity) {
          purchased[item.productId!] = amount - item.quantity;
          d.list.remove(item);
        } else {
          item.quantity -= amount;
          item.checked = false;
          purchased[item.productId!] = 0;
        }
      }
    }
    d.events.insert(
      0,
      StockEvent(
        id: newId(),
        title: 'Cupom importado',
        detail: selected.map((e) => '${e.quantity}× ${e.name}').join(' · '),
        date: DateTime.now(),
        total: total,
        kind: 'purchase',
      ),
    );
  });
  static void _receive(Product p, int quantity, DateTime? expiry) {
    p.closed += quantity;
    if (expiry != null) {
      p.lots.add(
        StockLot(id: newId(), closed: quantity, expiry: calendarDate(expiry)),
      );
    }
  }

  static void _event(
    AppData d,
    String title,
    String detail, {
    double total = 0,
    String kind = 'stock',
  }) {
    d.events.insert(
      0,
      StockEvent(
        id: newId(),
        title: title,
        detail: detail,
        date: DateTime.now(),
        total: total,
        kind: kind,
      ),
    );
  }
}
