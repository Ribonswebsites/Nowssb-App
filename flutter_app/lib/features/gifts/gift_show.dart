/// The three NowssB gift boxes, and a wheel that lands once.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../economy/economy_theme.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import 'gifts_screen.dart';

class GiftBox {
  const GiftBox(this.asset, this.title, this.line);
  final String asset;
  final String title;
  final String line;
}

const kGiftBoxes = <GiftBox>[
  GiftBox('assets/gifts/box-red.webp', 'Word gift', 'Red ribbon. A word, a stage, or a 7-day pass.'),
  GiftBox('assets/gifts/box-gold.webp', 'Subscription gift', 'Gold ribbon. Basic, Standard, or Premium.'),
  GiftBox('assets/gifts/box-black.webp', 'Signature gift', 'Black ribbon. The high tier. Rare on the wheel.'),
];

/// A product turntable. The photo is already a 3/4 render, so it yaws on a
/// stand instead of flipping like a card. Shadow stays on the floor.
class _Turntable extends StatefulWidget {
  const _Turntable({required this.child, this.phase = 0});
  final Widget child;
  final double phase;

  @override
  State<_Turntable> createState() => _TurntableState();
}

class _TurntableState extends State<_Turntable> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = (_c.value + widget.phase) * 2 * pi;
        final yaw = sin(t) * 0.55;
        final bob = sin(t) * 3;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, bob),
              child: Transform(
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0022)
                  ..rotateX(0.16)
                  ..rotateY(yaw),
                child: child,
              ),
            ),
            Container(
              height: 8,
              width: 70,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.35 + 0.25 * (1 - yaw.abs())),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Slice {
  const _Slice(this.label, this.weight, this.asset, this.tier, this.mark);
  final String label;
  final int weight;
  final String asset;
  final String tier;
  final String mark;
}

const _wheel = <_Slice>[
  _Slice('15 coins', 26, 'assets/gifts/box-red.webp', 'coins', NwsbMarks.rewards),
  _Slice('Stage', 18, 'assets/gifts/box-red.webp', 'stage', NwsbMarks.stages),
  _Slice('Ebook', 16, 'assets/gifts/box-gold.webp', 'ebook', NwsbMarks.book),
  _Slice('Basic', 14, 'assets/gifts/box-gold.webp', 'basic', NwsbMarks.sound),
  _Slice('Standard', 12, 'assets/gifts/box-gold.webp', 'standard', NwsbMarks.crown),
  _Slice('Premium', 8, 'assets/gifts/box-gold.webp', 'premium', NwsbMarks.flame),
  _Slice('Signature', 4, 'assets/gifts/box-black.webp', 'signature', NwsbMarks.signature),
  _Slice('Bundle', 2, 'assets/gifts/box-black.webp', 'bundle', NwsbMarks.bag),
];

