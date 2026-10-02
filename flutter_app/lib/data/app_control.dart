/// What the admin console switches on in every app, live, without a
/// release:
///   config/app      `minBuild` (+ `updateMessage`, `updateUrl`) force update,
///                   `maintenance` {on, blocking, title, message, until},
///                   `flags` {name: bool} feature flags,
///                   `announcement` {on, title, body, cta, link, audience,
///                   tone, dismissible, until, id}
///   users/{uid}     `blocked`, `blockedReason`, `restrictions` {key: true}
/// The rules and the admin server enforce blocks and restrictions too; this
/// is what the person sees. Never throws; with no Firebase it is all off.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_update.dart';
import 'firebase.dart';

int _ms(dynamic v) {
  if (v is num) return v.toInt();
  if (v is Timestamp) return v.millisecondsSinceEpoch;
  return DateTime.tryParse('${v ?? ''}')?.millisecondsSinceEpoch ?? 0;
}

class AppAnnouncement {
  const AppAnnouncement({
    this.on = false,
    this.id = '',
    this.title = '',
    this.body = '',
    this.cta = '',
    this.link = '',
    this.audience = 'all',
    this.tone = 'gold',
    this.dismissible = true,
    this.until = 0,
  });

  factory AppAnnouncement.fromMap(Map? m) {
    if (m == null) return const AppAnnouncement();
    return AppAnnouncement(
      on: m['on'] == true,
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}'.trim(),
      body: '${m['body'] ?? ''}'.trim(),
      cta: '${m['cta'] ?? ''}'.trim(),
      link: '${m['link'] ?? ''}'.trim(),
      audience: '${m['audience'] ?? 'all'}',
      tone: '${m['tone'] ?? 'gold'}',
      dismissible: m['dismissible'] != false,
      until: _ms(m['until']),
    );
  }

  final bool on;
  final String id;
  final String title;
  final String body;
  final String cta;
  final String link;
  final String audience;
  final String tone;
  final bool dismissible;
  final int until;

  bool get live => on && (title.isNotEmpty || body.isNotEmpty) && (until == 0 || until > DateTime.now().millisecondsSinceEpoch);
}

class AppMaintenance {
  const AppMaintenance({this.on = false, this.blocking = false, this.title = '', this.message = '', this.until = 0});
  factory AppMaintenance.fromMap(Map? m) => m == null
      ? const AppMaintenance()
      : AppMaintenance(
          on: m['on'] == true,
          blocking: m['blocking'] == true,
          title: '${m['title'] ?? ''}'.trim(),
          message: '${m['message'] ?? ''}'.trim(),
          until: _ms(m['until']),
        );
  final bool on;
  final bool blocking;
  final String title;
  final String message;
  final int until;
}

class AppControl extends ChangeNotifier {
  AppControl._();
  static final AppControl instance = AppControl._();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _cfg;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _me;
  StreamSubscription<User?>? _auth;
  bool _started = false;

  int minBuild = 0;
  String updateMessage = '';
  String updateUrl = '';
  AppMaintenance maintenance = const AppMaintenance();
  AppAnnouncement announcement = const AppAnnouncement();
  Map<String, bool> flags = const {};
  Map<String, dynamic> store = const {};

  bool blocked = false;
  String blockedReason = '';
  Map<String, bool> restrictions = const {};
  bool isPro = false;
  bool _isAdmin = false;
  String _dismissed = '';

  /// Below the console's minimum build (Settings → Force update).
  bool get mustUpdate => minBuild > 0 && NwsbAppUpdate.currentBuild < minBuild;

  /// Maintenance that stops the app (admins pass through to fix things).
  bool get maintenanceBlocks => maintenance.on && maintenance.blocking && !_isAdmin;

  bool get showAnnouncement {
    final a = announcement;
    if (!a.live || (a.dismissible && _dismissed == a.id)) return false;
    if (a.audience == 'free' && isPro) return false;
    if (a.audience == 'subscribers' && !isPro) return false;
    return true;
  }

  /// A feature flag; unknown flags are [fallback] (on by default).
  bool flag(String name, {bool fallback = true}) => flags[name] ?? fallback;

  /// True when the console restricted this account from [key]
  /// (community, referrals, payouts, gifting, earning, requests) or blocked it.
  bool restricted(String key) => blocked || restrictions[key] == true;

