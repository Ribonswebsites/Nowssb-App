/// A word that ships with the client's own recordings for each practice
/// stage (assets/content/client_words.json → `practice`). The recordings are
/// the only pronunciation reference — nothing synthetic is ever played.
///
/// Adding a recorded stage is a drop-in:
///  1. put `<word>_stage<N>_clean.m4a` (what Listen plays), optionally
///     `<word>_stage<N>_music.m4a`, and `<word>_stage<N>_ref.wav` (16 kHz
///     mono WAV that takes are scored against) in assets/words/<word>/;
///  2. add `{"stage": N, "deva": "…", "audio": …, "music": …,
///     "reference": …, "seconds": …}` to the word's `practice.stages` in
///     client_words.json, and take N out of `practice.comingSoon`.
/// A stage listed in `practice.comingSoon` shows as a locked "Coming soon"
/// slot with no audio until its recording is added.
library;

import '../../data/content.dart';
import '../../data/models.dart';

class PackStage {
  const PackStage({
    required this.number,
    required this.title,
    required this.text,
    required this.audio,
    required this.music,
    required this.reference,
    required this.seconds,
    this.musicSeconds = 0,
    this.deva = '',
    this.akshara = const [],
  });

  /// When each akshara of [deva] (or the word's) is voiced in [audio], in
  /// seconds: [[start, end], ...]. Empty when not measured.
  final List<List<double>> akshara;

  /// The client's Devanagari for this stage (from the recording's own
  /// label), or '' when the client has not given one.
  final String deva;

  /// 1-based.
  final int number;
  final String title;
  final String text;

  /// The cleaned client recording (asset path) — what "Listen" plays.
  final String audio;

  /// The same recording over soft background music, or '' when there is none.
  final String music;

  /// The client's original take as 16-bit WAV — what attempts are scored
  /// against.
  final String reference;

  /// Length of [audio] in seconds.
  final double seconds;

  /// Length of [music] in seconds (0 when unknown).
  final double musicSeconds;
}

class StagePack {
  const StagePack({
    required this.wordKey,
    required this.word,
    required this.stages,
    this.musicCredit = '',
    this.passMark = 70,
    this.deva = '',
    this.comingSoon = const [],
  });

  final String wordKey;
  final String word;

  /// The word in Devanagari as the client wrote it, or ''.
  final String deva;
  final List<PackStage> stages;
  final String musicCredit;

  /// Stage numbers the teacher has not recorded yet: shown as locked
  /// "Coming soon" slots, never playable.
  final List<int> comingSoon;

  /// Overall score that passes a stage (from the pack; provisional).
  final double passMark;

  bool get hasMusic => stages.any((s) => s.music.isNotEmpty);

  /// Parses the raw shipped entry. Null when it has no usable practice block.
  static StagePack? fromRaw(Map<String, dynamic> raw) {
    final practice = raw['practice'];
    if (practice is! Map) return null;
    final list = practice['stages'];
    if (list is! List || list.isEmpty) return null;
    final rawStages = raw['stages'] is List ? raw['stages'] as List : const [];
    final out = <PackStage>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m is! Map) continue;
      final ref = '${m['reference'] ?? ''}';
      final audio = '${m['audio'] ?? ''}';
      if (ref.isEmpty || audio.isEmpty) continue;
      final meta = i < rawStages.length && rawStages[i] is Map ? rawStages[i] as Map : const {};
      final n = (m['stage'] as num?)?.toInt() ?? i + 1;
      out.add(PackStage(
        number: n,
        title: '${meta['title'] ?? 'Stage $n'}',
        text: '${meta['text'] ?? ''}',
        audio: audio,
        music: '${m['music'] ?? ''}',
        reference: ref,
        seconds: (m['seconds'] as num?)?.toDouble() ?? 2.5,
        musicSeconds: (m['musicSeconds'] as num?)?.toDouble() ?? 0,
        deva: '${m['deva'] ?? meta['deva'] ?? ''}'.trim(),
        akshara: [
          if (m['akshara'] is List)
            for (final a in m['akshara'] as List)
              if (a is List && a.length == 2) [(a[0] as num).toDouble(), (a[1] as num).toDouble()],
        ],
      ));
    }
    if (out.isEmpty) return null;
    return StagePack(
      wordKey: '${raw['key'] ?? ''}',
      word: '${raw['word'] ?? ''}',
      deva: '${raw['deva'] ?? ''}'.trim(),
      stages: out,
      comingSoon: [
        if (practice['comingSoon'] is List)
          for (final c in practice['comingSoon'] as List)
            if ((c is Map ? c['stage'] : c) case final num n)
              if (!out.any((s) => s.number == n.toInt())) n.toInt(),
      ],
      musicCredit: '${practice['musicCredit'] ?? ''}',
      passMark: (practice['passMark'] as num?)?.toDouble() ?? 70,
    );
  }

  /// The practice pack for [w], when the app ships one for its key.
  static StagePack? forWord(Word w) => forKey(w.key);

  static StagePack? forKey(String key) {
    final raw = ContentStore.instance.clientWordRaw(key);
    return raw == null ? null : fromRaw(raw);
  }
}

/// Copy for a stage the teacher has not recorded yet.
const kStageComingSoon = 'Coming soon';
String stageComingSoonNote(int n) => 'Stage $n opens here as soon as your teacher records it.';
