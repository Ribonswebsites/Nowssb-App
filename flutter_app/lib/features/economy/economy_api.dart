/// Server economy. Balances change only inside Cloud Functions.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';

class EconomyException implements Exception {
  EconomyException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

class CashQuote {
  const CashQuote({
    required this.productId,
    required this.cash,
    required this.coins,
    this.catalogId,
  });

  final String productId;
  final int cash;
  final int coins;
  final String? catalogId;

  static const tiers = [99, 199, 299, 399, 499, 699, 999, 1499, 1999];

  static const catalogPrices = <String, int>{
    'nwsb_sub_resonance': 499,
    'nwsb_sub_frequency': 999,
    'nwsb_sub_frequency_x': 1999,
    'nwsb_word': 99,
    'nwsb_meaning': 99,
    'nwsb_bundle_10': 999,
    'nwsb_package': 399,
    'nwsb_streak_restore': 199,
  };

  /// Smallest Play cash tier that leaves at most 30% for coins.
  static CashQuote forPrice({
    required int price,
    required int balance,
    String? catalogId,
  }) {
    final cap = (price * 0.3).floor();
    final maxCoins = min(cap, max(0, balance));
    final minCash = price - maxCoins;
    int? best;
    for (final tier in tiers) {
      if (tier >= minCash && tier <= price) {
        best = tier;
        break;
      }
    }
    if (best != null && price - best > 0) {
      return CashQuote(
        productId: 'nwsb_cash_$best',
        cash: best,
        coins: price - best,
        catalogId: catalogId,
      );
    }
    if (catalogId != null && catalogPrices[catalogId] == price) {
      return CashQuote(productId: catalogId, cash: price, coins: 0, catalogId: catalogId);
    }
    final tier = tiers.firstWhere((t) => t >= price, orElse: () => tiers.last);
    return CashQuote(
      productId: 'nwsb_cash_$tier',
      cash: tier,
      coins: 0,
      catalogId: catalogId,
    );
  }
}

class EconomyApi {
  EconomyApi._();

  static FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  static Future<String> installId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('nwsb_install_id');
    if (saved != null && saved.isNotEmpty) return saved;
    final next = '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 32)}';
    await prefs.setString('nwsb_install_id', next);
    return next;
  }

  static Future<Map<String, dynamic>> call(String name, [Map<String, dynamic>? data]) async {
    if (!NwsbFirebase.ready) {
      throw EconomyException('Firebase is not connected on this build.');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw EconomyException('Sign in first. Coins and payouts stay on your account.');
    }
    try {
      final result = await _fn.httpsCallable(name).call(data ?? const {});
      final raw = result.data;
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      return {'ok': true};
    } on FirebaseFunctionsException catch (e) {
      throw EconomyException(_friendly(e), code: e.code);
    } catch (_) {
      throw EconomyException('That did not go through. Try again.');
    }
  }

  static String _friendly(FirebaseFunctionsException e) {
    final raw = e.message ?? '';
    if (raw.contains('Play Billing verification') || raw.contains('PLAY_SERVICE_ACCOUNT')) {
      return 'Play purchases are not switched on yet. Nothing was credited.';
    }
    if (raw.contains('Exception') || raw.contains('firebase') || raw.contains('INTERNAL')) {
      return 'That did not go through. Try again.';
    }
    switch (e.code) {
      case 'unauthenticated':
        return 'Sign in to continue.';
      case 'permission-denied':
        return 'That account cannot do this.';
      case 'not-found':
        return 'Saved on this phone.';
      case 'already-exists':
      case 'failed-precondition':
      case 'resource-exhausted':
      case 'invalid-argument':
        return raw.isEmpty ? 'That did not go through. Try again.' : raw;
      default:
        return 'That did not go through. Try again.';
    }
  }

  static bool isMissing(EconomyException e) {
    final code = e.code ?? '';
    final msg = e.message.toUpperCase();
    return code == 'not-found' || msg.contains('NOT_FOUND') || msg.contains('NOT FOUND');
  }

