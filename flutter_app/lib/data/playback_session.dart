/// Shared practice-player session that survives leaving the full player.
///
/// Back from [PracticePlayerScreen] minimizes into a floating pill; tapping
/// the pill opens the hearing-safety expanded UI. TTS lives here so audio
/// keeps going across those navigations.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'practice_progress.dart';

enum HearingTier { quiet, loud, danger }

class PlaybackSession extends ChangeNotifier {
  PlaybackSession._();
  static final PlaybackSession instance = PlaybackSession._();

  static const _doseKeyPrefix = 'nwsb_hearing_dose_';
  static const _volumeKey = 'nwsb_pw_volume';

  /// Estimated dB range matching the Auris-style slider (40–120).
  static const double minDb = 40;
  static const double maxDb = 120;
  static const double dangerDb = 85;

  final FlutterTts _tts = FlutterTts();

  List<Word> _words = const [];
  String _title = '';
  int _index = 0;
  String _artwork = '';
  bool _active = false;
  bool _minimized = false;
  bool _playing = false;
  bool _loop = false;
  double _db = 55;
  double _dosePercent = 0;
  String _doseDay = '';
  Timer? _doseTimer;
  DateTime? _startedAt;

  bool get active => _active;
  bool get minimized => _minimized;
  bool get showPill => _active && _minimized;
  bool get playing => _playing;
  bool get loop => _loop;
  double get db => _db;
  double get volume => ((_db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
  double get volumePercent => volume * 100;
  double get dosePercent => _dosePercent.clamp(0.0, 100.0);
  String get title => _title;
  int get index => _index;
  List<Word> get words => _words;
  Word? get word => (_words.isEmpty) ? null : _words[_index.clamp(0, _words.length - 1)];
  String get artwork {
    final w = word;
    if (w != null && w.img.isNotEmpty) return w.img;
    return _artwork;
  }

  HearingTier get tier {
    if (_db >= 100) return HearingTier.danger;
    if (_db >= 70) return HearingTier.loud;
    return HearingTier.quiet;
  }

  /// NIOSH-ish: 85 dB → 8h; every +3 dB halves safe time.
  static double safeSeconds(double dB) {
    if (dB < dangerDb) return double.infinity;
    return 8 * 3600 / math.pow(2, (dB - dangerDb) / 3);
  }

  String get safeListenLabel {
    final secs = safeSeconds(_db);
    if (!secs.isFinite) return 'No limit';
    if (secs >= 3600) {
      final h = secs / 3600;
      return h >= 10 ? '${h.round()} hr' : '${h.toStringAsFixed(1)} hr';
    }
    if (secs >= 60) {
      final m = (secs / 60).round();
      return '$m min';
    }
    return '${secs.round()} sec';
  }

  String get safeListenHeadline {
    if (tier == HearingTier.quiet) return 'SAFE TO LISTEN FOR';
    return 'DAMAGE BEGINS AFTER';
  }

  String get safeListenSubcopy {
    if (tier == HearingTier.quiet) {
      return 'Under 85 dB your ears can take it all day.';
    }
    return 'Past 85 dB every extra 3 dB halves the time you get.';
  }

  String get sceneLabel {
    switch (tier) {
      case HearingTier.quiet:
        return 'QUIET OFFICE';
      case HearingTier.loud:
        return 'CONCERT SPEAKER STACK';
      case HearingTier.danger:
        return 'JET TURBINE';
    }
  }

  String get tierLabel {
    switch (tier) {
      case HearingTier.quiet:
        return 'QUIET';
      case HearingTier.loud:
        return 'LOUD';
      case HearingTier.danger:
        return 'DANGER';
    }
  }

  Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_volumeKey);
    if (stored != null) {
      _db = (minDb + stored.clamp(0.0, 1.0) * (maxDb - minDb)).clamp(minDb, maxDb);
    }
    await _loadDose(prefs);
  }

