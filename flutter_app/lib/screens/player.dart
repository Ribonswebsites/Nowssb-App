/// The word player — Listen / Record / Repeat / Meaning / Guide.
/// Same five tabs as the Walkman on the website.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.word});
  final Word? word;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _tab = 0;
  int _part = 0;
  bool _playing = false;

  Word get _word {
    if (widget.word != null) return widget.word!;
    final all = ContentStore.instance.library;
    return all.isEmpty
        ? const Word(
            key: 'aarogya',
            word: 'AAROGYA',
            deva: '',
            translit: '',
            phonetic: 'aa · ro · gyaa',
            parts: [],
            audioMale: '',
            audioFemale: '',
            organ: 'Immune System',
            origin: 'Natural Origin',
            benefit: 'Activates cellular immunity and vital life force',
            meaning: 'Perfect health — freedom from all disease',
            mouthPos: 'Open jaw, tongue flat, breath from belly',
            resonance: 'Feel vibration in chest and upper throat',
            mistake: "Don't rush the final syllable — hold it 1 second",
            tip: 'Say 3 times on exhale, eyes closed, hand on chest',
            categories: [],
            gender: 'both',
            time: 'morning',
            price: 0,
            img: '',
          )
        : all.first;
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    final parts = w.parts.isEmpty
        ? w.syllables
            .map((s) => WordPart(roman: s, deva: '', hold: 1.5, say: '', audio: ''))
            .toList()
        : w.parts;

    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/player-liquid-splash.mp4',
              priority: ClipPriority.feature,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xCC060C18)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        'PLAYER',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: Color(0xB3FFFFFF),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  w.word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  w.phonetic,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NwsbColors.goldLight,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _part = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: i == _part
                                ? NwsbColors.gold
                                : const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            parts[i].roman,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: i == _part ? NwsbColors.ink : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => setState(() => _playing = !_playing),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: NwsbColors.gold, width: 3),
                    ),
                    child: Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: NwsbColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _playing ? 'Playing' : 'Hold the last sound',
                  style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final (i, label) in [
                        'Listen',
                        'Record',
                        'Repeat',
                        'Meaning',
                        'Guide',
                      ].indexed)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = i),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _tab == i
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: _tab == i
                                        ? NwsbColors.goldLight
                                        : const Color(0x8CFFFFFF),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 2,
                                  color: _tab == i
                                      ? NwsbColors.goldLight
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    child: _tabBody(w, parts),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(Word w, List<WordPart> parts) {
    final text = switch (_tab) {
      0 => 'Listen — each syllable lights as it is held. A recording per part plays when it exists; until then, say it with the boxes.',
      1 => 'Record — hold the mic, say the word, and the score compares your voice to the model.',
      2 => 'Repeat — x3 · x7 · x21. The last sound is the one that works.',
      3 => '${w.meaning}\n\nOrgan: ${w.organ}\nOrigin: ${w.origin}\n\n${w.benefit}',
      _ => 'Mouth: ${w.mouthPos}\n\nResonance: ${w.resonance}\n\nCommon mistake: ${w.mistake}\n\nTip: ${w.tip}',
    };
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xCCFFFFFF),
          height: 1.55,
        ),
      ),
    );
  }
}
