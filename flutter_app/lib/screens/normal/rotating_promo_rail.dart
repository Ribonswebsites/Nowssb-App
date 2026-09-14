/// Normal-home "More ways to keep your rhythm" — rebuilt from scratch.
///
/// Base: one rounded card, 3-up Store · Player · Earn (same icons, ripples,
/// labels). Rings are plain white/neutral rotating strokes — never rainbow.
///
/// Expanded: auto-cycles grid → Store → Player → Earn → grid. Each expanded
/// row reuses that item's exact icon circle (glyph + white ring + ripple), a
/// thin vertical divider, title + subtitle, and a small SVG in a white circle.
/// Same card height as the grid. No play-triangle left icon, no black arrow.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';

Color _bannerColor(double progress) {
  const seeds = [
    Color(0xFFFF9A3D), // orange
    Color(0xFFE94F83), // pink
    Color(0xFF9A58C9), // purple
    Color(0xFF3EAD7B), // green
    Color(0xFF467ED6), // blue
    Color(0xFF222633), // black
    Color(0xFF6B5B95), // soft periwinkle (readable white type)
  ];
  final scaled = progress * seeds.length;
  final index = scaled.floor() % seeds.length;
  final next = (index + 1) % seeds.length;
  return Color.lerp(seeds[index], seeds[next], scaled - scaled.floor())!;
}

/// Shared card height for grid and every expanded row.
const double kRhythmCardHeight = 146;

class NormalPromoRail extends StatefulWidget {
  const NormalPromoRail({
    super.key,
    required this.onStore,
    required this.onPlayer,
    required this.onEarn,
  });

  final VoidCallback onStore;
  final VoidCallback onPlayer;
  final VoidCallback onEarn;

  @override
  State<NormalPromoRail> createState() => _NormalPromoRailState();
}

class _NormalPromoRailState extends State<NormalPromoRail>
    with SingleTickerProviderStateMixin {
  /// 0 = grid, 1 = Store, 2 = Player, 3 = Earn
  var _page = 0;
  Timer? _cycle;

  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  List<_PromoDoorData> get _doors => [
        _PromoDoorData(
          title: NormalPromoRailLabels.store,
          subtitle: 'Words that heal',
          icon: 'assets/banners/promo/store.png',
          onTap: widget.onStore,
        ),
        _PromoDoorData(
          title: NormalPromoRailLabels.player,
          subtitle: 'Your word ritual',
          icon: 'assets/banners/promo/player.png',
          onTap: widget.onPlayer,
        ),
        _PromoDoorData(
          title: NormalPromoRailLabels.earn,
          subtitle: 'Grow with NowssB',
          icon: 'assets/banners/promo/earn.png',
          onTap: widget.onEarn,
        ),
      ];

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _page = (_page + 1) % _pageCount);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doors = _doors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More ways to keep your rhythm',
            style: TextStyle(
              color: NwsbColors.inkSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _motion,
            builder: (context, _) {
              return Container(
                height: kRhythmCardHeight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: _bannerColor(_motion.value),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x23000000),
                        blurRadius: 18,
                        offset: Offset(0, 8)),
                    BoxShadow(
                        color: Colors.white,
                        blurRadius: 12,
                        offset: Offset(-4, -4)),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _page == 0
                      ? KeyedSubtree(
                          key: const ValueKey('grid'),
                          child: _GridRow(doors: doors, motion: _motion),
                        )
                      : KeyedSubtree(
                          key: ValueKey('exp-$_page'),
                          child: _ExpandedRow(
                            door: doors[_page - 1],
                            phase: (_page - 1) / doors.length,
                            motion: _motion,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pageCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? NwsbColors.gold
                          : const Color(0x332B2D33),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoDoorData {
  const _PromoDoorData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;
}

/// 3-up grid — Store | Player | Earn.
class _GridRow extends StatelessWidget {
  const _GridRow({required this.doors, required this.motion});

  final List<_PromoDoorData> doors;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < doors.length; i++) ...[
          Expanded(
            child: _PromoDoor(
              phase: i / doors.length,
              motion: motion,
              door: doors[i],
            ),
          ),
          if (i != doors.length - 1)
            Container(
              width: 1,
              height: 66,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              color: Colors.white.withValues(alpha: .55),
            ),
        ],
      ],
    );
  }
}

/// Single expanded row: icon circle | divider | title+sub | white SVG disc.
class _ExpandedRow extends StatelessWidget {
  const _ExpandedRow({
    required this.door,
    required this.phase,
    required this.motion,
  });

  final _PromoDoorData door;
  final double phase;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: door.onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _IconDisc(phase: phase, motion: motion, icon: door.icon),
          const SizedBox(width: 14),
          Container(
            width: 1,
            height: 66,
            color: Colors.white.withValues(alpha: .55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  door.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  door.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Additional small SVG in its own white circle — never a black CTA.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: const Center(
              child: NwsbIcon(
                NwsbMarks.enterArrow,
                size: 14,
                viewBox: 12,
                color: Color(0xFF1A1A2E),
                strokeWidth: 1.7,
                cap: 'square',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoDoor extends StatelessWidget {
  const _PromoDoor({
    required this.phase,
    required this.motion,
    required this.door,
  });

  final double phase;
  final Animation<double> motion;
  final _PromoDoorData door;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: door.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconDisc(phase: phase, motion: motion, icon: door.icon),
          const SizedBox(height: 6),
          Text(
            door.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            door.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}

/// Exact grid icon circle: PNG glyph, white/neutral rotating ring, ripple.
class _IconDisc extends StatelessWidget {
  const _IconDisc({
    required this.phase,
    required this.motion,
    required this.icon,
  });

  final double phase;
  final Animation<double> motion;
  final String icon;

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, _) => CustomPaint(
          foregroundPainter:
              _NeutralRippleDiscPainter(value: (motion.value + phase) % 1),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xE9060C18),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain white/neutral rotating ring + ripple waves (no rainbow).
class _NeutralRippleDiscPainter extends CustomPainter {
  const _NeutralRippleDiscPainter({required this.value});
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        startAngle: value * math.pi * 2,
        colors: const [
          Color(0x00FFFFFF),
          Color(0xFFFFFFFF),
          Color(0xCCFFFFFF),
          Color(0x33FFFFFF),
          Color(0xEEFFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius, ring);

    for (var i = 0; i < 3; i++) {
      final wave = (value + i / 3) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: .82 * (1 - wave));
      canvas.drawCircle(center, radius * (.62 + wave * .48), paint);
    }
  }

  @override
  bool shouldRepaint(_NeutralRippleDiscPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Small semantic hooks for focused widget tests.
class NormalPromoRailLabels {
  static const store = 'Store';
  static const player = 'Player';
  static const earn = 'Earn';
}
