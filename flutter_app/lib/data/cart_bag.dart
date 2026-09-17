/// Store cart, wishlist and checkout — persisted locally so an add on any
/// Store page is still there when you open Cart, Wishlist or Checkout.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BagItem {
  BagItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.price,
    required this.kind,
    this.qty = 1,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final num price;
  final String kind;
  int qty;

  num get lineTotal => price * qty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'image': image,
        'price': price,
        'kind': kind,
        'qty': qty,
      };

  static BagItem fromJson(Map<String, dynamic> m) => BagItem(
        id: '${m['id'] ?? ''}',
        title: '${m['title'] ?? ''}',
        subtitle: '${m['subtitle'] ?? ''}',
        image: '${m['image'] ?? ''}',
        price: m['price'] is num ? m['price'] as num : num.tryParse('${m['price']}') ?? 0,
        kind: '${m['kind'] ?? 'Word'}',
        qty: (m['qty'] is num) ? (m['qty'] as num).toInt() : 1,
      );
}

class BagOrder {
  BagOrder({
    required this.id,
    required this.at,
    required this.name,
    required this.phone,
    required this.address,
    required this.payMethod,
    required this.items,
    required this.total,
  });

  final String id;
  final int at;
  final String name, phone, address, payMethod;
  final List<BagItem> items;
  final num total;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at,
        'name': name,
        'phone': phone,
        'address': address,
        'payMethod': payMethod,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
      };

  static BagOrder fromJson(Map<String, dynamic> m) => BagOrder(
        id: '${m['id'] ?? ''}',
        at: (m['at'] is num) ? (m['at'] as num).toInt() : 0,
        name: '${m['name'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        address: '${m['address'] ?? ''}',
        payMethod: '${m['payMethod'] ?? ''}',
        items: [
          for (final e in (m['items'] as List? ?? const []))
            if (e is Map) BagItem.fromJson(Map<String, dynamic>.from(e)),
        ],
        total: m['total'] is num ? m['total'] as num : 0,
      );
}

class CartBag extends ChangeNotifier {
  CartBag._();
  static final CartBag instance = CartBag._();

  static const _kCart = 'nwsb_store_cart';
  static const _kWish = 'nwsb_store_wish';
  static const _kOrders = 'nwsb_store_orders';
  static const _kShip = 'nwsb_store_ship';

  final List<BagItem> _cart = [];
  final List<BagItem> _wish = [];
  final List<BagOrder> _orders = [];
  String shipName = '';
  String shipPhone = '';
  String shipAddress = '';

  List<BagItem> get cart => List.unmodifiable(_cart);
  List<BagItem> get wishlist => List.unmodifiable(_wish);
  List<BagOrder> get orders => List.unmodifiable(_orders);

  int get cartCount => _cart.fold(0, (n, e) => n + e.qty);
  int get wishCount => _wish.length;
  num get cartTotal => _cart.fold<num>(0, (n, e) => n + e.lineTotal);

  bool inCart(String id) => _cart.any((e) => e.id == id);
  bool inWish(String id) => _wish.any((e) => e.id == id);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _cart
        ..clear()
        ..addAll(_readItems(p.getString(_kCart)));
      _wish
        ..clear()
        ..addAll(_readItems(p.getString(_kWish)));
      _orders
        ..clear()
        ..addAll(_readOrders(p.getString(_kOrders)));
      final ship = p.getString(_kShip);
      if (ship != null && ship.isNotEmpty) {
        final m = jsonDecode(ship);
        if (m is Map) {
          shipName = '${m['name'] ?? ''}';
          shipPhone = '${m['phone'] ?? ''}';
          shipAddress = '${m['address'] ?? ''}';
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addCart(BagItem item) async {
    final i = _cart.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _cart[i].qty += item.qty <= 0 ? 1 : item.qty;
    } else {
      _cart.add(BagItem(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        image: item.image,
        price: item.price,
        kind: item.kind,
        qty: item.qty <= 0 ? 1 : item.qty,
      ));
    }
    notifyListeners();
    await _persistCart();
  }

  Future<void> addWishlist(BagItem item) async {
    if (inWish(item.id)) {
      notifyListeners();
      return;
    }
    _wish.insert(
      0,
      BagItem(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        image: item.image,
        price: item.price,
        kind: item.kind,
        qty: 1,
      ),
    );
    notifyListeners();
    await _persistWish();
  }

  Future<void> removeCart(String id) async {
    _cart.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistCart();
  }

  Future<void> removeWishlist(String id) async {
    _wish.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistWish();
  }

  Future<void> setQty(String id, int qty) async {
    final i = _cart.indexWhere((e) => e.id == id);
    if (i < 0) return;
    if (qty <= 0) {
      _cart.removeAt(i);
    } else {
      _cart[i].qty = qty;
    }
    notifyListeners();
    await _persistCart();
  }

  Future<void> moveWishToCart(String id) async {
    final i = _wish.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final item = _wish.removeAt(i);
    await addCart(item);
    await _persistWish();
  }

  Future<void> saveShip({
    required String name,
    required String phone,
    required String address,
  }) async {
    shipName = name.trim();
    shipPhone = phone.trim();
    shipAddress = address.trim();
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _kShip,
        jsonEncode({
          'name': shipName,
          'phone': shipPhone,
          'address': shipAddress,
        }),
      );
    } catch (_) {}
  }

  Future<BagOrder?> checkout({
    required String name,
    required String phone,
    required String address,
    required String payMethod,
  }) async {
    if (_cart.isEmpty) return null;
    await saveShip(name: name, phone: phone, address: address);
    final now = DateTime.now();
    final order = BagOrder(
      id: 'NSB${now.millisecondsSinceEpoch}',
      at: now.millisecondsSinceEpoch,
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      payMethod: payMethod,
      items: [
        for (final e in _cart)
          BagItem(
            id: e.id,
            title: e.title,
            subtitle: e.subtitle,
            image: e.image,
            price: e.price,
            kind: e.kind,
            qty: e.qty,
          ),
      ],
      total: cartTotal,
    );
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    await _persistCart();
    await _persistOrders();
    return order;
  }

  List<BagItem> _readItems(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map) BagItem.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return const [];
    }
  }

  List<BagOrder> _readOrders(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map) BagOrder.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistCart() async => _write(_kCart, _cart.map((e) => e.toJson()).toList());
  Future<void> _persistWish() async => _write(_kWish, _wish.map((e) => e.toJson()).toList());
  Future<void> _persistOrders() async =>
      _write(_kOrders, _orders.map((e) => e.toJson()).toList());

  Future<void> _write(String key, Object value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, jsonEncode(value));
    } catch (_) {}
  }
}
