/// Google Play Billing for ONE-TIME products (words, stages, bundles, paid
/// scratch cards, gift cards, ebook pass, streak restore).
///
///  1. The server opens a checkout (`beginCheckout`): it prices the bag,
///     holds the coins / coupon and says which Play product to buy.
///  2. Play's sheet is opened for that product with the obfuscated account
///     id = sha256(uid) so the purchase is bound to this account.
///  3. The purchase token goes to POST /api/play/product. Only when the
///     server has checked it with Google (and settled the order: items,
///     coins back, link commission, ranks) is the purchase consumed.
///     Unconfirmed purchases are never consumed, so Play refunds them.
///  4. Purchases left over from a crash are re-sent on the next start.
///
/// Sideloaded copies cannot buy: they show "available in the Play Store
/// version" instead of a broken button. Subscriptions live in
/// lib/data/play_subscriptions.dart and are skipped here.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/billing_config.dart';
import '../../data/play_subscriptions.dart';
import 'economy_api.dart';

class PlayCheckout {
  PlayCheckout._();

  static const playStoreOnly = 'Available in the Play Store version of NowssB.';
  static const _productUrl = 'https://nowssb.com/api/play/product';
  static const _prefsKey = 'nwsb.play.checkouts';
  static final _prices = <String, String>{};
  static final _waiting = <String, Completer<Map<String, dynamic>>>{};
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool? _available;
  static String? _recoveredFor;

  /// Last settled order, so screens can refresh / celebrate.
  static final ValueNotifier<Map<String, dynamic>?> lastSettled = ValueNotifier(null);

  static bool _isOneTime(String id) => id.startsWith('nowssb_') && !kPlayProductIds.contains(id);

  /// Whether this install can buy through Google Play.
  static Future<bool> available() async {
    if (_available != null) return _available!;
    if (kIsWeb || !Platform.isAndroid) return _available = false;
    try {
      _available = await InAppPurchase.instance.isAvailable();
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  /// Listen for one-time purchases (also ones left over from last time).
  static Future<void> start() async {
    if (!await available()) return;
    _sub ??= InAppPurchase.instance.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('NowssB one-time billing: $e'));
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Recovery runs once per signed-in account. It used to run only on the
      // first start(): a guest who tapped Buy before signing in never got
      // their unconfirmed purchases re-sent until the next launch.
      if (user != null && !user.isAnonymous && _recoveredFor != user.uid) {
        _recoveredFor = user.uid;
        final android = InAppPurchase.instance.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final past = await android.queryPastPurchases();
        for (final p in past.pastPurchases) {
          if (_isOneTime(p.productID)) unawaited(_settle(p));
        }
      }
    } catch (e) {
      debugPrint('NowssB one-time billing recovery: $e');
    }
  }

  static Future<String> priceLabel(String productId) async {
    final cached = _prices[productId];
    if (cached != null) return cached;
    if (!await available()) return 'Play price';
    try {
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return 'Play price';
      final label = response.productDetails.first.price;
      _prices[productId] = label;
      return label;
    } catch (_) {
      return 'Play price';
    }
  }

