/// The three NowssB gift boxes, and a wheel that lands once.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/reward_fx.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import 'gifts_screen.dart';
import '../../admin/template/editable.dart';

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

/// Clockwise from the top peg, matching the Daily Spin face.
const _outlineGift =
    '<path d="M4.2 9.2h15.6v11.2H4.2z"/>'
    '<path d="M3 6.2h18v3.2H3z"/>'
    '<path d="M12 6.2v14.2"/>'
    '<path d="M12 6.2c-1.4-2.6-4-3.4-5.2-2.2C5.6 5.2 6.2 6.8 8.2 7.4"/>'
    '<path d="M12 6.2c1.4-2.6 4-3.4 5.2-2.2 1.2 1.2.6 2.8-1.4 3.4"/>';

const _drop =
    '<path d="M12 3.2s5.2 6 5.2 9.4a5.2 5.2 0 1 1-10.4 0C6.8 9.2 12 3.2 12 3.2z"/>';

const _wheel = <_Slice>[
  _Slice('Ebook', 16, 'assets/gifts/box-gold.webp', 'ebook', NwsbMarks.book),
  _Slice('Basic', 14, 'assets/gifts/box-gold.webp', 'basic', NwsbMarks.sound),
  _Slice('Premium', 8, 'assets/gifts/box-gold.webp', 'premium', NwsbMarks.crown),
  _Slice('Bundle', 2, 'assets/gifts/box-black.webp', 'bundle', _drop),
  _Slice('Signature', 4, 'assets/gifts/box-black.webp', 'signature', NwsbMarks.signature),
  _Slice('15 coins', 26, 'assets/gifts/box-red.webp', 'coins', _outlineGift),
  _Slice('Standard', 12, 'assets/gifts/box-gold.webp', 'standard', NwsbMarks.rewards),
  _Slice('Stage', 18, 'assets/gifts/box-red.webp', 'stage', NwsbMarks.stages),
];

const _spinCost = 15;

