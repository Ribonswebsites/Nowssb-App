import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../pronunciation/shabda/shabda_practice.dart';
import 'stage_checklist.dart';

/// A scored take plus the teacher recording's loudness contour, so the
/// Player can draw the word and point at WHERE the take differed.
class StageTake {
  const StageTake(this.result, this.refTimes, this.refEnergyDb, {this.checks = const []});
  final AttemptResult result;

  /// The "what to improve" checklist, worked out with the score (in the
  /// scoring isolate) so nothing is computed while the score animates.
  final List<StageCheck> checks;

  /// Frame times (s) and loudness (dB) of the conditioned reference — the
  /// same time base as `result.score.errors` / `refStart` / `refEnd`.
  final List<double> refTimes;
  final List<double> refEnergyDb;
}

/// Scores [take] against the teacher's [ref] recording for [stage] in a
/// background isolate: sounds, rhythm, pitch, vowel length, completeness,
/// with what to fix (and where) and what was right.
Future<AttemptResult> scoreStageTake(Uint8List ref, Uint8List take, {required int stage, required double passMark}) async =>
    (await scoreStageTakeWithContour(ref, take, stage: stage, passMark: passMark)).result;

Future<StageTake> scoreStageTakeWithContour(Uint8List ref, Uint8List take, {required int stage, required double passMark}) {
  return compute(_scoreJob, (ref, take, stage, passMark));
}

StageTake _scoreJob((Uint8List, Uint8List, int, double) a) {
  final feats = referenceFeatures(a.$1);
  final r = assessTakeBytes(feats, a.$2, stage: a.$3, config: PracticeConfig(passMark: a.$4));
  return StageTake(r, List<double>.of(feats.times), List<double>.of(feats.energyDb), checks: buildChecklist(r));
}
