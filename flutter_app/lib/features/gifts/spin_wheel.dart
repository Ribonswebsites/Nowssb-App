/// NowssB Daily Spin.
///
/// One free spin a day, then each extra spin costs the server's spin price
/// while the balance allows. The server takes the coins, draws the slice
/// from the published weights and puts the prize on the account; the phone
/// only animates the landing.
///
/// The spin itself: the first ~3 s of assets/gifts/spin-wheel.mp4 play as the
/// intro (the button press and the spin-up), then it crossfades into a
/// code-drawn wheel in the same dark-luxury style — eight segments
/// alternating black and metallic gold, white labels from the server's own
/// slice list, a black hub with a gold rim, a gold diamond pointer at twelve
/// o'clock, motion blur and a light streak while it is fast — which then
/// slows with easeOutQuart onto the exact segment the server chose, one
/// tick and one light haptic per segment. Then "You won X" and the coins fly
/// into the balance pill (reward_overlay.dart).
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../admin/template/editable.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/reward_fx.dart';

/// One slice as the server publishes it (config.spin.slices, same order the
/// server draws from).
class SpinSlice {
  const SpinSlice(this.label, this.weight);
  final String label;
  final num weight;

  String get mark {
    final l = label.toLowerCase();
    if (l.contains('coin')) return NwsbMarks.rewards;
    if (l.contains('ebook')) return NwsbMarks.book;
    if (l.contains('premium')) return NwsbMarks.crown;
    if (l.contains('signature')) return NwsbMarks.signature;
    if (l.contains('stage')) return NwsbMarks.stages;
    if (l.contains('bundle')) return NwsbMarks.bag;
    if (l.contains('basic')) return NwsbMarks.sound;
    return NwsbMarks.gift;
  }
}

/// The server's published wheel. Until the first summary arrives this is the
/// bundled copy of the same server default (functions/_lib/economy/config.js).
List<SpinSlice> spinSlices() {
  final cfg = EconomyMirror.instance.summary['config'];
  final spin = cfg is Map ? cfg['spin'] : null;
  final raw = spin is Map ? spin['slices'] : null;
  if (raw is List && raw.isNotEmpty) {
    final out = <SpinSlice>[
      for (final s in raw)
        if (s is Map) SpinSlice('${s['label'] ?? ''}', (s['w'] as num?) ?? 0),
    ];
    if (out.isNotEmpty) return out;
  }
  return const [
    SpinSlice('Ebook', 16), SpinSlice('Basic', 14), SpinSlice('Premium', 8), SpinSlice('Bundle', 2),
    SpinSlice('Signature', 4), SpinSlice('15 coins', 26), SpinSlice('Standard', 12), SpinSlice('Stage', 18),
  ];
}

String _pct(List<SpinSlice> all, SpinSlice s) {
  final total = all.fold<num>(0, (a, b) => a + b.weight);
  if (total <= 0) return '';
  final p = s.weight * 100 / total;
  return p == p.roundToDouble() ? '${p.round()}%' : '${p.toStringAsFixed(1)}%';
}

/// What the wheel can do now: 'free' (today's free spin is waiting) or
/// 'limit' (used today; it comes back tomorrow). There are no paid spins.
class SpinNow {
  const SpinNow(this.next, this.freeLeft);
  final String next;
  final int freeLeft;

  static SpinNow read() {
    final m = EconomyMirror.instance;
    final s = m.summary;
    final cfg = s['config'] is Map ? (s['config'] as Map)['spin'] : null;
    final freePerDay = (cfg is Map ? (cfg['freePerDay'] as num?)?.toInt() : null) ?? 1;
    final today = s['today'] is Map ? s['today'] as Map : const {};
    final used = (today['spins'] as num?)?.toInt() ?? 0;
    final freeLeft = max(0, freePerDay - used);
    return SpinNow(freeLeft > 0 ? 'free' : 'limit', freeLeft);
  }
}

class GiftWheel extends StatefulWidget {
  const GiftWheel({super.key});

  @override
  State<GiftWheel> createState() => _GiftWheelState();
}

class _GiftWheelState extends State<GiftWheel> {
  double _angle = -pi / 8;
  var _busy = false;
  String? _last;