  Future<void> _loadDose(SharedPreferences prefs) async {
    final day = _today();
    _doseDay = day;
    _dosePercent = prefs.getDouble('$_doseKeyPrefix$day') ?? 0;
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> start({
    required List<Word> words,
    required String title,
    int index = 0,
    String artwork = '',
    bool autoplay = true,
  }) async {
    await ensureLoaded();
    _words = List<Word>.from(words);
    _title = title;
    _index = words.isEmpty ? 0 : index.clamp(0, words.length - 1);
    _artwork = artwork;
    _active = true;
    _minimized = false;
    notifyListeners();
    if (autoplay && _words.isNotEmpty) {
      await play();
    }
  }

  /// Snapshot from the full practice player when the user presses back.
  Future<void> adoptFromPlayer({
    required List<Word> words,
    required String title,
    required int index,
    required bool wasPlaying,
    double? volume01,
    String artwork = '',
  }) async {
    await ensureLoaded();
    _words = List<Word>.from(words);
    _title = title;
    _index = words.isEmpty ? 0 : index.clamp(0, words.length - 1);
    _artwork = artwork;
    if (volume01 != null) {
      _db = (minDb + volume01.clamp(0.0, 1.0) * (maxDb - minDb)).clamp(minDb, maxDb);
    }
    _active = true;
    _minimized = true;
    notifyListeners();
    if (volume01 != null) await _persistVolume();
    if (wasPlaying) {
      await play();
    } else {
      _playing = false;
      _stopDoseClock();
      notifyListeners();
    }
  }

  void minimize() {
    if (!_active) return;
    _minimized = true;
    notifyListeners();
  }

  void expand() {
    if (!_active) return;
    _minimized = false;
    notifyListeners();
  }

  Future<void> dismiss() async {
    await stop();
    _active = false;
    _minimized = false;
    _words = const [];
    _title = '';
    _index = 0;
    _artwork = '';
    notifyListeners();
  }

  Future<void> setDb(double value) async {
    _db = value.clamp(minDb, maxDb);
    notifyListeners();
    await _persistVolume();
    if (_playing) {
      try {
        await _tts.setVolume(volume);
      } catch (_) {}
    }
  }

  Future<void> setVolume01(double v) => setDb(minDb + v.clamp(0.0, 1.0) * (maxDb - minDb));

  Future<void> _persistVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, volume);
  }

  Future<void> togglePlay() async {
    if (_playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> pause() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _playing = false;
    _stopDoseClock();
    notifyListeners();
  }

  Future<void> stop() async {
    await pause();
  }

  Future<void> play() async {
    final w = word;
    if (w == null) return;
    if (_playing) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
    _playing = true;
    _startedAt = DateTime.now();
    _startDoseClock();
    notifyListeners();
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.0);
      await _tts.setVolume(volume);
      await _tts.speak(w.word);
      final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now()).inSeconds;
      await PracticeProgress.instance.recordCompletedWord(
        w,
        durationSec: elapsed > 0 ? elapsed : 1,
      );
      if (_loop && _active) {
        await play();
        return;
      }
    } catch (_) {
      // Device TTS unavailable — keep session UI alive.
    } finally {
      if (_playing && !_loop) {
        _playing = false;
        _stopDoseClock();
        notifyListeners();
      }
    }
  }

  Future<void> next() async {
    if (_words.length < 2) {
      await play();
      return;
    }
    await pause();
    _index = (_index + 1) % _words.length;
    notifyListeners();
    await play();
  }

  Future<void> previous() async {
    final elapsed = _startedAt == null
        ? 0.0
        : DateTime.now().difference(_startedAt!).inMilliseconds / 1000;
    if (elapsed > 1.5) {
      await play();
      return;
    }
    if (_words.length < 2) {
      await play();
      return;
    }
    await pause();
    _index = (_index - 1 + _words.length) % _words.length;
    notifyListeners();
    await play();
  }

  void setLoop(bool value) {
    _loop = value;
    notifyListeners();
  }

  void setIndex(int i) {
    if (_words.isEmpty) return;
    _index = i.clamp(0, _words.length - 1);
    notifyListeners();
  }

  void _startDoseClock() {
    _doseTimer?.cancel();
    _doseTimer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_tickDose()));
  }

  void _stopDoseClock() {
    _doseTimer?.cancel();
    _doseTimer = null;
  }

  Future<void> _tickDose() async {
    if (!_playing) return;
    final day = _today();
    if (day != _doseDay) {
      _doseDay = day;
      _dosePercent = 0;
    }
    final safe = safeSeconds(_db);
    // 100% dose = one full safe allowance at current level (or 8h if quiet).
    final denom = safe.isFinite ? safe : (8 * 3600);
    _dosePercent = (_dosePercent + (100.0 / denom)).clamp(0.0, 100.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_doseKeyPrefix$day', _dosePercent);
  }
}