class GiftGallery extends StatelessWidget {
  const GiftGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < kGiftBoxes.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: Color(0x33FFFFFF)),
              Expanded(child: _boxCell(context, kGiftBoxes[i], i / kGiftBoxes.length)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _boxCell(BuildContext context, GiftBox box, double phase) {
    return GestureDetector(
      onTap: () => openGiftBox(context, box: box, prize: box.line, itemId: box.title),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            _Turntable(
              phase: phase,
              child: Image.asset(box.asset, height: 108, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(box.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Open', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class GiftWheel extends StatefulWidget {
  const GiftWheel({super.key});

  @override
  State<GiftWheel> createState() => _GiftWheelState();
}

class _GiftWheelState extends State<GiftWheel> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _lamps;
  late final AnimationController _flap;
  double _angle = 0;
  var _busy = false;
  String? _landed;
  var _peg = 0;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 5800));
    _lamps = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _flap = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _load();
  }

  @override
  void dispose() {
    _spin.dispose();
    _lamps.dispose();
    _flap.dispose();
    super.dispose();
  }

  String get _day {
    final n = DateTime.now();
    return '${n.year}${n.month}${n.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('nwsb_wheel_$_day');
    if (saved == null || !mounted) return;
    final parts = saved.split('|');
    final label = parts.first;
    var index = parts.length > 1 ? int.tryParse(parts[1]) ?? -1 : -1;
    if (index < 0) index = _wheel.indexWhere((s) => s.label == label);
    if (index < 0) index = 0;
    final sweep = 2 * pi / _wheel.length;
    setState(() {
      _landed = label;
      _angle = -index * sweep - sweep / 2;
    });
  }

  _Slice _pick() {
    final total = _wheel.fold<int>(0, (s, e) => s + e.weight);
    var roll = Random().nextInt(total);
    for (final s in _wheel) {
      if (roll < s.weight) return s;
      roll -= s.weight;
    }
    return _wheel.first;
  }

  Future<void> _go() async {
    if (_busy || _landed != null) return;
    setState(() => _busy = true);
    final slice = _pick();
    final index = _wheel.indexOf(slice);
    final sweep = 2 * pi / _wheel.length;
    final turns = 7 * 2 * pi;
    final land = turns - index * sweep - sweep / 2;
    final start = _angle;
    _peg = (start / sweep).floor();
    final anim = CurvedAnimation(parent: _spin, curve: const _WheelDecel());
    void tick() {
      final ang = start + (land - start) * anim.value;
      final peg = (ang / sweep).floor();
      if (peg != _peg) {
        _peg = peg;
        HapticFeedback.selectionClick();
        _flap.forward(from: 0);
      }
      if (mounted) setState(() => _angle = ang);
    }

    anim.addListener(tick);
    try {
      await _spin.forward(from: 0);
    } finally {
      anim.removeListener(tick);
      anim.dispose();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nwsb_wheel_$_day', '${slice.label}|$index');
    final record = await GiftBook.instance.award(slice.tier, slice.label);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _angle = land;
      _landed = slice.label;
    });
    await openGiftBox(
      context,
      box: GiftBox(slice.asset, slice.label, 'Wheel · ${slice.weight}%'),
      prize: slice.label,
      itemId: slice.tier,
      code: record.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('WHEEL', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'One spin a day. It ticks, then slows into the peg. Premium 8%. Signature 4%.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final frame = min(300.0, constraints.maxWidth);
              final disc = frame - 34;
              return SizedBox(
                height: frame + 8,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: frame * 0.58,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: const [
                            BoxShadow(color: Color(0xE6000000), blurRadius: 16, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0011)
                        ..rotateX(-0.42),
                      child: SizedBox(
                        width: frame,
                        height: frame,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _lamps,
                              builder: (context, _) => CustomPaint(
                                size: Size(frame, frame),
                                painter: _LampPainter(_lamps.value, _busy),
                              ),
                            ),
                            Transform.rotate(
                              angle: _angle,
                              child: SizedBox(
                                width: disc,
                                height: disc,
                                child: Stack(
                                  children: [
                                    Positioned.fill(child: CustomPaint(painter: _WheelPainter(_wheel))),
                                    for (var i = 0; i < _wheel.length; i++) _mark(i, disc),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: disc * 0.24,
                              height: disc * 0.24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0A0A0A),
                                border: Border.all(color: const Color(0xFFE4C56A), width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x66000000), blurRadius: 8),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text('N', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800, fontSize: 20)),
                            ),
                            Positioned(
                              top: 0,
                              child: AnimatedBuilder(
                                animation: _flap,
                                builder: (context, _) => Transform.rotate(
                                  alignment: Alignment.topCenter,
                                  angle: -sin(_flap.value * pi) * 0.48,
                                  child: const CustomPaint(size: Size(26, 38), painter: _Pointer()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _wheel.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: _odds(_wheel[i])),
                  const SizedBox(width: 10),
                  Expanded(child: _odds(_wheel[i + 1])),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            _landed == null ? 'Spin once. Higher tiers are on the wheel.' : 'Today: $_landed',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: _landed != null ? 'Spun today' : (_busy ? 'Spinning…' : 'Spin the wheel'),
            onTap: (_landed != null || _busy) ? null : _go,
          ),
        ],
      ),
    );
  }

  Widget _odds(_Slice s) {
    return Row(
      children: [
        NwsbIcon(s.mark, size: 14, color: const Color(0xFFE4C56A)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(s.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        Text('${s.weight}%', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }

  Widget _mark(int i, double size) {
    final sweep = 2 * pi / _wheel.length;
    final mid = -pi / 2 + i * sweep + sweep / 2;
    const box = 30.0;
    final radius = size * 0.33;
    final cx = size / 2 + cos(mid) * radius;
    final cy = size / 2 + sin(mid) * radius;
    return Positioned(
      left: cx - box / 2,
      top: cy - box / 2,
      width: box,
      height: box,
      child: Transform.rotate(
        angle: -_angle,
        child: Center(
          child: NwsbIcon(_wheel[i].mark, size: 22, color: const Color(0xFFF6E7B2)),
        ),
      ),
    );
  }
}

class _WheelDecel extends Curve {
  const _WheelDecel();

  @override
  double transform(double t) => 1 - pow(1 - t, 3.2).toDouble();
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices);
  final List<_Slice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;
    final sweep = 2 * pi / slices.length;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < slices.length; i++) {
      final dark = i.isEven;
      final start = -pi / 2 + i * sweep;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF2C2618), Color(0xFF070707)]
                : const [Color(0xFFD4B36A), Color(0xFF3A2A10)],
          ).createShader(rect),
      );
      final inner = r * 0.46;
      canvas.drawLine(
        c + Offset(cos(start), sin(start)) * inner,
        c + Offset(cos(start), sin(start)) * (r - 2),
        Paint()
          ..color = const Color(0xFFF0D78A)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        c + Offset(cos(start), sin(start)) * (r - 1),
        4.2,
        Paint()..color = const Color(0xFFF6E7B2),
      );
    }
    canvas.drawCircle(
      c,
      r * 0.44,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF1A140C), Color(0xFF050505)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.44)),
    );
    canvas.drawCircle(
      c,
      r * 0.44,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE4C56A),
    );
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFF6E7B2),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _LampPainter extends CustomPainter {
  _LampPainter(this.phase, this.hot);
  final double phase;
  final bool hot;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final ring = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3C4), Color(0xFFC6A15A), Color(0xFF5A4014)],
        ).createShader(ring),
    );
    const n = 24;
    final head = (phase * (hot ? 8 : 2) * n).floor();
    for (var i = 0; i < n; i++) {
      final a = -pi / 2 + i * 2 * pi / n;
      final dist = (i - head) % n;
      final lit = dist == 0 || dist == 1;
      final o = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
      if (lit) {
        canvas.drawCircle(o, 7, Paint()..color = const Color(0x66F6E7B2));
      }
      canvas.drawCircle(
        o,
        lit ? 3.6 : 2.6,
        Paint()..color = lit ? const Color(0xFFFFF6D2) : const Color(0xFF3E3014),
      );
    }
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.phase != phase || old.hot != hot;
}

