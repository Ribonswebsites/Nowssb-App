/// RITUAL CARD v2 — a dark NowssB cinema frame inset in a raised white
/// neumorphic shell. A headphone cut-out model stands silhouetted against a
/// time-of-day sky; the giant time word is split-layered (behind her head,
/// in front of her body); light rays + flare; slow camera push-in; today's
/// sessions are light points on the horizon; the x/8 and streak are etched
/// into the ground plate.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RitualTime { morning, afternoon, evening, night }

/// Device-local hour: 05–11 morning, 12–16 afternoon, 17–20 evening, 21–04 night.
RitualTime ritualTimeFor(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return RitualTime.morning;
  if (h >= 12 && h < 17) return RitualTime.afternoon;
  if (h >= 17 && h < 21) return RitualTime.evening;
  return RitualTime.night;
}

class RitualPalette {
  final String word, title, model;
  final List<Color> sky;
  final Color sun, glow, ground, accent, wordBack, wordFront, cloud;
  final bool moon;
  /// Sun x position (0..1) and height above horizon (0..1 of sky).
  final double sunX, sunY;
  /// Motion multiplier — night is slowest.
  final double motion;
  /// Silhouette strength 0 (lit) .. 1 (black).
  final double shade;
  const RitualPalette({
    required this.word, required this.title, required this.model, required this.sky,
    required this.sun, required this.glow, required this.ground, required this.accent,
    required this.wordBack, required this.wordFront, required this.cloud,
    this.moon = false, required this.sunX, required this.sunY, required this.motion, required this.shade,
  });

  static RitualPalette of(RitualTime t) => switch (t) {
        RitualTime.morning => const RitualPalette(
            word: 'MORNING', title: 'Morning Ritual', model: 'assets/hero-curve/subject.webp',
            sky: [Color(0xFF2B1B5E), Color(0xFF8E3F8F), Color(0xFFF07A5A), Color(0xFFFFC77A)],
            sun: Color(0xFFFFE3A0), glow: Color(0xFFFFB25C), ground: Color(0xFF140A2A),
            accent: Color(0xFFFFB25C), wordBack: Color(0xFFFFF1D6), wordFront: Color(0xFFFFD08A),
            cloud: Color(0xFFFF9E80), sunX: .26, sunY: .12, motion: 1, shade: .55),
        RitualTime.afternoon => const RitualPalette(
            word: 'AFTERNOON', title: 'Afternoon Ritual', model: 'assets/hero-curve/tab-subject.webp',
            sky: [Color(0xFF1C2E8C), Color(0xFF3F6FE0), Color(0xFF7FB6FF), Color(0xFFD7E9FF)],
            sun: Color(0xFFFFFFFF), glow: Color(0xFFFFF4C2), ground: Color(0xFF120B30),
            accent: Color(0xFFFFE27A), wordBack: Color(0xFFFFFFFF), wordFront: Color(0xFFFFE27A),
            cloud: Color(0xFFFFFFFF), sunX: .2, sunY: .78, motion: 1, shade: .5),
        RitualTime.evening => const RitualPalette(
            word: 'EVENING', title: 'Evening Ritual', model: 'assets/hero-curve/cleopatra.webp',
            sky: [Color(0xFF12082E), Color(0xFF4A1466), Color(0xFFC2305E), Color(0xFFFF7A3C)],
            sun: Color(0xFFFF6A3D), glow: Color(0xFFFF4D6D), ground: Color(0xFF0D0620),
            accent: Color(0xFFFF6A8A), wordBack: Color(0xFFFFE0EA), wordFront: Color(0xFFFF8FA8),
            cloud: Color(0xFFB0306A), sunX: .74, sunY: .06, motion: .8, shade: .7),
        RitualTime.night => const RitualPalette(
            word: 'NIGHT', title: 'Night Ritual', model: 'assets/hero-curve/pointer.webp',
            sky: [Color(0xFF03030F), Color(0xFF0C0C2E), Color(0xFF1E1650), Color(0xFF3A2A7A)],
            sun: Color(0xFFF2EEDC), glow: Color(0xFF8E7CFF), ground: Color(0xFF05040F),
            accent: Color(0xFFA897FF), wordBack: Color(0xFFE9E4FF), wordFront: Color(0xFFB9ABFF),
            cloud: Color(0xFF3A2E80), moon: true, sunX: .16, sunY: .8, motion: .5, shade: .35),
      };
}

