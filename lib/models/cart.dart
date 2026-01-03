import 'package:flutter/foundation.dart';

class CartItem {
  final String barcode;
  final String nameSnapshot;
  final double priceSnapshot;
  int qty;

  CartItem({
    required this.barcode,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.qty,
  });

  double get lineTotal => priceSnapshot * qty;
}

class Cart extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  double get total => items.fold(0.0, (s, it) => s + it.lineTotal);
  bool get isEmpty => _items.isEmpty;

  void addOrInc({
    required String barcode,
    required String name,
    required double price,
  }) {
    final it = _items[barcode];
    if (it != null) {
      it.qty += 1;
    } else {
      _items[barcode] = CartItem(
        barcode: barcode,
        nameSnapshot: name,
        priceSnapshot: price,
        qty: 1,
      );
    }
    notifyListeners();
  }

  void setQty(String barcode, int qty) {
    final it = _items[barcode];
    if (it == null) return;
    it.qty = qty < 1 ? 1 : qty;
    notifyListeners();
  }

  void remove(String barcode) {
    _items.remove(barcode);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