  Future<void> _go() async {
    if (_busy) return;
    final now = SpinNow.read();
    if (now.next != 'free') return;
    setState(() => _busy = true);
    final slices = spinSlices();
    final nonce = '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 20)}';
    Future<Map<String, dynamic>> ask() => EconomyApi.call('spin', {'nonce': nonce});
    // A retry with the same nonce returns the same answer (never a second spin).
    final result = ask().catchError((Object e) async {
      if (e is EconomyException && (e.code == 'timeout' || e.code == 'offline')) return ask();
      throw e;
    });
    final out = await SpinStage.play(context, slices: slices, result: result, startAngle: _angle);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (out.angle != null) _angle = out.angle!;
    });
    if (out.error != null) {
      showEconomyError(context, out.error!);
      return;
    }
    final r = out.result;
    if (r == null) return;
    final label = '${r['label'] ?? ''}';
    setState(() => _last = label);
    // Root overlay: reveal, then coins into the pill. Never depends on this card.
    unawaited(celebrate(context, r, title: 'Daily Spin · $label'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final coins = EconomyMirror.instance.coins;
        final now = SpinNow.read();
        final slices = spinSlices();
        final free = now.next == 'free';
        final can = !_busy && free;
        final buttonTitle = free ? 'SPIN FREE' : 'SPIN THE WHEEL';
        final buttonSub = _busy
            ? 'Spinning…'
            : free
                ? 'Your free spin for today'
                : 'Come back tomorrow';
        final status = free
            ? 'One free spin every day.'
            : _last == null
                ? 'Today\u2019s free spin is used. Come back tomorrow for the next one.'
                : 'Last spin: $_last. Come back tomorrow for the next free spin.';
        final rare = slices.where((s) => s.weight <= 8).map((s) => '${s.label} ${_pct(slices, s)}').join('  ·  ');
        return GlassWrap(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE4C56A))),
                    alignment: Alignment.center,
                    child: const NwsbIcon(NwsbMarks.rewards, size: 16, color: Color(0xFFE4C56A)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.05),
                            children: [
                              TextSpan(text: 'Daily ', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'Spin', style: TextStyle(color: Color(0xFFE4C56A))),
                            ],
                          ),
                        ),
                        SizedBox(height: 2),
                        EditableLabel('spin_wheel.GiftWheel', 'One free spin a day. Extra spins cost coins.\nIt spins fast, then slows onto the peg.',
                            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.25)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66E4C56A))),
                    child: Column(
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          EditableImage.asset(NwsbCoinFly.disc, width: 16, height: 16, fit: BoxFit.contain, slot: 'spin_wheel.GiftWheel'),
                          const SizedBox(width: 4),
                          Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ]),
                        const EditableLabel('spin_wheel.GiftWheel', 'Your coins', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              if (rare.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(rare, style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, c) {
                final size = min(300.0, c.maxWidth);
                return Center(
                  child: GestureDetector(
                    onTap: can ? _go : null,
                    child: SizedBox(
                      width: size,
                      height: size + 12,
                      child: CustomPaint(
                        painter: SpinWheelPainter(slices: slices, angle: _angle, freeToday: now.next == 'free'),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              _oddsBoard(slices),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x66E4C56A))),
                    child: Column(
                      children: [
                        EditableImage.asset(NwsbCoinFly.disc, width: 22, height: 22, fit: BoxFit.contain, slot: 'spin_wheel.GiftWheel'),
                        Text(now.next == 'free' ? 'FREE' : 'USED',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.1)),
                        EditableLabel('spin_wheel.GiftWheel', 'today',
                            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: can ? _go : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: can
                              ? const LinearGradient(colors: [Color(0xFFF6E7B2), Color(0xFFC6A15A), Color(0xFF9A7432)])
                              : null,
                          color: can ? null : const Color(0xFF4A3B22),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: can ? const [BoxShadow(color: Color(0x66E4C56A), blurRadius: 18)] : null,
                        ),
                        child: Column(
                          children: [
                            EditableLabel('spin_wheel.GiftWheel', buttonTitle,
                                style: TextStyle(color: can ? const Color(0xFF1A1408) : const Color(0xFFB7A98A), fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 15)),
                            Text(buttonSub, style: TextStyle(color: can ? const Color(0xFF3A2C14) : const Color(0xFF8C7B5E), fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11, height: 1.3)),
            ],
          ),
        );
      },
    );
  }

  Widget _oddsBoard(List<SpinSlice> slices) {
    final rows = <List<SpinSlice>>[];
    for (var i = 0; i < slices.length; i += 4) {
      rows.add(slices.sublist(i, min(i + 4, slices.length)));
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x55E4C56A))),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const Divider(height: 1, thickness: 1, color: Color(0x33E4C56A)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  for (var k = 0; k < rows[r].length; k++) ...[
                    if (k > 0) Container(width: 1, height: 28, color: const Color(0x33E4C56A)),
                    Expanded(
                      child: Row(children: [
                        const SizedBox(width: 4),
                        NwsbIcon(rows[r][k].mark, size: 14, color: const Color(0xFFE4C56A)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(rows[r][k].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            Text(_pct(slices, rows[r][k]), style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 10, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wheel angle that puts the middle of segment [i] under the 12 o'clock peg.
double spinRestAngle(int i, int n) => -(i + 0.5) * 2 * pi / n;

/// Paints the wheel: gold rim with lamps, eight black / metallic-gold
/// segments with white labels, black hub with gold rim, gold diamond pointer.
class SpinWheelPainter extends CustomPainter {
  SpinWheelPainter({
    required this.slices,
    required this.angle,
    this.blur = 0,
    this.streak = 0,
    this.lamps = 0,
    this.flap = 0,
    this.win,
    this.freeToday = true,
  });

  final List<SpinSlice> slices;
  final double angle;

  /// 0…1: motion-blur strength (ghost copies of the face).
  final double blur;

  /// 0…1: the light streak sweeping across while it is fast.
  final double streak;
  final double lamps;
  final double flap;

  /// Index of the winning segment once landed (it glows).
  final int? win;
  final bool freeToday;

  static const _gold = [Color(0xFFFFF3C9), Color(0xFFE8C56A), Color(0xFFA67C32)];

  @override
  void paint(Canvas canvas, Size size) {
    final pointerH = size.width * 0.085;
    final c = Offset(size.width / 2, pointerH * 0.55 + (size.width / 2));
    final rOuter = size.width / 2 - 2;
    final rFace = rOuter * 0.86;
    final n = max(1, slices.length);
    final sweep = 2 * pi / n;

    // Floor glow.
    canvas.drawCircle(c, rOuter, Paint()
      ..color = const Color(0x55C6A15A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));

    // Rim.
    final rimRect = Rect.fromCircle(center: c, radius: rOuter);
    canvas.drawCircle(c, rOuter - rOuter * 0.07, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rOuter * 0.14
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF3C4), Color(0xFFC6A15A), Color(0xFF5A4014)]).createShader(rimRect));
    const lampCount = 24;
    final head = (lamps * lampCount).floor();
    for (var i = 0; i < lampCount; i++) {
      final a = -pi / 2 + i * 2 * pi / lampCount;
      final o = c + Offset(cos(a), sin(a)) * (rOuter - rOuter * 0.07);
      final lit = ((i - head) % lampCount) < 2;
      if (lit) canvas.drawCircle(o, rOuter * 0.04, Paint()..color = const Color(0x66F6E7B2));
      canvas.drawCircle(o, lit ? rOuter * 0.022 : rOuter * 0.016, Paint()..color = lit ? const Color(0xFFFFF8DC) : const Color(0xFFE4C56A));
    }

    // Face (with motion-blur ghosts when fast).
    void face(double a, double alpha) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      final rect = Rect.fromCircle(center: Offset.zero, radius: rFace);
      final goldShader = const RadialGradient(colors: _gold, stops: [0.35, 0.7, 1]).createShader(rect);
      final inkShader = const RadialGradient(colors: [Color(0xFF241E14), Color(0xFF0C0C0C), Color(0xFF050505)], stops: [0.2, 0.72, 1]).createShader(rect);
      for (var i = 0; i < n; i++) {
        final start = -pi / 2 + i * sweep;
        final p = Paint()..shader = i.isEven ? inkShader : goldShader;
        if (alpha < 1) p.color = p.color.withValues(alpha: alpha);
        canvas.drawArc(rect, start, sweep, true, p);
        if (win == i) {
          canvas.drawArc(rect, start, sweep, true, Paint()..color = const Color(0x44FFF3C9));
        }
        canvas.drawLine(Offset(cos(start), sin(start)) * rFace * 0.3, Offset(cos(start), sin(start)) * rFace,
            Paint()..color = const Color(0xFFF0D78A).withValues(alpha: alpha)..strokeWidth = 1.4);
      }
      if (alpha >= 1) {
        for (var i = 0; i < n; i++) {
          final mid = -pi / 2 + i * sweep + sweep / 2;
          _label(canvas, slices[i], _pct(slices, slices[i]), mid, rFace * 0.66, rFace, i.isOdd);
        }
      }
      canvas.restore();
    }

    if (blur > 0.02) {
      for (var k = 3; k >= 1; k--) {
        face(angle - k * 0.06 * blur, 0.18 * blur);
      }
    }
    face(angle, 1);

    // Light streak while fast.
    if (streak > 0.01) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: rFace)));
      final shader = SweepGradient(
        transform: GradientRotation(-angle * 0.35),
        colors: [const Color(0x00FFFFFF), Color.fromRGBO(255, 248, 220, 0.55 * streak), const Color(0x00FFFFFF), const Color(0x00FFFFFF)],
        stops: const [0.0, 0.06, 0.14, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: rFace));
      canvas.drawCircle(c, rFace, Paint()..shader = shader..blendMode = BlendMode.plus);
      canvas.restore();
    }

    // Hub.
    final hubR = rFace * 0.3;
    canvas.drawCircle(c, hubR, Paint()..shader = const RadialGradient(colors: [Color(0xFF1A140C), Color(0xFF050505)]).createShader(Rect.fromCircle(center: c, radius: hubR)));
    canvas.drawCircle(c, hubR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hubR * 0.12
      ..shader = const LinearGradient(colors: _gold).createShader(Rect.fromCircle(center: c, radius: hubR)));
    _text(canvas, 'SPIN', c + Offset(0, -hubR * 0.16), hubR * 0.52, const Color(0xFFE4C56A), FontWeight.w900);
    _text(canvas, freeToday ? '1 free spin daily' : 'extra spins · coins', c + Offset(0, hubR * 0.38), hubR * 0.17, const Color(0xCCFFFFFF), FontWeight.w600);

    // Diamond pointer at 12 o'clock.
    final top = Offset(c.dx, c.dy - rOuter - pointerH * 0.35);
    canvas.save();
    canvas.translate(top.dx, top.dy);
    canvas.rotate(-sin(flap * pi) * 0.28);
    final w = pointerH * 0.62;
    final h = pointerH * 1.25;
    final diamond = Path()
      ..moveTo(0, h)
      ..lineTo(w / 2, h * 0.42)
      ..lineTo(0, 0)
      ..lineTo(-w / 2, h * 0.42)
      ..close();
    canvas.drawShadow(diamond, Colors.black, 4, false);
    canvas.drawPath(diamond, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _gold).createShader(Rect.fromLTWH(-w / 2, 0, w, h)));
    canvas.drawLine(Offset(0, 0), Offset(0, h), Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 1);
    canvas.drawPath(diamond, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFF3A2A10));
    canvas.restore();
  }

  void _label(Canvas canvas, SpinSlice s, String pct, double mid, double r, double rFace, bool onGold) {
    final pos = Offset(cos(mid), sin(mid)) * r;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(mid + pi / 2);
    final shadow = [Shadow(color: onGold ? const Color(0xAA3A2A10) : const Color(0xAA000000), blurRadius: 3)];
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(children: [
        TextSpan(text: '${s.label}\n', style: TextStyle(color: Colors.white, fontSize: rFace * 0.085, fontWeight: FontWeight.w800, height: 1.1, shadows: shadow)),
        TextSpan(text: pct, style: TextStyle(color: Colors.white, fontSize: rFace * 0.075, fontWeight: FontWeight.w700, height: 1.1, shadows: shadow)),
      ]),
    )..layout(maxWidth: rFace * 0.5);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _text(Canvas canvas, String t, Offset centre, double size, Color color, FontWeight weight) {
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: weight, letterSpacing: size * 0.04, height: 1)),
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(SpinWheelPainter o) =>
      o.angle != angle || o.blur != blur || o.streak != streak || o.lamps != lamps || o.flap != flap || o.win != win || o.slices != slices || o.freeToday != freeToday;
}

