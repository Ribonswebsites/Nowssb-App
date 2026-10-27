/// The client's reference recording(s) for a word, fetched through the same
/// 60-day voice cache the player uses. Every distinct recording on the word
/// (main, male, female) counts as one reference take.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/word_voice.dart';
import 'scorer.dart';

List<String> referenceUrls(Word w) {
  final out = <String>[];
  for (final u in [w.audio, w.audioMale, w.audioFemale]) {
    final t = u.trim();
    if (t.startsWith('http') && !out.contains(t)) out.add(t);
  }
  return out;
}

Future<List<Uint8List>> loadReferences(Word w) async {
  final out = <Uint8List>[];
  for (final u in referenceUrls(w)) {
    try {
      final f = await WordVoice.cache.getSingleFile(u);
      out.add(await f.readAsBytes());
    } catch (_) {}
  }
  return out;
}

class _Job {
  _Job(this.refs, this.take, this.syllables);
  final List<Uint8List> refs;
  final Uint8List take;
  final List<String> syllables;
}

PronunciationResult _run(_Job j) =>
    scoreTake(references: j.refs, take: j.take, syllables: j.syllables);

/// Scores off the UI thread.
Future<PronunciationResult> scoreInBackground(
        List<Uint8List> refs, Uint8List take, List<String> syllables) =>
    compute(_run, _Job(refs, take, syllables));
