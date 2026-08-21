/// The word player — Listen / Record / Repeat / Meaning / Guide.
/// Same five tabs as the Walkman on the website.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/settings.dart';
import 'player_dial.dart';

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
  VideoPlayerController? _audio;

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
      backgroundColor: const Color(0xFF050506),
      body: Stack(
        children: [
          Positioned.fill(
            child: PlayerDial(word: w.word, playing: _playing, onPlay: () => _togglePlay(w, parts)),
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
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'PLAYER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                            color: Color(0x8CFFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00050506), Color(0x66050506), Color(0xB3050506)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
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
                                            ? Colors.white
                                            : const Color(0x8CFFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 2,
                                      color: _tab == i
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_tab > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _tabBodyText(w, parts),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xCCFFFFFF),
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlay(Word w, List<WordPart> parts) async {
    if (_playing) {
      await _audio?.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final url = (parts.isNotEmpty &&
            _part < parts.length &&
            parts[_part].audio.isNotEmpty)
        ? parts[_part].audio
        : (w.audioMale.isNotEmpty ? w.audioMale : w.audioFemale);
    if (url.isEmpty) {
      if (mounted) setState(() => _playing = true);
      return;
    }
    try {
      await _audio?.dispose();
    } catch (_) {}
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      final s = Settings.instance;
      await c.setVolume(s.volume);
      await c.setPlaybackSpeed(s.speed);
      final infinite = s.loop == 'infinite';
      await c.setLooping(infinite);
      await c.play();
      _audio = c;
      var left = infinite ? -1 : (s.loop == 'once' ? s.reps * 2 : s.reps);
      c.addListener(() {
        if (!mounted) return;
        final v = c.value;
        if (!v.isPlaying &&
            v.position >= v.duration &&
            v.duration > Duration.zero) {
          if (left > 1) {
            left--;
            c.seekTo(Duration.zero).then((_) => c.play());
            return;
          }
          setState(() => _playing = false);
        }
      });
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      try {
        await c.dispose();
      } catch (_) {}
      if (mounted) setState(() => _playing = true);
    }
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  String _tabBodyText(Word w, List<WordPart> parts) {
    final text = switch (_tab) {
      0 => 'Listen — each syllable lights as it is held. A recording per part plays when it exists; until then, say it with the boxes.',
      1 => 'Record — hold the mic, say the word, and the score compares your voice to the model.',
      2 => 'Repeat — x3 · x7 · x21. The last sound is the one that works.',
      3 => '${w.meaning}\n\nOrgan: ${w.organ}\nOrigin: ${w.origin}\n\n${w.benefit}',
      _ => 'Mouth: ${w.mouthPos}\n\nResonance: ${w.resonance}\n\nCommon mistake: ${w.mistake}\n\nTip: ${w.tip}',
    };
    return text;
  }
}