class RitualCard extends StatefulWidget {
  final int completed, total, sessionCount, streak;
  /// Null = device local time. Pass to pin (tests, admin preview).
  final RitualTime? time;
  /// The real ritual title (TodayRitual.title); null = the palette's.
  final String? title;
  final VoidCallback onBegin, onSeeProgress;
  /// At total/total the primary becomes 'Play again'; falls back to onBegin.
  final VoidCallback? onReplay;
  /// Test hook: fixes breath (0..1) and push-in (0..1) phases.
  final double? debugPhase;
  const RitualCard({
    super.key, required this.completed, required this.total, required this.sessionCount,
    required this.streak, required this.onBegin, required this.onSeeProgress, this.onReplay, this.time, this.title, this.debugPhase,
  });

  @override
  State<RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<RitualCard> with TickerProviderStateMixin {
  static const _surface = Color(0xFFF0F2F7);
  static const _base = Color(0xFF0C0C20);
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500));
  late final AnimationController _push = AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final AnimationController _press = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 140), reverseDuration: const Duration(milliseconds: 420));
  late final AnimationController _ignite = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  Offset _tilt = Offset.zero;
  bool _reduced = false;
  RitualTime? _lastTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _sync();
  }

  void _sync() {
    final tm = widget.time ?? ritualTimeFor(DateTime.now());
    final m = RitualPalette.of(tm).motion;
    if (_reduced || widget.debugPhase != null) {
      _breath.stop();
      _push.stop();
      _breath.value = widget.debugPhase ?? .5;
      _push.value = widget.debugPhase ?? .5;
      _ignite.value = 1;
      return;
    }
    if (_lastTime != tm) {
      _lastTime = tm;
      _breath.duration = Duration(milliseconds: (5500 / m).round());
      _push.duration = Duration(milliseconds: (24000 / m).round());
      _breath.repeat(reverse: true);
      _push.repeat(reverse: true);
    }
    if (_ignite.value == 0) _ignite.forward();
  }

  @override
  void didUpdateWidget(RitualCard old) {
    super.didUpdateWidget(old);
    if (old.completed != widget.completed && !_reduced) _ignite.forward(from: 0);
    _sync();
  }

  @override
  void dispose() {
    _breath.dispose();
    _push.dispose();
    _press.dispose();
    _ignite.dispose();
    super.dispose();
  }

  void _tap(VoidCallback cb) {
    HapticFeedback.lightImpact();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final p = RitualPalette.of(widget.time ?? ritualTimeFor(DateTime.now()));
    final total = math.max(widget.total, 0);
    final int done = widget.completed.clamp(0, total).toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        // raised white neumorphic shell
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(color: Color(0x24000000), offset: Offset(10, 10), blurRadius: 26),
            BoxShadow(color: Color(0xFAFFFFFF), offset: Offset(-7, -7), blurRadius: 20),
          ],
        ),
        padding: const EdgeInsets.all(9),
        child: Container(
          // inset dark cinema frame
          decoration: BoxDecoration(
            color: _base,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
            boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(-2, -2), blurRadius: 4)],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                label: '${widget.title ?? p.title}. $done of $total sessions done today. ${widget.streak} day streak. Begin',
                child: ExcludeSemantics(
                  child: AspectRatio(
                    aspectRatio: 1.02,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_breath, _push, _press, _ignite]),
                      builder: (_, __) => _Scene(
                        p: p, done: done, total: total, streak: widget.streak,
                        breath: (Curves.easeInOutSine.transform(_breath.value) - .5) * 2,
                        push: Curves.easeInOutSine.transform(_push.value),
                        press: _press.value, ignite: Curves.easeOutCubic.transform(_ignite.value), tilt: _tilt,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _Footer(p: p, title: widget.title ?? p.title, sessionCount: widget.sessionCount, complete: total > 0 && done >= total,
                onBegin: () => _tap(done >= total && total > 0 ? (widget.onReplay ?? widget.onBegin) : widget.onBegin), onSeeProgress: () => _tap(widget.onSeeProgress)),
          ]),
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  final RitualPalette p;
  final int done, total, streak;
  final double breath, push, press, ignite;
  final Offset tilt;
  const _Scene({required this.p, required this.done, required this.total, required this.streak,
      required this.breath, required this.push, required this.press, required this.ignite, required this.tilt});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final horizon = h * .74;
      final cam = 1.0 + .07 * push - .015 * press; // slow push-in, tap dips
      Offset par(double depth) => Offset(-tilt.dx * 10 * depth + breath * 3 * depth * p.motion, -tilt.dy * 5 * depth);
      final wordStyle = TextStyle(fontFamily: 'Anton', height: .92, letterSpacing: 1.5, fontSize: 200,
          color: p.wordBack);
      final wordBox = Rect.fromLTWH(12, h * .17, w - 24, h * .25);
      Widget word(Color col, {List<Shadow>? shadows}) => Positioned.fromRect(
            rect: wordBox.shift(par(.6)),
            child: FittedBox(fit: BoxFit.contain, child: Text(p.word, textScaler: TextScaler.noScaling,
                style: wordStyle.copyWith(color: col, shadows: shadows))),
          );
      final modelH = h * .86;
      final modelRect = Rect.fromLTWH(w * .52, -h * .02, modelH * .62, modelH);

      return Transform.scale(
        scale: cam,
        alignment: Alignment(.1, .2),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          // 1 · sky, clouds, stars, sun/moon, rays
          Positioned.fill(child: CustomPaint(painter: _SkyPainter(p: p, horizon: horizon, breath: breath, tilt: tilt))),
          // 2 · the word, behind her (full, bright)
          word(p.wordBack, shadows: [Shadow(color: p.glow.withValues(alpha: .6), blurRadius: 24)]),
          // 3 · model, silhouetted with a rim light
          Positioned.fromRect(
            rect: modelRect.shift(par(1)),
            child: Stack(fit: StackFit.expand, children: [
              Transform.translate(offset: const Offset(-2, -1), child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: ColorFiltered(colorFilter: ColorFilter.mode(p.glow, BlendMode.srcIn),
                    child: Image.asset(p.model, fit: BoxFit.contain, alignment: Alignment.bottomCenter)),
              )),
              ColorFiltered(
                colorFilter: ColorFilter.mode(Color.lerp(p.ground, Colors.black, .3)!.withValues(alpha: p.shade), BlendMode.srcATop),
                child: Image.asset(p.model, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
              ),
            ]),
          ),
          // 4 · the word again, in front of her body only (split layering)
          Positioned.fill(child: ClipRect(clipper: _BandClip(Rect.fromLTRB(0, wordBox.top + wordBox.height * .16, w, h)),
              child: Stack(children: [word(p.wordBack, shadows: const [Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, -2))])]))),
          // 5 · ground plate, horizon lights, etched data
          Positioned.fill(child: CustomPaint(painter: _GroundPainter(
              p: p, horizon: horizon, done: done, total: total, ignite: ignite, breath: breath, shift: par(1.4)))),
          Positioned(
            left: 14 + par(1.4).dx, right: 14 - par(1.4).dx, top: horizon + h * .065,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _Etched(big: '$done/$total', small: done >= total && total > 0 ? 'ALL LIT TODAY' : 'LIT TODAY', p: p),
              const Spacer(),
              _Etched(big: '$streak', small: 'DAY STREAK', p: p, end: true),
            ]),
          ),
          // 6 · lens flare, vignette, glass sheen
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FlarePainter(p: p, horizon: horizon, breath: breath, tilt: tilt)))),
        ]),
      );
    });
  }
}

