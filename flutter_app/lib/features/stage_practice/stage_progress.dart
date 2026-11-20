/// Best score, attempts and pass per practice stage, kept on this phone
/// under the signed-in account. Stage 1 is always open; each later stage
/// opens when the one before it is passed.
library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';

class StageRecord {
  const StageRecord({this.best = 0, this.attempts = 0, this.passed = false, this.lastAt});

  final int best;
  final int attempts;
  final bool passed;
  final DateTime? lastAt;

  Map<String, dynamic> toJson() => {
        'best': best,
        'attempts': attempts,
        'passed': passed,
        if (lastAt != null) 'lastAt': lastAt!.millisecondsSinceEpoch,
      };

  static StageRecord fromJson(Object? j) {
    if (j is! Map) return const StageRecord();
    final at = j['lastAt'];
    return StageRecord(
      best: (j['best'] as num?)?.toInt() ?? 0,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      passed: j['passed'] == true,
      lastAt: at is num ? DateTime.fromMillisecondsSinceEpoch(at.toInt()) : null,
    );
  }
}

class StageProgressStore extends ChangeNotifier {
  StageProgressStore._();
  static final StageProgressStore instance = StageProgressStore._();

  static const _prefix = 'nwsb_stage_progress_v1';

  /// wordKey → stage number → record.
  final Map<String, Map<int, StageRecord>> _data = {};
  String? _loadedFor;

  /// Test hook: who the progress belongs to without Firebase.
  @visibleForTesting
  static String? debugAccount;

  String get _account {
    if (debugAccount != null) return debugAccount!;
    if (!NwsbFirebase.ready) return 'local';
    return FirebaseAuth.instance.currentUser?.uid ?? 'local';
  }

  String get _key => '$_prefix:$_account';

  Future<void> ensureLoaded() async {
    final key = _key;
    if (_loadedFor == key) return;
    _data.clear();
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw);
        if (m is Map) {
          for (final e in m.entries) {
            final stages = e.value;
            if (stages is! Map) continue;
            _data['${e.key}'] = {
              for (final s in stages.entries)
                if (int.tryParse('${s.key}') != null) int.parse('${s.key}'): StageRecord.fromJson(s.value),
            };
          }
        }
      }
    } catch (_) {}
    _loadedFor = key;
    notifyListeners();
  }

  StageRecord record(String wordKey, int stage) => _data[wordKey]?[stage] ?? const StageRecord();

  /// Stage 1 is open; stage n opens once stage n-1 is passed.
  bool isUnlocked(String wordKey, int stage) => stage <= 1 || record(wordKey, stage - 1).passed;

  /// Stages passed for [wordKey].
  int passedCount(String wordKey) => (_data[wordKey]?.values ?? const <StageRecord>[]).where((r) => r.passed).length;

  /// The first stage not yet passed (or the last one when all are).
  int currentStage(String wordKey, int stageCount) {
    for (var n = 1; n <= stageCount; n++) {
      if (!record(wordKey, n).passed) return n;
    }
    return stageCount;
  }

  /// Records a scored attempt. Returns true when this attempt passed the
  /// stage for the first time.
  Future<bool> addAttempt(String wordKey, int stage, {required int score, required bool passed}) async {
    await ensureLoaded();
    final was = record(wordKey, stage);
    final next = StageRecord(
      best: score > was.best ? score : was.best,
      attempts: was.attempts + 1,
      passed: was.passed || passed,
      lastAt: DateTime.now(),
    );
    (_data[wordKey] ??= {})[stage] = next;
    notifyListeners();
    await _save();
    return passed && !was.passed;
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          for (final e in _data.entries) e.key: {for (final s in e.value.entries) '${s.key}': s.value.toJson()},
        }),
      );
    } catch (_) {}
  }

  @visibleForTesting
  void debugReset() {
    _data.clear();
    _loadedFor = null;
  }
}
