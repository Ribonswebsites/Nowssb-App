/// What the person chose: per-category switches, quiet hours, the daily
/// reminder time — plus the small de-duplication ledger. Everything is in
/// SharedPreferences so the FCM background isolate reads the same answers.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notif_categories.dart';

/// Minutes after midnight.
typedef DayMinute = int;

class NotifPrefs extends ChangeNotifier {
  NotifPrefs._();
  static final NotifPrefs instance = NotifPrefs._();

  static const kCatOff = 'nwsb_notif_cat_off';
  static const kQuietOn = 'nwsb_notif_quiet_on';
  static const kQuietFrom = 'nwsb_notif_quiet_from';
  static const kQuietTo = 'nwsb_notif_quiet_to';
  static const kSeen = 'nwsb_notif_seen';
  static const kAdmin = 'nwsb_notif_is_admin';
  static const kUid = 'nwsb_notif_uid';

  /// The Profile page's "Daily Reminder" (HH:mm) — the word of the day time.
  static const kReminder = 'nowssb_reminder';

  /// NotifStore's keys (lib/data/notifications.dart): master + kinds off.
  static const kLegacyMaster = 'nwsb_notif_master';
  static const kLegacyOff = 'nwsb_notif_off';

  static const defaultQuietFrom = 22 * 60 + 30;
  static const defaultQuietTo = 7 * 60;
  static const defaultReminder = 7 * 60;
  static const seenWindow = Duration(hours: 48);
  static const sameTextWindow = Duration(minutes: 15);

