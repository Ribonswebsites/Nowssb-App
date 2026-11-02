/// R27 — the sound/meditation Hero (replaces the Cleopatra / red-haired
/// model heroes) and the black meditation banner (replaces the purple
/// banner-sit art).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'anims.dart';
import 'kit.dart';

/// One hour word from assets/content/library.json.
class R27HourWord {
  const R27HourWord(this.key, this.word, this.meaning);
  final String key, word, meaning;
}

/// Black stage: the hour's poster in an arch, a seated meditator breathing
/// in front of it, sound rings, and the other hour posters orbiting behind.
/// The giant Anton word sits under the arch (Hero language).
class R27SoundHero extends StatelessWidget {
  const R27SoundHero({super.key, required this.hour, required this.orbit, required this.onListen, required this.onOwn, this.hello = "This hour's sound"});
  final R27HourWord hour;
  /// Other hour poster keys for the orbit (text-free posters).
  final List<String> orbit;
  final VoidCallback onListen, onOwn;
  final String hello;
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: r27Black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: .92,
            child: LayoutBuilder(builder: (c, box) {
              final w = box.maxWidth, h = box.maxHeight;
              final archW = w * .5, archH = h * .66;
              return R27Anim(
                period: const Duration(seconds: 40),
                builder: (_, t) {
                  final cards = <({double z, Widget w})>[];
                  for (var i = 0; i < orbit.length; i++) {
                    final a = t * math.pi * 2 + i / orbit.length * math.pi * 2;
                    final z = math.sin(a); // -1 back … 1 front
                    final x = w / 2 + math.cos(a) * w * .42;
                    final y = h * .38 + z * h * .06;
                    final s = .62 + .2 * (z + 1) / 2;
                    final cw = w * .22 * s, ch = cw * 1.33;
                    cards.add((z: z, w: Positioned(
                      left: x - cw / 2, top: y - ch / 2, width: cw, height: ch,
                      child: Opacity(
                        opacity: .45 + .4 * (z + 1) / 2,
                        child: Transform.rotate(angle: math.cos(a) * .18,
                            child: ClipRRect(borderRadius: BorderRadius.circular(6), child: R27Img(orbit[i]))),
                      ),
                    )));
                  }
                  cards.sort((p, q) => p.z.compareTo(q.z));
                  final back = cards.where((e) => e.z < .2).map((e) => e.w);
                  final front = cards.where((e) => e.z >= .2).map((e) => e.w);
                  return Stack(clipBehavior: Clip.hardEdge, children: [
                    ...back,
                    Positioned(
                      left: (w - archW) / 2, top: h * .06, width: archW, height: archH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(archW / 2), bottom: const Radius.circular(8)),
                        child: Stack(fit: StackFit.expand, children: [
                          R27Img(hour.key, sat: .8),
                          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xB3000000)], stops: [.62, 1]))),
                        ]),
                      ),
                    ),
                    Positioned(
                      left: (w - archW * 1.15) / 2, top: h * .06 + archH * .38, width: archW * 1.15, height: archH * .7,
                      child: R27Meditator(figure: false, size: Size(archW * 1.15, archH * .7)),
                    ),
                    ...front,
                    Positioned(left: 14, right: 14, bottom: 0, height: h * .27,
                        child: R27Word(hour.word, align: Alignment.bottomCenter)),
                  ]);
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              R27Head(dark: true, hello: hello, title: hour.word[0] + hour.word.substring(1).toLowerCase(), sub: hour.meaning),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                R27Pill('Listen', onTap: onListen),
                R27Pill('Own this word', filled: false, onTap: onOwn),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Black meditation banner — replaces the purple banner-sit art. Poster
/// on the right fades into black; giant SIT word; greeting lines.
class R27MeditationBanner extends StatelessWidget {
  const R27MeditationBanner({super.key, required this.hourCount, required this.onTap, this.light = false});

  /// Normal home: white neumorphic card, dark text.
  final bool light;
  /// Real count of hour words in the library.
  final int hourCount;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: 'NowssB Meditation',
            child: DecoratedBox(
             decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: light ? r27LNeu : null),
             child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: light ? r27LSurf : r27Black,
                child: Stack(children: [
                  const SizedBox(width: double.infinity),
                  Positioned.fill(child: FractionallySizedBox(widthFactor: .58, heightFactor: 1, alignment: Alignment.centerRight,
                      child: Stack(fit: StackFit.expand, children: [
                        if (light) const Center(child: R27Meditator(color: Color(0xFFB07A1A), size: Size(150, 150))) else const R27Img('ojas', sat: .55),
                        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: light ? const [r27LSurf, Color(0x00F0F2F7)] : const [r27Black, Color(0x00000000)], stops: const [0, .7]))),
                      ]))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                    child: FractionallySizedBox(
                      widthFactor: .6,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('NowssB Meditation', style: light ? dHello.copyWith(color: r27LInk) : dHello),
                        const SizedBox(height: 6),
                        SizedBox(height: 70, child: R27Word('SIT', color: light ? const Color(0xFF8A5A0B) : r27Gold, shadow: !light)),
                        const SizedBox(height: 8),
                        Text('$hourCount hour words · sit with one', style: light ? dSub.copyWith(color: r27LSub) : dSub),
                        const SizedBox(height: 12),
                        R27Pill('Begin', onTap: onTap),
                      ]),
                    ),
                  ),
                ]),
              ),
             ),
            ),
          ),
        ),
      );
}
