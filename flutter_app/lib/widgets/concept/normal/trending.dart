/// Trending Now — "Live poster": the #1 word is a giant poster word with a
/// live equaliser rising behind it; #2/#3 sit on rank pebbles.
///
/// Data: [words] is the shared Trending ranking (trendingChart, first three via v5TrendingPick), in its
/// order. No play counts exist on the phone, so the copy makes no
/// "most played / healing the most" claim; it only says these are picks.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NTrending extends StatefulWidget {
  const NTrending({super.key, required this.words, required this.onWord, required this.onLibrary, this.onSeeAll});
  /// Ranked words (ContentStore library pick), first = #1.
  final List<String> words;
  final void Function(String word) onWord;
  final VoidCallback onLibrary;
  /// Opens the full Trending page; no link when null.
  final VoidCallback? onSeeAll;
  @override
  State<NTrending> createState() => _NTrendingState();
}

class _NTrendingState extends State<NTrending> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 3);
  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) return const SizedBox.shrink();
    final top = widget.words.first;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 10), child: Container(
      decoration: neu(r: 30), padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Wrap, not Flexible: at 320 x1.3 the badge drops below instead of
          // breaking 'Trending' mid-word.
          Expanded(child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Trending now', style: nHello),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: nLink, borderRadius: BorderRadius.circular(10)),
                child: const Text('#1', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white))),
          ])),
          // 'See all' takes the bars' place at the right of the title row, one line.
          if (widget.onSeeAll case final onSeeAll?)
            TextButton(key: const ValueKey('trending-see-all'), onPressed: onSeeAll,
                style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8), minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('See all', softWrap: false, maxLines: 1, style: nLinkStyle))
          else
            // small live equaliser (same loop as the poster), not a speaker icon
            ExcludeSemantics(child: SizedBox(width: 30, height: 24, child: AnimatedBuilder(animation: loop,
                builder: (_, __) => CustomPaint(painter: _Bars(loop.value))))),
        ]),
        const SizedBox(height: 6),
        NPress(label: 'Open $top', onTap: () => widget.onWord(top), child: SizedBox(height: 120, child: Stack(children: [
          Positioned.fill(child: AnimatedBuilder(animation: loop, builder: (_, __) =>
              CustomPaint(painter: _Eq(loop.value)))),
          Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(fit: BoxFit.contain, alignment: Alignment.centerLeft,
              child: Text(top.toUpperCase(), textScaler: TextScaler.noScaling,
                  style: nPoster.copyWith(fontSize: 120, letterSpacing: 3))))),
        ]))),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (var i = 1; i < widget.words.length && i < 3; i++)
            NPress(label: 'Open ${widget.words[i]}', onTap: () => widget.onWord(widget.words[i]), child: Container(
              decoration: neu(r: 18, pressed: true),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '0${i + 1}  ', style: nSub.copyWith(color: nLink, fontWeight: FontWeight.w700)),
                TextSpan(text: titleCase(widget.words[i]), style: nHello.copyWith(color: nInk)),
              ])),
            )),
        ]),
        const SizedBox(height: 10),
        const Text('Picked from the library today', style: nSub),
        Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: widget.onLibrary,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 44)),
            child: const Text('Open the library  →', style: nLinkStyle))),
      ]),
    ));
  }
}

/// 'SURYA' -> 'Surya', 'NEW MOON' -> 'New Moon' (library words are upper case).
String titleCase(String s) => s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');

class _Bars extends CustomPainter {
  _Bars(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    const n = 4;
    final bw = s.width / n;
    final p = Paint()..color = nLink;
    for (var i = 0; i < n; i++) {
      final v = .3 + .7 * (.5 + .5 * math.sin(t * math.pi * 2 * 3 + i * 1.7));
      c.drawRRect(RRect.fromLTRBR(i * bw + 2, s.height * (1 - v), (i + 1) * bw - 2, s.height, const Radius.circular(2)), p);
    }
  }
  @override
  bool shouldRepaint(_Bars o) => o.t != t;
}

class _Eq extends CustomPainter {
  _Eq(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    const n = 26;
    final bw = s.width / n;
    for (var i = 0; i < n; i++) {
      final v = .25 + .75 * (.5 + .5 * math.sin(t * math.pi * 2 * 2 + i * .7)) * (.5 + .5 * math.sin(i * 1.3));
      final hgt = s.height * v;
      c.drawRRect(RRect.fromLTRBR(i * bw + 2, s.height - hgt, (i + 1) * bw - 2, s.height, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Color(0xCC6C63D9), Color(0x406C63D9)]).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
    }
  }
  @override
  bool shouldRepaint(_Eq o) => o.t != t;
}
