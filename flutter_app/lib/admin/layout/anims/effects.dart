/// Entrance (plays once) and loop (plays forever) effects, built with
/// flutter_animate. A section keeps them in its props (`entrance`, `loop`),
/// an element in its override style (same keys). The five classic
/// entrances (fadeUp, slide, scale, blur, fade) stay in
/// layout_sections.dart's entranceTransform so saved layouts look the same.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const kClassicEntrances = {'fadeUp', 'slide', 'scale', 'blur', 'fade'};

/// Every entrance, id → drawer label.
const kEntranceNames = <String, String>{
  'none': 'None',
  'fadeUp': 'Fade up',
  'slide': 'Slide in',
  'scale': 'Grow in',
  'blur': 'Blur in',
  'fade': 'Fade',
  'pop': 'Pop',
  'drop': 'Drop',
  'zoom': 'Zoom out',
  'rise': 'Rise',
  'swirl': 'Swirl',
  'elastic': 'Elastic',
  'fromLeft': 'From left',
  'flip': 'Flip',
  'flipUp': 'Flip up',
  'unfold': 'Unfold',
  'blurUp': 'Blur up',
};

/// Every loop, id → drawer label.
const kLoopNames = <String, String>{
  'none': 'Still',
  'pulse': 'Pulse',
  'float': 'Float',
  'breathe': 'Breathe',
  'bounce': 'Bounce',
  'heartbeat': 'Heartbeat',
  'wobble': 'Wobble',
  'swing': 'Swing',
  'shake': 'Shake',
  'jello': 'Jello',
  'tilt': 'Tilt',
  'spin': 'Spin',
  'shimmer': 'Shimmer',
  'flicker': 'Flicker',
};

const _ms = Duration.new;

FadeEffect _fadeIn([int ms = 260]) => FadeEffect(begin: 0, end: 1, delay: Duration.zero, duration: _ms(milliseconds: ms));

/// flutter_animate effects for a non-classic entrance (null: classic/none).
List<Effect<dynamic>>? entranceEffects(String kind) {
  const d = Duration.zero;
  return switch (kind) {
    'pop' => [_fadeIn(), const ScaleEffect(begin: Offset(0.7, 0.7), end: Offset(1, 1), delay: d, duration: Duration(milliseconds: 520), curve: Curves.easeOutBack)],
    'drop' => [_fadeIn(160), const MoveEffect(begin: Offset(0, -70), end: Offset.zero, delay: d, duration: Duration(milliseconds: 900), curve: Curves.bounceOut)],
    'zoom' => [_fadeIn(400), const ScaleEffect(begin: Offset(1.3, 1.3), end: Offset(1, 1), delay: d, duration: Duration(milliseconds: 650), curve: Curves.easeOutCubic)],
    'rise' => [_fadeIn(500), const SlideEffect(begin: Offset(0, 0.35), end: Offset.zero, delay: d, duration: Duration(milliseconds: 700), curve: Curves.easeOutQuart)],
    'swirl' => [
        _fadeIn(400),
        const RotateEffect(begin: -0.2, end: 0, delay: d, duration: Duration(milliseconds: 750), curve: Curves.easeOutBack),
        const ScaleEffect(begin: Offset(0.5, 0.5), end: Offset(1, 1), delay: d, duration: Duration(milliseconds: 750), curve: Curves.easeOutCubic),
      ],
    'elastic' => [_fadeIn(200), const ScaleEffect(begin: Offset(0.3, 0.3), end: Offset(1, 1), delay: d, duration: Duration(milliseconds: 1000), curve: Curves.elasticOut)],
    'fromLeft' => [_fadeIn(400), const MoveEffect(begin: Offset(-90, 0), end: Offset.zero, delay: d, duration: Duration(milliseconds: 650), curve: Curves.easeOutCubic)],
    'flip' => [_fadeIn(300), const FlipEffect(begin: -0.5, end: 0, delay: d, duration: Duration(milliseconds: 750), curve: Curves.easeOutBack, direction: Axis.horizontal)],
    'flipUp' => [_fadeIn(300), const FlipEffect(begin: 0.5, end: 0, delay: d, duration: Duration(milliseconds: 750), curve: Curves.easeOutBack, direction: Axis.vertical)],
    'unfold' => [_fadeIn(200), const ScaleEffect(begin: Offset(1, 0.02), end: Offset(1, 1), delay: d, duration: Duration(milliseconds: 600), curve: Curves.easeOutCubic, alignment: Alignment.topCenter)],
    'blurUp' => [
        _fadeIn(450),
        const BlurEffect(begin: Offset(14, 14), end: Offset.zero, delay: d, duration: Duration(milliseconds: 650)),
        const MoveEffect(begin: Offset(0, 24), end: Offset.zero, delay: d, duration: Duration(milliseconds: 650), curve: Curves.easeOutCubic),
      ],
    _ => null,
  };
}

