/// PAPER RITUAL CARD (Ribon 11-02: the one he wants on the Normal home hero) — the Normal home's "TODAY" card, rebuilt as a cut-paper
/// diorama: a poster-type sky, a sun/moon that rides an arc, torn-paper
/// hills in three parallax layers, today's sessions as light-beads on the
/// arc and the streak as a stacked embossed tally. Sits on the white
/// neumorphic page (raised frame, inset window).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home_text.dart';
import 'ritual_card.dart' show RitualTime, ritualTimeFor;

class PaperRitualPalette {
  final String word, title;
  final List<Color> sky;
  final Color orb, orbGlow, far, mid, near, ink, accent, poster;
  final bool moon;
  /// Where the orb sits on the arc (0 = left horizon, 1 = right horizon).
  final double arcPos;
  /// Breath amplitude multiplier — calmer at night.
  final double motion;
  const PaperRitualPalette({
    required this.word, required this.title, required this.sky, required this.orb,
    required this.orbGlow, required this.far, required this.mid, required this.near,
    required this.ink, required this.accent, required this.poster,
    this.moon = false, required this.arcPos, required this.motion,
  });

  static PaperRitualPalette of(RitualTime t) => switch (t) {
        RitualTime.morning => const PaperRitualPalette(
            word: 'MORNING', title: 'Morning Ritual',
            sky: [Color(0xFFFFE3C4), Color(0xFFFFC9B0), Color(0xFFF6A79A)],
            orb: Color(0xFFFF8A3D), orbGlow: Color(0xFFFFD08A),
            far: Color(0xFFF3B8A6), mid: Color(0xFFE9897A), near: Color(0xFFC85C5C),
            ink: Color(0xFF3A1E1E), accent: Color(0xFFFF7A3D), poster: Color(0x55FFFFFF),
            arcPos: .22, motion: 1),
        RitualTime.afternoon => const PaperRitualPalette(
            word: 'NOON', title: 'Afternoon Ritual',
            sky: [Color(0xFFCFF2FF), Color(0xFF9FDCF5), Color(0xFF7CC6E8)],
            orb: Color(0xFFFFD447), orbGlow: Color(0xFFFFF1A8),
            far: Color(0xFFB5E3D2), mid: Color(0xFF6CC3A6), near: Color(0xFF2E8C7A),
            ink: Color(0xFF10343A), accent: Color(0xFF1C9C86), poster: Color(0x66FFFFFF),
            arcPos: .5, motion: 1),
        RitualTime.evening => const PaperRitualPalette(
            word: 'DUSK', title: 'Evening Ritual',
            sky: [Color(0xFF6B4BA8), Color(0xFFD9638A), Color(0xFFFFA569)],
            orb: Color(0xFFFF5E5B), orbGlow: Color(0xFFFFB36B),
            far: Color(0xFFB0577F), mid: Color(0xFF7A3B78), near: Color(0xFF3D2152),
            ink: Color(0xFF2A1638), accent: Color(0xFFE2557A), poster: Color(0x40FFFFFF),
            arcPos: .8, motion: .8),
        RitualTime.night => const PaperRitualPalette(
            word: 'NIGHT', title: 'Night Ritual',
            sky: [Color(0xFF0B1230), Color(0xFF1B2A5C), Color(0xFF34407A)],
            orb: Color(0xFFF4EBC8), orbGlow: Color(0xFF9FB2FF),
            far: Color(0xFF2B3A73), mid: Color(0xFF1C2754), near: Color(0xFF0E1534),
            ink: Color(0xFF141A33), accent: Color(0xFF6D7EF0), poster: Color(0x26FFFFFF),
            moon: true, arcPos: .64, motion: .55),
      };
}

class PaperRitualCard extends StatefulWidget {
  final int completed, total, sessionCount, streak;
  /// Defaults to device local time. Pass to pin (tests, admin preview).
  final RitualTime? time;
  final VoidCallback onBegin;
  final VoidCallback? onSeeProgress; // unused: Progress page removed
  /// Real ritual title (TodayRitual.title); null = the time of day's.
  final String? title;
  const PaperRitualCard({this.title,
    super.key, required this.completed, required this.total, required this.sessionCount,
    required this.streak, required this.onBegin, this.onSeeProgress, this.time,
  });

  @override
  State<PaperRitualCard> createState() => _PaperRitualCardState();
}

