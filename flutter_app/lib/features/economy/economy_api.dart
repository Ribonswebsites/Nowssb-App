/// Server economy. Balances change only on the server: Cloudflare Pages
/// Functions at https://nowssb.com/api/economy/<action> (Firebase stays on
/// the free Spark plan — Auth + Firestore + rules, no Cloud Functions).
library;

import '../../data/app_control.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';

class EconomyException implements Exception {
  EconomyException(this.message, {this.code, this.extra = const {}});
  final String message;
  final String? code;
  final Map<String, dynamic> extra;
  @override
  String toString() => message;
}

class EconomyApi {
  EconomyApi._();

  /// The Pages Function router (functions/api/economy/[action].js).
  static const base = 'https://nowssb.com/api/economy/';

  /// True after a 501: the server is waiting for its Firebase service
  /// account in Cloudflare. The app shows a calm "switching on" state.
  static final ValueNotifier<bool> switchingOn = ValueNotifier(false);

  static const switchingOnMessage =
      'Rewards are switching on. Nothing was lost — your coins and gifts start counting as soon as it is live.';

  static Future<String> installId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('nwsb_install_id');
    if (saved != null && saved.isNotEmpty) return saved;
    final next = '${DateTime.now().microsecondsSinceEpoch}${Random.secure().nextInt(1 << 32)}';
    await prefs.setString('nwsb_install_id', next);
    return next;
  }

  /// POST an action with the signed-in user's Firebase ID token.
  static Future<Map<String, dynamic>> call(String name, [Map<String, dynamic>? data]) async {
    if (!NwsbFirebase.ready) {
      throw EconomyException('Firebase is not connected on this build.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw EconomyException('Sign in first. Coins and payouts stay on your account.', code: 'unauthenticated');
    }
    // Admin console blocks, restrictions and feature flags (data/app_control.dart).
    final stop = AppControl.instance.blockForEconomy(name);
    if (stop != null) throw EconomyException(stop, code: 'restricted');
    http.Response res;
    try {
      final token = await user.getIdToken();
      res = await http
          .post(
            Uri.parse('$base$name'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode(data ?? const {}),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw EconomyException('The network is slow. Nothing was lost — try again.', code: 'timeout');
    } catch (_) {
      throw EconomyException('You look offline. Nothing was lost — try again.', code: 'offline');
    }
    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) body = decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    if (res.statusCode == 501) {
      switchingOn.value = true;
      throw EconomyException(switchingOnMessage, code: 'not-configured');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (switchingOn.value) switchingOn.value = false;
      EconomyMirror.instance._afterAction(name, body);
      return body;
    }
    final code = '${body['code'] ?? ''}';
    final message = '${body['error'] ?? ''}';
    if (res.statusCode == 401) throw EconomyException('Sign in again to continue.', code: 'unauthenticated');
    if (res.statusCode >= 500 || message.isEmpty) {
      throw EconomyException('That did not go through. Try again.', code: code.isEmpty ? 'internal' : code);
    }
    throw EconomyException(message, code: code.isEmpty ? 'failed-precondition' : code, extra: body);
  }

  /// The server is not switched on yet (Cloudflare is missing its key).
  static bool isMissing(EconomyException e) => e.code == 'not-configured';

  /// Today's login coins (server streak). 0 when already claimed.
  static Future<int> claimToday() async {
    final result = await call('claimDailyLogin');
    return (result['coins'] as num?)?.toInt() ?? 0;
  }

  /// Everything the program pages show, in one read.
  static Future<Map<String, dynamic>> summary() async {
    await call('summary');
    return EconomyMirror.instance.summary;
  }

  /// Published odds, ladders and caps — readable before sign-in.
  static Future<Map<String, dynamic>> publicConfig() async {
    try {
      final res = await http.get(Uri.parse('${base}config')).timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['config'] is Map) {
        return (decoded['config'] as Map).map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return const {};
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

  /// Last `summary` from the server (program pages read from it).
  Map<String, dynamic> summary = const {};
  int partnerPending = 0;
  int holds = 0;
  int freezes = 0;
  int restores = 0;

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
    await _todaySub?.cancel();
    _todaySub = null;
    _midnight?.cancel();
    uid = user?.uid;
    live = user != null;
    if (user == null) {
      coins = 0;
      _serverCoins = 0;
      summary = const {};
      cash = 0;
      plan = 'Free';
      code = '';
      loginToday = false;
      scratchToday = false;
      capsReady = false;
      notifyListeners();
      return;
    }
    // Local "grants" from older builds are not balances; drop them.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nwsb_local_delta_${user.uid}');
    loginToday = false;
    scratchToday = false;
    unawaited(() async {
      try {
        summary = await EconomyApi.call('ensureEconomyProfile', {
          'installId': await EconomyApi.installId(),
        });
        notifyListeners();
      } catch (e) {
        debugPrint('ensureEconomyProfile: $e');
      }
    }());
    final id = user.uid;
    _watch('users/$id/wallet/main', (data) {
      _serverCoins = (data['coins'] as num?)?.toInt() ?? 0;
      coins = _serverCoins;
      holds = (data['holds'] as num?)?.toInt() ?? 0;
      freezes = (data['freezes'] as num?)?.toInt() ?? 0;
      restores = (data['restores'] as num?)?.toInt() ?? 0;
      plan = (data['plan'] as String?)?.isNotEmpty == true ? data['plan'] as String : 'Free';
      streak = (data['streak'] as num?)?.toInt() ?? 0;
      freezesLeft = (data['freezesLeft'] as num?)?.toInt() ?? 0;
      practice = (data['practice'] as num?)?.toInt() ?? 0;
      playerOpens = (data['playerOpens'] as num?)?.toInt() ?? 0;
      purchases = (data['purchases'] as num?)?.toInt() ?? 0;
      practiceCredits = (data['practiceCredits'] as num?)?.toInt() ?? 0;
      subUntil = (data['subUntil'] as num?)?.toInt() ?? 0;
    });
    _watch('users/$id/payout/main', (data) {
      // cashBalance is rupees on the server; the money widgets take cents.
      cash = (((data['cashBalance'] as num?) ?? 0) * 100).round();
      lifetimeCents = (data['lifetimeCents'] as num?)?.toInt() ?? 0;
      upi = (data['upi'] as String?) ?? '';
      country = (data['country'] as String?) ?? '';
      payoutRail = (data['payoutRail'] as String?) ?? '';
    });
    _watch('users/$id/partner/main', (data) {
      partnerPoints = (data['points'] as num?)?.toInt() ?? 0;
      partnerPending = (data['pending'] as num?)?.toInt() ?? 0;
      partnerPerk = (data['perk'] as String?) ?? '';
    });
    _watchToday(id);
    _scheduleMidnight();
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

  StreamSubscription<dynamic>? _todaySub;
  String _todayBound = '';
  Timer? _midnight;
  int _summaryAt = 0;

  /// Today's caps doc. Re-bound at the server's midnight (IST), so login and
  /// scratch state roll over without restarting the app.
  void _watchToday(String id) {
    _todaySub?.cancel();
    _todayBound = _todayKey();
    _todaySub = FirebaseFirestore.instance.doc('users/$id/earnCaps/$_todayBound').snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final login = data['login'] == true;
      final scratch = data['scratch'] == true;
      final changed = login != loginToday || scratch != scratchToday || !capsReady;
      loginToday = login;
      scratchToday = scratch;
      capsReady = true;
      if (changed) notifyListeners();
    }, onError: (_) {});
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final ist = DateTime.now().toUtc().add(const Duration(minutes: 330));
    final next = DateTime.utc(ist.year, ist.month, ist.day).add(const Duration(days: 1, seconds: 3));
    _midnight = Timer(next.difference(ist), _rollDay);
  }

  void _rollDay() {
    final id = uid;
    if (id == null) return;
    loginToday = false;
    scratchToday = false;
    capsReady = false;
    _watchToday(id);
    _scheduleMidnight();
    unawaited(refresh());
  }

  /// Back in the app: roll the day if midnight passed while away, and
  /// refresh the summary only when it is old (no per-minute reloads).
  void onForeground() {
    if (uid == null) return;
    if (_todayBound != _todayKey()) {
      _rollDay();
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - _summaryAt > 3 * 60 * 1000) unawaited(refresh());
  }

  /// Sets the summary and tells listeners only if something they show changed.
  void _setSummary(Map<String, dynamic> body) {
    _summaryAt = DateTime.now().millisecondsSinceEpoch;
    String sig(Map<String, dynamic> m) {
      final c = Map<String, dynamic>.from(m)..remove('now')..remove('effects');
      try {
        return jsonEncode(c);
      } catch (_) {
        return '${c.length}${DateTime.now()}';
      }
    }
    final same = summary.isNotEmpty && sig(summary) == sig(body);
    summary = body;
    if (!same) notifyListeners();
  }

  bool get subscribed =>
      plan != 'Free' && subUntil > DateTime.now().millisecondsSinceEpoch && subscriptionActive;

  /// The server's day: midnight IST (config dayOffsetMinutes 330).
  String _todayKey() {
    final n = DateTime.now().toUtc().add(const Duration(minutes: 330));
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}$m$d';
  }

  /// After any server action: refresh the summary in the background so
  /// every program page shows the new state.
  void _afterAction(String name, Map<String, dynamic> body) {
    if (name == 'summary' || name == 'ensureEconomyProfile') {
      _setSummary(body);
      return;
    }
    if (name == 'registerDevice') return;
    if (name == 'heartbeat') {
      // Minutes tick every beat; only a newly reached ladder step (or a
      // fragment prize) is worth a reload. Everything else stays quiet.
      final today = summary['today'];
      if (today is Map) {
        final before = '${today['ladder']}';
        final t = Map<String, dynamic>.from(today);
        t['minutes'] = body['minutes'] ?? t['minutes'];
        if (body['ladder'] != null) t['ladder'] = body['ladder'];
        summary = {...summary, 'today': t};
        if (before != '${t['ladder']}') notifyListeners();
      }
      if (body['fragment'] != null || body['pass'] == true) _refreshSoon();
      return;
    }
    if (name == 'reportAction' && ((body['coins'] as num?) ?? 0) == 0) return;
    if (name == 'claimDailyLogin') loginToday = true;
    if (name == 'dailyScratch' || name == 'scratchCoupon') scratchToday = true;
    _refreshSoon();
  }

  Timer? _refresh;
  void _refreshSoon() {
    _refresh?.cancel();
    // Rewards play on the root overlay (reward_overlay.dart), so this reload
    // can no longer cancel a reveal or a coin flight.
    _refresh = Timer(const Duration(milliseconds: 900), () async {
      try {
        await EconomyApi.call('summary');
      } catch (_) {}
    });
  }

  Future<void> refresh() async {
    try {
      await EconomyApi.call('summary');
    } catch (_) {
      notifyListeners();
    }
  }

  /// Older builds kept a local coin bonus here. Coins now come only from the
  /// server, so this never adds anything (kept so callers compile).
  @Deprecated('Coins are server-only.')
  Future<int> grantOnce(String key, int amount, {bool daily = true}) async => 0;

  void _watch(String path, void Function(Map<String, dynamic> data) apply) {
    String? last;
    _docs.add(FirebaseFirestore.instance.doc(path).snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final sig = data.toString();
      if (sig == last) return; // same values: nobody needs to rebuild
      last = sig;
      apply(data);
      notifyListeners();
    }, onError: (_) {}));
  }
}
