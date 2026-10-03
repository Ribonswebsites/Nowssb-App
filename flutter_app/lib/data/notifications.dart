/// Notifications store — port of app/js/part064.js.
///
/// The feed starts empty and only fills when something calls [notify].
/// A kind switched off (or the master off) is dropped at [notify], so
/// turning it off stops it arriving rather than merely hiding it.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';

class NotifKind {
  const NotifKind({required this.k, required this.label, required this.sub});
  final String k;
  final String label;
  final String sub;
}

class NotifGroup {
  const NotifGroup({required this.name, required this.items});
  final String name;
  final List<NotifKind> items;
}

class NotifItem {
  NotifItem({
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
    this.remotePath,
  });

  /// Set for an item that lives in Firestore users/{uid}/notifications
  /// (admin messages, request replies, purchases) — the one inbox.
  final String? remotePath;

  final String type;
  final String title;
  final String body;
  final int at;
  bool read;

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'body': body,
        'at': at,
        'read': read,
      };

  static NotifItem fromJson(Map<String, dynamic> m) => NotifItem(
        type: '${m['type'] ?? ''}',
        title: '${m['title'] ?? ''}',
        body: '${m['body'] ?? ''}',
        at: (m['at'] is num) ? (m['at'] as num).toInt() : DateTime.now().millisecondsSinceEpoch,
        read: m['read'] == true,
      );
}

/// Same remote URLs as `var A` / `IC` in part064.js.
class NotifIcons {
  NotifIcons._();

  static const chat =
      'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png';
  static const reels =
      'https://media.nowssb.com/migrated-images/1b075adfd52b4af8_10d7afe0-5bf2-11f1-8248-b91d5cd919c2_b0bff9.png';
  static const connect =
      'https://media.nowssb.com/migrated-images/a0b5196292b572ab_04d5f4e0-5bf2-11f1-8248-b91d5cd919c2_mcohzv.png';
  static const profile =
      'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png';
  static const store =
      'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png';
  static const cart =
      'https://media.nowssb.com/migrated-images/311c26afee2bc52c_file_00000000f02c72088cd128f3f4b08af5_vskoom.png';
  static const library =
      'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png';
  static const offer =
      'https://media.nowssb.com/migrated-images/5972de26815c527d_file_000000006b20820b84961321dcdcaaa8_be9meu.png';
  static const wordsci =
      'https://media.nowssb.com/migrated-images/dd44cf9fc35b783c_file_0000000086d872089ce376674620d5f3_mtfftb.png';
  static const routines =
      'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png';
  static const ai =
      'https://media.nowssb.com/migrated-images/41c9ed21b2822c90_file_0000000062a882089abd27eb90ea3945_ngqyu6.png';
  static const streak =
      'https://media.nowssb.com/migrated-images/f82047a0e727766b_file_0000000010fc820891f9e15a38316d2b_ffffhq.png';
  static const every =
      'https://media.nowssb.com/migrated-images/47f9e2c9fad5a78f_file_00000000be547207aaa56f43cfef4f67_nxhvw0.png';
  static const settings =
      'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png';

  static const byKind = <String, String>{
    'messages': chat,
    'posts': reels,
    'reactions': connect,
    'follows': profile,
    'orders': store,
    'delivery': store,
    'cart': cart,
    'arrivals': library,
    'offers': offer,
    'trending': wordsci,
    'routine': routines,
    'rx': ai,
    'streak': streak,
    'reader': library,
    'subscription': every,
    'support': settings,
  };

  static String urlFor(String type) => byKind[type] ?? settings;
}

class NotifStore extends ChangeNotifier {
  NotifStore._();
  static final NotifStore instance = NotifStore._();

  static const kOff = 'nwsb_notif_off';
  static const kMaster = 'nwsb_notif_master';
  static const kFeed = 'nwsb_notif_feed';
  static const feedMax = 60;