class SpinOutcome {
  const SpinOutcome({this.result, this.error, this.angle});
  final Map<String, dynamic>? result;
  final Object? error;
  final double? angle;
}

/// Full-screen spin: film intro → crossfade → painted wheel → exact landing.
class SpinStage extends StatefulWidget {
  const SpinStage({super.key, required this.slices, required this.result, required this.startAngle});
  final List<SpinSlice> slices;
  final Future<Map<String, dynamic>> result;
  final double startAngle;

  static Future<SpinOutcome> play(
    BuildContext context, {
    required List<SpinSlice> slices,
    required Future<Map<String, dynamic>> result,
    required double startAngle,
  }) async {
    final quiet = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (quiet || !context.mounted) {
      try {
        final r = await result;
        final i = ((r['slice'] as num?)?.toInt() ?? 0).clamp(0, slices.length - 1);
        return SpinOutcome(result: r, angle: spinRestAngle(i, slices.length));
      } catch (e) {
        return SpinOutcome(error: e);
      }
    }
    final out = await Navigator.of(context, rootNavigator: true).push<SpinOutcome>(PageRouteBuilder<SpinOutcome>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => SpinStage(slices: slices, result: result, startAngle: startAngle),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
    return out ?? const SpinOutcome();
  }

  @override
  State<SpinStage> createState() => _SpinStageState();
}

enum _Phase { intro, fast, decel, landed }

class _SpinStageState extends State<SpinStage> with SingleTickerProviderStateMixin {
  static const _introSeconds = 3.0;
  static const _crossfade = 0.45;
  static const _omega = 12.0; // rad/s while fast (≈1.9 turns a second)
  static const _decelSeconds = 3.6; // easeOutQuart onto the segment

