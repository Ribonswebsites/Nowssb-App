/// The NowssB gift unwrap moment.
///
/// One focus per beat: a single hero box floats in a pool of gold light,
/// shakes when tapped, bursts open (Lottie "Gift Box Opening Animation" by
/// Goodeisgn) with light rays and a gold confetti burst (painted), then the real
/// server-granted contents rise in a glass card with one Claim action.
/// Reduced motion (MediaQuery.disableAnimations) skips straight to the reveal.
/// Credits: flutter_app/assets/CREDITS.md.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/tokens.dart';
import '../economy/reward_fx.dart';
import '../economy/reward_overlay.dart';

const _gold = Color(0xFFE4C56A);
const _goldLight = Color(0xFFF6E3A1);
const _rose = NwsbColors.gold;
const _amber = NwsbColors.goldLight;

const kGiftBoxLottie = 'assets/gifts/gift_box_open_gold.json';
const kGiftSparkleLottie = 'assets/gifts/sparkle_stars_loop_gold.json';

/// Big hero gift: the Lottie box on its first frame, floating slowly over a
/// soft gold halo. Used on the Gifts page and as the idle state of the moment.
class GiftHeroBox extends StatefulWidget {
  const GiftHeroBox({super.key, this.size = 220, this.controller});
  final double size;
  final AnimationController? controller;
  @override
  State<GiftHeroBox> createState() => _GiftHeroBoxState();
}

class _GiftHeroBoxState extends State<GiftHeroBox> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.25,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_float.value);
          return Stack(alignment: Alignment.center, children: [
            // halo
            Container(
              width: s * (1.35 + .08 * t),
              height: s * (1.35 + .08 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _gold.withValues(alpha: .34),
                  _gold.withValues(alpha: .10),
                  _gold.withValues(alpha: 0),
                ], stops: const [0, .45, 1]),
              ),
            ),
            IgnorePointer(child: Opacity(opacity: .8, child: Lottie.asset(kGiftSparkleLottie, width: s * 1.4, height: s * 1.2, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()))),
            Transform.translate(offset: Offset(0, -10 * t), child: child),
          ]);
        },
        child: widget.controller != null
            ? Lottie.asset(kGiftBoxLottie, controller: widget.controller, width: s, height: s, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard_rounded, color: _gold, size: s * .6))
            : Lottie.asset(kGiftBoxLottie, animate: false, width: s, height: s, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard_rounded, color: _gold, size: s * .6)),
      ),
    );
  }
}

/// Full-screen unwrap. [items] are the real items the server granted.
class GiftUnwrapMoment extends StatefulWidget {
  const GiftUnwrapMoment({super.key, required this.title, required this.items, this.autoOpen = false, this.initialProgress});
  final String title;
  final List<Map<String, dynamic>> items;
  final bool autoOpen;

  /// For previews/tests: jump the sequence to a fixed point (0..1).
  final double? initialProgress;

  static Future<void> show(BuildContext context, {required String title, required List<Map<String, dynamic>> items}) {
    return RewardOverlay.enqueue((nav) => nav.push<void>(PageRouteBuilder<void>(
          opaque: false,
          barrierColor: const Color(0xF0000000),
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, _, __) => GiftUnwrapMoment(title: title, items: items),
          transitionsBuilder: (context, a, _, child) => FadeTransition(opacity: a, child: child),
        )));
  }

  @override
  State<GiftUnwrapMoment> createState() => _GiftUnwrapMomentState();
}

