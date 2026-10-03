/// Practice history used by the native dashboard and player, kept per
/// account on this phone (a second account signing in starts empty) and
/// topped up from the server's own practice days after a reinstall.
///
/// A completed word is recorded once per day, matching the WebView session
/// key convention (`YYYY-MM-DD_WORD`). No fabricated totals are shown: every
/// count below comes from an actual completed native playback session (or a
/// practice day the server recorded for this account).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'firebase.dart';
import 'models.dart';
import '../features/economy/economy_api.dart';
import '../features/economy/reward_fx.dart';

class PracticeProgress extends ChangeNotifier {
  PracticeProgress._();
  static final PracticeProgress instance = PracticeProgress._();

  // Signed out (guest) uses the original device-wide keys; each account gets
  // its own `_<uid>` keys.
  static const _guestKey = 'nwsb_native_sessions';
  static const _guestLevelKey = 'nwsb_player_level';
  static const _migratedKey = 'nwsb_native_sessions_migrated';
  final Map<String, Map<String, dynamic>> _sessions = {};
  bool _started = false;
  int? _levelOverride;
  String? _uid;
  StreamSubscription<User?>? _authSub;

  String get _storageKey => _uid == null ? _guestKey : '${_guestKey}_$_uid';
  String get _levelKey => _uid == null ? _guestLevelKey : '${_guestLevelKey}_$_uid';
  String get _clearedKey => '${_guestKey}_cleared_${_uid ?? ''}';

