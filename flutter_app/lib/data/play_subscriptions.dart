/// Google Play Billing for NowssB subscriptions — the only way to pay.
///
///  1. The Subscribe button asks Play for the product in [kPlayPlans]
///     (lib/data/billing_config.dart) and launches Play's purchase sheet with
///     the obfuscated account id = sha256(Firebase uid).
///  2. Play reports the purchase on [InAppPurchase.purchaseStream]. The
///     purchase token + product id go to POST /api/play/verify
///     (functions/api/play/verify.js) with the Firebase ID token.
///  3. Only when the server says the subscription is active (it has checked
///     with the Google Play Developer API and written users/{uid}) is the
///     plan unlocked here and the purchase completed (acknowledged).
///     If the server cannot confirm, the purchase is NOT completed, so Play
///     refunds it automatically if it is never confirmed.
///
/// [activeTier] reads users/{uid} (isPro, tier, subscriptionEndDate), which
/// only the server or an admin can write — so it also reflects renewals,
/// cancellations (Real-time Developer Notifications) and studio grants.
///
/// A sideloaded / GitHub APK usually cannot buy through Play: that shows as
/// "not available" instead of a broken button.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/economy/economy_api.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'billing_config.dart';
import 'firebase.dart';

class PlayResult {
  const PlayResult(this.ok, this.message, {this.pending = false});
  final bool ok;
  final bool pending;
  final String message;
}

class PlaySubscriptions extends ChangeNotifier {
  PlaySubscriptions._();
  static final PlaySubscriptions instance = PlaySubscriptions._();

  static const _tiers = {'resonance', 'frequency', 'frequencyX'};

  bool _started = false;

  /// null while checking; false when Play Billing cannot be used here.
  bool? available;

  /// Why purchases are unavailable, for the UI. Null when they work.
  String? unavailableReason;

  bool busy = false;

  /// Base-plan details per product id (for the displayed price).
  final Map<String, ProductDetails> _base = {};

  /// What to buy per product id (an eligible offer such as a free trial if
  /// Play returned one, otherwise the base plan).
  final Map<String, ProductDetails> _buy = {};

  /// Active Play purchases seen this session, for upgrades / downgrades.
  final Map<String, GooglePlayPurchaseDetails> _owned = {};

  final Map<String, Completer<PlayResult>> _waiting = {};
  final List<Future<void>> _inflight = [];
  StreamSubscription<List<PurchaseDetails>>? _sub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  // Entitlement from users/{uid}.
  String? _tier;
  DateTime? _until;
  String _source = '';

  /// resonance / frequency / frequencyX while a plan is active, else null.
  String? get activeTier {
    if (_tier == null) return null;
    if (_until != null && _until!.isBefore(DateTime.now())) return null;
    return _tier;
  }

  DateTime? get activeUntil => activeTier == null ? null : _until;
  String get activeSource => _source;

  /// Play's price for a product in the buyer's currency, when known.
  String? priceFor(String productId) => _base[productId]?.price;