  /// Only the kinds the app actually sends. Social and delivery rows that
  /// never fired were removed so the page stays short.
  static const groups = <NotifGroup>[
    NotifGroup(name: 'Your Practice', items: [
      NotifKind(k: 'routine', label: 'Daily words', sub: 'A reminder in your morning, local time'),
      NotifKind(k: 'streak', label: 'Streak', sub: 'Evening reminder if you have not practiced'),
      NotifKind(k: 'reader', label: 'Reading', sub: 'Reminders you set in the Reader'),
    ]),
    NotifGroup(name: 'Offers', items: [
      NotifKind(k: 'offers', label: 'Offers & news', sub: 'Announcements from NowssB, never in quiet hours'),
    ]),
    NotifGroup(name: 'Account', items: [
      NotifKind(k: 'subscription', label: 'Subscription', sub: 'Renewals, plan changes and billing'),
      NotifKind(k: 'orders', label: 'Orders', sub: 'Confirmed and completed store orders'),
    ]),
  ];

  static final allKinds = <String>[
    for (final g in groups)
      for (final i in g.items) i.k,
  ];

  /// Fired for every item that is actually kept. Phone + banner listen here.
  static void Function(NotifItem item)? onDelivered;

  bool _master = true;
  List<String> _off = [];
  List<NotifItem> _feed = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get master => _master;
  List<String> get offSet => List.unmodifiable(_off);
  /// Local reminders + this account's Firestore notifications, newest first.
  List<NotifItem> get feed {
    if (_remote.isEmpty) return List.unmodifiable(_feed);
    final all = [..._feed, ..._remote]..sort((a, b) => b.at.compareTo(a.at));
    return List.unmodifiable(all);
  }

  List<NotifItem> _remote = [];
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  static String _remoteType(Map<String, dynamic> d) {
    final k = '${d['kind'] ?? d['type'] ?? ''}';
    if (k == 'request_done' || k == 'arrivals') return 'arrivals';
    if (k.contains('sub')) return 'subscription';
    if (k.contains('order') || k.contains('purchase')) return 'orders';
    if (k.contains('offer')) return 'offers';
    return 'support';
  }