class _PaperRitualCardState extends State<PaperRitualCard> with TickerProviderStateMixin {
  static const _surface = Color(0xFFF0F2F7);
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 140), reverseDuration: const Duration(milliseconds: 420));
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  Offset _tilt = Offset.zero;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) {
      _breath..stop()..value = .5;
      _intro.value = 1;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _press.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _tap(VoidCallback cb) {
    HapticFeedback.lightImpact();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaperRitualPalette.of(widget.time ?? ritualTimeFor(DateTime.now()));
    final int done = widget.completed.clamp(0, math.max(widget.total, 0)).toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Color(0x24000000), offset: Offset(10, 10), blurRadius: 26),
            BoxShadow(color: Color(0xFAFFFFFF), offset: Offset(-7, -7), blurRadius: 20),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── the diorama window ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _press.forward(),
            onTapCancel: () => _press.reverse(),
            onTapUp: (_) => _press.reverse(),
            onTap: () => _tap(widget.onBegin),
            onPanUpdate: _reduced ? null : (d) => setState(() => _tilt = Offset(
                (_tilt.dx + d.delta.dx / 120).clamp(-1, 1), (_tilt.dy + d.delta.dy / 120).clamp(-1, 1))),
            onPanEnd: (_) => setState(() => _tilt = Offset.zero),
            child: Semantics(
              button: true,
              label: '${p.title}, $done of ${widget.total} done. Begin',
              child: AnimatedBuilder(
                animation: Listenable.merge([_breath, _press, _intro]),
                builder: (_, __) {
                  final b = Curves.easeInOutSine.transform(_breath.value);
                  final s = 1 - .02 * _press.value;
                  return Transform.scale(
                    scale: s,
                    child: AspectRatio(
                      aspectRatio: 1.32,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: CustomPaint(
                          painter: _ScenePainter(
                            p: p, breath: (b - .5) * p.motion, tilt: _tilt,
                            intro: Curves.easeOutCubic.transform(_intro.value),
                            done: done, total: widget.total,
                          ),
                          child: _SceneOverlay(p: p, done: done, total: widget.total, streak: widget.streak, breath: b),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── the strip under the window ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(builder: (ctx, c) {
              final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TODAY · ${widget.sessionCount} SESSIONS',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 10.5, letterSpacing: 1.6,
                        fontWeight: FontWeight.w700, color: p.ink.withValues(alpha: .55))),
                const SizedBox(height: 2),
                // HomeText heading weight, dark on white (no italic serif).
                Text(widget.title ?? p.title,
                    style: HomeText.heading.copyWith(fontSize: 22, color: const Color(0xFF1A1A2E))),
              ]);
              final buttons = Row(mainAxisSize: MainAxisSize.min, children: [
                _BeginButton(p: p, onTap: () => _tap(widget.onBegin)),
              ]);
              final scale = MediaQuery.textScalerOf(ctx).scale(10) / 10;
              if (c.maxWidth * (1 / scale) >= 330) {
                return Row(children: [Expanded(child: title), const SizedBox(width: 8), buttons]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                title, const SizedBox(height: 10),
                Row(children: [buttons]),
              ]);
            }),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

/// Text layers that sit inside the scene (poster numerals + streak tally).
class _SceneOverlay extends StatelessWidget {
  final PaperRitualPalette p;
  final int done, total, streak;
  final double breath;
  const _SceneOverlay({required this.p, required this.done, required this.total, required this.streak, required this.breath});

  @override
  Widget build(BuildContext context) {
    final light = p.moon || p.word == 'DUSK';
    return Stack(children: [
      // torn paper ticket: the progress fraction, poster type
      Positioned(
        left: 12, bottom: 12,
        child: Transform.rotate(
          angle: -.035,
          child: ClipPath(
            clipper: _TornClipper(seed: 3),
            child: Container(
              color: const Color(0xFFFFFBF2),
              padding: const EdgeInsets.fromLTRB(12, 8, 14, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '$done', style: TextStyle(fontFamily: 'Anton', fontSize: 30, height: 1, color: p.accent)),
                  TextSpan(text: ' / $total', style: TextStyle(fontFamily: 'Anton', fontSize: 18, height: 1, color: p.ink)),
                ]), textScaler: TextScaler.noScaling),
                Text(done >= total && total > 0 ? 'ALL LIT' : 'LIT TODAY',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, letterSpacing: 1.8,
                        fontWeight: FontWeight.w800, color: p.ink.withValues(alpha: .7))),
              ]),
            ),
          ),
        ),
      ),
      // streak: stacked embossed tally
      Positioned(
        right: 12, bottom: 12,
        child: _Tally(streak: streak, p: p, light: light),
      ),
    ]);
  }
}