  /// Which restriction / flag an economy server call needs, by function name.
  static const _economyGate = <String, String>{
    'requestPayout': 'payouts', 'savePayoutAccount': 'payouts',
    'redeemGift': 'gifting', 'sendGift': 'gifting', 'buyGift': 'gifting',
    'applyReferralCode': 'referrals', 'logPartnerAction': 'referrals',
    'claimDailyLogin': 'earning', 'claimQuest': 'earning', 'claimMilestone': 'earning', 'scratchCoupon': 'earning', 'reportPractice': 'earning',
    'createEchoPost': 'community', 'commentOnPost': 'community', 'toggleEchoLike': 'community',
  };
  static const _flagFor = {'payouts': 'earn', 'referrals': 'earn', 'earning': 'earn', 'gifting': 'gifts', 'community': 'community'};

  /// A short reason when the console stops this action, else null.
  String? blockFor(String area) {
    if (blocked) return 'This account is paused.';
    if (restrictions[area] == true) {
      return switch (area) {
        'payouts' => 'Payouts are paused on this account. Write to us if you think this is a mistake.',
        'gifting' => 'Gifts are switched off on this account.',
        'referrals' => 'Invites are switched off on this account.',
        'earning' => 'Rewards are paused on this account.',
        'community' => 'Posting is paused on this account.',
        'requests' => 'Requests are paused on this account.',
        _ => 'This is switched off on this account.',
      };
    }
    final f = _flagFor[area] ?? area;
    if (!flag(f)) return 'This is switched off for now. Try again later.';
    return null;
  }

  /// [blockFor] for an economy server function name.
  String? blockForEconomy(String fn) {
    final area = _economyGate[fn];
    return area == null ? (blocked ? 'This account is paused.' : null) : blockFor(area);
  }

  Future<void> start() async {
    if (_started || !NwsbFirebase.ready) return;
    _started = true;
    try {
      final p = await SharedPreferences.getInstance();
      _dismissed = p.getString('nwsb.announcement.dismissed') ?? '';
    } catch (_) {}
    _cfg = FirebaseFirestore.instance.doc('config/app').snapshots().listen((s) {
      final d = s.data() ?? const {};
      minBuild = (d['minBuild'] as num?)?.toInt() ?? int.tryParse('${d['minBuild'] ?? ''}') ?? 0;
      updateMessage = '${d['updateMessage'] ?? ''}';
      updateUrl = '${d['updateUrl'] ?? ''}';
      maintenance = AppMaintenance.fromMap(d['maintenance'] as Map?);
      announcement = AppAnnouncement.fromMap(d['announcement'] as Map?);
      flags = {
        if (d['flags'] is Map)
          for (final e in (d['flags'] as Map).entries)
            if (e.value is bool) '${e.key}': e.value as bool,
      };
      store = d['store'] is Map ? Map<String, dynamic>.from(d['store'] as Map) : const {};
      notifyListeners();
    }, onError: (_) {});
    _auth = FirebaseAuth.instance.authStateChanges().listen(_watchMe);
  }

  void _watchMe(User? u) {
    _me?.cancel();
    _me = null;
    blocked = false;
    blockedReason = '';
    restrictions = const {};
    isPro = false;
    _isAdmin = false;
    notifyListeners();
    if (u == null) return;
    FirebaseFirestore.instance.collection('admins').doc(u.uid).get().then((s) {
      _isAdmin = s.exists;
      notifyListeners();
    }).catchError((_) {});
    _me = FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots().listen((s) {
      final d = s.data() ?? const {};
      blocked = d['blocked'] == true;
      blockedReason = '${d['blockedReason'] ?? ''}';
      restrictions = {
        if (d['restrictions'] is Map)
          for (final e in (d['restrictions'] as Map).entries)
            if (e.value == true) '${e.key}': true,
      };
      final end = _ms(d['subscriptionEndDate']);
      isPro = d['isPro'] == true && (end == 0 || end > DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> dismissAnnouncement() async {
    _dismissed = announcement.id;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('nwsb.announcement.dismissed', _dismissed);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cfg?.cancel();
    _me?.cancel();
    _auth?.cancel();
    super.dispose();
  }
}
