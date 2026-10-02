/// Store prices for words, meanings, Signature pieces and ebooks.
///
/// One source for every price the Store shows and every Play product it
/// buys: Admin → Settings → Products & prices writes `config/store`
/// `{ defaults: {word, meaning, signature, ebook}, items: {<bagId>: price} }`
/// (public read, admin write). Without a doc the defaults in
/// billing_config.dart apply (PDF-2 band ₹70–₹350 for words). A price is
/// always snapped UP to a Play price point, so what the card says is what
/// Google Play charges at the India tier.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'billing_config.dart';
import 'firebase.dart';

class StorePrices extends ChangeNotifier {
  StorePrices._() {
    _start();
  }
  static final StorePrices instance = StorePrices._();

  Map<String, num> _defaults = const {};
  Map<String, num> _items = const {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Map<String, num> get defaults => {
        for (final e in kContentDefaultPrice.entries) e.key: _defaults[e.key] ?? e.value,
      };
  Map<String, num> get items => Map.unmodifiable(_items);

  void _start() {
    if (!NwsbFirebase.ready) return;
    try {
      _sub = FirebaseFirestore.instance.doc('config/store').snapshots().listen((s) {
        final d = s.data() ?? const <String, dynamic>{};
        _defaults = _nums(d['defaults']);
        _items = _nums(d['items']);
        notifyListeners();
      }, onError: (Object e) => debugPrint('NowssB prices: $e'));
    } catch (_) {}
  }

  static Map<String, num> _nums(dynamic raw) => {
        if (raw is Map)
          for (final e in raw.entries)
            if (e.value is num && (e.value as num) >= 0) '${e.key}': e.value as num,
      };

  /// The Play price point for item [itemId] of [kind].
  ///
  /// Order: the admin's per-item price (Products & prices → config/store
  /// `items`), else for ebooks the catalogue price, else the kind default
  /// (config/store `defaults`, else [kContentDefaultPrice]). The bundled
  /// word / meaning catalogue carries placeholder numbers (₹49, ₹24.5, 0)
  /// that were never real prices, so [shown] is ignored for those kinds —
  /// what a card shows is what Google Play charges. An admin price of 0
  /// makes an item free.
  num priceFor(String itemId, {String? kind, num? shown}) {
    final k = kind ?? contentKindOfItem(itemId) ?? 'word';
    final set = _items[itemId];
    if (set != null) return set <= 0 ? 0 : contentTierFor(k, set);
    if (k == 'ebook' && shown != null && shown > 0) return contentTierFor(k, shown);
    return defaultFor(k);
  }

  /// The regular price when [itemId] is on an admin sale (its own price
  /// below the kind default), else null — for the strike-through.
  num? regularIfOnSale(String itemId, {String? kind}) {
    final k = kind ?? contentKindOfItem(itemId) ?? 'word';
    final set = _items[itemId];
    if (set == null || set <= 0) return null;
    final d = defaultFor(k);
    return contentTierFor(k, set) < d ? d : null;
  }

  /// Default price for [kind] (snapped to a Play price point).
  num defaultFor(String kind) =>
      contentTierFor(kind, _defaults[kind] ?? kContentDefaultPrice[kind] ?? 99);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
