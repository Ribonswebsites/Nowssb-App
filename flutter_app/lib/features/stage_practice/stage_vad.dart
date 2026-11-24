/// Ends a practice take by itself: speech, then a short silence.
///
/// Fed the microphone's level (dBFS, about 20 times a second). The first
/// quarter second sets the room's noise floor; speech is a level clearly
/// above it. Once the word has been said (at least [minSpeech] of speech),
/// [silenceToStop] of quiet after it ends the take. A take with no speech
/// at all ends after [noSpeechTimeout]; any take ends at [maxLength].
library;

import 'dart:math' as math;

enum VadDecision { keepGoing, finished, noSpeech, tooLong }

class StageVad {
  StageVad({
    required this.maxLength,
    this.silenceToStop = const Duration(milliseconds: 900),
    this.minSpeech = const Duration(milliseconds: 200),
    this.noSpeechTimeout = const Duration(seconds: 5),
    this.calibration = const Duration(milliseconds: 250),
  });

  /// Max take length for a stage whose recording runs [stageSeconds]: the
  /// recording's own length twice over plus a few seconds, capped at 15 s.
  factory StageVad.forStage(double stageSeconds) => StageVad(
        maxLength: Duration(milliseconds: (math.min(15.0, stageSeconds * 2 + 3) * 1000).round()),
        noSpeechTimeout: Duration(milliseconds: (math.max(4.0, math.min(7.0, stageSeconds + 3)) * 1000).round()),
      );

  final Duration maxLength;
  final Duration silenceToStop;
  final Duration minSpeech;
  final Duration noSpeechTimeout;
  final Duration calibration;

  final List<double> _floorSamples = [];
  double? _floor;
  Duration? _speechStart;
  Duration _speech = Duration.zero;
  Duration? _quietSince;
  Duration? _last;

  bool get heardSpeech => _speech >= minSpeech;

  /// Level a frame must reach to count as speech.
  double get threshold {
    final f = _floor ?? -60;
    return (f + 12).clamp(-48.0, -22.0);
  }

  /// One level reading [db] at time [t] since the take started.
  VadDecision add(double db, Duration t) {
    final dt = _last == null ? Duration.zero : t - _last!;
    _last = t;
    if (!db.isFinite) db = -90;
    if (_floor == null) {
      _floorSamples.add(db);
      if (t >= calibration && _floorSamples.length >= 3) {
        final s = [..._floorSamples]..sort();
        _floor = s[s.length ~/ 2];
      }
      // Speech right at the start still counts once the floor is known.
      if (_floor == null) return _limit(t);
    }
    final loud = db >= threshold;
    final quiet = db < threshold - 3;
    if (loud) {
      _speechStart ??= t;
      _speech += dt;
      _quietSince = null;
    } else if (quiet && _speechStart != null) {
      _quietSince ??= t;
    }
    if (heardSpeech && _quietSince != null && t - _quietSince! >= silenceToStop) {
      return VadDecision.finished;
    }
    return _limit(t);
  }

  VadDecision _limit(Duration t) {
    if (t >= maxLength) return heardSpeech ? VadDecision.tooLong : VadDecision.noSpeech;
    if (!heardSpeech && t >= noSpeechTimeout) return VadDecision.noSpeech;
    return VadDecision.keepGoing;
  }
}