  /// Opens a server checkout and buys it through Play.
  /// [checkout] is the `beginCheckout` payload: `{kind: cart|scratch|giftcard|product, ...}`.
  static Future<Map<String, dynamic>> purchase(Map<String, dynamic> checkout) async {
    if (!await available()) throw EconomyException(playStoreOnly, code: 'play-only');
    await start();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) throw EconomyException('Sign in first — purchases are saved to your NowssB account.');
    final opened = await EconomyApi.call('beginCheckout', checkout);
    final productId = '${opened['productId'] ?? ''}';
    final checkoutId = '${opened['checkoutId'] ?? ''}';
    if (productId.isEmpty) throw EconomyException('The checkout did not name a product.');
    try {
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        throw EconomyException('This item is not in the Play Store yet ($productId).', code: 'play-missing');
      }
      final prefs = await SharedPreferences.getInstance();
      final map = _readMap(prefs);
      map[productId] = checkoutId;
      await prefs.setString(_prefsKey, jsonEncode(map));
      final done = Completer<Map<String, dynamic>>();
      _waiting[productId] = done;
      final started = await InAppPurchase.instance.buyConsumable(
        purchaseParam: GooglePlayPurchaseParam(productDetails: response.productDetails.first, applicationUserName: PlaySubscriptions.accountHash(user.uid)),
        autoConsume: false,
      );
      if (!started) throw EconomyException('Google Play did not open the purchase.');
      final r = await done.future.timeout(const Duration(minutes: 10), onTimeout: () => throw EconomyException('The purchase did not finish. If you were charged it will be added automatically.'));
      return {...r, 'checkout': opened};
    } catch (e) {
      _waiting.remove(productId);
      // Give held coins / coupon back if nothing was bought.
      if (e is EconomyException && e.code != 'pending') {
        unawaited(EconomyApi.call('cancelCheckout', {'checkoutId': checkoutId}).catchError((_) => <String, dynamic>{}));
      }
      rethrow;
    }
  }

  /// Back-compat entry point used by older screens: buys a standalone product.
  static Future<Map<String, dynamic>> buy({String callable = '', required String productId, Map<String, dynamic> payload = const {}}) {
    return purchase({'kind': 'product', ...payload, 'productId': productId});
  }

  static Map<String, dynamic> _readMap(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static void _resolve(String id, {Map<String, dynamic>? ok, Object? error}) {
    final c = _waiting.remove(id);
    if (c == null || c.isCompleted) return;
    if (error != null) {
      c.completeError(error);
    } else {
      c.complete(ok ?? const {});
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!_isOneTime(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _resolve(p.productID, error: EconomyException('Payment pending with Google Play. It is added as soon as it goes through.', code: 'pending'));
        case PurchaseStatus.canceled:
          _resolve(p.productID, error: EconomyException('Purchase cancelled.'));
        case PurchaseStatus.error:
          _resolve(p.productID, error: EconomyException(p.error?.message.isNotEmpty == true ? 'Google Play: ${p.error!.message}' : 'Google Play could not complete the purchase.'));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _settle(p);
      }
    }
  }

  static Future<void> _settle(PurchaseDetails p) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readMap(prefs);
      final idToken = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse(_productUrl),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
            body: jsonEncode({'productId': p.productID, 'purchaseToken': p.verificationData.serverVerificationData, 'checkoutId': map[p.productID] ?? ''}),
          )
          .timeout(const Duration(seconds: 40));
      Map<String, dynamic> body = const {};
      try {
        final d = jsonDecode(res.body);
        if (d is Map<String, dynamic>) body = d;
      } catch (_) {}
      if (res.statusCode == 200 && body['ok'] == true) {
        await _consume(p);
        map.remove(p.productID);
        await prefs.setString(_prefsKey, jsonEncode(map));
        lastSettled.value = body;
        unawaited(EconomyMirror.instance.refresh());
        _resolve(p.productID, ok: body);
        return;
      }
      if (res.statusCode == 202) {
        _resolve(p.productID, error: EconomyException('Payment pending with Google Play. It is added as soon as it goes through.', code: 'pending'));
        return;
      }
      if (res.statusCode == 501) {
        EconomyApi.switchingOn.value = true;
        _resolve(p.productID, error: EconomyException('Purchases are switching on. Nothing was charged for good — Google Play refunds an unconfirmed purchase automatically.', code: 'not-configured'));
        return;
      }
      _resolve(p.productID, error: EconomyException('${body['error'] ?? 'Could not confirm the purchase (${res.statusCode}).'}'));
    } catch (e) {
      _resolve(p.productID, error: EconomyException('Could not reach NowssB to confirm the purchase. It is retried automatically next time you open the app.'));
    }
  }

  static Future<void> _consume(PurchaseDetails p) async {
    try {
      final android = InAppPurchase.instance.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await android.consumePurchase(p);
    } catch (e) {
      debugPrint('NowssB consume failed: $e');
    }
    if (p.pendingCompletePurchase) {
      try {
        await InAppPurchase.instance.completePurchase(p);
      } catch (_) {}
    }
  }
}
