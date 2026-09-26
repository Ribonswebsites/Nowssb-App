/// NowssB Coins, resale, and referral ledger.
///
/// Everything here is stored on the phone. When Firebase is already up, the
/// referral code is also written so another phone can pay this profile.
/// No extra API key. Charging a card or UPI still needs a payment key —
/// the cash share is recorded the same way Store checkout already records
/// an order.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_bag.dart';
import 'firebase.dart';
import 'practice_progress.dart';

class EarnActivity {
  EarnActivity({required this.at, required this.title, required this.detail, required this.coins});
  final int at;
  final String title;
  final String detail;
  final int coins;

  Map<String, dynamic> toJson() => {'at': at, 'title': title, 'detail': detail, 'coins': coins};
  static EarnActivity fromJson(Map<String, dynamic> m) => EarnActivity(
        at: (m['at'] as num?)?.toInt() ?? 0,
        title: '${m['title'] ?? ''}',
        detail: '${m['detail'] ?? ''}',
        coins: (m['coins'] as num?)?.toInt() ?? 0,
      );
}

class OwnedPiece {
  OwnedPiece({required this.id, required this.title, required this.kind, required this.price, this.image = ''});
  final String id;
  final String title;
  final String kind;
  final num price;
  final String image;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'kind': kind, 'price': price, 'image': image};
  static OwnedPiece fromJson(Map<String, dynamic> m) => OwnedPiece(
        id: '${m['id'] ?? ''}',
        title: '${m['title'] ?? ''}',
        kind: '${m['kind'] ?? 'Word'}',
        price: m['price'] is num ? m['price'] as num : num.tryParse('${m['price']}') ?? 0,
        image: '${m['image'] ?? ''}',
      );
}

class ResaleListing {
  ResaleListing({
    required this.id,
    required this.title,
    required this.kind,
    required this.price,
    required this.image,
    required this.at,
  });
  final String id;
  final String title;
  final String kind;
  final num price;
  final String image;
  final int at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'price': price,
        'image': image,
        'at': at,
      };
  static ResaleListing fromJson(Map<String, dynamic> m) => ResaleListing(
        id: '${m['id'] ?? ''}',
        title: '${m['title'] ?? ''}',
        kind: '${m['kind'] ?? 'Word'}',
        price: m['price'] is num ? m['price'] as num : 0,
        image: '${m['image'] ?? ''}',
        at: (m['at'] as num?)?.toInt() ?? 0,
      );
}

class PromoPost {
  PromoPost({required this.at, required this.title, required this.body});
  final int at;
  final String title;
  final String body;
  Map<String, dynamic> toJson() => {'at': at, 'title': title, 'body': body};
  static PromoPost fromJson(Map<String, dynamic> m) => PromoPost(
        at: (m['at'] as num?)?.toInt() ?? 0,
        title: '${m['title'] ?? ''}',
        body: '${m['body'] ?? ''}',
      );
}

class CoinQuote {
  const CoinQuote({required this.price, required this.maxCoins, required this.coins, required this.cash});
  final num price;
  final int maxCoins;
  final int coins;
  final num cash;
}

class EarnPlan {
  const EarnPlan(this.name, this.rupees);
  final String name;
  final int rupees;
}

class EarnWallet extends ChangeNotifier {
  EarnWallet._();
  static final EarnWallet instance = EarnWallet._();

  static const plans = <EarnPlan>[
    EarnPlan('Resonance', 249),
    EarnPlan('Frequency', 499),
    EarnPlan('Frequency X', 999),
  ];
  static const restorePrice = 99;
  static const maxCoinFraction = 0.30;

  static const _key = 'nwsb_earn_wallet_v1';

  int coins = 0;
  String code = '';
  String plan = 'Free';
  int wordsSold = 0;
  int posts = 0;
  int referralSubs = 0;
  bool playerOpened = false;
  bool welcomePaid = false;
  bool streak10Paid = false;
  bool termsAccepted = false;
  int lastLoginYmd = 0;
  int streakPaidYmd = 0;
  String referredBy = '';
  final List<EarnActivity> activity = [];
  final List<OwnedPiece> owned = [];
  final List<ResaleListing> listings = [];
  final List<PromoPost> promoPosts = [];
  final List<String> inviteCodes = [];
  final Set<String> usedCodes = {};
  bool _ready = false;

  bool get ready => _ready;

