/// Gift unwrap: a black-glass gift box with a gold ribbon. Tap it and the
/// lid lifts and tips away, the ribbon parts, a soft gold glow blooms and
/// the wrapped content rises out. Pure Flutter — no external assets.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  static const _gold = Color(0xFFE4C56A);

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
                        _gold.withValues(alpha: .30 * lid), _gold.withValues(alpha: 0),
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
                        child: Center(child: Container(width: 16, color: _gold.withValues(alpha: 1 - lid * .7))),
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
                              border: Border.all(color: _gold),
                            ),
                            child: Center(child: Container(width: 16, color: _gold)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Text(widget.label,
                          style: const TextStyle(color: _gold, letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
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
