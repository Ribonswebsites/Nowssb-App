// The word in Devanagari with the akshara being voiced lit up, in step with
// the teacher's recording as it plays. Timings come from the recording
// (tool/audio/akshara_times.py → "akshara" on each practice stage).
import 'package:flutter/material.dart';

import '../../data/word_voice.dart';
import 'stage_pack.dart';

const _virama = 0x094D;

/// Splits Devanagari into aksharas: a consonant with any virama-joined
/// consonants and its vowel signs, or an independent vowel.
List<String> devaAksharas(String s) {
  final out = <String>[];
  for (final r in s.runes) {
    if (r == 0x20) continue;
    final ch = String.fromCharCode(r);
    final dependent = (r >= 0x093A && r <= 0x094F) || (r >= 0x0900 && r <= 0x0903) ||
        (r >= 0x0955 && r <= 0x0957) || (r >= 0x0962 && r <= 0x0963);
    if (out.isNotEmpty && (dependent || out.last.runes.last == _virama)) {
      out[out.length - 1] += ch;
    } else {
      out.add(ch);
    }
  }
  return out;
}

/// Seconds the voice starts at in [asset]: the music versions put 2.5 s of
/// music before the teacher's voice.
double voiceOffsetFor(String? asset) =>
    asset != null && RegExp(r'_music\d?\.m4a$').hasMatch(asset) ? 2.5 : 0;

/// Which akshara is being voiced at [pos] seconds into [asset], or -1.
int aksharaAt(List<List<double>> times, double pos, String? asset) {
  final t = pos - voiceOffsetFor(asset);
  for (var i = 0; i < times.length; i++) {
    if (t >= times[i][0] && t < times[i][1]) return i;
  }
  return -1;
}

/// True when [stage] has Devanagari and timings to light up.
bool hasKaraoke(PackStage? stage, String fallbackDeva) {
  if (stage == null) return false;
  final deva = stage.deva.isNotEmpty ? stage.deva : fallbackDeva;
  return deva.isNotEmpty && stage.akshara.length == devaAksharas(deva).length;
}

class AksharaKaraoke extends StatelessWidget {
  const AksharaKaraoke({
    super.key,
    required this.deva,
    required this.times,
    this.size = 34,
    this.english,
    this.onlyWhilePlaying = false,
  });

  final String deva;
  final List<List<double>> times;
  final double size;
  final String? english;

  /// Hidden (zero size) unless a recording is playing.
  final bool onlyWhilePlaying;

  @override
  Widget build(BuildContext context) {
    final parts = devaAksharas(deva);
    final voice = WordVoice.instance;
    return ValueListenableBuilder<Duration?>(
      valueListenable: voice.position,
      builder: (_, pos, __) {
        final playing = pos != null;
        if (onlyWhilePlaying && !playing) return const SizedBox.shrink(key: ValueKey('akshara-hidden'));
        final on = playing && times.length == parts.length
            ? aksharaAt(times, pos.inMilliseconds / 1000, voice.currentAsset)
            : -1;
        final base = DefaultTextStyle.of(context).style;
        return Column(key: const ValueKey('akshara-karaoke'), mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < parts.length; i++)
              AnimatedDefaultTextStyle(
                key: ValueKey(i == on ? 'akshara-on-$i' : 'akshara-$i'),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                style: base.merge(TextStyle(
                  fontSize: size,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: !playing
                      ? const Color(0xF2FFFFFF)
                      : (i == on ? Colors.white : const Color(0x59FFFFFF)),
                  shadows: i == on
                      ? const [
                          Shadow(color: Color(0xCCFFFFFF), blurRadius: 14),
                          Shadow(color: Color(0x66FFFFFF), blurRadius: 28),
                        ]
                      : const [],
                )),
                child: Text(parts[i]),
              ),
          ]),
          if (english != null && english!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(english!,
                key: const ValueKey('akshara-english'),
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2.2)),
          ],
        ]);
      },
    );
  }
}
