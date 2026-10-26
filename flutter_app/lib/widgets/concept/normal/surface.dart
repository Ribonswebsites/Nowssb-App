/// NORMAL HOME v2 — white neumorphic page tokens only (no shared components:
/// every section draws its own signature shape).
library;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../theme/tokens.dart';

const nBase = NwsbColors.surface;
const nInk = NwsbColors.ink;
const nSoft = Color(0xFF5F6475);
const nAccent = Color(0xFF6C63D9);
const nGold = Color(0xFFD9A441);

/// Raised (convex) or pressed (concave) neumorphic decoration.
BoxDecoration neu({double r = 26, bool pressed = false, Color color = nBase}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r),
      boxShadow: pressed
          ? const []
          : const [
              BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 14),
              BoxShadow(color: Color(0x2E8E97B5), offset: Offset(7, 8), blurRadius: 18),
            ],
      gradient: pressed
          ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFDDE1EA), Color(0xFFF7F8FB)])
          : null,
    );

/// Loop driver for a section; holds still under reduced motion or [debugT].
mixin NormalLoop<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  /// Renders/tests: freeze every NORMAL HOME loop at this phase (0–1).
  static double? debugT;
  late final AnimationController loop;
  Duration get period;
  @override
  void initState() {
    super.initState();
    loop = AnimationController(vsync: this, duration: period);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || debugT != null;
    if (still) {
      loop.stop();
      loop.value = debugT ?? .35;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }
  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Holder so tests can set the freeze phase without touching the mixin.
class NormalMotion {
  static set freeze(double? t) => NormalLoop.debugT = t;
}

// Type: copies the home greeting exactly (DM Sans via theme).
/// "Good Evening" — 19 / w300 / inkSoft.
/// v3: ink raised to ~57% black so it clears WCAG AA (4.5:1) on [nBase].
const nHello = TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: nHelloInk);
const nHelloInk = Color(0x91000000);
/// Sublines: ~62% black (AA on [nBase]).
const nSubInk = Color(0x9E000000);
/// Links: #5A50C8 (AA on [nBase] and white).
const nLink = Color(0xFF5A50C8);
/// "Healer" — 26 / w800 / ink / 1.1.
const nTitle = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: NwsbColors.ink, height: 1.1);
/// "Ready for today's healing practice?" — 12.5 / inkFaint.
const nSub = TextStyle(fontSize: 12.5, color: nSubInk, height: 1.35);
/// A link line in greeting type.
const nLinkStyle = TextStyle(fontSize: 12.5, color: nLink, fontWeight: FontWeight.w700, height: 1.35);
/// Only giant poster words may use this.
const nPoster = TextStyle(fontFamily: 'Anton', height: .95, color: NwsbColors.ink);

/// Lottie that freezes with [NormalLoop.debugT] / reduced motion.
class NLottie extends StatelessWidget {
  const NLottie(this.asset, {super.key, this.size = 56});
  final String asset;
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = NormalLoop.debugT;
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return Lottie.asset(asset, width: size, height: size, fit: BoxFit.contain,
        controller: t != null ? AlwaysStoppedAnimation<double>(t) : null,
        animate: t == null && !still,
        errorBuilder: (_, __, ___) => SizedBox.square(dimension: size));
  }
}

/// A whole-card tap target with a soft press-in.
class NPress extends StatefulWidget {
  const NPress({super.key, required this.onTap, required this.child, this.label});
  final VoidCallback onTap;
  final Widget child;
  final String? label;
  @override
  State<NPress> createState() => _NPressState();
}

class _NPressState extends State<NPress> {
  bool _d = false;
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: widget.label,
      child: GestureDetector(behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _d = true), onTapCancel: () => setState(() => _d = false),
        onTapUp: (_) => setState(() => _d = false), onTap: widget.onTap,
        child: AnimatedScale(scale: _d ? .97 : 1, duration: const Duration(milliseconds: 140), child: widget.child)));
}