  /// Starts listening. Safe to call more than once; never throws.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _watchEntitlement();
    if (kIsWeb || !Platform.isAndroid) {
      _unavailable('Subscriptions are sold through Google Play on Android.');
      return;
    }
    try {
      _sub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('NowssB billing stream: $e'),
      );
      final ok = await InAppPurchase.instance.isAvailable();
      if (!ok) {
        _unavailable('Google Play Billing is not available on this device. Install NowssB from Google Play to subscribe.');
        return;
      }
      available = true;
      notifyListeners();
      await loadProducts();
    } catch (e) {
      _unavailable('Google Play Billing is not available on this device.');
    }
  }

  void _unavailable(String why) {
    available = false;
    unavailableReason = why;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (available != true) return;
    try {
      final r = await InAppPurchase.instance.queryProductDetails(kPlayProductIds);
      _base.clear();
      _buy.clear();
      for (final d in r.productDetails) {
        if (d is GooglePlayProductDetails && d.subscriptionIndex != null) {
          final offers = d.productDetails.subscriptionOfferDetails;
          final offer = offers == null ? null : offers[d.subscriptionIndex!];
          final isBase = offer == null || offer.offerId == null;
          if (isBase) {
            _base[d.id] = d;
            _buy.putIfAbsent(d.id, () => d);
          } else {
            _buy[d.id] = d; // an offer Play says this buyer is eligible for
          }
        } else {
          _base[d.id] = d;
          _buy[d.id] = d;
        }
      }
      if (_buy.isEmpty) {
        unavailableReason = 'Subscriptions are not available in this build. Install NowssB from Google Play to subscribe.';
      } else {
        unavailableReason = null;
      }
    } catch (e) {
      unavailableReason = 'Could not reach Google Play. Check your connection and try again.';
    }
    notifyListeners();
  }

  static String accountHash(String uid) => sha256.convert(utf8.encode(uid)).toString();

  User? get _user {
    if (!NwsbFirebase.ready) return null;
    final u = FirebaseAuth.instance.currentUser;
    return (u == null || u.isAnonymous) ? null : u;
  }

  /// Buys (or switches to) [tier] monthly / yearly. Resolves when the server
  /// has confirmed it, or with the reason it did not happen.
  Future<PlayResult> buy(String tier, {required bool yearly}) async {
    await start();
    final plan = playPlanFor(tier, yearly: yearly);
    if (plan == null) return const PlayResult(false, 'Unknown plan.');
    final user = _user;
    if (user == null) return const PlayResult(false, 'Sign in first — your plan is saved to your NowssB account.');
    if (available != true) {
      return PlayResult(false, unavailableReason ?? 'Google Play Billing is not available on this device.');
    }
    if (_buy[plan.productId] == null) await loadProducts();
    final details = _buy[plan.productId];
    if (details == null) {
      return PlayResult(false, unavailableReason ?? '${plan.name} is not available on Google Play yet.');
    }
    if (busy) return const PlayResult(false, 'A purchase is already in progress.');
    busy = true;
    notifyListeners();
    try {
      GooglePlayPurchaseDetails? old;
      for (final p in _owned.values) {
        if (p.productID != plan.productId) old = p;
      }
      final offers = details is GooglePlayProductDetails ? details.productDetails.subscriptionOfferDetails : null;
      final idx = details is GooglePlayProductDetails ? details.subscriptionIndex : null;
      final param = GooglePlayPurchaseParam(
        productDetails: details,
        applicationUserName: accountHash(user.uid),
        offerToken: _offerToken(offers, idx),
        changeSubscriptionParam: old == null
            ? null
            : ChangeSubscriptionParam(oldPurchaseDetails: old, replacementMode: ReplacementMode.withTimeProration),
      );
      final done = Completer<PlayResult>();
      _waiting[plan.productId] = done;
      final launched = await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
      if (!launched) {
        _waiting.remove(plan.productId);
        return const PlayResult(false, 'Google Play did not open the purchase.');
      }
      return await done.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => const PlayResult(false, 'The purchase did not finish. If you were charged, tap Restore purchases.'),
      );
    } on PlatformException catch (e) {
      return PlayResult(false, 'Google Play could not start the purchase: ${e.message ?? e.code}');
    } catch (e) {
      return PlayResult(false, 'Google Play could not start the purchase: $e');
    } finally {
      _waiting.remove(plan.productId);
      busy = false;
      notifyListeners();
    }
  }

  /// The plan's base offer, or — while a friend's link holds this account —
  /// the Play offer tagged 'referral' on the same base plan (friend offer,
  /// set up in Play Console; the server's config names the tag).
  String? _offerToken(List<SubscriptionOfferDetailsWrapper>? offers, int? idx) {
    if (offers == null || idx == null || idx >= offers.length) return null;
    final base = offers[idx];
    final s = EconomyMirror.instance.summary;
    final ref = s['referral'];
    if (ref is Map && ref['held'] == true && ref['locked'] != true) {
      final cfg = s['config'] is Map ? (s['config'] as Map)['reference'] : null;
      final fd = cfg is Map ? cfg['friendDiscount'] : null;
      final tag = fd is Map ? '${fd['subscriptionOfferTag'] ?? 'referral'}' : 'referral';
      for (final o in offers) {
        if (o.basePlanId == base.basePlanId && o.offerTags.contains(tag)) return o.offerIdToken;
      }
    }
    return base.offerIdToken;
  }

  /// Re-sends every active Play subscription on this Google account to the
  /// server (new phone, reinstall, or a purchase that was never confirmed).
  Future<PlayResult> restore() async {
    await start();
    final user = _user;
    if (user == null) return const PlayResult(false, 'Sign in first, then restore.');
    if (available != true) {
      return PlayResult(false, unavailableReason ?? 'Google Play Billing is not available on this device.');
    }
    busy = true;
    notifyListeners();
    _restored = 0;
    _restoreErrors.clear();
    try {
      await InAppPurchase.instance.restorePurchases(applicationUserName: accountHash(user.uid));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      while (_inflight.isNotEmpty) {
        await Future.wait(List.of(_inflight));
      }
      if (_restored > 0) return const PlayResult(true, 'Your Google Play subscription is restored.');
      if (_restoreErrors.isNotEmpty) return PlayResult(false, _restoreErrors.first);
      return const PlayResult(false, 'No active NowssB subscription was found on this Google account.');
    } catch (e) {
      return PlayResult(false, 'Could not restore purchases: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  int _restored = 0;
  final List<String> _restoreErrors = [];

  void _resolve(String productId, PlayResult r) {
    final c = _waiting.remove(productId);
    if (c != null && !c.isCompleted) c.complete(r);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!kPlayProductIds.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _resolve(p.productID, const PlayResult(false,
              'Payment pending with Google Play. Your plan unlocks as soon as it goes through.', pending: true));
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _complete(p);
          _resolve(p.productID, const PlayResult(false, 'Purchase cancelled.'));
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) await _complete(p);
          _resolve(p.productID, PlayResult(false, _friendlyError(p.error)));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final f = _confirm(p);
          _inflight.add(f);
          unawaited(f.whenComplete(() => _inflight.remove(f)));
      }
    }
  }

  Future<void> _confirm(PurchaseDetails p) async {
    final r = await _verifyWithServer(p);
    if (r.ok) {
      if (p is GooglePlayPurchaseDetails) _owned[p.productID] = p;
      if (p.pendingCompletePurchase) await _complete(p);
      if (p.status == PurchaseStatus.restored) _restored++;
    } else if (p.status == PurchaseStatus.restored) {
      _restoreErrors.add(r.message);
    }
    _resolve(p.productID, r);
  }

  Future<void> _complete(PurchaseDetails p) async {
    try {
      await InAppPurchase.instance.completePurchase(p);
    } catch (e) {
      debugPrint('NowssB billing: completePurchase failed: $e');
    }
  }

  Future<PlayResult> _verifyWithServer(PurchaseDetails p) async {
    final user = _user;
    if (user == null) return const PlayResult(false, 'Sign in first — the purchase is kept by Google Play; tap Restore purchases after signing in.');
    try {
      final idToken = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse(kPlayVerifyUrl),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
            body: jsonEncode({
              'productId': p.productID,
              'purchaseToken': p.verificationData.serverVerificationData,
            }),
          )
          .timeout(const Duration(seconds: 40));
      Map<String, dynamic> body = const {};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}
      if (res.statusCode == 200 && body['ok'] == true) {
        _applyServer(body);
        final name = playPlanById('${body['productId'] ?? p.productID}')?.name ?? 'Your plan';
        return PlayResult(true, '$name is active. Thank you!');
      }
      if (res.statusCode == 202) {
        return const PlayResult(false, 'Payment pending with Google Play. Your plan unlocks as soon as it goes through.', pending: true);
      }
      if (res.statusCode == 501) {
        return const PlayResult(false, 'Purchases are not switched on yet. Nothing was unlocked; Google Play refunds an unconfirmed purchase automatically.');
      }
      final msg = '${body['error'] ?? 'Could not confirm the purchase (${res.statusCode}).'}';
      return PlayResult(false, msg);
    } on TimeoutException {
      return const PlayResult(false, 'The server did not answer. Tap Restore purchases in a moment.');
    } catch (e) {
      return const PlayResult(false, 'Could not reach NowssB to confirm the purchase. Tap Restore purchases when you are online.');
    }
  }

  void _applyServer(Map<String, dynamic> body) {
    final tier = '${body['tier'] ?? ''}';
    if (_tiers.contains(tier)) {
      _tier = tier;
      _until = DateTime.tryParse('${body['subscriptionEndDate'] ?? ''}');
      _source = 'play';
      notifyListeners();
    }
  }

  String _friendlyError(IAPError? e) {
    final m = (e?.message ?? '').toLowerCase();
    if (m.contains('not configured for billing') || m.contains('developer_error') || m.contains('developererror')) {
      return 'This copy of NowssB cannot buy through Google Play. Install NowssB from Google Play to subscribe.';
    }
    if (m.contains('already') && m.contains('own')) {
      return 'You already have this subscription. Tap Restore purchases.';
    }
    if (m.contains('unavailable') || m.contains('service')) {
      return 'Google Play is not available right now. Try again in a moment.';
    }
    return e?.message.isNotEmpty == true ? 'Google Play: ${e!.message}' : 'Google Play could not complete the purchase.';
  }

  void _watchEntitlement() {
    if (!NwsbFirebase.ready) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _userSub?.cancel();
      _userSub = null;
      _tier = null;
      _until = null;
      _source = '';
      _owned.clear();
      notifyListeners();
      if (u == null || u.isAnonymous) return;
      _userSub = FirebaseFirestore.instance.doc('users/${u.uid}').snapshots().listen((snap) {
        final d = snap.data() ?? const <String, dynamic>{};
        final tier = '${d['tier'] ?? ''}';
        final pro = d['isPro'] == true;
        _tier = pro && _tiers.contains(tier) ? tier : null;
        final end = d['subscriptionEndDate'];
        _until = end is Timestamp ? end.toDate() : DateTime.tryParse('${end ?? ''}');
        _source = '${d['subscriptionSource'] ?? ''}';
        notifyListeners();
      }, onError: (Object e) => debugPrint('NowssB entitlement watch: $e'));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
