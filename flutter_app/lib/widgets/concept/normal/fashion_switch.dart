/// Fashion Mode — "The big switch": a physical toggle whose dark half is a
/// real still of the Fashion home (assets/fashion/fp-intro.webp), cropped
/// to the model and the neon plus; tapping
/// slides the knob into it, then switches.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

const kNFashionStill = 'assets/fashion/fp-intro.webp';

class NFashionSwitch extends StatefulWidget {
  const NFashionSwitch({super.key, required this.onSwitch});
  final VoidCallback onSwitch;
  @override
  State<NFashionSwitch> createState() => _NFashionSwitchState();
}

class _NFashionSwitchState extends State<NFashionSwitch> with SingleTickerProviderStateMixin, NormalLoop {
  bool _on = false;
  @override
  Duration get period => const Duration(milliseconds: 3600);
  Future<void> _go() async {
    setState(() => _on = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) {
      widget.onSwitch();
      setState(() => _on = false);
    }
  }
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Switch to Fashion Mode', onTap: _go, child: Container(decoration: neu(r: 30), padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text('Discover the experience', maxLines: 1, softWrap: false, style: nHello)),
          const Text('Fashion Mode', style: nTitle),
          const SizedBox(height: 4),
          const Text('Dark · Cinematic · Editorial', style: nSub),
          const SizedBox(height: 16),
          SizedBox(height: 84, child: LayoutBuilder(builder: (c, k) {
            final w = k.maxWidth;
            return AnimatedBuilder(animation: loop, builder: (_, __) {
              final nudge = _on ? 1.0 : math.max(0.0, math.sin(loop.value * math.pi * 2)) * .08;
              return Stack(children: [
                // track: light half → the real Fashion home still
                Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(42), child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF0E0B16)),
                  Positioned(right: 0, top: 0, bottom: 0, width: w * .64,
                      child: _ModelCrop(width: w * .64, height: 84)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [Color(0xFFE4E7EF), Color(0xFFE4E7EF), Color(0x002A2440)], stops: [0, .28, .46]))),
                ]))),
                AnimatedPositioned(duration: const Duration(milliseconds: 380), curve: Curves.easeInOutBack,
                  left: 6 + (w - 84) * nudge, top: 6, width: 72, height: 72,
                  child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: _on ? const Color(0xFF14101E) : nBase,
                    boxShadow: const [BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6), BoxShadow(color: Color(0x408E97B5), offset: Offset(3, 4), blurRadius: 8)]),
                    child: Icon(_on ? Icons.nightlight_round : Icons.wb_sunny_outlined, color: _on ? const Color(0xFFE6C77A) : nInk, size: 26))),
              ]);
            });
          })),
        ]))));
}

/// Crops the Fashion still to the model and the neon plus (the stacked
/// FASHION letters can't read whole in a short track, so they're left out).
class _ModelCrop extends StatelessWidget {
  const _ModelCrop({required this.width, required this.height});
  final double width, height;
  // focus point and visible span, as fractions of the 941×1672 still
  static const _fx = .40, _fy = .475, _span = .62;
  @override
  Widget build(BuildContext context) {
    final iw = width / _span, ih = iw * 1672 / 941;
    return ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned(left: width / 2 - iw * _fx, top: height / 2 - ih * _fy, width: iw, height: ih,
          child: Image.asset(kNFashionStill, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const SizedBox())),
    ]));
  }
}