  Future<void> start() async {
    if (_started) return;
    _started = true;
    String? uid;
    if (NwsbFirebase.ready) {
      final u = FirebaseAuth.instance.currentUser;
      uid = (u == null || u.isAnonymous) ? null : u.uid;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        final id = (u == null || u.isAnonymous) ? null : u.uid;
        if (id != _uid) unawaited(_load(id));
      });
    }
    await _load(uid);
  }

  /// Loads [uid]'s history (null = signed out) in place of the current one.
  Future<void> _load(String? uid) async {
    _uid = uid;
    final storageKey = _storageKey, levelKey = _levelKey;
    final sessions = <String, Map<String, dynamic>>{};
    int? level;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (uid != null && !preferences.containsKey(storageKey) && !(preferences.getBool(_migratedKey) ?? false)) {
        // One time: history recorded before it was kept per account belongs
        // to the first account that signs in on this phone after the update.
        final legacy = preferences.getString(_guestKey);
        if (legacy != null && legacy.isNotEmpty) await preferences.setString(storageKey, legacy);
        final legacyLevel = preferences.getInt(_guestLevelKey);
        if (legacyLevel != null) await preferences.setInt(levelKey, legacyLevel);
        await preferences.remove(_guestKey);
        await preferences.remove(_guestLevelKey);
        await preferences.setBool(_migratedKey, true);
      }
      final raw = preferences.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              sessions['${entry.key}'] = Map<String, dynamic>.from(entry.value as Map);
            }
          }
        }
      }
      final storedLevel = preferences.getInt(levelKey);
      if (storedLevel != null && storedLevel >= 1 && storedLevel <= 10) {
        level = storedLevel;
      }
    } catch (_) {
      // The player still works if device persistence is temporarily unavailable.
    }
    if (_uid != uid) return; // another account signed in meanwhile
    _sessions
      ..clear()
      ..addAll(sessions);
    _levelOverride = level;
    notifyListeners();
    if (uid != null) unawaited(_hydrate(uid));
  }

  /// Adds the practice days the server recorded for this account
  /// (users/{uid}/mastery: last practice day per word) that this phone
  /// doesn't have, e.g. after a reinstall or on a new phone. Days on or
  /// before a "Clear practice history" are not brought back.
  Future<void> _hydrate(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users/$uid/mastery').limit(500).get();
      if (_uid != uid) return;
      final preferences = await SharedPreferences.getInstance();
      final cleared = preferences.getString(_clearedKey) ?? '';
      final library = ContentStore.instance.library;
      var added = false;
      for (final doc in snap.docs) {
        final ymd = '${doc.data()['lastPracticeDay'] ?? ''}';
        if (!RegExp(r'^\d{8}$').hasMatch(ymd)) continue;
        final date = '${ymd.substring(0, 4)}-${ymd.substring(4, 6)}-${ymd.substring(6, 8)}';
        if (cleared.isNotEmpty && date.compareTo(cleared) <= 0) continue;
        final id = '${doc.data()['word'] ?? doc.id}'.toLowerCase();
        final known = _sessions.values.any((x) => x['date'] == date && '${x['word'] ?? ''}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '') == id);
        if (known) continue;
        final match = library.where((w) => w.key == id || w.word.toLowerCase() == id);
        final word = match.isEmpty ? id : match.first.word;
        _sessions['${date}_$word'] = {'date': date, 'word': word, 'completedAt': '${date}T12:00:00.000', 'source': 'server'};
        added = true;
      }
      if (!added) return;
      await _save();
      notifyListeners();
    } catch (e) {
      debugPrint('NowssB practice history sync: $e');
    }
  }

  Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, jsonEncode(_sessions));
    } catch (_) {}
  }

  int get totalSessions => _sessions.length;

  List<Map<String, dynamic>> get sessionsSnapshot => _sessions.values
      .map((session) => Map<String, dynamic>.from(session))
      .toList()
    ..sort((a, b) => '${b['completedAt'] ?? b['date']}'.compareTo('${a['completedAt'] ?? a['date']}'));

  int get uniqueWords => _sessions.values
      .map((session) => '${session['word'] ?? ''}')
      .where((word) => word.isNotEmpty)
      .toSet()
      .length;

  String? get lastPracticed {
    final dates = _sessions.values
        .map((session) => '${session['date'] ?? ''}')
        .where((date) => date.isNotEmpty)
        .toList()
      ..sort();
    return dates.isEmpty ? null : dates.last;
  }

  int get todaySessions {
    final today = _day(DateTime.now());
    return _sessions.values.where((session) => session['date'] == today).length;
  }

  int get streak {
    final days = <String>{
      for (final session in _sessions.values)
        if (session['date'] is String) session['date'] as String,
    };
    var cursor = DateTime.now();
    if (!days.contains(_day(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    var value = 0;
    while (days.contains(_day(cursor)) && value < 365) {
      value += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return value;
  }

  /// Accumulated practice time from recorded sessions. Sessions without a
  /// stored duration contribute nothing — the UI shows `0m` until real
  /// playback length has been written.
  int get totalMinutes {
    var seconds = 0;
    for (final session in _sessions.values) {
      final duration = session['durationSec'];
      if (duration is num && duration > 0) {
        seconds += duration.round();
      }
    }
    return (seconds / 60).round();
  }

  String get timeLabel {
    if (_sessions.isEmpty) return '0m';
    final m = totalMinutes;
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  /// One level per 30 minutes meditated, minimum 1, cap 10.
  int get earnedLevel {
    final value = (totalMinutes / 30).floor() + 1;
    if (value < 1) return 1;
    if (value > 10) return 10;
    return value;
  }

  int get level {
    final override = _levelOverride;
    if (override != null && override >= 1 && override <= 10) return override;
    return earnedLevel;
  }

  Future<void> setLevel(int value) async {
    final next = value < 1 ? 1 : (value > 10 ? 10 : value);
    _levelOverride = next;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_levelKey, next);
    } catch (_) {}
    notifyListeners();
  }

  int completedTodayFor(Iterable<Word> words) {
    final today = _day(DateTime.now());
    final wordSet = words.map((word) => word.word).toSet();
    return _sessions.values
        .where((session) => session['date'] == today && wordSet.contains(session['word']))
        .length;
  }


  /// Mon→Sun of the current week with practiced flags (website week grid).
  List<({String date, bool done, bool isToday, bool isFuture})> get thisWeekDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: (today.weekday + 6) % 7));
    final practiced = <String>{
      for (final session in _sessions.values)
        if (session['date'] is String) session['date'] as String,
    };
    final out = <({String date, bool done, bool isToday, bool isFuture})>[];
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final key = _day(d);
      out.add((
        date: key,
        done: practiced.contains(key),
        isToday: key == _day(today),
        isFuture: d.isAfter(today),
      ));
    }
    return out;
  }

  /// Days practiced this week / 7 as a percent (Glass Orb "Consistency").
  int get weekConsistencyPercent {
    final done = thisWeekDays.where((d) => d.done).length;
    return ((done / 7) * 100).round();
  }

  /// Meditation time logged Mon→today.
  String get weekTimeLabel {
    final days = thisWeekDays.map((d) => d.date).toSet();
    var seconds = 0;
    for (final session in _sessions.values) {
      if (!days.contains('${session['date'] ?? ''}')) continue;
      final duration = session['durationSec'];
      if (duration is num && duration > 0) seconds += duration.round();
    }
    if (seconds <= 0) return '0m';
    final m = (seconds / 60).round();
    if (m < 60) return '${m}m';
    final h = m / 60;
    if (h == h.roundToDouble()) return '${h.round()}h';
    return '${h.toStringAsFixed(1)}h';
  }

  Future<void> recordCompletedWord(Word word, {int durationSec = 0}) async {
    final today = _day(DateTime.now());
    final key = '${today}_${word.word}';
    _sessions[key] = {
      'date': today,
      'word': word.word,
      'completedAt': DateTime.now().toIso8601String(),
      'source': 'native-player',
      if (durationSec > 0) 'durationSec': durationSec,
    };
    await _save(); // the in-memory session stays even if storage fails
    notifyListeners();
    // Profile > Sound Feedback: a short click when a word is completed.
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString('nowssb_sound') != 'off') unawaited(SystemSound.play(SystemSoundType.click));
    } catch (_) {}
    // Server: practice counters, starter quest and mastery practice days.
    unawaited(EconomyApi.call('reportPractice', {'practiced': true, 'wordId': word.word})
        .then((_) {}, onError: (_) {}));
    // Practice Ring · listen: a full listen just finished.
    reportEarn('ring_listen');
  }

  /// Wipes this account's recorded sessions on this phone. Used by Settings.
  /// The server's practice days up to today are not synced back afterwards.
  Future<void> clearAll() async {
    _sessions.clear();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey);
      await preferences.setString(_clearedKey, _day(DateTime.now()));
    } catch (_) {}
    notifyListeners();
  }

  /// Fills yesterday so a broken streak reconnects. Returns false when
  /// yesterday is already practiced.
  Future<bool> restoreBrokenStreak() async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final day = _day(yesterday);
    final already = _sessions.values.any((s) => s['date'] == day);
    if (already) return false;
    _sessions['${day}_Streak restore'] = {
      'date': day,
      'word': 'Streak restore',
      'completedAt': DateTime.now().toIso8601String(),
      'source': 'coin-restore',
      'durationSec': 60,
    };
    await _save();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  static String _day(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