class _BandClip extends CustomClipper<Rect> {
  final Rect r;
  const _BandClip(this.r);
  @override
  Rect getClip(Size size) => r;
  @override
  bool shouldReclip(_BandClip o) => o.r != r;
}

/// Data carved into the ground plate: dark inset type with a lit lower lip.
class _Etched extends StatelessWidget {
  final String big, small;
  final RitualPalette p;
  final bool end;
  const _Etched({required this.big, required this.small, required this.p, this.end = false});
  @override
  Widget build(BuildContext context) {
    final lip = p.accent.withValues(alpha: .55);
    return Column(crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(big, textScaler: TextScaler.noScaling, style: TextStyle(fontFamily: 'DM Sans', fontSize: 26, fontWeight: FontWeight.w800, height: 1.1,
          color: Color.lerp(p.accent, Colors.white, .35), shadows: [
            const Shadow(color: Color(0xE6000000), offset: Offset(0, -1.5)),
            Shadow(color: lip, offset: const Offset(0, 1.5), blurRadius: 1),
            Shadow(color: p.glow.withValues(alpha: .5), blurRadius: 14),
          ])),
      const SizedBox(height: 3),
      Text(small, textScaler: TextScaler.noScaling, style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, letterSpacing: 2.2,
          fontWeight: FontWeight.w800, color: p.accent.withValues(alpha: .85))),
    ]);
  }
}