class GiftShowcase extends StatelessWidget {
  const GiftShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 320,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: EditableImage.asset(
              'assets/gifts/gift-hero.png',
              width: w * 0.74,
              height: 320,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 320),
              slot: 'gift_show.GiftShowcase',
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: max(240, w - 48),
            child: const GiftGallery(),
          ),
        ],
      ),
    );
  }
}

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
      onTap: () => showGiftCardSheet(context, giftCardFor(box.title)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            _Turntable(
              phase: phase,
              child: EditableImage.asset(box.asset, height: 108, fit: BoxFit.contain, slot: 'gift_show.GiftGallery'),
            ),
            const SizedBox(height: 8),
            Text(box.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            EditableLabel('gift_show.GiftGallery', 'Open', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700, fontSize: 12)),
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
  double _angle = -pi / 8;
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
    final spins = ((EconomyMirror.instance.summary['today'] as Map?)?['spins'] as num?)?.toInt() ?? 0;
    if (saved == null && spins == 0) return;
    if (!mounted) return;
    final parts = (saved ?? 'Spun today|0').split('|');
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

  Future<void> _go() async {
    if (_busy || _landed != null) return;
    if (EconomyMirror.instance.coins < _spinCost) return;
    setState(() => _busy = true);
    // The server takes the coins, draws the slice from the published
    // weights and puts the prize on the account. The wheel only lands there.
    Map<String, dynamic> result;
    try {
      result = await EconomyApi.call('spin', {'idem': '${DateTime.now().microsecondsSinceEpoch}'});
    } on EconomyException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showEconomyError(context, e);
      }
      return;
    }
    if (!mounted) return;
    final index = ((result['slice'] as num?)?.toInt() ?? 0).clamp(0, _wheel.length - 1);
    final slice = _wheel[index];
    final quiet = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!quiet && mounted) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Spin',
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => const _SpinFilm(),
      );
    }
    if (!mounted) return;
    final sweep = 2 * pi / _wheel.length;
    final turns = 2 * 2 * pi;
    final land = turns - index * sweep - sweep / 2;
    final start = _angle;
    _peg = (start / sweep).floor();
    _spin.duration = const Duration(milliseconds: 1700);
    final anim = CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic);
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
    HapticFeedback.mediumImpact();
    final granted = (result['granted'] as Map?) ?? const {};
    if (!mounted) return;
    setState(() {
      _busy = false;
      _angle = -index * sweep - sweep / 2;
      _landed = slice.label;
    });
    await openGiftBox(
      context,
      box: GiftBox(slice.asset, slice.label, 'Wheel · ${slice.weight}%'),
      prize: '${granted['label'] ?? result['label'] ?? slice.label}',
      itemId: slice.tier,
    );
    if (mounted) await playCoins(context, coinsIn(result), balanceAfter: balanceIn(result));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final coins = EconomyMirror.instance.coins;
        final can = _landed == null && !_busy && coins >= _spinCost;
        final buttonSub = _landed != null
            ? 'Come back tomorrow'
            : (_busy ? 'Spinning…' : (coins < _spinCost ? 'Need 15 coins' : 'Spend 15 coins to spin'));
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4C56A)),
                    ),
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
                        EditableLabel('gift_show.GiftWheel',
                          'One spin a day. It ticks, then slows\ninto the peg.',
                          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66E4C56A)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EditableImage.asset(NwsbCoinFly.disc, width: 16, height: 16, fit: BoxFit.contain, slot: 'gift_show.GiftWheel'),
                            const SizedBox(width: 4),
                            Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const EditableLabel('gift_show.GiftWheel', 'Your coins', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const EditableLabel('gift_show.GiftWheel',
                'Premium 8%  ·  Signature 4%',
                style: TextStyle(color: Color(0xFFE4C56A), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final frame = min(320.0, constraints.maxWidth);
                  final disc = frame - 28;
                  return SizedBox(
                    height: frame + 6,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 8,
                          child: Container(
                            width: frame * 0.62,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [BoxShadow(color: Color(0x88C6A15A), blurRadius: 24, spreadRadius: 2)],
                            ),
                          ),
                        ),
                        SizedBox(
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
                              GestureDetector(
                                onTap: can ? _go : null,
                                child: Container(
                                  width: disc * 0.36,
                                  height: disc * 0.36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0B0B0B),
                                    border: Border.all(color: const Color(0xFFE4C56A), width: 4),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x99E4C56A), blurRadius: 16),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      EditableLabel('gift_show.GiftWheel', 'SPIN', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2, height: 1)),
                                      SizedBox(height: 2),
                                      EditableLabel('gift_show.GiftWheel', '1 spin daily', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: AnimatedBuilder(
                                  animation: _flap,
                                  builder: (context, _) => Transform.rotate(
                                    alignment: Alignment.topCenter,
                                    angle: -sin(_flap.value * pi) * 0.35,
                                    child: const CustomPaint(size: Size(34, 46), painter: _Pointer()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _oddsBoard(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x66E4C56A)),
                    ),
                    child: Column(
                      children: [
                        EditableImage.asset(NwsbCoinFly.disc, width: 22, height: 22, fit: BoxFit.contain, slot: 'gift_show.GiftWheel'),
                        const EditableLabel('gift_show.GiftWheel', '15', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.1)),
                        const EditableLabel('gift_show.GiftWheel', 'per spin', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: can ? _go : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: can ? const Color(0xFFC6A15A) : const Color(0xFF4A3B22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            EditableLabel('gift_show.GiftWheel',
                              'SPIN THE WHEEL',
                              style: TextStyle(color: can ? const Color(0xFF1A1408) : const Color(0xFFB7A98A), fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 15),
                            ),
                            Text(
                              buttonSub,
                              style: TextStyle(color: can ? const Color(0xFF3A2C14) : const Color(0xFF8C7B5E), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 16, height: 1, color: const Color(0x33FFFFFF)),
                  const SizedBox(width: 6),
                  const Icon(Icons.lock_outline, size: 12, color: Color(0x99FFFFFF)),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: EditableLabel('gift_show.GiftWheel',
                      'Come back tomorrow for your next spin.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 16, height: 1, color: const Color(0x33FFFFFF)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _oddsBoard() {
    const order = <int>[5, 7, 0, 1, 6, 2, 4, 3];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55E4C56A)),
      ),
      child: Column(
        children: [
          _oddsRow(order.take(4).toList()),
          const Divider(height: 1, thickness: 1, color: Color(0x33E4C56A)),
          _oddsRow(order.skip(4).toList()),
        ],
      ),
    );
  }

  Widget _oddsRow(List<int> ids) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          for (var k = 0; k < ids.length; k++) ...[
            if (k > 0) Container(width: 1, height: 28, color: const Color(0x33E4C56A)),
            _oddsCell(ids[k]),
          ],
        ],
      ),
    );
  }

  Widget _oddsCell(int i) {
    final s = _wheel[i];
    return Expanded(
      child: Row(
        children: [
          const SizedBox(width: 4),
          NwsbIcon(s.mark, size: 14, color: const Color(0xFFE4C56A)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                Text('${s.weight}%', style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mark(int i, double size) {
    final sweep = 2 * pi / _wheel.length;
    final mid = -pi / 2 + i * sweep + sweep / 2;
    const boxW = 74.0;
    const boxH = 56.0;
    final radius = size * 0.34;
    final cx = size / 2 + cos(mid) * radius;
    final cy = size / 2 + sin(mid) * radius;
    final goldSlice = i.isOdd;
    final ink = goldSlice ? const Color(0xFF1A1206) : const Color(0xFFF8F1D8);
    final s = _wheel[i];
    return Positioned(
      left: cx - boxW / 2,
      top: cy - boxH / 2,
      width: boxW,
      height: boxH,
      child: Transform.rotate(
        angle: -_angle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NwsbIcon(s.mark, size: 18, color: ink),
            const SizedBox(height: 1),
            Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w800, height: 1.05)),
            Text('${s.weight}%', style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w800, height: 1.05)),
          ],
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
    final r = size.width / 2 - 1;
    final sweep = 2 * pi / slices.length;
    final rect = Rect.fromCircle(center: c, radius: r);
    final gold = const RadialGradient(
      colors: [Color(0xFFFFF3C9), Color(0xFFE8C56A), Color(0xFFA67C32)],
      stops: [0.42, 0.72, 1],
    ).createShader(rect);
    final ink = const RadialGradient(
      colors: [Color(0xFF241E14), Color(0xFF0C0C0C), Color(0xFF050505)],
      stops: [0.2, 0.72, 1],
    ).createShader(rect);
    for (var i = 0; i < slices.length; i++) {
      final start = -pi / 2 + i * sweep;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..shader = i.isEven ? ink : gold,
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
      r * 0.34,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF1A140C), Color(0xFF050505)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.44)),
    );
    canvas.drawCircle(
      c,
      r * 0.34,
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
        lit ? 3.4 : 2.4,
        Paint()..color = lit ? const Color(0xFFFFF8DC) : const Color(0xFFE4C56A),
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


/// Shows a gift that the server has already put on this account (or a
/// gift card code Play has just paid for). Nothing is minted here.
Future<void> openGiftBox(
  BuildContext context, {
  required GiftBox box,
  required String prize,
  required String itemId,
  String? code,
}) async {
  if (!context.mounted) return;
  RewardHaptics.big();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Gift',
    barrierColor: const Color(0xC0000000),
    pageBuilder: (context, _, __) => Stack(children: [
      const Positioned.fill(child: ConfettiBurst(color: Color(0xFFE4C56A), count: 70)),
      _Reveal(box: box, prize: prize, code: code ?? ''),
    ]),
  );
}

GiftBox giftBoxFor(String cardId) => switch (cardId) {
      'bundle' || 'signature3' => kGiftBoxes[2],
      'basic7' || 'ebook7' || 'standard30' || 'premium30' || 'ebook30' => kGiftBoxes[1],
      _ => kGiftBoxes[0],
    };

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
      onTap: () => showGiftCardSheet(context, giftCardFor(id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            _Turntable(
              phase: (title.hashCode.abs() % 9) / 9,
              child: EditableImage.asset(asset, height: 86, fit: BoxFit.contain, slot: 'gift_show.GiftPlanGrid'),
            ),
            const SizedBox(height: 8),
            EditableLabel('gift_show.GiftPlanGrid', title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
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
                                child: EditableImage.asset(widget.box.asset, fit: BoxFit.contain, slot: 'gift_show.Reveal'),
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
                              if (widget.code.isNotEmpty)
                                Text(widget.code, style: const TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 4),
                              const EditableLabel('gift_show.Reveal', 'On this account. Not cash. Not a rank key.', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () async {
                                  if (widget.code.isNotEmpty) await Clipboard.setData(ClipboardData(text: widget.code));
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                                child: widget.code.isEmpty
                                    ? const EditableLabel('gift_show.Reveal', 'Lovely', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800))
                                    : const EditableLabel('gift_show.Reveal', 'Copy code', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800)),
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


  @override
  Widget build(BuildContext context) {
    return GoldButton(
      label: 'Open a random gift',
      filled: false,
      // Today's free gift box, drawn by the server from the published
      // contents (Gifts → Rules). One a day; minutes in the app pick the box.
      onTap: () => runReward(context, () => EconomyApi.call('openDailyBox', {}), title: 'Today\u2019s gift'),
    );
  }
}

/// The casino spin. Plays once, then the wheel is already on the peg.
class _SpinFilm extends StatefulWidget {
  const _SpinFilm();

  @override
  State<_SpinFilm> createState() => _SpinFilmState();
}

class _SpinFilmState extends State<_SpinFilm> {
  VideoPlayerController? _video;
  var _left = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final video = VideoPlayerController.asset('assets/gifts/spin-wheel.mp4');
    _video = video;
    try {
      await video.initialize();
      if (!mounted) return;
      setState(() {});
      await video.setLooping(false);
      await video.play();
      video.addListener(_watch);
    } catch (_) {
      _close();
    }
    Future<void>.delayed(const Duration(seconds: 9), _close);
  }

  void _watch() {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    final length = video.value.duration;
    if (length > Duration.zero && video.value.position >= length - const Duration(milliseconds: 200)) {
      _close();
    }
  }

  void _close() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _video?.removeListener(_watch);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final ready = video != null && video.value.isInitialized;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: ready
            ? AspectRatio(
                aspectRatio: video.value.aspectRatio == 0 ? 9 / 16 : video.value.aspectRatio,
                child: VideoPlayer(video),
              )
            : const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Color(0xFFE4C56A), strokeWidth: 2),
              ),
      ),
    );
  }
}