/// flutter_animate effects for one loop cycle, and whether it plays back
/// and forth (null: none / unknown).
(List<Effect<dynamic>>, bool)? loopEffects(String kind) {
  const d = Duration.zero;
  Duration ms(int v) => _ms(milliseconds: v);
  return switch (kind) {
    'pulse' => (const [ScaleEffect(begin: Offset(1, 1), end: Offset(1.06, 1.06), delay: d, duration: Duration(milliseconds: 700), curve: Curves.easeInOut)], true),
    'float' => (const [MoveEffect(begin: Offset(0, 4), end: Offset(0, -6), delay: d, duration: Duration(milliseconds: 1600), curve: Curves.easeInOut)], true),
    'breathe' => (
        const [
          ScaleEffect(begin: Offset(0.985, 0.985), end: Offset(1.025, 1.025), delay: d, duration: Duration(milliseconds: 2400), curve: Curves.easeInOut),
          FadeEffect(begin: 0.82, end: 1, delay: d, duration: Duration(milliseconds: 2400), curve: Curves.easeInOut),
        ],
        true
      ),
    'bounce' => ([CustomEffect(delay: d, duration: ms(900), builder: (_, v, child) => Transform.translate(offset: Offset(0, -12 * math.sin(v * math.pi).abs()), child: child))], false),
    'heartbeat' => (
        [
          CustomEffect(
            delay: d,
            duration: ms(1300),
            builder: (_, v, child) {
              double bump(double at) => math.max(0.0, 1 - ((v - at) / 0.08).abs());
              return Transform.scale(scale: 1 + 0.08 * bump(0.1) + 0.06 * bump(0.3), child: child);
            },
          ),
        ],
        false
      ),
    'wobble' => (const [RotateEffect(begin: -0.012, end: 0.012, delay: d, duration: Duration(milliseconds: 900), curve: Curves.easeInOut)], true),
    'swing' => (const [RotateEffect(begin: -0.03, end: 0.03, delay: d, duration: Duration(milliseconds: 1100), curve: Curves.easeInOut, alignment: Alignment.topCenter)], true),
    'shake' => (
        [
          const ShakeEffect(delay: d, duration: Duration(milliseconds: 600), hz: 6, offset: Offset(5, 0), rotation: 0),
          const FadeEffect(begin: 1, end: 1, delay: Duration(milliseconds: 600), duration: Duration(milliseconds: 1400)),
        ],
        false
      ),
    'jello' => (
        [
          CustomEffect(
            delay: d,
            duration: ms(1600),
            builder: (_, v, child) {
              final s = v < 0.6 ? math.sin(v / 0.6 * math.pi * 4) * (1 - v / 0.6) * 0.12 : 0.0;
              return Transform(alignment: Alignment.center, transform: Matrix4.skewX(s), child: child);
            },
          ),
        ],
        false
      ),
    'tilt' => (
        [
          CustomEffect(
            delay: d,
            duration: ms(1800),
            curve: Curves.easeInOut,
            begin: -1,
            end: 1,
            builder: (_, v, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(v * 0.18),
              child: child,
            ),
          ),
        ],
        true
      ),
    'spin' => (const [RotateEffect(begin: 0, end: 1, delay: d, duration: Duration(milliseconds: 6000), curve: Curves.linear)], false),
    'shimmer' => (
        const [
          ShimmerEffect(delay: d, duration: Duration(milliseconds: 1400), color: Color(0x88FFFFFF)),
          FadeEffect(begin: 1, end: 1, delay: Duration(milliseconds: 1400), duration: Duration(milliseconds: 900)),
        ],
        false
      ),
    'flicker' => (
        [
          CustomEffect(
            delay: d,
            duration: ms(2200),
            builder: (_, v, child) {
              final off = (v > 0.1 && v < 0.13) || (v > 0.18 && v < 0.2) || (v > 0.62 && v < 0.64);
              return Opacity(opacity: off ? 0.35 : 1, child: child);
            },
          ),
        ],
        false
      ),
    _ => null,
  };
}

/// Plays loop [kind] on [child] forever (still when animations are off).
class LoopFx extends StatelessWidget {
  const LoopFx({super.key, required this.kind, required this.child});
  final String kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fx = loopEffects(kind);
    if (fx == null || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return child;
    return Animate(
      key: ValueKey('loop-$kind'),
      effects: fx.$1,
      onPlay: (c) => c.repeat(reverse: fx.$2),
      child: child,
    );
  }
}

/// Plays non-classic entrance [kind] once. Change [play] to replay it.
class EntranceFx extends StatelessWidget {
  const EntranceFx({super.key, required this.kind, required this.child, this.play = 0, this.repeat = false});
  final String kind;
  final Widget child;
  final int play;

  /// Drawer previews: play, hold, play again.
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    final fx = entranceEffects(kind);
    if (fx == null) return child;
    return Animate(
      key: ValueKey('ent-$kind-$play'),
      effects: [
        ...fx,
        if (repeat) const FadeEffect(begin: 1, end: 1, delay: Duration(milliseconds: 1000), duration: Duration(milliseconds: 1000)),
      ],
      onPlay: repeat ? (c) => c.repeat() : null,
      child: child,
    );
  }
}
