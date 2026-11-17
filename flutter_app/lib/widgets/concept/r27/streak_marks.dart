/// Streak marks — three candidates for the Normal-home "YOUR STREAK" tile
/// (72 × 84 inside the inset well). All hand-painted; no circles, orbs,
/// rings, orbiting dots, aurora or particles.
///  • [StreakVoiceStair] (A) — seven voice-meter bars rising as a stair.
///  • [StreakLetterSha]  (B) — the Devanagari श (shabda, "word") written
///    stroke by stroke in gold, then a soft gold shimmer. The fill deepens
///    with the streak; 0 days is still a clear pale-gold letter.
///  • [StreakDiyaLine]   (C) — a line-art diya whose flame grows with the streak.
/// Each plays a one-time intro on open, then a calm loop. Still under
/// reduced motion and in tests ([StreakMarkFrame.debug] picks a frame).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/settings.dart';
import '../normal/surface.dart' show NormalLoop;
import 'kit.dart';

const _tau = math.pi * 2;
const _accent = Color(0xFF6C63D9);
const _indigo = Color(0xFF453BB3);
const _gold = r27Gold;
const _groove = Color(0xFFD9DCE5);
const _ghost = Color(0xFFDADDE6);

/// Lit days in the current week, the same rule as the card's seven checks.
int streakLitInWeek(int s) => s <= 0 ? 0 : (s % 7 == 0 ? 7 : s % 7);

/// Debug override: render a fixed (intro, loop) frame.
class StreakMarkFrame {
  static (double, double)? debug;
}

/// One-shot intro + repeating loop, both frozen when motion is off (shared by
/// every streak mark, including streak_marks2.dart).
class StreakMarkAnim extends StatefulWidget {
  const StreakMarkAnim({super.key, required this.intro, required this.period, required this.builder});
  final Duration intro;
  final Duration period;
  final Widget Function(BuildContext, double intro, double t) builder;
  @override
  State<StreakMarkAnim> createState() => _StreakMarkAnimState();
}

class _StreakMarkAnimState extends State<StreakMarkAnim> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: widget.intro);
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.period);

  /// Reduced motion, shot/test freeze, or the Settings "Still" motion switch.
  bool get _still => r27Still(context) || !Settings.instance.fashionPlus;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    if (_still) {
      _in
        ..stop()
        ..value = 1;
      _loop
        ..stop()
        ..value = NormalLoop.debugT ?? .35;
    } else {
      if (_in.value < 1 && !_in.isAnimating) _in.forward();
      if (!_loop.isAnimating) _loop.repeat();
    }
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_sync);
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_in, _loop]),
        builder: (c, _) {
          final d = StreakMarkFrame.debug;
          return widget.builder(c, d?.$1 ?? _in.value, d?.$2 ?? _loop.value);
        },
      );
}

double _ease(double x) => Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));
double _seg(double x, double a, double b) => ((x - a) / (b - a)).clamp(0.0, 1.0);

// ───────────────────────── A · voice stair ─────────────────────────

/// Seven rounded voice-wave bars that rise like a stair. This week's days
/// are inked purple and breathe like a live voice level; today's bar is
/// gold. At 0 days the grooves sit empty with a slow "listening" lift.
class StreakVoiceStair extends StatelessWidget {
  const StreakVoiceStair({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: const Duration(milliseconds: 1100),
          period: const Duration(milliseconds: 2400),
          builder: (_, i, t) => CustomPaint(size: size, painter: _StairP(streak, i, t)),
        ),
      );
}

