/// Notifications store — port of app/js/part064.js.
///
/// The feed starts empty and only fills when something calls [notify].
/// A kind switched off (or the master off) is dropped at [notify], so
/// turning it off stops it arriving rather than merely hiding it.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

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

  /// Same GROUPS as part064.js.
  static const groups = <NotifGroup>[
    NotifGroup(name: 'NowssB Connect', items: [
      NotifKind(k: 'messages', label: 'Messages', sub: 'New texts from people you follow'),
      NotifKind(k: 'posts', label: 'Posts & Reels', sub: 'New posts and reels on your feed'),
      NotifKind(k: 'reactions', label: 'Likes & Comments', sub: 'When someone reacts to what you shared'),
      NotifKind(k: 'follows', label: 'New Followers', sub: 'When someone starts following you'),
    ]),
    NotifGroup(name: 'Store & Orders', items: [
      NotifKind(k: 'orders', label: 'Order Updates', sub: 'Confirmed, packed and completed'),
      NotifKind(k: 'delivery', label: 'On Its Way', sub: 'Where your order is and how long it will take'),
      NotifKind(k: 'cart', label: 'Cart Reminders', sub: 'Words still in your cart, before they are gone'),
      NotifKind(k: 'arrivals', label: 'New Arrivals', sub: 'New words, meanings and drops'),
      NotifKind(k: "offers", label: "Today's Offers", sub: 'Coupons and limited-time discounts'),
      NotifKind(k: "trending", label: "Today's Trending", sub: 'The word healing the most today'),
    ]),
    NotifGroup(name: 'Your Practice', items: [
      NotifKind(k: 'routine', label: 'Daily Routine', sub: 'Reminders for each routine slot'),
      NotifKind(k: 'rx', label: 'AI Prescription', sub: 'When your daily words are ready'),
      NotifKind(k: 'streak', label: 'Streak', sub: 'Before your streak is about to break'),
      NotifKind(k: 'reader', label: 'Reading Reminders', sub: 'Reminders you set yourself in the Reader'),
    ]),
    NotifGroup(name: 'Account', items: [
      NotifKind(k: 'subscription', label: 'Subscription', sub: 'Renewals, plan changes and billing'),
      NotifKind(k: 'support', label: 'Support', sub: 'Replies to your support requests'),
    ]),
  ];

  static final allKinds = <String>[
    for (final g in groups)
      for (final i in g.items) i.k,
  ];

  bool _master = true;
  List<String> _off = [];
  List<NotifItem> _feed = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get master => _master;
  List<String> get offSet => List.unmodifiable(_off);
  List<NotifItem> get feed => List.unmodifiable(_feed);

  int get unreadCount => _feed.where((x) => !x.read).length;

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
    return true;
  }

  Future<void> clearAll() async {
    _feed = [];
    await _persistFeed();
    notifyListeners();
  }

  Future<void> markRead(int index) async {
    if (index < 0 || index >= _feed.length) return;
    if (_feed[index].read) return;
    _feed[index].read = true;
    await _persistFeed();
    notifyListeners();
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
    final list = _feed;
    final unread = unreadCount;
    if (!_master) return 'Muted — nothing is coming through';
    if (list.isEmpty) return 'Nothing new right now';
    if (unread > 0) return '$unread unread of ${list.length}';
    return list.length == 1 ? '1 update' : '${list.length} updates';
  }
}
