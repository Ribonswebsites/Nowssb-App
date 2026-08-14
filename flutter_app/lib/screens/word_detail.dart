/// One word, in full.
///
/// This is the screen the content model was built for. A NowssB word is not
/// an English word — it is a sound, written in Devanagari, which has letters
/// English does not have. There is no roman spelling of ऋ a reader can simply
/// read out. So the word arrives in four parts at once and this screen shows
/// all four:
///
///   deva      आरोग्य        the word as it is actually written
///   word      AAROGYA       a roman spelling to hold on to
///   parts[]   आ · रो · ग्य   the pronunciation boxes, three to five of them
///   audio     a recording    the only thing that ever settles an argument
///
/// Each box carries its own Devanagari, its own roman spelling, how long to
/// hold it, and one plain sentence on how to make the sound. That is what a
/// reader who has never seen Devanagari actually needs: something to look at,
/// something to read, and something to hear.
library;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

class WordDetail extends StatelessWidget {
  const WordDetail({super.key, required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          // The player's own artwork, which is what the website puts behind
          // a word. assets/player/liquid-splash.webp is the still of the
          // same film — a picture here rather than a decoder, because this
          // page is for reading.
          Positioned.fill(
            child: Image.asset(
              'assets/player/liquid-splash.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: NwsbColors.deep),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB3060C18), Color(0xFA060C18)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(title: word.word),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _Headline(word: word),
                      const SizedBox(height: 26),
                      if (word.parts.isNotEmpty) ...[
                        const _SectionLabel('HOW TO SAY IT'),
                        const SizedBox(height: 12),
                        _Parts(parts: word.parts),
                        const SizedBox(height: 26),
                      ],
                      if (word.meaning.isNotEmpty)
                        _Fact(
                          label: 'MEANING',
                          value: word.meaning,
                          icon: Icons.translate,
                        ),
                      if (word.benefit.isNotEmpty)
                        _Fact(
                          label: 'WHAT IT DOES',
                          value: word.benefit,
                          icon: Icons.favorite_border,
                        ),
                      if (word.organ.isNotEmpty)
                        _Fact(
                          label: 'WHERE IT WORKS',
                          value: word.organ,
                          icon: Icons.my_location,
                        ),
                      if (word.mouthPos.isNotEmpty)
                        _Fact(
                          label: 'YOUR MOUTH',
                          value: word.mouthPos,
                          icon: Icons.record_voice_over_outlined,
                        ),
                      if (word.resonance.isNotEmpty)
                        _Fact(
                          label: 'WHERE YOU FEEL IT',
                          value: word.resonance,
                          icon: Icons.graphic_eq,
                        ),
                      if (word.mistake.isNotEmpty)
                        _Fact(
                          label: 'THE COMMON MISTAKE',
                          value: word.mistake,
                          icon: Icons.error_outline,
                          warn: true,
                        ),
                      if (word.tip.isNotEmpty)
                        _Fact(
                          label: 'A TIP',
                          value: word.tip,
                          icon: Icons.lightbulb_outline,
                        ),
                      const SizedBox(height: 18),
                      if (word.categories.isNotEmpty) _Chips(word.categories),
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: NwsbColors.ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.origin,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
            color: NwsbColors.gold,
          ),
        ),
        const SizedBox(height: 14),
        // The Devanagari first and largest when it exists — it is the word.
        // The roman spelling under it is a reading aid, not the thing itself.
        if (word.deva.isNotEmpty)
          Text(
            word.deva,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        Text(
          word.word,
          style: TextStyle(
            fontSize: word.deva.isEmpty ? 42 : 26,
            fontWeight: FontWeight.w800,
            color: word.deva.isEmpty ? Colors.white : NwsbColors.goldLight,
            height: 1.1,
            letterSpacing: word.deva.isEmpty ? -0.5 : 1,
          ),
        ),
        if (word.phonetic.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            word.phonetic,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0x99FFFFFF),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w700,
        color: Color(0x8CFFFFFF),
      ),
    );
  }
}

/// The pronunciation boxes. Three to five, side by side and scrollable —
/// they are read left to right as one word, so they must not wrap into a
/// grid where the reading order stops being obvious.
class _Parts extends StatelessWidget {
  const _Parts({required this.parts});
  final List<WordPart> parts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = parts[i];
          return Container(
            width: 116,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.gold,
                  ),
                ),
                const Spacer(),
                if (p.deva.isNotEmpty)
                  Text(
                    p.deva,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                Text(
                  p.roman,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: p.deva.isEmpty ? 22 : 15,
                    fontWeight: FontWeight.w700,
                    color: p.deva.isEmpty
                        ? Colors.white
                        : const Color(0xB3FFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'hold ${p.hold.toStringAsFixed(p.hold % 1 == 0 ? 0 : 1)}s',
                  style: const TextStyle(
                    fontSize: 10,
                    color: NwsbColors.goldLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.icon,
    this.warn = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warn ? const Color(0x1AE0342B) : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warn ? const Color(0x33E0342B) : const Color(0x14FFFFFF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 17,
              color: warn ? const Color(0xFFFF8A80) : NwsbColors.goldLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: warn
                        ? const Color(0xCCFF8A80)
                        : const Color(0x8CFFFFFF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xCCFFFFFF),
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }
}