  static int _ms(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is num) return v.toInt();
    return DateTime.tryParse('${v ?? ''}')?.millisecondsSinceEpoch ?? 0;
  }

  void _listenRemote() {
    if (_authSub != null || !NwsbFirebase.ready) return;
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        _remoteSub?.cancel();
        _remoteSub = null;
        _remote = [];
        notifyListeners();
        if (u == null || u.isAnonymous) return;
        _remoteSub = FirebaseFirestore.instance
            .collection('users/${u.uid}/notifications')
            .orderBy('at', descending: true)
            .limit(40)
            .snapshots()
            .listen((snap) {
          _remote = [
            for (final d in snap.docs)
              NotifItem(
                type: _remoteType(d.data()),
                title: '${d.data()['title'] ?? 'NowssB'}',
                body: '${d.data()['body'] ?? ''}',
                at: _ms(d.data()['at'] ?? d.data()['createdAt']),
                read: d.data()['read'] == true,
                remotePath: d.reference.path,
              ),
          ];
          notifyListeners();
        }, onError: (Object e) => debugPrint('NowssB inbox: $e'));
      });
    } catch (_) {}
  }

  int get unreadCount =>
      _feed.where((x) => !x.read).length + _remote.where((x) => !x.read).length;

  /// Badge text for header bells — empty when zero, capped at 99+.
  String get badgeText {
    final n = unreadCount;
    if (n <= 0) return '';
    return n > 99 ? '99+' : '$n';
  }

  int get badgeCount {
    final n = unreadCount;
    if (n <= 0) return 0;
    return n > 99 ? 99 : n;
  }

  /// For UI that needs the raw unread (and formats 99+ itself).
  int get unreadRaw => unreadCount;

  String labelOf(String k) {
    for (final g in groups) {
      for (final i in g.items) {
        if (i.k == k) return i.label;
      }
    }
    return k;
  }

  bool isKindOn(String k) => _master && !_off.contains(k);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _master = (p.getString(kMaster) ?? '1') != '0';
      try {
        final raw = jsonDecode(p.getString(kOff) ?? '[]');
        if (raw is List) {
          _off = raw
              .map((e) => '$e')
              .where((k) => allKinds.contains(k))
              .toList();
        }
      } catch (_) {
        _off = [];
      }
      try {
        final raw = jsonDecode(p.getString(kFeed) ?? '[]');
        if (raw is List) {
          _feed = raw
              .whereType<Map>()
              .map((e) => NotifItem.fromJson(Map<String, dynamic>.from(e)))
              .where((n) => allKinds.contains(n.type))
              .take(feedMax)
              .toList();
        }
      } catch (_) {
        _feed = [];
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      _loaded = true;
      notifyListeners();
    }
    _listenRemote();
  }

  Future<void> _persistMaster() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(kMaster, _master ? '1' : '0');
    } catch (_) {}
  }

  Future<void> _persistOff() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(kOff, jsonEncode(_off));
    } catch (_) {}
  }

  Future<void> _persistFeed() async {
    try {
      final p = await SharedPreferences.getInstance();
      final slice = _feed.take(feedMax).map((e) => e.toJson()).toList();
      await p.setString(kFeed, jsonEncode(slice));
    } catch (_) {}
  }

  Future<void> toggleMaster() async {
    _master = !_master;
    await _persistMaster();
    notifyListeners();
  }

  Future<void> setMaster(bool on) async {
    if (_master == on) return;
    _master = on;
    await _persistMaster();
    notifyListeners();
  }

  /// With master muted, tapping a kind switch turns master back on
  /// (same as part064 `ntToggle`).
  Future<void> toggleKind(String k) async {
    if (!allKinds.contains(k)) return;
    if (!_master) {
      _master = true;
      await _persistMaster();
      notifyListeners();
      return;
    }
    if (_off.contains(k)) {
      _off = [..._off]..remove(k);
    } else {
      _off = [..._off, k];
    }
    await _persistOff();
    notifyListeners();
  }

  /// Public API — `window.nwsbNotify({ type, title, body })`.
  /// Returns true if the notification was kept.
  Future<bool> notify({
    required String type,
    String? title,
    String? body,
    int? at,
  }) async {
    if (!allKinds.contains(type)) return false;
    if (!_master || _off.contains(type)) return false;
    final item = NotifItem(
      type: type,
      title: title ?? labelOf(type),
      body: body ?? '',
      at: at ?? DateTime.now().millisecondsSinceEpoch,
      read: false,
    );
    _feed = [item, ..._feed].take(feedMax).toList();
    await _persistFeed();
    notifyListeners();
    onDelivered?.call(item);
    return true;
  }

  Future<void> clearAll() async {
    _feed = [];
    await _persistFeed();
    final remote = _remote;
    _remote = [];
    notifyListeners();
    for (final n in remote) {
      try {
        await FirebaseFirestore.instance.doc(n.remotePath!).delete();
      } catch (_) {}
    }
  }

  /// [index] into [feed] (the merged list).
  Future<void> markRead(int index) async {
    final list = feed;
    if (index < 0 || index >= list.length) return;
    final n = list[index];
    if (n.read) return;
    n.read = true;
    notifyListeners();
    if (n.remotePath != null) {
      try {
        await FirebaseFirestore.instance.doc(n.remotePath!).update({'read': true});
      } catch (_) {}
      return;
    }
    await _persistFeed();
  }

  /// Relative time — same bands as part064 `ago()`.
  static String ago(int ts) {
    final s = ((DateTime.now().millisecondsSinceEpoch - ts) / 1000)
        .floor()
        .clamp(0, 1 << 30);
    if (s < 60) return 'just now';
    final m = (s / 60).floor();
    if (m < 60) return '${m}m ago';
    final h = (m / 60).floor();
    if (h < 24) return '${h}h ago';
    final d = (h / 24).floor();
    if (d < 7) return '${d}d ago';
    return '${(d / 7).floor()}w ago';
  }

  String sheetSubtitle() {
    final list = feed;
    final unread = unreadCount;
    if (!_master) return 'Muted — nothing is coming through';
    if (list.isEmpty) return 'Nothing new right now';
    if (unread > 0) return '$unread unread of ${list.length}';
    return list.length == 1 ? '1 update' : '${list.length} updates';
  }
}