  /// Today's coins. If the callable is not deployed, the wallet still
  /// moves on this phone so the coin flight can play after the tap.
  static Future<int> claimToday() async {
    try {
      final result = await call('claimDailyLogin');
      return (result['coins'] as num?)?.toInt() ?? 0;
    } on EconomyException catch (e) {
      if (!isMissing(e)) rethrow;
      return EconomyMirror.instance.grantOnce('daily', 10);
    }
  }
}

class EconomyMirror extends ChangeNotifier {
  EconomyMirror._();
  static final instance = EconomyMirror._();

  int coins = 0;
  int cash = 0;
  String plan = 'Free';
  int streak = 0;
  int freezesLeft = 2;
  int practice = 0;
  int playerOpens = 0;
  int purchases = 0;
  int practiceCredits = 0;
  String code = '';
  String referredBy = '';
  String circleTier = 'Member';
  int paidReferrals = 0;
  int unitsSold = 0;
  String sellerTier = 'Seller';
  int wordsSold = 0;
  int nextSellerTarget = 100;
  int subUntil = 0;
  int lifetimeCents = 0;
  bool subscriptionActive = false;
  bool hasSeenEarn = false;
  int unread = 0;
  String upi = '';
  String country = '';
  String payoutRail = '';
  int partnerPoints = 0;
  String partnerPerk = '';
  bool loginToday = false;
  bool scratchToday = false;
  bool capsReady = false;
  bool live = false;
  String? uid;
  int _serverCoins = 0;
  int _localBonus = 0;

  StreamSubscription<User?>? _auth;
  final List<StreamSubscription<dynamic>> _docs = [];

  Future<void> start() async {
    if (!NwsbFirebase.ready || _auth != null) return;
    _auth = FirebaseAuth.instance.authStateChanges().listen(_bind);
  }

  Future<void> _bind(User? user) async {
    for (final sub in _docs) {
      await sub.cancel();
    }
    _docs.clear();
    uid = user?.uid;
    live = user != null;
    if (user == null) {
      coins = 0;
      _serverCoins = 0;
      _localBonus = 0;
      cash = 0;
      plan = 'Free';
      code = '';
      loginToday = false;
      scratchToday = false;
      capsReady = false;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final day = _todayKey();
    _localBonus = prefs.getInt('nwsb_local_delta_${user.uid}') ??
        prefs.getInt('nwsb_local_bonus_${user.uid}_$day') ??
        (prefs.getBool('nwsb_local_daily_${user.uid}_$day') == true ? 10 : 0);
    loginToday = prefs.getBool('nwsb_grant_${user.uid}_${day}_daily') == true ||
        prefs.getBool('nwsb_local_daily_${user.uid}_$day') == true;
    scratchToday = prefs.getBool('nwsb_grant_${user.uid}_${day}_scratch') == true;
    coins = _serverCoins + _localBonus;
    try {
      await EconomyApi.call('ensureEconomyProfile', {
        'installId': await EconomyApi.installId(),
      });
    } catch (e) {
      debugPrint('ensureEconomyProfile: $e');
    }
    final id = user.uid;
    _watch('users/$id/wallet/main', (data) {
      _serverCoins = (data['coins'] as num?)?.toInt() ?? 0;
      coins = _serverCoins + _localBonus;
      plan = (data['plan'] as String?)?.isNotEmpty == true ? data['plan'] as String : 'Free';
      streak = (data['streak'] as num?)?.toInt() ?? 0;
      freezesLeft = (data['freezesLeft'] as num?)?.toInt() ?? 2;
      practice = (data['practice'] as num?)?.toInt() ?? 0;
      playerOpens = (data['playerOpens'] as num?)?.toInt() ?? 0;
      purchases = (data['purchases'] as num?)?.toInt() ?? 0;
      practiceCredits = (data['practiceCredits'] as num?)?.toInt() ?? 0;
      subUntil = (data['subUntil'] as num?)?.toInt() ?? 0;
    });
    _watch('users/$id/payout/main', (data) {
      cash = (data['cashBalance'] as num?)?.toInt() ?? 0;
      lifetimeCents = (data['lifetimeCents'] as num?)?.toInt() ?? 0;
      upi = (data['upi'] as String?) ?? '';
      country = (data['country'] as String?) ?? '';
      payoutRail = (data['payoutRail'] as String?) ?? '';
    });
    _watch('users/$id/partner/main', (data) {
      partnerPoints = (data['points'] as num?)?.toInt() ?? 0;
      partnerPerk = (data['perk'] as String?) ?? '';
    });
    _watch('users/$id/earnCaps/${_todayKey()}', (data) {
      final serverLogin = data['login'] == true;
      loginToday = serverLogin || loginToday;
      scratchToday = data['scratch'] == true || scratchToday;
      capsReady = true;
    });
    _watch('users/$id/referral/main', (data) {
      code = (data['code'] as String?) ?? '';
      referredBy = (data['referredBy'] as String?) ?? '';
      circleTier = (data['tier'] as String?) ?? 'Member';
      paidReferrals = (data['paidReferralCount'] as num?)?.toInt() ?? 0;
      unitsSold = (data['unitsSold'] as num?)?.toInt() ?? paidReferrals;
      subscriptionActive = data['subscriptionActive'] == true;
    });
    _watch('users/$id/sellerStats/main', (data) {
      sellerTier = (data['tier'] as String?) ?? 'Seller';
      wordsSold = (data['wordsSoldTotal'] as num?)?.toInt() ?? 0;
      nextSellerTarget = (data['nextTierTarget'] as num?)?.toInt() ?? 100;
    });
    _watch('users/$id/prefs/earn', (data) {
      hasSeenEarn = data['hasSeenEarnCard'] == true;
    });
    _docs.add(
      FirebaseFirestore.instance
          .collection('users/$id/notifications')
          .where('read', isEqualTo: false)
          .limit(20)
          .snapshots()
          .listen((snap) {
        unread = snap.size;
        notifyListeners();
      }),
    );
  }

  bool get subscribed =>
      plan != 'Free' && subUntil > DateTime.now().millisecondsSinceEpoch && subscriptionActive;

  String _todayKey() {
    final n = DateTime.now().toUtc();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}$m$d';
  }