class _StairP extends CustomPainter {
  _StairP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;
  @override
  void paint(Canvas c, Size s) {
    const n = 7;
    final lit = streakLitInWeek(streak);
    final gap = s.width * .05;
    final bw = (s.width - gap * (n + 1)) / n;
    final mid = s.height * .5;
    final minH = s.height * .22, maxH = s.height * .86;
    final r = Radius.circular(bw / 2);
    for (var i = 0; i < n; i++) {
      final x = gap + i * (bw + gap);
      final h = minH + (maxH - minH) * i / (n - 1);
      // Empty groove: a pressed channel in the well, centred like a waveform.
      c.drawRRect(RRect.fromLTRBR(x, mid - h / 2, x + bw, mid + h / 2, r), Paint()..color = _groove);
      c.drawRRect(
        RRect.fromLTRBR(x + bw * .55, mid - h / 2 + bw * .45, x + bw * .82, mid + h / 2 - bw * .45, Radius.circular(bw * .14)),
        Paint()..color = const Color(0x99FFFFFF),
      );
      if (i < lit) {
        final grow = _ease(_seg(intro, i * .07, .45 + i * .07));
        final wave = math.sin(_tau * (t - i * .12));
        final level = (.78 + .22 * (.5 + .5 * wave)) * grow;
        final hh = math.max(bw, h * level);
        final today = i == lit - 1;
        final bar = RRect.fromLTRBR(x, mid - hh / 2, x + bw, mid + hh / 2, r);
        c.drawRRect(
          bar,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x, mid + h / 2),
              Offset(x, mid - h / 2),
              today
                  ? const [Color(0xFFB98222), _gold, Color(0xFFFFE3A0)]
                  : const [_indigo, _accent, Color(0xFF9C95F0)],
              const [0, .55, 1],
            ),
        );
        c.drawRRect(
          RRect.fromLTRBR(x + bw * .2, mid - hh / 2 + bw * .5, x + bw * .4, mid + hh / 2 - bw * .5, Radius.circular(bw * .1)),
          Paint()..color = const Color(0x59FFFFFF),
        );
      } else if (lit == 0) {
        // Idle: one soft "listening" lift travels across the empty grooves.
        final p = (t - i / n) % 1.0;
        final lift = math.max(0.0, math.sin(p * math.pi * 2)) * .55 * _ease(intro);
        final hh = h * lift;
        if (hh > bw * 1.6) {
          c.drawRRect(RRect.fromLTRBR(x, mid - hh / 2, x + bw, mid + hh / 2, r),
              Paint()..color = _accent.withValues(alpha: .22));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StairP o) => o.t != t || o.intro != intro || o.streak != streak;
}

// ───────────────────────── B · letter श written ─────────────────────────

/// The Devanagari श (shabda — "word") written stroke by stroke in gold:
/// bowl, tail, stem, then the headline. After the last stroke it holds with
/// a soft gold shimmer. Fill and intensity deepen with the streak; at 0 days
/// the letter is still a clear pale gold. Glyph outline from Noto Sans
/// Devanagari (SIL OFL 1.1).
class StreakLetterSha extends StatelessWidget {
  const StreakLetterSha({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: const Duration(milliseconds: 1900),
          period: const Duration(milliseconds: 3200),
          builder: (_, i, t) => CustomPaint(size: size, painter: _ShaP(streak, i, t)),
        ),
      );
}

/// Noto Sans Devanagari (wght 600) glyph U+0936, font units, y down
/// (y = 700 − font y). © The Noto Project Authors, SIL Open Font License 1.1.
final Path _shaT = Path()
      ..moveTo(647,174)
      ..lineTo(647,700)
      ..lineTo(530,700)
      ..lineTo(530,174)
      ..lineTo(453,174)
      ..lineTo(453,78)
      ..lineTo(743,78)
      ..lineTo(743,174)
      ..close();
final Path _shaBowl = Path()
      ..moveTo(139,544)
      ..quadraticBezierTo(89,544,57.0,520.5)
      ..quadraticBezierTo(25,497,25,455)
      ..quadraticBezierTo(25,422,47.0,403.0)
      ..quadraticBezierTo(69,384,104,384)
      ..quadraticBezierTo(136,384,161.0,398.5)
      ..quadraticBezierTo(186,413,214,445)
      ..lineTo(226,465)
      ..quadraticBezierTo(275,505,318.5,553.0)
      ..quadraticBezierTo(362,601,401,652)
      ..lineTo(303,714)
      ..quadraticBezierTo(252,641,207.5,585.5)
      ..quadraticBezierTo(163,530,125,492)
      ..lineTo(127,441)
      ..quadraticBezierTo(185,436,226.5,412.0)
      ..quadraticBezierTo(268,388,291.0,348.0)
      ..quadraticBezierTo(314,308,314,256)
      ..quadraticBezierTo(314,208,294.0,182.0)
      ..quadraticBezierTo(274,156,236,156)
      ..quadraticBezierTo(209,156,193.5,170.5)
      ..quadraticBezierTo(178,185,178,206)
      ..quadraticBezierTo(178,233,202.0,247.5)
      ..quadraticBezierTo(226,262,269,266)
      ..lineTo(241,342)
      ..quadraticBezierTo(158,334,114.5,298.0)
      ..quadraticBezierTo(71,262,71,201)
      ..quadraticBezierTo(71,141,112.5,104.5)
      ..quadraticBezierTo(154,68,232,68)
      ..quadraticBezierTo(295,68,339.0,92.5)
      ..quadraticBezierTo(383,117,406.0,161.0)
      ..quadraticBezierTo(429,205,429,265)
      ..quadraticBezierTo(429,326,406.0,375.0)
      ..quadraticBezierTo(383,424,339.5,460.0)
      ..quadraticBezierTo(296,496,235,519)
      ..lineTo(218,528)
      ..quadraticBezierTo(196,536,177.0,540.5)
      ..quadraticBezierTo(158,545,139,544)
      ..close();
final Path _shaGlyph = Path()
  ..addPath(_shaT, Offset.zero)
  ..addPath(_shaBowl, Offset.zero);

Offset _fu(double x, double y) => Offset(x, 700 - y);

/// Writing order as thick mask strokes (font units, y up → flipped).
final List<(Path, double)> _shaStrokes = [
  (
    Path()
      ..moveTo(_fu(255, 425).dx, _fu(255, 425).dy)
      ..cubicTo(_fu(185, 440).dx, _fu(185, 440).dy, _fu(118, 470).dx, _fu(118, 470).dy, _fu(118, 530).dx, _fu(118, 530).dy)
      ..cubicTo(_fu(118, 590).dx, _fu(118, 590).dy, _fu(200, 620).dx, _fu(200, 620).dy, _fu(290, 620).dx, _fu(290, 620).dy)
      ..cubicTo(_fu(400, 620).dx, _fu(400, 620).dy, _fu(470, 540).dx, _fu(470, 540).dy, _fu(470, 450).dx, _fu(470, 450).dy)
      ..cubicTo(_fu(470, 320).dx, _fu(470, 320).dy, _fu(370, 220).dx, _fu(370, 220).dy, _fu(250, 195).dx, _fu(250, 195).dy)
      ..cubicTo(_fu(150, 175).dx, _fu(150, 175).dy, _fu(70, 195).dx, _fu(70, 195).dy, _fu(70, 250).dx, _fu(70, 250).dy)
      ..cubicTo(_fu(70, 300).dx, _fu(70, 300).dy, _fu(150, 315).dx, _fu(150, 315).dy, _fu(230, 270).dx, _fu(230, 270).dy),
    160,
  ),
  (Path()..moveTo(_fu(160, 200).dx, _fu(160, 200).dy)..lineTo(_fu(360, 0).dx, _fu(360, 0).dy), 150),
  (Path()..moveTo(_fu(588, 522).dx, _fu(588, 522).dy)..lineTo(_fu(588, -20).dx, _fu(588, -20).dy), 140),
  (Path()..moveTo(_fu(430, 575).dx, _fu(430, 575).dy)..lineTo(_fu(760, 575).dx, _fu(760, 575).dy), 130),
];

class _ShaP extends CustomPainter {
  _ShaP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;