  late final Ticker _ticker = createTicker(_onTick);
  VideoPlayerController? _video;
  var _videoReady = false;
  _Phase _phase = _Phase.intro;
  Duration _last = Duration.zero;
  double _t = 0; // seconds since start
  double _wheelIn = 0; // 0 → 1 crossfade
  double? _fadeStart;
  late double _angle = widget.startAngle;
  double _fastFor = 0;
  double _decelStart = 0, _decelFrom = 0, _decelDelta = 0;
  int? _target;
  double _targetAngle = 0;
  Map<String, dynamic>? _result;
  Object? _error;
  int _lastSeg = 0;
  double _lastTickAt = -1;
  double _flap = 0;
  var _closing = false;

  int get _n => max(1, widget.slices.length);
  double get _sweep => 2 * pi / _n;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _openFilm();
    widget.result.then((r) {
      if (!mounted) return;
      _result = r;
      final i = ((r['slice'] as num?)?.toInt() ?? 0).clamp(0, _n - 1);
      _target = i;
      // Land inside the segment, not always on its exact centre line.
      final jitter = (Random().nextDouble() - 0.5) * 0.5 * _sweep;
      _targetAngle = spinRestAngle(i, _n) + jitter;
    }, onError: (Object e) {
      if (!mounted) return;
      _error = e;
    });
    _lastSeg = (_angle / _sweep).floor();
    _ticker.start();
  }