class _SkyPainter extends CustomPainter {
  final RitualPalette p;
  final double horizon, breath;
  final Offset tilt;
  _SkyPainter({required this.p, required this.horizon, required this.breath, required this.tilt});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final sky = Rect.fromLTWH(0, 0, w, horizon + 2);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: p.sky, stops: const [0, .45, .8, 1]).createShader(sky));
    final sun = Offset(w * p.sunX - tilt.dx * 3, horizon - horizon * p.sunY + breath * -3 * p.motion);
    // atmosphere bloom
    c.drawCircle(sun, w * .7, Paint()..shader = RadialGradient(colors: [
      p.glow.withValues(alpha: .55), p.glow.withValues(alpha: .12), p.glow.withValues(alpha: 0)], stops: const [0, .45, 1])
        .createShader(Rect.fromCircle(center: sun, radius: w * .7)));
    // stars
    if (p.moon) {
      final r = math.Random(4);
      for (var i = 0; i < 90; i++) {
        final o = Offset((r.nextDouble() * w + breath * 6 + tilt.dx * -3) % w, r.nextDouble() * horizon * .9);
        final tw = .5 + .5 * math.sin(i * 1.7 + breath * 3);
        c.drawCircle(o, .4 + r.nextDouble() * 1.2, Paint()..color = Colors.white.withValues(alpha: .25 + .65 * tw * r.nextDouble()));
      }
    }
    // light rays (day only); night gets a moon halo instead
    if (p.moon) {
      for (final k in [.18, .3, .46]) {
        c.drawCircle(sun, w * k * (1 + .03 * breath), Paint()..color = p.sun.withValues(alpha: .07)..maskFilter = MaskFilter.blur(BlurStyle.normal, w * k * .35));
      }
    }
    final rays = Paint()..blendMode = BlendMode.plus;
    for (var i = 1; i < (p.moon ? 0 : 8); i++) {
      final a = -math.pi / 2 + (i - 4) * .33 + breath * .03 + (p.sunX - .5) * .8;
      final len = w * 1.4;
      final spread = .05 + (i % 3) * .02;
      final path = Path()
        ..moveTo(sun.dx, sun.dy)
        ..lineTo(sun.dx + math.cos(a - spread) * len, sun.dy + math.sin(a - spread) * len)
        ..lineTo(sun.dx + math.cos(a + spread) * len, sun.dy + math.sin(a + spread) * len)
        ..close();
      rays.shader = RadialGradient(colors: [p.sun.withValues(alpha: p.moon ? .10 : .22), p.sun.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: sun, radius: len * .8));
      c.drawPath(path, rays);
    }
    // clouds: soft layered banks drifting with breath
    final r = math.Random(p.word.length);
    for (var layer = 0; layer < 3; layer++) {
      final y = horizon * (.25 + layer * .2);
      final cp = Paint()
        ..color = p.cloud.withValues(alpha: p.moon ? .18 : .22 + layer * .06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 - layer * 3.0);
      for (var k = 0; k < 4; k++) {
        final cx = r.nextDouble() * w + breath * (6 + layer * 5) * p.motion - tilt.dx * (4 + layer * 4);
        c.drawOval(Rect.fromCenter(center: Offset(cx, y + r.nextDouble() * 18), width: w * (.3 + r.nextDouble() * .35), height: 30 + r.nextDouble() * 18), cp);
      }
    }
    // sun / moon disc
    c.drawCircle(sun, w * .075, Paint()..color = p.sun..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    if (p.moon) {
      c.drawCircle(sun + Offset(w * .03, -w * .018), w * .066, Paint()..color = p.sky[1]);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter o) => true;
}