  static const _box = Rect.fromLTRB(25, 68, 743, 714);

  /// 0 at no streak, 1 at a week or more. The letter stays gold at 0.
  double get _fill => streak <= 0 ? 0.0 : (streak / 7).clamp(0.0, 1.0);

  @override
  void paint(Canvas c, Size s) {
    final k = math.min(s.width * .86 / _box.width, s.height * .8 / _box.height);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(k);
    c.translate(-_box.center.dx, -_box.center.dy);
    final px = 1 / k; // one logical pixel in glyph units

    // Soft pressed ghost so the well never looks empty mid-stroke.
    c.drawPath(_shaGlyph.shift(Offset(-px, -px)), Paint()..color = const Color(0xFFFFFFFF));
    c.drawPath(_shaGlyph.shift(Offset(px * .8, px * .8)), Paint()..color = const Color(0x1A000000));
    c.drawPath(_shaGlyph, Paint()..color = const Color(0xFFE6E8EF));

    final f = _fill;
    final top = Color.lerp(const Color(0xFFEEDBA8), const Color(0xFFFFF1C2), f)!;
    final mid = Color.lerp(const Color(0xFFD4B56C), _gold, f)!;
    final deep = Color.lerp(const Color(0xFFB89248), const Color(0xFF8A5E14), f)!;
    final alpha = 0.66 + 0.34 * f;

    final bounds = _box.inflate(40);
    c.saveLayer(bounds, Paint());
    c.drawPath(
      _shaGlyph,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 100),
          const Offset(0, 714),
          [
            top.withValues(alpha: alpha),
            mid.withValues(alpha: alpha),
            deep.withValues(alpha: alpha),
          ],
          const [0, .45, 1],
        ),
    );
    // Slightly brighter gold on the headline, written last.
    c.drawRect(
      const Rect.fromLTRB(440, 70, 750, 176),
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = ui.Gradient.linear(
          const Offset(0, 78),
          const Offset(0, 176),
          [
            const Color(0xFFFFF6D0).withValues(alpha: alpha),
            Color.lerp(const Color(0xFFE8C36A), _gold, f)!.withValues(alpha: alpha),
          ],
        ),
    );
    // Linear highlight along the letter — not a circular shine.
    c.drawPath(
      _shaGlyph,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = ui.Gradient.linear(
          const Offset(80, 120),
          const Offset(420, 520),
          [
            const Color(0xFFFFFFFF).withValues(alpha: 0.20 + 0.10 * f),
            const Color(0x00FFFFFF),
          ],
        ),
    );
    if (intro < 1) {
      c.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
      const spans = [(0.0, .46), (.46, .62), (.62, .80), (.80, 1.0)];
      final mask = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF000000);
      for (var i = 0; i < _shaStrokes.length; i++) {
        final p = _ease(_seg(intro, spans[i].$1, spans[i].$2));
        if (p <= 0) continue;
        final (path, w) = _shaStrokes[i];
        mask
          ..strokeWidth = w
          ..strokeCap = i < 2 ? StrokeCap.round : StrokeCap.butt;
        c.save();
        c.clipPath(i < 2 ? _shaBowl : _shaT);
        for (final m in path.computeMetrics()) {
          c.drawPath(m.extractPath(0, m.length * p), mask);
        }
        c.restore();
      }
      c.restore();
    }
    c.restore();

    // Crisp gold edge once the letter is written, so a pale 0-day mark stays sharp.
    if (intro >= 1) {
      c.drawPath(
        _shaGlyph,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeJoin = StrokeJoin.round
          ..color = deep.withValues(alpha: 0.55 + 0.35 * f),
      );
      _sheen(c, t, 0.7 + 0.3 * f);
    }
    c.restore();
  }

  /// A diagonal band of gold light that sweeps across the letter once per loop.
  void _sheen(Canvas c, double t, double strength) {
    final x = -300 + 1500 * _ease(_seg(t, .12, .82));
    final gleam = (0.18 + 0.14 * _fill) * strength;
    c.save();
    c.clipPath(_shaGlyph);
    c.drawRect(
      _box.inflate(60),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x - 160, 80),
          Offset(x + 160, 680),
          [
            const Color(0x00FFF6D8),
            const Color(0xFFFFF6D8).withValues(alpha: gleam),
            const Color(0x00FFF6D8),
          ],
          const [0, .5, 1],
        ),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_ShaP o) => o.t != t || o.intro != intro || o.streak != streak;
}