  bool master = true;
  Set<String> off = {};
  Set<String> legacyOff = {};
  bool quietOn = true;
  DayMinute quietFrom = defaultQuietFrom;
  DayMinute quietTo = defaultQuietTo;
  DayMinute reminder = defaultReminder;
  bool isAdmin = false;
  String uid = '';
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  /// [fresh] re-reads the platform store (another isolate may have written).
  Future<void> load({bool fresh = false}) async {
    try {
      final p = await _p();
      if (fresh) await p.reload();
      master = (p.getString(kLegacyMaster) ?? '1') != '0';
      off = _set(p.getString(kCatOff));
      legacyOff = _set(p.getString(kLegacyOff));
      quietOn = p.getBool(kQuietOn) ?? true;
      quietFrom = p.getInt(kQuietFrom) ?? defaultQuietFrom;
      quietTo = p.getInt(kQuietTo) ?? defaultQuietTo;
      reminder = parseHm(p.getString(kReminder)) ?? defaultReminder;
      isAdmin = p.getBool(kAdmin) ?? false;
      uid = p.getString(kUid) ?? '';
    } catch (e) {
      debugPrint('NowssB notif prefs: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  static Set<String> _set(String? raw) {
    try {
      final v = jsonDecode(raw ?? '[]');
      if (v is List) return v.map((e) => '$e').toSet();
    } catch (_) {}
    return {};
  }

  static DayMinute? parseHm(String? s) {
    if (s == null || !s.contains(':')) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  static String hm(DayMinute v) =>
      '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

  bool isOn(NotifCategory c) {
    if (!master) return false;
    if (off.contains(c.id)) return false;
    final legacy = c.legacyKind;
    if (legacy != null && legacyOff.contains(legacy)) return false;
    return true;
  }

  Future<void> setOn(NotifCategory c, bool on) async {
    final p = await _p();
    off = {...off};
    if (on) {
      off.remove(c.id);
    } else {
      off.add(c.id);
    }
    await p.setString(kCatOff, jsonEncode(off.toList()..sort()));
    // Keep the older page's switch in step (it reads nwsb_notif_off).
    final legacy = c.legacyKind;
    if (legacy != null) {
      legacyOff = {...legacyOff};
      if (on) {
        legacyOff.remove(legacy);
      } else {
        legacyOff.add(legacy);
      }
      await p.setString(kLegacyOff, jsonEncode(legacyOff.toList()));
    }
    if (on && !master) {
      master = true;
      await p.setString(kLegacyMaster, '1');
    }
    notifyListeners();
  }

  Future<void> setQuiet({bool? on, DayMinute? from, DayMinute? to}) async {
    final p = await _p();
    if (on != null) {
      quietOn = on;
      await p.setBool(kQuietOn, on);
    }
    if (from != null) {
      quietFrom = from;
      await p.setInt(kQuietFrom, from);
    }
    if (to != null) {
      quietTo = to;
      await p.setInt(kQuietTo, to);
    }
    notifyListeners();
  }

  Future<void> setReminder(DayMinute v) async {
    reminder = v;
    await (await _p()).setString(kReminder, hm(v));
    notifyListeners();
  }

  Future<void> setIdentity({required String uid, required bool admin}) async {
    final p = await _p();
    this.uid = uid;
    isAdmin = admin;
    if (uid.isEmpty) {
      await p.remove(kUid);
    } else {
      await p.setString(kUid, uid);
    }
    await p.setBool(kAdmin, admin);
  }

  /// Quiet hours contain [t]? The window may cross midnight (22:30 → 07:00).
  bool inQuiet(DateTime t) => quietOn && quietContains(quietFrom, quietTo, t.hour * 60 + t.minute);

  static bool quietContains(DayMinute from, DayMinute to, DayMinute m) {
    if (from == to) return false;
    if (from < to) return m >= from && m < to;
    return m >= from || m < to;
  }

  /// [t], or the end of quiet hours if [t] falls inside them.
  DateTime outsideQuiet(DateTime t) => shiftOutOfQuiet(t, on: quietOn, from: quietFrom, to: quietTo);

  static DateTime shiftOutOfQuiet(DateTime t, {required bool on, required DayMinute from, required DayMinute to}) {
    if (!on || !quietContains(from, to, t.hour * 60 + t.minute)) return t;
    var end = DateTime(t.year, t.month, t.day, to ~/ 60, to % 60);
    if (!end.isAfter(t)) end = DateTime(t.year, t.month, t.day + 1, to ~/ 60, to % 60);
    return end;
  }

  /// De-duplication. A notification is shown once per [key] (a server nid or
  /// a schedule key) and once per identical title+body within
  /// [sameTextWindow], whichever path (push, inbox watch, local) gets there
  /// first. Returns true if it is new and records it.
  Future<bool> claim({required String key, required String title, required String body, DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final p = await _p();
    try {
      await p.reload();
    } catch (_) {}
    final ledger = <String, int>{};
    try {
      final raw = jsonDecode(p.getString(kSeen) ?? '{}');
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is num && at - v.toInt() < seenWindow.inMilliseconds) ledger['$k'] = v.toInt();
        });
      }
    } catch (_) {}
    final text = 't:${textKey(title, body)}';
    if (key.isNotEmpty && ledger.containsKey('k:$key')) return false;
    final last = ledger[text];
    if (last != null && at - last < sameTextWindow.inMilliseconds) return false;
    if (key.isNotEmpty) ledger['k:$key'] = at;
    ledger[text] = at;
    // Newest 200 only.
    final kept = ledger.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    await p.setString(kSeen, jsonEncode(Map.fromEntries(kept.take(200))));
    return true;
  }

  /// Records a key as delivered without checking (the OS showed it itself).
  Future<void> remember(String key, String title, String body, int atMs) async {
    final p = await _p();
    Map<String, dynamic> raw = {};
    try {
      final v = jsonDecode(p.getString(kSeen) ?? '{}');
      if (v is Map) raw = Map<String, dynamic>.from(v);
    } catch (_) {}
    raw['k:$key'] = atMs;
    raw['t:${textKey(title, body)}'] = atMs;
    await p.setString(kSeen, jsonEncode(raw));
  }

  static String textKey(String title, String body) {
    // FNV-1a, stable across isolates and launches.
    var h = 0x811c9dc5;
    for (final c in utf8.encode('${title.trim()}\u0000${body.trim()}')) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }
}