class _GroundPainter extends CustomPainter {
  final RitualPalette p;
  final double horizon, ignite, breath;
  final int done, total;
  final Offset shift;
  _GroundPainter({required this.p, required this.horizon, required this.done, required this.total,
      required this.ignite, required this.breath, required this.shift});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // distant ridge
    final ridge = Path()..moveTo(0, horizon);
    for (double x = 0; x <= w; x += 6) {
      ridge.lineTo(x, horizon - 6 - 5 * math.sin(x / w * 7 + 1) - 3 * math.sin(x / w * 23));
    }
    ridge..lineTo(w, h)..lineTo(0, h)..close();
    c.drawPath(ridge, Paint()..color = Color.lerp(p.ground, p.sky[2], .25)!);
    // ground plate (glossy dark with a reflected glow)
    final g = Rect.fromLTWH(0, horizon - h * .08, w, h - horizon + h * .08);
    final dune = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += 4) {
      dune.lineTo(x, duneY(x, w, h));
    }
    dune..lineTo(w, h)..close();
    c.drawPath(dune, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color.lerp(p.ground, p.glow, .25)!, p.ground, Colors.black]).createShader(g));
    // dune rim light
    final rim = Path()..moveTo(0, duneY(0, w, h));
    for (double x = 0; x <= w; x += 4) {
      rim.lineTo(x, duneY(x, w, h));
    }
    c.drawPath(rim, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = p.sun.withValues(alpha: .75));
    // horizon lights: one per session, ignite as done
    final n = math.max(total, 1);
    if (total > 0 && done >= total) {
      final line = Path()..moveTo(w * .06, duneY(w * .06, w, h));
      for (double x = w * .06; x <= w * .94; x += 3) {
        line.lineTo(x, duneY(x, w, h));
      }
      final on = ignite;
      c.drawPath(line, Paint()..style = PaintingStyle.stroke..strokeWidth = 10 * on..color = p.glow.withValues(alpha: .45 * on)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawPath(line, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: on));
      // keep going: all beads glow on top of the joined line at 8/8
    }
    var litCount = 0;
    for (var i = 0; i < n; i++) {
      final x = w * (.06 + .88 * (i + .5) / n) + shift.dx * .5;
      final pos = Offset(x, duneY(x, w, h));
      final lit = i < done;
      final on = lit ? (ignite * n - i * .6).clamp(0.0, 1.0) : 0.0;
      if (on > 0) {
        final pulse = 1 + .15 * breath;
        c.drawCircle(pos, 16 * on * pulse, Paint()..color = p.glow.withValues(alpha: .35 * on)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        c.drawLine(pos.translate(-14 * on, 0), pos.translate(14 * on, 0), Paint()..color = Colors.white.withValues(alpha: .8 * on)..strokeWidth = 1);
        c.drawLine(pos.translate(0, 18 * on), pos, Paint()..color = p.glow.withValues(alpha: .5 * on)..strokeWidth = 2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        c.drawCircle(pos, 3.4, Paint()..color = Colors.white);
        litCount++;
      } else {
        c.drawCircle(pos, 2.6, Paint()..color = Colors.white.withValues(alpha: .28));
        c.drawCircle(pos, 2.6, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = p.accent.withValues(alpha: .5));
      }
    }
    _GroundPainter.debugLitBeads = litCount;
  }

  /// Lit beads drawn in the last paint (tests).
  @visibleForTesting
  static int debugLitBeads = 0;

  /// Foreground dune: flat horizon on the left, rising in a soft swell in
  /// front of the model so she stands behind it (never a straight crop).
  double duneY(double x, double w, double h) {
    final t = x / w;
    final swell = math.exp(-math.pow((t - .66) / .2, 2)) * h * .085;
    return horizon - swell + 2 * math.sin(t * 19);
  }

  @override
  bool shouldRepaint(_GroundPainter o) => true;
}

class _FlarePainter extends CustomPainter {
  final RitualPalette p;
  final double horizon, breath;
  final Offset tilt;
  _FlarePainter({required this.p, required this.horizon, required this.breath, required this.tilt});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final sun = Offset(w * p.sunX - tilt.dx * 3, horizon - horizon * p.sunY);
    final ctr = Offset(w / 2, h / 2) + tilt * 8;
    final add = Paint()..blendMode = BlendMode.plus;
    const ghosts = [(.45, 10.0, .10), (.8, 5.0, .14), (1.25, 22.0, .06), (1.6, 8.0, .10)];
    for (final g in ghosts) {
      final pos = Offset.lerp(sun, ctr, g.$1 + breath * .03)!;
      add.color = p.glow.withValues(alpha: g.$3 * (p.moon ? 0 : 1));
      c.drawCircle(pos, g.$2, add);
    }
    // vignette
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = RadialGradient(radius: .9, colors: [Colors.transparent, Colors.black.withValues(alpha: .45)], stops: const [.6, 1]).createShader(r));
  }

  @override
  bool shouldRepaint(_FlarePainter o) => true;
}

