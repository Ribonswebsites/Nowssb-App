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
  EconomyException(this.message);
  final String message;
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

  static const tiers = [49, 99, 149, 199, 249, 299, 399, 499, 699, 999];

  static const catalogPrices = <String, int>{
    'nwsb_sub_resonance': 249,
    'nwsb_sub_frequency': 499,
    'nwsb_sub_frequency_x': 999,
    'nwsb_word': 49,
    'nwsb_meaning': 49,
    'nwsb_bundle_10': 490,
    'nwsb_package': 199,
    'nwsb_streak_restore': 99,
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
      throw EconomyException(e.message ?? e.code);
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
  String sellerTier = 'Seller';
  int wordsSold = 0;
  int nextSellerTarget = 100;
  bool live = false;
  String? uid;

  StreamSubscription<User?>? _auth;
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _docs = [];

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
      cash = 0;
      plan = 'Free';
      code = '';
      notifyListeners();
      return;
    }
    try {
      await EconomyApi.call('ensureEconomyProfile', {
        'installId': await EconomyApi.installId(),
      });
    } catch (e) {
      debugPrint('ensureEconomyProfile: $e');
    }
    final id = user.uid;
    _watch('users/$id/wallet/main', (data) {
      coins = (data['coins'] as num?)?.toInt() ?? 0;
      plan = (data['plan'] as String?)?.isNotEmpty == true ? data['plan'] as String : 'Free';
      streak = (data['streak'] as num?)?.toInt() ?? 0;
      freezesLeft = (data['freezesLeft'] as num?)?.toInt() ?? 2;
      practice = (data['practice'] as num?)?.toInt() ?? 0;
      playerOpens = (data['playerOpens'] as num?)?.toInt() ?? 0;
      purchases = (data['purchases'] as num?)?.toInt() ?? 0;
      practiceCredits = (data['practiceCredits'] as num?)?.toInt() ?? 0;
    });
    _watch('users/$id/payout/main', (data) {
      cash = (data['cashBalance'] as num?)?.toInt() ?? 0;
    });
    _watch('users/$id/referral/main', (data) {
      code = (data['code'] as String?) ?? '';
      referredBy = (data['referredBy'] as String?) ?? '';
      circleTier = (data['tier'] as String?) ?? 'Member';
      paidReferrals = (data['paidReferralCount'] as num?)?.toInt() ?? 0;
    });
    _watch('users/$id/sellerStats/main', (data) {
      sellerTier = (data['tier'] as String?) ?? 'Seller';
      wordsSold = (data['wordsSoldTotal'] as num?)?.toInt() ?? 0;
      nextSellerTarget = (data['nextTierTarget'] as num?)?.toInt() ?? 100;
    });
  }

  void _watch(String path, void Function(Map<String, dynamic> data) apply) {
    _docs.add(FirebaseFirestore.instance.doc(path).snapshots().listen((snap) {
      apply(snap.data() ?? {});
      notifyListeners();
    }));
  }
}