  int get commissionPercent {
    var base = 5;
    if (wordsSold >= 1000) {
      base = 20;
    } else if (wordsSold >= 500) {
      base = 15;
    } else if (wordsSold >= 300) {
      base = 12;
    } else if (wordsSold >= 100) {
      base = 8;
    }
    final postBoost = min(5, posts ~/ 20);
    return base + postBoost;
  }

  String get rank {
    if (wordsSold >= 1000) return '1,000';
    if (wordsSold >= 500) return '500';
    if (wordsSold >= 300) return '300';
    if (wordsSold >= 100) return '100';
    return 'Starter';
  }

  int get nextTarget {
    if (wordsSold < 100) return 100;
    if (wordsSold < 300) return 300;
    if (wordsSold < 500) return 500;
    if (wordsSold < 1000) return 1000;
    return 1000;
  }

  CoinQuote quote(num price) {
    final whole = price.round();
    final cap = (whole * maxCoinFraction).floor();
    final use = min(cap, coins);
    final cash = whole - use;
    return CoinQuote(price: whole, maxCoins: cap, coins: use, cash: cash < 0 ? 0 : cash);
  }

  Future<void> start() async {
    if (_ready) return;
    _ready = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw);
        if (m is Map) _read(Map<String, dynamic>.from(m));
      }
    } catch (_) {}
    if (code.isEmpty) code = _makeCode();
    PracticeProgress.instance.addListener(_onStreak);
    await PracticeProgress.instance.start();
    _onStreak();
    notifyListeners();
    await _persist();
    await _pullFirebaseRewards();
  }

  void _read(Map<String, dynamic> m) {
    coins = (m['coins'] as num?)?.toInt() ?? 0;
    code = '${m['code'] ?? ''}';
    plan = '${m['plan'] ?? 'Free'}';
    wordsSold = (m['wordsSold'] as num?)?.toInt() ?? 0;
    posts = (m['posts'] as num?)?.toInt() ?? 0;
    referralSubs = (m['referralSubs'] as num?)?.toInt() ?? 0;
    playerOpened = m['playerOpened'] == true;
    welcomePaid = m['welcomePaid'] == true;
    streak10Paid = m['streak10Paid'] == true;
    termsAccepted = m['termsAccepted'] == true;
    lastLoginYmd = (m['lastLoginYmd'] as num?)?.toInt() ?? 0;
    streakPaidYmd = (m['streakPaidYmd'] as num?)?.toInt() ?? 0;
    referredBy = '${m['referredBy'] ?? ''}';
    activity
      ..clear()
      ..addAll([
        for (final e in (m['activity'] as List? ?? const []))
          if (e is Map) EarnActivity.fromJson(Map<String, dynamic>.from(e)),
      ]);
    owned
      ..clear()
      ..addAll([
        for (final e in (m['owned'] as List? ?? const []))
          if (e is Map) OwnedPiece.fromJson(Map<String, dynamic>.from(e)),
      ]);
    listings
      ..clear()
      ..addAll([
        for (final e in (m['listings'] as List? ?? const []))
          if (e is Map) ResaleListing.fromJson(Map<String, dynamic>.from(e)),
      ]);
    promoPosts
      ..clear()
      ..addAll([
        for (final e in (m['postsList'] as List? ?? const []))
          if (e is Map) PromoPost.fromJson(Map<String, dynamic>.from(e)),
      ]);
    inviteCodes
      ..clear()
      ..addAll([
        for (final e in (m['inviteCodes'] as List? ?? const [])) '$e',
      ]);
    usedCodes
      ..clear()
      ..addAll([
        for (final e in (m['usedCodes'] as List? ?? const [])) '$e',
      ]);
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode({
        'coins': coins,
        'code': code,
        'plan': plan,
        'wordsSold': wordsSold,
        'posts': posts,
        'referralSubs': referralSubs,
        'playerOpened': playerOpened,
        'welcomePaid': welcomePaid,
        'streak10Paid': streak10Paid,
        'termsAccepted': termsAccepted,
        'lastLoginYmd': lastLoginYmd,
        'streakPaidYmd': streakPaidYmd,
        'referredBy': referredBy,
        'activity': activity.map((e) => e.toJson()).toList(),
        'owned': owned.map((e) => e.toJson()).toList(),
        'listings': listings.map((e) => e.toJson()).toList(),
        'postsList': promoPosts.map((e) => e.toJson()).toList(),
        'inviteCodes': inviteCodes,
        'usedCodes': usedCodes.toList(),
      }));
    } catch (_) {}
    notifyListeners();
    await _mirror();
  }

  void _log(String title, String detail, int delta) {
    activity.insert(0, EarnActivity(
      at: DateTime.now().millisecondsSinceEpoch,
      title: title,
      detail: detail,
      coins: delta,
    ));
    if (activity.length > 40) activity.removeRange(40, activity.length);
  }

  Future<void> _grant(int amount, String title, String detail) async {
    if (amount == 0) return;
    coins += amount;
    if (coins < 0) coins = 0;
    _log(title, detail, amount);
    await _persist();
  }

  Future<bool> _spend(int amount, String title, String detail) async {
    if (amount <= 0) return true;
    if (coins < amount) return false;
    coins -= amount;
    _log(title, detail, -amount);
    await _persist();
    return true;
  }

  Future<void> onSignedIn() async {
    if (!_ready) await start();
    final day = _ymd(DateTime.now());
    if (lastLoginYmd == day && welcomePaid) return;
    var changed = false;
    if (!welcomePaid) {
      welcomePaid = true;
      coins += 25;
      _log('Login complete', 'First full sign-in', 25);
      changed = true;
    }
    if (lastLoginYmd != day) {
      lastLoginYmd = day;
      coins += 10;
      _log('Daily sign-in', 'Opened the app signed in', 10);
      changed = true;
    }
    if (changed) await _persist();
  }

  void _onStreak() {
    final streak = PracticeProgress.instance.streak;
    final day = _ymd(DateTime.now());
    var changed = false;
    if (streak >= 1 && streakPaidYmd != day) {
      streakPaidYmd = day;
      coins += 10;
      _log('1-day streak', 'Streak is $streak', 10);
      changed = true;
    }
    if (streak >= 10 && !streak10Paid) {
      streak10Paid = true;
      coins += 100;
      _log('10-day streak', 'Ten days in a row', 100);
      changed = true;
    }
    if (changed) {
      _persist();
    }
  }

  Future<void> onPlayerOpened() async {
    if (!_ready) await start();
    if (playerOpened) return;
    playerOpened = true;
    coins += 25;
    _log('Player opened', 'First time in the practice player', 25);
    await _persist();
  }

  Future<void> onStoreOrder(BagOrder order) async {
    if (!_ready) await start();
    var words = 0;
    var meanings = 0;
    var bundles = 0;
    for (final item in order.items) {
      final kind = item.kind.toLowerCase();
      final qty = item.qty <= 0 ? 1 : item.qty;
      if (kind.contains('bundle') || kind.contains('package')) {
        bundles += qty;
      } else if (kind.contains('meaning')) {
        meanings += qty;
      } else if (kind.contains('word') || kind.contains('signature')) {
        words += qty;
      }
      if (!owned.any((o) => o.id == item.id)) {
        owned.insert(0, OwnedPiece(
          id: item.id,
          title: item.title,
          kind: item.kind,
          price: item.price,
          image: item.image,
        ));
      }
    }
    var bonus = words * 8 + meanings * 8 + (bundles > 0 ? 40 : 0);
    if (words >= 10) bonus += 50;
    if (bonus > 0) {
      coins += bonus;
      _log(
        'Purchase',
        '$words word${words == 1 ? '' : 's'} · $meanings meaning${meanings == 1 ? '' : 's'}',
        bonus,
      );
    } else {
      _log('Order ${order.id}', order.payMethod, 0);
    }
    await _persist();
  }

  Future<String?> pay({
    required String title,
    required num price,
    required bool useCoins,
    String kind = 'Word',
    String id = '',
    String image = '',
  }) async {
    if (!_ready) await start();
    final q = quote(price);
    final spend = useCoins ? q.coins : 0;
    if (spend > coins) return 'Not enough NowssB Coins.';
    if (spend > 0) coins -= spend;
    final pieceId = id.isEmpty ? 'buy:${title.toLowerCase()}' : id;
    final skipOwn = kind == 'Subscription' ||
        kind == 'Streak' ||
        kind == 'Bundle' ||
        kind == 'Package';
    if (!skipOwn && !owned.any((o) => o.id == pieceId)) {
      owned.insert(0, OwnedPiece(
        id: pieceId,
        title: title,
        kind: kind,
        price: price,
        image: image,
      ));
    }
    if (kind == 'Subscription') {
      plan = title;
      await _payReferrer(price.round());
    }
    final cash = price.round() - spend;
    _log(
      title,
      spend == 0
          ? 'Cash ₹${price.round()} recorded'
          : '₹$spend coins · ₹${cash < 0 ? 0 : cash} cash recorded',
      -spend,
    );
    final bonus = _purchaseBonus(kind, id, title);
    if (bonus > 0) {
      coins += bonus;
      _log('Purchase bonus', title, bonus);
    }
    await _persist();
    return null;
  }

  int _purchaseBonus(String kind, String id, String title) {
    final k = kind.toLowerCase();
    if (k == 'word' || k == 'meaning') return 8;
    if (k == 'package') return 40;
    if (k == 'bundle') {
      final ten = id == 'bundle:10' || title.toLowerCase().contains('10');
      return ten ? 90 : 40;
    }
    return 0;
  }

  Future<void> rememberOwned(List<OwnedPiece> pieces) async {
    if (!_ready) await start();
    var changed = false;
    for (final piece in pieces) {
      if (piece.id.isEmpty || owned.any((o) => o.id == piece.id)) continue;
      owned.insert(0, piece);
      changed = true;
    }
    if (changed) await _persist();
  }

  /// Spends up to 30% of [total] and returns how many coins were taken.
  Future<int> reserveCheckoutCoins(num total, {required bool use}) async {
    if (!_ready) await start();
    if (!use) return 0;
    final q = quote(total);
    if (q.coins <= 0) return 0;
    final ok = await _spend(
      q.coins,
      'Coins on checkout',
      '30% of ₹${q.price} · cash still ₹${q.cash}',
    );
    return ok ? q.coins : 0;
  }

  Future<String?> mintInviteCode() async {
    if (!_ready) await start();
    if (inviteCodes.length >= 20) return 'You already have 20 invite codes.';
    var next = _makeCode();
    var guard = 0;
    while ((next == code || inviteCodes.contains(next)) && guard < 8) {
      next = _makeCode();
      guard++;
    }
    inviteCodes.insert(0, next);
    _log('Invite code', next, 0);
    await _persist();
    return null;
  }

  Future<String?> restoreStreak({required bool useCoins}) async {
    final q = quote(restorePrice);
    final err = await pay(title: 'Streak restore', price: restorePrice, useCoins: useCoins, kind: 'Streak');
    if (err != null) return err;
    final ok = await PracticeProgress.instance.restoreBrokenStreak();
    if (!ok) {
      coins += useCoins ? q.coins : 0;
      _log('Streak already intact', 'Yesterday is already practiced. Coins returned.', useCoins ? q.coins : 0);
      await _persist();
      return 'Yesterday is already on your streak. Nothing to restore.';
    }
    _onStreak();
    return null;
  }

  Future<void> acceptTerms() async {
    termsAccepted = true;
    await _persist();
  }

  Future<String?> listForSale(OwnedPiece piece, num price) async {
    if (!termsAccepted) return 'Accept the resell terms first.';
    if (price < 1) return 'Set a price.';
    if (listings.any((l) => l.id == piece.id)) return 'Already listed.';
    listings.insert(0, ResaleListing(
      id: piece.id,
      title: piece.title,
      kind: piece.kind,
      price: price,
      image: piece.image,
      at: DateTime.now().millisecondsSinceEpoch,
    ));
    _log('Listed ${piece.title}', 'Resell shop · ₹${price.round()}', 0);
    await _persist();
    return null;
  }

  Future<String?> confirmSale(String id) async {
    final i = listings.indexWhere((l) => l.id == id);
    if (i < 0) return 'That listing is gone.';
    final listing = listings.removeAt(i);
    owned.removeWhere((o) => o.id == id);
    wordsSold += 1;
    final cut = (listing.price * commissionPercent / 100).round();
    coins += cut;
    _log(
      'Sold ${listing.title}',
      '$commissionPercent% commission · rank $rank',
      cut,
    );
    await _persist();
    return null;
  }

  Future<void> addPost(String title, String body) async {
    final t = title.trim();
    final b = body.trim();
    if (t.isEmpty || b.isEmpty) return;
    promoPosts.insert(0, PromoPost(at: DateTime.now().millisecondsSinceEpoch, title: t, body: b));
    if (promoPosts.length > 30) promoPosts.removeRange(30, promoPosts.length);
    posts += 1;
    _log('Promo post', t, 0);
    await _persist();
  }

  Future<String> redeemCode(String raw) async {
    if (!_ready) await start();
    final entered = raw.trim().toUpperCase().replaceAll(' ', '');
    if (entered.length < 6) return 'Enter the full code.';
    if (entered == code || inviteCodes.contains(entered)) {
      return 'You cannot use your own code.';
    }
    if (referredBy.isNotEmpty) return 'A referral code is already on this profile.';
    referredBy = entered;
    usedCodes.add(entered);
    _log('Referral code', entered, 0);
    await _persist();
    if (!NwsbFirebase.ready) {
      return 'Code saved on this phone. Subscribe to pay your friend. They are credited when Firebase connects — no new key, the NowssB project is enough.';
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      final db = FirebaseFirestore.instance;
      final snap = await db.collection('earn_codes').doc(entered).get();
      if (!snap.exists) {
        return 'Code saved. It is not on Firebase yet, so your friend is paid when their phone syncs and you subscribe.';
      }
      final uid = '${snap.data()?['uid'] ?? ''}';
      if (uid.isEmpty || uid == user?.uid) {
        referredBy = '';
        await _persist();
        return 'That code is not someone else.';
      }
      return 'Code applied. Subscribe and your friend gets that plan free, or coins if they already have it.';
    } catch (e) {
      return 'Code saved here. Firebase refused the lookup ($e).';
    }
  }

  Future<void> _payReferrer(int price) async {
    if (referredBy.isEmpty || !NwsbFirebase.ready) return;
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection('earn_codes').doc(referredBy).get();
      if (!snap.exists) return;
      final uid = '${snap.data()?['uid'] ?? ''}';
      final me = FirebaseAuth.instance.currentUser?.uid;
      if (uid.isEmpty || uid == me) return;
      await db.collection('earn_profiles').doc(uid).set({
        'pendingHits': FieldValue.increment(1),
        'pendingPlan': plan,
        'pendingPrice': price,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _pullFirebaseRewards() async {
    if (!NwsbFirebase.ready) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('earn_profiles').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final hits = (data['pendingHits'] as num?)?.toInt() ?? 0;
      if (hits <= 0) return;
      final bought = '${data['pendingPlan'] ?? 'Resonance'}';
      final price = (data['pendingPrice'] as num?)?.toInt() ?? _planPrice(bought);
      for (var n = 0; n < hits; n++) {
        referralSubs += 1;
        final boughtRank = _planRank(bought);
        if (boughtRank > _planRank(plan)) {
          plan = bought;
          _log('Referral subscription', 'Free $bought — person $referralSubs', 0);
        } else {
          coins += price;
          _log('Referral coins', 'You already have $plan', price);
        }
        if (referralSubs >= 5) {
          final cut = (price * 0.20).round();
          coins += cut;
          _log('20% referral commission', 'Subscriber $referralSubs', cut);
        }
      }
      await db.collection('earn_profiles').doc(user.uid).set({
        'pendingHits': 0,
        'pendingPlan': '',
        'pendingPrice': 0,
      }, SetOptions(merge: true));
      await _persist();
    } catch (_) {}
  }

  Future<void> _mirror() async {
    if (!NwsbFirebase.ready) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || code.isEmpty) return;
      final db = FirebaseFirestore.instance;
      await db.collection('earn_codes').doc(code).set({
        'uid': user.uid,
        'plan': plan,
      }, SetOptions(merge: true));
      for (final extra in inviteCodes) {
        if (extra.isEmpty || extra == code) continue;
        await db.collection('earn_codes').doc(extra).set({
          'uid': user.uid,
          'plan': plan,
        }, SetOptions(merge: true));
      }
      await db.collection('earn_profiles').doc(user.uid).set({
        'code': code,
        'coins': coins,
        'plan': plan,
        'wordsSold': wordsSold,
        'posts': posts,
        'referralSubs': referralSubs,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  int _planPrice(String name) {
    for (final p in plans) {
      if (p.name == name) return p.rupees;
    }
    return 249;
  }

  int _planRank(String name) {
    if (name == 'Frequency X') return 3;
    if (name == 'Frequency') return 2;
    if (name == 'Resonance') return 1;
    return 0;
  }

  bool holdsPlan(String name) => _planRank(plan) >= _planRank(name) && _planRank(name) > 0;

  static int _ymd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static String _makeCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    final body = List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    return 'NSB$body';
  }
}
