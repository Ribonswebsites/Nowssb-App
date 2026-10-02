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
              Expanded(child: _boxCell(context, kGiftBoxes[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _boxCell(BuildContext context, GiftBox box) {
    return GestureDetector(
      onTap: () => openGiftBox(context, box: box, prize: box.line, itemId: box.title),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            Image.asset(box.asset, height: 108, fit: BoxFit.contain),
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
  double _angle = 0;
  var _busy = false;
  String? _landed;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
    _lamps = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
    _load();
  }

  @override
  void dispose() {
    _spin.dispose();
    _lamps.dispose();
    super.dispose();
  }

  String get _day {
    final n = DateTime.now();
    return '${n.year}${n.month}${n.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('nwsb_wheel_$_day');
    if (saved != null && mounted) setState(() => _landed = saved);
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
    final turns = 6 * 2 * pi;
    final land = turns - index * sweep - sweep / 2;
    final start = _angle;
    final anim = CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic);
    void tick() {
      if (mounted) setState(() => _angle = start + (land - start) * anim.value);
    }

    anim.addListener(tick);
    try {
      await _spin.forward(from: 0);
    } finally {
      anim.removeListener(tick);
      anim.dispose();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nwsb_wheel_$_day', slice.label);
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
    const wheel = 292.0;
    return GlassWrap(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('WHEEL', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'One spin. Icons only on the wheel. Premium 8%. Signature 4%.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: wheel + 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _lamps,
                  builder: (context, _) => CustomPaint(
                    size: Size(wheel + 18, wheel + 18),
                    painter: _LampPainter(_lamps.value),
                  ),
                ),
                Transform.rotate(
                  angle: _angle,
                  child: SizedBox(
                    width: wheel,
                    height: wheel,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(wheel, wheel),
                          painter: _WheelPainter(_wheel),
                        ),
                        for (var i = 0; i < _wheel.length; i++) _mark(i, wheel),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF111111),
                    border: Border.all(color: const Color(0xFFE4C56A), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const Text('N', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                const Positioned(
                  top: 0,
                  child: CustomPaint(size: Size(22, 28), painter: _Pointer()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final s in _wheel)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  NwsbIcon(s.mark, size: 16, color: const Color(0xFFE4C56A)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('${s.weight}%', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700, fontSize: 12)),
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

  Widget _mark(int i, double wheel) {
    final sweep = 2 * pi / _wheel.length;
    final mid = -pi / 2 + i * sweep + sweep / 2;
    return Positioned.fill(
      child: Transform.rotate(
        angle: mid,
        child: Align(
          alignment: const Alignment(0, -0.56),
          child: NwsbIcon(_wheel[i].mark, size: 22, color: const Color(0xFFF6E7B2)),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices);
  final List<_Slice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final sweep = 2 * pi / slices.length;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < slices.length; i++) {
      final dark = i.isEven;
      canvas.drawArc(
        rect,
        -pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = dark ? const Color(0xFF0C0C0C) : const Color(0xFF3A2C14),
      );
      canvas.drawArc(
        rect,
        -pi / 2 + i * sweep,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFE4C56A),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFFC6A15A),
    );
    canvas.drawCircle(
      c,
      r - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF6E7B2),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _LampPainter extends CustomPainter {
  _LampPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const n = 20;
    final on = (phase * 2).floor().isEven;
    for (var i = 0; i < n; i++) {
      final a = -pi / 2 + i * 2 * pi / n;
      final lit = on ? i.isEven : i.isOdd;
      canvas.drawCircle(
        Offset(c.dx + cos(a) * r, c.dy + sin(a) * r),
        3.2,
        Paint()..color = lit ? const Color(0xFFF6E7B2) : const Color(0xFF5C4A22),
      );
    }
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.phase != phase;
}

class _Pointer extends CustomPainter {
  const _Pointer();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE4C56A));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF111111),
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
            Image.asset(asset, height: 86, fit: BoxFit.contain),
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

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _open;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _open,
            builder: (context, _) {
              final t = Curves.easeOutBack.transform(_open.value.clamp(0.0, 1.0));
              return Transform.scale(
                scale: 0.86 + 0.14 * t,
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
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: Image.asset(widget.box.asset, fit: BoxFit.cover),
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