class _Tally extends StatelessWidget {
  final int streak;
  final PaperRitualPalette p;
  final bool light;
  const _Tally({required this.streak, required this.p, required this.light});
  @override
  Widget build(BuildContext context) {
    final layers = streak.clamp(0, 5);
    return SizedBox(
      width: 74, height: 64,
      child: Stack(clipBehavior: Clip.none, children: [
        for (var i = layers - 1; i >= 1; i--)
          Positioned(
            right: i * 3.0, bottom: i * 4.0,
            child: Transform.rotate(
              angle: (i.isEven ? 1 : -1) * .05 * i,
              child: Container(width: 62, height: 50,
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFFEDE6D8), p.far, .25 * i / 5),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(1, 2), blurRadius: 3)],
                  )),
            ),
          ),
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 62, height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(2, 3), blurRadius: 5)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$streak', textScaler: TextScaler.noScaling,
                  style: TextStyle(fontFamily: 'Anton', fontSize: 24, height: 1, color: p.ink, shadows: const [
                    Shadow(color: Color(0xFFFFFFFF), offset: Offset(-1, -1)),
                    Shadow(color: Color(0x33000000), offset: Offset(1, 1), blurRadius: 1),
                  ])),
              const SizedBox(height: 2),
              Text('DAY STREAK', textScaler: TextScaler.noScaling,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 7.5, letterSpacing: 1.2,
                      fontWeight: FontWeight.w800, color: p.ink.withValues(alpha: .65))),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BeginButton extends StatefulWidget {
  final PaperRitualPalette p;
  final VoidCallback onTap;
  const _BeginButton({required this.p, required this.onTap});
  @override
  State<_BeginButton> createState() => _BeginButtonState();
}

class _BeginButtonState extends State<_BeginButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true, label: "Begin today's session", hint: widget.p.title, excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.p.ink,
            borderRadius: BorderRadius.circular(23),
            boxShadow: _down
                ? const [BoxShadow(color: Color(0x22000000), offset: Offset(2, 2), blurRadius: 4)]
                : const [
                    BoxShadow(color: Color(0x33000000), offset: Offset(6, 6), blurRadius: 14),
                    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-5, -5), blurRadius: 12),
                  ],
          ),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.play_arrow_rounded, size: 18, color: widget.p.orbGlow),
            const SizedBox(width: 4),
            const Text('Begin', textScaler: TextScaler.linear(1),
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

class _InsetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _InsetButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true, label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46, height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE6E9F0),
            boxShadow: [
              BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(4, 4), blurRadius: 8),
              BoxShadow(color: Color(0x1F000000), offset: Offset(-2, -2), blurRadius: 6),
            ],
          ),
          child: const Icon(Icons.insights_rounded, size: 20, color: Color(0xFF4A4E63)),
        ),
      ),
    );
  }
}

/// Deterministic torn-paper edge.
Path _tornEdge(Size s, double baseY, double amp, int seed, {double wave = 0, double phase = 0}) {
  final r = math.Random(seed);
  final path = Path()..moveTo(-20, s.height + 2);
  const step = 7.0;
  for (double x = -20; x <= s.width + 20; x += step) {
    final hill = math.sin(x / s.width * math.pi * (1.3 + seed % 3 * .4) + phase) * wave;
    final jag = (r.nextDouble() - .5) * amp;
    path.lineTo(x, baseY - hill + jag);
  }
  path..lineTo(s.width + 20, s.height + 2)..close();
  return path;
}

class _TornClipper extends CustomClipper<Path> {
  final int seed;
  const _TornClipper({required this.seed});
  @override
  Path getClip(Size s) {
    final r = math.Random(seed);
    final p = Path()..moveTo(0, 2);
    for (double x = 0; x <= s.width; x += 5) {
      p.lineTo(x, r.nextDouble() * 3);
    }
    p.lineTo(s.width, s.height);
    for (double x = s.width; x >= 0; x -= 5) {
      p.lineTo(x, s.height - r.nextDouble() * 3);
    }
    return p..close();
  }

  @override
  bool shouldReclip(_TornClipper o) => o.seed != seed;
}