  Future<void> _openFilm() async {
    final v = VideoPlayerController.asset('assets/gifts/spin-wheel.mp4', videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _video = v;
    try {
      await v.initialize().timeout(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await v.setLooping(false);
      await v.play();
      setState(() => _videoReady = true);
    } catch (_) {
      // No film (old phone / decoder busy): go straight to the painted wheel.
      _startCrossfade();
    }
  }

  void _startCrossfade() {
    if (_fadeStart != null) return;
    _fadeStart = _t;
    _phase = _Phase.fast;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _t += dt;
    if (_error != null && !_closing) {
      _close(SpinOutcome(error: _error, angle: _angle));
      return;
    }
    if (_phase == _Phase.intro) {
      final pos = _video?.value.position.inMilliseconds ?? 0;
      if ((_videoReady && pos >= (_introSeconds - _crossfade) * 1000) || _t > _introSeconds + 1.2) _startCrossfade();
    }
    if (_fadeStart != null) {
      _wheelIn = ((_t - _fadeStart!) / _crossfade).clamp(0.0, 1.0);
      if (_wheelIn >= 1 && _video != null && _video!.value.isPlaying) _video!.pause();
    }
    switch (_phase) {
      case _Phase.intro:
        break;
      case _Phase.fast:
        _angle += _omega * dt;
        _fastFor += dt;
        // With the answer in, wait for the exact point where a constant
        // easeOutQuart from full speed ends on the target, so the slowdown
        // starts at the same speed the wheel is turning (no jump).
        if (_target != null && _wheelIn >= 1 && _fastFor > 0.5) {
          final delta = _omega * _decelSeconds / 4;
          final end = _angle + delta;
          final off = ((end - _targetAngle) % (2 * pi) + 2 * pi) % (2 * pi);
          if (off < _omega * dt * 1.5 || off > 2 * pi - _omega * dt * 0.5) {
            _phase = _Phase.decel;
            _decelStart = _t;
            _decelFrom = _angle;
            // End exactly on the target (tiny correction absorbed here).
            final exact = end - (off > pi ? off - 2 * pi : off);
            _decelDelta = exact - _angle;
          }
        }
      case _Phase.decel:
        final u = ((_t - _decelStart) / _decelSeconds).clamp(0.0, 1.0);
        final e = 1 - pow(1 - u, 4).toDouble();
        _angle = _decelFrom + _decelDelta * e;
        if (u >= 1) {
          _phase = _Phase.landed;
          HapticFeedback.mediumImpact();
          Future<void>.delayed(const Duration(milliseconds: 750), () => _close(SpinOutcome(result: _result, angle: _angle)));
        }
      case _Phase.landed:
        break;
    }
    // One tick + one light haptic per segment the peg passes.
    if (_phase != _Phase.intro) {
      final seg = (_angle / _sweep).floor();
      if (seg != _lastSeg) {
        _lastSeg = seg;
        if (_t - _lastTickAt > 0.045) {
          _lastTickAt = _t;
          _flap = 1;
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.selectionClick();
        }
      }
    }
    _flap = max(0, _flap - dt * 9);
    setState(() {});
  }

  void _close(SpinOutcome out) {
    if (_closing || !mounted) return;
    _closing = true;
    _ticker.stop();
    Navigator.of(context).pop(out);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _video?.dispose();
    super.dispose();
  }

  double get _speed => switch (_phase) {
        _Phase.fast => 1,
        _Phase.decel => pow(1 - ((_t - _decelStart) / _decelSeconds).clamp(0.0, 1.0), 3).toDouble(),
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final speed = _speed;
    final landed = _phase == _Phase.landed;
    final label = landed && _target != null ? widget.slices[_target!].label : null;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _CasinoBackdrop(),
            if (video != null && _videoReady)
              Opacity(
                opacity: 1 - _wheelIn,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: video.value.size.width == 0 ? 1080 : video.value.size.width,
                    height: video.value.size.height == 0 ? 1920 : video.value.size.height,
                    child: VideoPlayer(video),
                  ),
                ),
              ),
            Opacity(
              opacity: _wheelIn,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    const EditableLabel('spin_wheel.SpinStage', 'NowssB',
                        style: TextStyle(color: Color(0xFFF6E7B2), fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1,
                            shadows: [Shadow(color: Color(0xAAE4C56A), blurRadius: 18)])),
                    const SizedBox(height: 4),
                    const EditableLabel('spin_wheel.SpinStage', 'DAILY SPIN',
                        style: TextStyle(color: Color(0xFFE4C56A), fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    LayoutBuilder(builder: (context, c) {
                      final size = min(c.maxWidth - 32, 420.0);
                      return SizedBox(
                        width: size,
                        height: size + 24,
                        child: CustomPaint(
                          painter: SpinWheelPainter(
                            slices: widget.slices,
                            angle: _angle,
                            blur: (speed * 1.2).clamp(0.0, 1.0),
                            streak: _phase == _Phase.fast ? 1 : (speed > 0.25 ? speed : 0),
                            lamps: (_t * (0.6 + 2.4 * speed)) % 1,
                            flap: _flap,
                            win: landed ? _target : null,
                            freeToday: true,
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: label == null ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: Text(label ?? ' ',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    EditableLabel('spin_wheel.SpinStage', _target == null ? 'Drawing on the server…' : 'Odds are published on the wheel.',
                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark luxury room: warm glow, soft gold bokeh. Drawn in code.
class _CasinoBackdrop extends StatelessWidget {
  const _CasinoBackdrop();

  @override
  Widget build(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _BokehPainter()));
}

class _BokehPainter extends CustomPainter {
  const _BokehPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const RadialGradient(center: Alignment(0, -0.2), radius: 1.0, colors: [Color(0xFF2A1E0C), Color(0xFF0B0805), Color(0xFF000000)], stops: [0, 0.55, 1]).createShader(rect));
    final r = Random(7);
    for (var i = 0; i < 46; i++) {
      final o = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      final rad = 3 + r.nextDouble() * 14;
      canvas.drawCircle(o, rad, Paint()
        ..color = Color.fromRGBO(228, 197, 106, 0.05 + r.nextDouble() * 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.8));
    }
  }

  @override
  bool shouldRepaint(_BokehPainter old) => false;
}