// ───────────────────────── C · line-art diya ─────────────────────────

/// A clean line-drawn diya. On open the lamp is drawn, then the flame is
/// traced; the flame then sways. Flame height follows the streak (1 → 7+).
/// 0 days: an unlit lamp with a thin curl of smoke line drifting up.
class StreakDiyaLine extends StatelessWidget {
  const StreakDiyaLine({super.key, required this.streak, this.size = const Size(72, 84)});
  final int streak;
  final Size size;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: StreakMarkAnim(
          intro: const Duration(milliseconds: 1500),
          period: const Duration(milliseconds: 2800),
          builder: (_, i, t) => CustomPaint(size: size, painter: _DiyaP(streak, i, t)),
        ),
      );
}

class _DiyaP extends CustomPainter {
  _DiyaP(this.streak, this.intro, this.t);
  final int streak;
  final double intro, t;

  void _trace(Canvas c, Path p, Paint paint, double f) {
    if (f <= 0) return;
    for (final m in p.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * f), paint);
    }
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final lip = h * .70; // rim of the lamp
    final sw = math.max(2.2, w * .036);

    // Lamp: a boat-shaped bowl with a pinched spout on the right and a foot.
    final bowl = Path()
      ..moveTo(w * .12, lip)
      ..cubicTo(w * .16, h * .86, w * .36, h * .90, cx, h * .90)
      ..cubicTo(w * .66, h * .90, w * .80, h * .84, w * .86, lip - h * .01)
      ..quadraticBezierTo(w * .90, lip - h * .04, w * .94, lip - h * .05)
      ..quadraticBezierTo(w * .88, lip + h * .01, w * .80, lip)
      ..lineTo(w * .12, lip);
    final foot = Path()
      ..moveTo(cx - w * .14, h * .965)
      ..lineTo(cx + w * .14, h * .965);
    final draw = _ease(_seg(intro, 0, .5));
    c.drawPath(
      bowl,
      Paint()
        ..color = Color.lerp(const Color(0x00FFFFFF), const Color(0x2ED9A441), _ease(_seg(intro, .3, .6)))!,
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(Offset(0, lip - h * .06), Offset(0, h), const [Color(0xFFE9B85A), Color(0xFFA9741E)]);
    _trace(c, bowl, line, draw);
    _trace(c, foot, line, _ease(_seg(intro, .35, .55)));
    // Wick.
    final wickTop = Offset(cx, lip - h * .045);
    final wick = Paint()
      ..color = const Color(0xFF3A2A1C)
      ..strokeWidth = sw * .8
      ..strokeCap = StrokeCap.round;
    if (draw > .7) c.drawLine(Offset(cx, lip + h * .005), wickTop, wick);

    final lit = streak > 0;
    if (!lit) {
      // A thin curl of smoke line drawing up and fading.
      final p = t;
      final smoke = Path()..moveTo(wickTop.dx, wickTop.dy);
      const n = 24;
      for (var i = 1; i <= n; i++) {
        final f = i / n;
        smoke.lineTo(wickTop.dx + math.sin(f * _tau * 1.1 + p * _tau) * w * .07 * f,
            wickTop.dy - f * h * .42);
      }
      final m = smoke.computeMetrics().first;
      final head = _ease(_seg(p, 0, .7));
      final tail = _ease(_seg(p, .35, 1));
      c.drawPath(
        m.extractPath(m.length * tail, m.length * head),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw * .7
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF9AA0B2).withValues(alpha: .7 * _ease(intro)),
      );
      return;
    }

    final strength = (math.min(streak, 7) - 1) / 6; // 0 → 1
    final fh = h * (.30 + .30 * strength) * (1 + .05 * math.sin(t * _tau * 2));
    final fw = w * (.13 + .04 * strength);
    final sway = math.sin(t * _tau) * .55 + math.sin(t * _tau * 2 + .8) * .2;
    Path flame(double k, double lift) {
      final b = Offset(cx, wickTop.dy - lift);
      final tip = Offset(cx + sway * fw * .55 * k, b.dy - fh * k);
      return Path()
        ..moveTo(tip.dx, tip.dy)
        ..cubicTo(tip.dx - fw * .15 * k, b.dy - fh * k * .62, b.dx - fw * k, b.dy - fh * k * .38, b.dx - fw * k * .78, b.dy - fh * k * .12)
        ..cubicTo(b.dx - fw * k * .58, b.dy + fh * k * .06, b.dx + fw * k * .58, b.dy + fh * k * .06, b.dx + fw * k * .78, b.dy - fh * k * .12)
        ..cubicTo(b.dx + fw * k, b.dy - fh * k * .38, tip.dx + fw * .15 * k, b.dy - fh * k * .62, tip.dx, tip.dy);
    }

    final f1 = _ease(_seg(intro, .45, .85));
    final wash = _ease(_seg(intro, .78, 1));
    final f2 = _ease(_seg(intro, .65, 1));
    final outer = flame(1, h * .01);
    // Warm wash inside the outer line (soft fill, no glow disc).
    c.drawPath(
      outer,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, wickTop.dy), Offset(0, wickTop.dy - fh),
            [const Color(0xFFFFD27A).withValues(alpha: .55 * wash), const Color(0xFFFFF3D6).withValues(alpha: .15 * wash)]),
    );
    _trace(
      c,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(Offset(0, wickTop.dy), Offset(0, wickTop.dy - fh),
            const [Color(0xFFE08A2E), _gold, Color(0xFFF2C46B)], const [0, .5, 1]),
      f1,
    );
    _trace(
      c,
      flame(.48, h * .012),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * .85
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _accent,
      f2,
    );
  }

  @override
  bool shouldRepaint(_DiyaP o) => o.t != t || o.intro != intro || o.streak != streak;
}
