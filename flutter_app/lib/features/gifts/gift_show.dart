/// The three NowssB gift boxes, and a wheel that lands once.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../economy/economy_theme.dart';
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
  const _Slice(this.label, this.weight, this.asset, this.tier);
  final String label;
  final int weight;
  final String asset;
  final String tier;
}

const _wheel = <_Slice>[
  _Slice('15 coins', 26, 'assets/gifts/box-red.webp', 'coins'),
  _Slice('Stage fragment', 18, 'assets/gifts/box-red.webp', 'stage'),
  _Slice('7-day ebook', 16, 'assets/gifts/box-gold.webp', 'ebook'),
  _Slice('7-day Basic', 14, 'assets/gifts/box-gold.webp', 'basic'),
  _Slice('30-day Standard', 12, 'assets/gifts/box-gold.webp', 'standard'),
  _Slice('30-day Premium', 8, 'assets/gifts/box-gold.webp', 'premium'),
  _Slice('3-day Signature', 4, 'assets/gifts/box-black.webp', 'signature'),
  _Slice('10-word bundle', 2, 'assets/gifts/box-black.webp', 'bundle'),
];

class GiftGallery extends StatelessWidget {
  const GiftGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('THE BOXES', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kGiftBoxes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final box = kGiftBoxes[i];
              return GestureDetector(
                onTap: () => openGiftBox(context, box: box, prize: box.line, itemId: box.title),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 190,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(box.asset, fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xE0000000)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(box.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(box.line, style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 12, height: 1.3)),
                              const SizedBox(height: 6),
                              const Text('Tap to open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
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
        const SizedBox(height: 8),
        const Text(
          'A gifted subscription does not unlock a rank. That seat has to be paid by the holder.',
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class GiftWheel extends StatefulWidget {
  const GiftWheel({super.key});

  @override
  State<GiftWheel> createState() => _GiftWheelState();
}

class _GiftWheelState extends State<GiftWheel> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  double _angle = 0;
  var _busy = false;
  String? _landed;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _load();
  }

  @override
  void dispose() {
    _spin.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('WHEEL', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'One spin a day. Premium is 8%. Signature is 4%. The odds sit on the wheel before it moves.',
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _angle,
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: _WheelPainter(_wheel),
                ),
              ),
              const Positioned(
                top: 0,
                child: Icon(Icons.arrow_drop_down, color: Color(0xFFE4C56A), size: 42),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in _wheel)
              Text('${s.label} ${s.weight}%', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
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
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices);
  final List<_Slice> slices;

  static const _colors = <Color>[
    Color(0xFF1A1A1A),
    Color(0xFF3A2A12),
    Color(0xFF111111),
    Color(0xFF2A2416),
    Color(0xFF0E0E0E),
    Color(0xFF4A3818),
    Color(0xFF000000),
    Color(0xFF2C220E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sweep = 2 * pi / slices.length;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < slices.length; i++) {
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.drawArc(rect, -pi / 2 + i * sweep, sweep, true, paint);
      canvas.drawArc(
        rect,
        -pi / 2 + i * sweep,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFE4C56A),
      );
      final mid = -pi / 2 + i * sweep + sweep / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: slices[i].label,
          style: const TextStyle(color: Color(0xFFF6E7B2), fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: r * 0.62);
      canvas.save();
      canvas.translate(c.dx + cos(mid) * r * 0.58, c.dy + sin(mid) * r * 0.58);
      canvas.rotate(mid + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, 28, Paint()..color = const Color(0xFFE4C56A));
    final hub = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    hub.paint(canvas, Offset(c.dx - hub.width / 2, c.dy - hub.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
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
    _Slice('Stage card', 22, 'assets/gifts/box-red.webp', 'stage'),
    _Slice('Word card', 18, 'assets/gifts/box-red.webp', 'word'),
    _Slice('7-day Basic', 16, 'assets/gifts/box-gold.webp', 'basic'),
    _Slice('7-day ebook', 14, 'assets/gifts/box-gold.webp', 'ebook'),
    _Slice('30-day Standard', 12, 'assets/gifts/box-gold.webp', 'standard'),
    _Slice('30-day Premium', 10, 'assets/gifts/box-gold.webp', 'premium'),
    _Slice('3-day Signature', 5, 'assets/gifts/box-black.webp', 'signature'),
    _Slice('Bundle card', 3, 'assets/gifts/box-black.webp', 'bundle'),
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