class _ScenePainter extends CustomPainter {
  final PaperRitualPalette p;
  final double breath, intro;
  final Offset tilt;
  final int done, total;
  _ScenePainter({required this.p, required this.breath, required this.tilt, required this.intro, required this.done, required this.total});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // sky
    c.drawRect(Offset.zero & s, Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.sky).createShader(Offset.zero & s));

    // paper grain bands
    final grain = Paint()..color = Colors.white.withValues(alpha: p.moon ? .025 : .06);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(0, h * (.08 + i * .1), w, 2), grain);
    }

    // stars at night
    if (p.moon) {
      final r = math.Random(9);
      for (var i = 0; i < 46; i++) {
        final o = Offset(r.nextDouble() * w, r.nextDouble() * h * .55);
        final tw = .4 + .6 * (0.5 + 0.5 * math.sin(i + breath * 6));
        c.drawCircle(o, .6 + r.nextDouble() * 1.1, Paint()..color = Colors.white.withValues(alpha: .35 + .5 * tw * r.nextDouble()));
      }
    }

    // poster word, huge, behind everything (outline + soft fill)
    final px = tilt.dx * -4 + breath * 3;
    final tp = TextPainter(
      text: TextSpan(text: p.word, style: TextStyle(fontFamily: 'Anton', fontSize: h * .42, height: 1,
          letterSpacing: 2, color: p.poster)),
      textDirection: TextDirection.ltr,
    )..layout();
    final scale = math.min(1.0, (w - 16) / tp.width);
    c.save();
    c.translate(w / 2 - tp.width * scale / 2 + px, h * .06);
    c.scale(scale);
    tp.paint(c, Offset.zero);
    c.restore();

    // the arc
    final arcC = Offset(w / 2 + tilt.dx * -6, h * .74);
    final arcR = w * .44;
    final beadR = w * .33;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: .55);
    _dashedArc(c, arcC, arcR, arcPaint);
    _dashedArc(c, arcC, beadR, arcPaint..color = Colors.white.withValues(alpha: .3));

    // orb on arc
    final a = math.pi + math.pi * p.arcPos;
    final orbPos = arcC + Offset(math.cos(a), math.sin(a)) * arcR + Offset(0, breath * -4);
    final orbR = h * .085 * (1 + breath * .04);
    c.drawCircle(orbPos, orbR * 3.2, Paint()..shader = RadialGradient(colors: [
      p.orbGlow.withValues(alpha: .55), p.orbGlow.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: orbPos, radius: orbR * 3.2)));
    // paper disc with offset shadow (cut-out)
    c.drawCircle(orbPos + const Offset(2.5, 3), orbR, Paint()..color = Colors.black.withValues(alpha: .18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawCircle(orbPos, orbR, Paint()..color = p.orb);
    if (p.moon) {
      c.drawCircle(orbPos + Offset(orbR * .45, -orbR * .25), orbR * .86, Paint()..color = p.sky[1]);
    } else {
      c.drawCircle(orbPos + Offset(-orbR * .3, -orbR * .3), orbR * .35, Paint()..color = Colors.white.withValues(alpha: .35));
    }

    // session beads along the arc (light-points)
    final n = math.max(total, 1);
    for (var i = 0; i < n; i++) {
      final t = (i + .5) / n;
      final ang = math.pi + math.pi * (.08 + .84 * t);
      final pos = arcC + Offset(math.cos(ang), math.sin(ang)) * beadR + Offset(0, breath * (i.isEven ? 2 : -2));
      final lit = i < done;
      final reveal = (intro * n - i).clamp(0.0, 1.0);
      final r = 5.5 * (lit ? 1 + .12 * breath : 1) * (.6 + .4 * reveal);
      if (lit) {
        c.drawCircle(pos, r * 2.6, Paint()..color = p.orbGlow.withValues(alpha: .45 * reveal)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        c.drawCircle(pos, r, Paint()..color = Colors.white);
        c.drawCircle(pos, r * .55, Paint()..color = p.orb);
      } else {
        c.drawCircle(pos + const Offset(1, 1.5), r, Paint()..color = Colors.black.withValues(alpha: .12));
        c.drawCircle(pos, r, Paint()..color = Colors.white.withValues(alpha: p.moon ? .22 : .5));
        c.drawCircle(pos, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: .85));
      }
    }

    // torn-paper hills: far, mid, near — parallax
    void layer(Color col, double y, double amp, int seed, double wave, double par) {
      final dx = tilt.dx * par * -10 + breath * par * 5;
      final dy = tilt.dy * par * -4 + (1 - intro) * 40 * par;
      c.save();
      c.translate(dx, dy);
      final path = _tornEdge(s, y, amp, seed, wave: wave, phase: par);
      c.drawPath(path.shift(const Offset(0, -3)), Paint()..color = Colors.white.withValues(alpha: p.moon ? .18 : .7));
      c.drawShadow(path, Colors.black, 4, false);
      c.drawPath(path, Paint()..color = col);
      c.restore();
    }

    layer(p.far, h * .64, 4, 11, h * .06, .4);
    layer(p.mid, h * .74, 5, 23, h * .07, .8);
    layer(p.near, h * .86, 6, 37, h * .045, 1.3);
  }

  void _dashedArc(Canvas c, Offset ctr, double r, Paint paint) {
    const seg = 22;
    for (var i = 0; i < seg; i++) {
      if (i.isOdd) continue;
      c.drawArc(Rect.fromCircle(center: ctr, radius: r), math.pi + math.pi * i / seg, math.pi / seg, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter o) => true;
}