class _GiftUnwrapMomentState extends State<GiftUnwrapMoment> with TickerProviderStateMixin {
  // 0–.18 shake · .18–.62 box opens · .5 burst · .62–1 reveal
  late final AnimationController _seq = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _box = AnimationController(vsync: this);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _seq.addListener(() {
      final v = ((_seq.value - .18) / .44).clamp(0.0, 1.0);
      if (_box.duration != null) _box.value = v;
    });
    if (widget.initialProgress != null) {
      _started = true;
      _seq.value = widget.initialProgress!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still && !_started) {
      _started = true;
      _seq.value = 1;
    } else if (widget.autoOpen && !_started) {
      _open();
    }
  }

  void _open() {
    if (_started) return;
    setState(() => _started = true);
    RewardHaptics.big();
    _seq.forward();
  }

  @override
  void dispose() {
    _seq.dispose();
    _box.dispose();
    super.dispose();
  }

  double _span(double a, double b) => ((_seq.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _seq,
        builder: (context, _) {
          final shake = _span(0, .18);
          final burst = _span(.48, .78);
          final reveal = Curves.easeOutCubic.transform(_span(.62, 1));
          final boxFade = 1 - Curves.easeIn.transform(_span(.66, .86));
          final wiggle = math.sin(shake * math.pi * 8) * (1 - shake) * .12;
          return Stack(alignment: Alignment.center, children: [
            // depth: a deep radial pool of light that swells on the burst
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.15),
                    radius: .55 + .5 * burst,
                    colors: [
                      Color.lerp(_rose, _gold, burst)!.withValues(alpha: .22 + .22 * burst * (1 - reveal * .5)),
                      NwsbColors.deep.withValues(alpha: .94),
                      NwsbColors.plate,
                    ],
                    stops: const [0, .55, 1],
                  ),
                ),
              ),
            ),
            if (burst > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: _seq.value * .6,
                    child: CustomPaint(painter: _Rays(progress: burst, fade: 1 - reveal * .55)),
                  ),
                ),
              ),
            // eyebrow + title
            Positioned(
              top: MediaQuery.paddingOf(context).top + 36,
              left: 24,
              right: 24,
              child: Column(children: [
                Text(widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 30, height: 1.1, fontWeight: FontWeight.w600)),
              ]),
            ),
            // hero box
            if (boxFade > 0)
              Align(
                alignment: Alignment(0, -.05 - .42 * reveal),
                child: Opacity(
                  opacity: boxFade,
                  child: Transform.scale(
                    scale: (1 + .18 * Curves.easeOutBack.transform(_span(.18, .5)) + .2 * burst) * (1 - .3 * reveal),
                    child: Transform.rotate(
                      angle: wiggle,
                      child: GestureDetector(
                        onTap: _open,
                        child: _BoxLottie(controller: _box, size: math.min(size.width * .62, 260)),
                      ),
                    ),
                  ),
                ),
              ),
            if (_seq.value > .5) const IgnorePointer(child: ConfettiBurst(count: 45, color: _amber)),
            if (_seq.value > .5) const IgnorePointer(child: ConfettiBurst(count: 40, color: _rose)),
            // reveal card
            if (reveal > 0)
              Align(
                alignment: const Alignment(0, .5),
                child: Opacity(
                  opacity: reveal,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - reveal)),
                    child: _RevealCard(items: widget.items),
                  ),
                ),
              ),
            // the one action per beat
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 28,
              child: !_started
                  ? _Pill(label: 'Tap to open', onTap: _open, filled: false)
                  : Opacity(
                      opacity: reveal,
                      child: IgnorePointer(
                        ignoring: reveal < .9,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          _Pill(label: 'Claim', onTap: () => Navigator.of(context).maybePop()),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Close', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                          ),
                        ]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _BoxLottie extends StatelessWidget {
  const _BoxLottie({required this.controller, required this.size});
  final AnimationController controller;
  final double size;
  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        Container(
          width: size * 1.1,
          height: size * 1.1,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _gold.withValues(alpha: .25), blurRadius: 80, spreadRadius: 4)]),
        ),
        Lottie.asset(
          kGiftBoxLottie,
          controller: controller,
          width: size,
          height: size,
          fit: BoxFit.contain,
          onLoaded: (c) => controller.duration = c.duration,
          errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard_rounded, color: _gold, size: size * .6),
        ),
      ]);
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    final shown = items.isEmpty ? <Map<String, dynamic>>[{'type': 'none', 'label': 'This box was empty'}] : items;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x2EFFFFFF), Color(0x0AFFFFFF)]),
              border: Border.all(color: _gold.withValues(alpha: .55)),
              boxShadow: [BoxShadow(color: _gold.withValues(alpha: .22), blurRadius: 40, spreadRadius: -8)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < shown.length && i < 4; i++) RewardItemTile(item: shown[i], delayMs: i * 120),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.filled = true});
  final String label;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: filled ? const LinearGradient(colors: [_goldLight, _gold]) : null,
            border: filled ? null : Border.all(color: _gold.withValues(alpha: .7)),
            boxShadow: filled ? [BoxShadow(color: _gold.withValues(alpha: .35), blurRadius: 24, spreadRadius: -6)] : null,
          ),
          child: Text(label,
              style: TextStyle(color: filled ? Colors.black : _gold, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .4)),
        ),
      );
}