  /// One local grant per key per day. The cloud function stays the source of
  /// truth when it exists. This only runs when that function is not deployed.
  Future<int> grantOnce(String key, int amount, {bool daily = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final id = daily
        ? 'nwsb_grant_${uid ?? 'local'}_${_todayKey()}_$key'
        : 'nwsb_grant_${uid ?? 'local'}_once_$key';
    if (prefs.getBool(id) == true) {
      if (key == 'daily') loginToday = true;
      if (key == 'scratch') scratchToday = true;
      notifyListeners();
      return 0;
    }
    await prefs.setBool(id, true);
    _localBonus += amount;
    coins = _serverCoins + _localBonus;
    await prefs.setInt('nwsb_local_delta_${uid ?? 'local'}', _localBonus);
    if (key == 'daily') {
      loginToday = true;
      if (streak < 1) streak = 1;
      await prefs.setBool('nwsb_local_daily_${uid ?? 'local'}_${_todayKey()}', true);
    }
    if (key == 'scratch') scratchToday = true;
    notifyListeners();
    return amount;
  }

  /// Local coin spend when Play/server spend is not deployed.
  Future<bool> spendLocal(int cost) async {
    if (cost <= 0 || coins < cost) return false;
    final prefs = await SharedPreferences.getInstance();
    _localBonus -= cost;
    coins = _serverCoins + _localBonus;
    await prefs.setInt('nwsb_local_delta_${uid ?? 'local'}', _localBonus);
    notifyListeners();
    return true;
  }

  void addPartnerPoints(int add) {
    if (add <= 0) return;
    partnerPoints += add;
    notifyListeners();
  }

  Future<int> grantLocalDaily() => grantOnce('daily', 10);

  void _watch(String path, void Function(Map<String, dynamic> data) apply) {
    _docs.add(FirebaseFirestore.instance.doc(path).snapshots().listen((snap) {
      apply(snap.data() ?? {});
      notifyListeners();
    }, onError: (_) {}));
  }
}