class _Pointer extends CustomPainter {
  const _Pointer();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(w * 0.98, h * 0.42, w * 0.66, 2)
      ..lineTo(w * 0.34, 2)
      ..quadraticBezierTo(w * 0.02, h * 0.42, w / 2, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF6E7B2));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF1A1408),
    );
  }

  @override
  bool shouldRepaint(_Pointer old) => false;
}


Future<void> openGiftBox(
  BuildContext context, {
  required GiftBox box,
  required String prize,
  required String itemId,
  String? code,
}) async {
  final record = code == null ? await GiftBook.instance.award(itemId, prize) : null;
  final shown = code ?? record!.code;
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Gift',
    barrierColor: const Color(0xC0000000),
    pageBuilder: (context, _, __) => _Reveal(box: box, prize: prize, code: shown),
  );
}

class GiftPlanGrid extends StatelessWidget {
  const GiftPlanGrid({super.key});

  static const _items = <(String, String, String, String)>[
    ('Stage card', 'One locked stage.', 'assets/gifts/box-red.webp', 'stage'),
    ('Word card', 'One full word.', 'assets/gifts/box-red.webp', 'word'),
    ('Bundle card', 'Ten words.', 'assets/gifts/box-black.webp', 'bundle'),
    ('7-day Basic', 'No rank credit.', 'assets/gifts/box-gold.webp', 'basic'),
    ('7-day ebook', 'After the trial.', 'assets/gifts/box-gold.webp', 'ebook'),
    ('30-day Standard', 'Gifted is not a rate.', 'assets/gifts/box-gold.webp', 'standard'),
    ('30-day Premium', 'Higher tier.', 'assets/gifts/box-gold.webp', 'premium'),
    ('3-day Signature', 'Does not unlock Partner.', 'assets/gifts/box-black.webp', 'signature'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var r = 0; r < _items.length; r += 2) ...[
            if (r > 0) const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _cell(context, _items[r])),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0x33FFFFFF)),
                  Expanded(child: _cell(context, _items[r + 1])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, (String, String, String, String) item) {
    final (title, line, asset, id) = item;
    return GestureDetector(
      onTap: () => openGiftBox(
        context,
        box: GiftBox(asset, title, line),
        prize: title,
        itemId: id,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            _Turntable(
              phase: (title.hashCode.abs() % 9) / 9,
              child: Image.asset(asset, height: 86, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(line, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.box, required this.prize, required this.code});
  final GiftBox box;
  final String prize;
  final String code;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with TickerProviderStateMixin {
  late final AnimationController _open;
  late final AnimationController _sway;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _open.forward().whenComplete(() {
      if (mounted) _sway.repeat();
    });
  }

  @override
  void dispose() {
    _open.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_open, _sway]),
            builder: (context, _) {
              final intro = Curves.easeOutCubic.transform(_open.value.clamp(0.0, 1.0));
              final sway = sin(_sway.value * 2 * pi) * 0.4;
              final yaw = (1 - intro) * 1.45 + intro * sway;
              final spin = Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(0.2)
                ..rotateY(yaw);
              return Opacity(
                opacity: intro.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + 0.1 * intro,
                  child: Container(
                    width: 300,
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4C56A)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: Transform(
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                transform: spin,
                                child: Image.asset(widget.box.asset, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            children: [
                              Text(widget.prize, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(widget.code, style: const TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('On this account. Not cash. Not a rank key.', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: widget.code));
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                                child: const Text('Copy code', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Weighted open. Higher subscription tiers are on the table, not the default.
class RandomGiftButton extends StatelessWidget {
  const RandomGiftButton({super.key});

  static const _table = <_Slice>[
    _Slice('Stage card', 22, 'assets/gifts/box-red.webp', 'stage', NwsbMarks.stages),
    _Slice('Word card', 18, 'assets/gifts/box-red.webp', 'word', NwsbMarks.word),
    _Slice('7-day Basic', 16, 'assets/gifts/box-gold.webp', 'basic', NwsbMarks.sound),
    _Slice('7-day ebook', 14, 'assets/gifts/box-gold.webp', 'ebook', NwsbMarks.book),
    _Slice('30-day Standard', 12, 'assets/gifts/box-gold.webp', 'standard', NwsbMarks.crown),
    _Slice('30-day Premium', 10, 'assets/gifts/box-gold.webp', 'premium', NwsbMarks.flame),
    _Slice('3-day Signature', 5, 'assets/gifts/box-black.webp', 'signature', NwsbMarks.signature),
    _Slice('Bundle card', 3, 'assets/gifts/box-black.webp', 'bundle', NwsbMarks.bag),
  ];

  @override
  Widget build(BuildContext context) {
    return GoldButton(
      label: 'Open a random gift',
      filled: false,
      onTap: () {
        final total = _table.fold<int>(0, (s, e) => s + e.weight);
        var roll = Random().nextInt(total);
        _Slice hit = _table.first;
        for (final s in _table) {
          if (roll < s.weight) {
            hit = s;
            break;
          }
          roll -= s.weight;
        }
        final box = GiftBox(hit.asset, hit.label, '${hit.weight}% · gifted pass does not unlock a rank');
        openGiftBox(context, box: box, prize: hit.label, itemId: hit.tier);
      },
    );
  }
}
