/// A word that ships with the client's own recordings for each practice
/// stage (assets/content/client_words.json → `practice`). The recordings are
/// the only pronunciation reference — nothing synthetic is ever played.
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
  });

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
}

class StagePack {
  const StagePack({
    required this.wordKey,
    required this.word,
    required this.stages,
    this.musicCredit = '',
    this.passMark = 70,
  });

  final String wordKey;
  final String word;
  final List<PackStage> stages;
  final String musicCredit;

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
      ));
    }
    if (out.isEmpty) return null;
    return StagePack(
      wordKey: '${raw['key'] ?? ''}',
      word: '${raw['word'] ?? ''}',
      stages: out,
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