class _Rays extends CustomPainter {
  _Rays({required this.progress, required this.fade});
  final double progress;
  final double fade;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .43);
    final r = size.longestSide * (.3 + .7 * progress);
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a - .07), c.dy + r * math.sin(a - .07))
        ..lineTo(c.dx + r * math.cos(a + .07), c.dy + r * math.sin(a + .07))
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(colors: [_goldLight.withValues(alpha: .35 * fade), _gold.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: c, radius: r)));
    }
  }

  @override
  bool shouldRepaint(_Rays o) => o.progress != progress || o.fade != fade;
}

/// Inline tap-to-unwrap wrapper (kept for existing callers and goldens).
class GiftUnwrapReveal extends StatefulWidget {
  const GiftUnwrapReveal({super.key, required this.child, this.label = 'Tap to unwrap'});
  final Widget child;
  final String label;

  @override
  State<GiftUnwrapReveal> createState() => _GiftUnwrapRevealState();
}

class _GiftUnwrapRevealState extends State<GiftUnwrapReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _goldC = Color(0xFFE4C56A);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        if (t >= 1) return widget.child;
        final lid = Curves.easeOutBack.transform((t / .55).clamp(0.0, 1.0));
        final fade = Curves.easeIn.transform(((t - .45) / .55).clamp(0.0, 1.0));
        return GestureDetector(
          onTap: _c.isAnimating ? null : () => _c.forward(),
          child: Stack(alignment: Alignment.center, children: [
            Opacity(opacity: fade, child: Transform.translate(offset: Offset(0, 24 * (1 - fade)), child: widget.child)),
            if (fade < 1)
              Opacity(
                opacity: 1 - fade,
                child: SizedBox(
                  height: 200,
                  child: Stack(alignment: Alignment.center, children: [
                    // glow
                    Container(
                      width: 160 + 80 * lid, height: 160 + 80 * lid,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [
                        _goldC.withValues(alpha: .30 * lid), _goldC.withValues(alpha: 0),
                      ])),
                    ),
                    // box body
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 130, height: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1408), Colors.black, Color(0xFF14100A)]),
                          border: Border.all(color: const Color(0x99E4C56A)),
                        ),
                        child: Center(child: Container(width: 16, color: _goldC.withValues(alpha: 1 - lid * .7))),
                      ),
                    ),
                    // lid
                    Positioned(
                      bottom: 108,
                      child: Transform.translate(
                        offset: Offset(46 * lid, -70 * lid),
                        child: Transform.rotate(
                          angle: math.pi / 7 * lid,
                          child: Container(
                            width: 146, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF1A1408),
                              border: Border.all(color: _goldC),
                            ),
                            child: Center(child: Container(width: 16, color: _goldC)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Text(widget.label,
                          style: const TextStyle(color: _goldC, letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}