class _Footer extends StatelessWidget {
  final RitualPalette p;
  final int sessionCount;
  final String title;
  final bool complete;
  final VoidCallback onBegin, onSeeProgress;
  const _Footer({required this.p, required this.title, required this.sessionCount, required this.onBegin, required this.onSeeProgress, this.complete = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: .07), Colors.white.withValues(alpha: .02)]),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .12))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: LayoutBuilder(builder: (ctx, c) {
        final head = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Greeting type system: hello 19/w300 soft · name 26/w800 · sub 12.5 faint.
          Text('Today', style: TextStyle(fontFamily: 'DM Sans', fontSize: 19, fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: .62))),
          // B022: break only between words. Each word is its own unbreakable
          // run (scaled down only if a single word is wider than the line).
          Wrap(key: const ValueKey('ritual-title'), spacing: 7, children: [
            for (final w in title.split(' '))
              FittedBox(fit: BoxFit.scaleDown, child: Text(w, maxLines: 1, softWrap: false,
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.1))),
          ]),
          const SizedBox(height: 2),
          Text('$sessionCount sessions so far', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12.5,
              color: Colors.white.withValues(alpha: .6))),
        ]);
        final scale = MediaQuery.textScalerOf(ctx).scale(10) / 10;
        // Primary always first (left on a row, top when stacked).
        final go = complete
            ? _Pill(label: 'Play again', icon: Icons.replay_rounded, onTap: onBegin, p: p, primary: true)
            : _Pill(label: 'Begin', icon: Icons.play_arrow_rounded, onTap: onBegin, p: p, primary: true);
        final see = complete
            ? _Pill(label: 'Ritual complete', icon: Icons.check_circle_rounded, onTap: null, p: p, primary: false)
            : _Pill(label: 'See progress', icon: Icons.insights_rounded, onTap: onSeeProgress, p: p, primary: false);
        if (c.maxWidth / scale < 300) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            head, const SizedBox(height: 12), go, const SizedBox(height: 8), see]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          head, const SizedBox(height: 12),
          Row(children: [Expanded(flex: 5, child: go), const SizedBox(width: 8), Expanded(flex: 6, child: see)]),
        ]);
      }),
    );
  }
}

class _Pill extends StatefulWidget {
  final String label;
  final IconData icon;
  /// null → a non-tappable status chip.
  final VoidCallback? onTap;
  final RitualPalette p;
  final bool primary;
  const _Pill({required this.label, required this.icon, required this.onTap, required this.p, required this.primary});
  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final pr = widget.primary;
    if (widget.onTap == null) {
      return Semantics(label: widget.label, child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(widget.icon, size: 18, color: widget.p.accent),
          const SizedBox(width: 6),
          Flexible(child: Text(widget.label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13.5,
              fontWeight: FontWeight.w700, color: widget.p.accent))),
        ]),
      ));
    }
    return Semantics(
      button: true, label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .95 : 1, duration: const Duration(milliseconds: 140), curve: Curves.easeOut,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: pr ? LinearGradient(colors: [widget.p.sun, widget.p.accent]) : null,
              color: pr ? null : Colors.white.withValues(alpha: .08),
              border: Border.all(color: Colors.white.withValues(alpha: pr ? .5 : .22)),
              boxShadow: pr ? [BoxShadow(color: widget.p.glow.withValues(alpha: .45), blurRadius: 16)] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 18, color: pr ? const Color(0xFF14100A) : Colors.white),
              const SizedBox(width: 6),
              Flexible(child: Text(widget.label, textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13.5, fontWeight: FontWeight.w800,
                      color: pr ? const Color(0xFF14100A) : Colors.white))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Lit horizon beads in the last painted card (tests only).
@visibleForTesting
int get ritualDebugLitBeads => _GroundPainter.debugLitBeads;
