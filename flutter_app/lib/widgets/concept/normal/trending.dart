/// Trending Now — "Live poster": the #1 word is a giant poster word with a
/// live equaliser rising behind it; #2/#3 sit on rank pebbles.
///
/// Data: [words] is the home's V5Trending ContentStore library pick (v5TrendingPick), in its
/// order. No play counts exist on the phone, so the copy makes no
/// "most played / healing the most" claim; it only says these are picks.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NTrending extends StatefulWidget {
  const NTrending({super.key, required this.words, required this.onWord, required this.onLibrary});
  /// Ranked words (ContentStore library pick), first = #1.
  final List<String> words;
  final void Function(String word) onWord;
  final VoidCallback onLibrary;
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
        Row(children: [
          const Text('Trending now', style: nHello),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: nLink, borderRadius: BorderRadius.circular(10)),
              child: const Text('#1', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white))),
          const Spacer(),
          const NLottie('assets/home/nm-anim-speaker.json', size: 36),
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
                TextSpan(text: widget.words[i], style: nHello.copyWith(color: nInk)),
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
