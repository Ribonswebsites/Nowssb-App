/// Per-device practice history used by the native dashboard and player.
///
/// A completed word is recorded once per day, matching the WebView session
/// key convention (`YYYY-MM-DD_WORD`). No fabricated totals are shown: every
/// count below comes from an actual completed native playback session.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class PracticeProgress extends ChangeNotifier {
  PracticeProgress._();
  static final PracticeProgress instance = PracticeProgress._();

  static const _storageKey = 'nwsb_native_sessions';
  static const _levelKey = 'nwsb_player_level';
  final Map<String, Map<String, dynamic>> _sessions = {};
  bool _started = false;
  int? _levelOverride;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              _sessions['${entry.key}'] = Map<String, dynamic>.from(entry.value as Map);
            }
          }
        }
      }
      final storedLevel = preferences.getInt(_levelKey);
      if (storedLevel != null && storedLevel >= 1 && storedLevel <= 10) {
        _levelOverride = storedLevel;
      }
    } catch (_) {
      // The player still works if device persistence is temporarily unavailable.
    }
    notifyListeners();
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
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, jsonEncode(_sessions));
    } catch (_) {
      // Keep the in-memory session even if storage cannot complete.
    }
    notifyListeners();
  }

  static String _day(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
