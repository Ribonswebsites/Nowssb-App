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
      if (storedLevel != null && storedLevel >= 1 && storedLevel <= 12) {
        _levelOverride = storedLevel;
      }
    } catch (_) {
      // The player still works if device persistence is temporarily unavailable.
    }
    notifyListeners();
  }

  int get totalSessions => _sessions.length;

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

  /// One level per 30 minutes meditated, minimum 1, cap 12 — same curve as the web player.
  int get earnedLevel {
    final value = (totalMinutes / 30).floor() + 1;
    if (value < 1) return 1;
    if (value > 12) return 12;
    return value;
  }

  int get level {
    final override = _levelOverride;
    if (override != null && override >= 1 && override <= 12) return override;
    return earnedLevel;
  }

  Future<void> setLevel(int value) async {
    final next = value < 1 ? 1 : (value > 12 ? 12 : value);
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
