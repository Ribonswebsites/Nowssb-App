/// The Normal-home promo rail: three animated circular doors separated by hairline rules.
///
/// The web version uses the `.npc-card` fabric, three expanding ripple waves,
/// and a conic-gradient ring. Flutter keeps the same language while presenting
/// the three requested doors together: Store, Player, and Earn.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

List<Color> _shadeFamily(double progress) {
  const seeds = [
    Color(0xFFE34C62),
    Color(0xFFE59A30),
    Color(0xFF9A58C9),
    Color(0xFF3EAD7B),
    Color(0xFF467ED6),
    Color(0xFF222633),
  ];
  final scaled = progress * seeds.length;
  final index = scaled.floor() % seeds.length;
  final next = (index + 1) % seeds.length;
  final base = Color.lerp(seeds[index], seeds[next], scaled - scaled.floor())!;
  return List.generate(
    7,
    (i) => Color.lerp(Colors.white, base, .22 + (i * .12).clamp(0, .78))!,
  );
}

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
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doors =
        <({String title, String subtitle, String icon, VoidCallback tap})>[
      (
        title: 'Store',
        subtitle: 'Words that heal',
        icon: 'assets/banners/promo/store.png',
        tap: widget.onStore
      ),
      (
        title: 'Player',
        subtitle: 'Your word ritual',
        icon: 'assets/banners/promo/player.png',
        tap: widget.onPlayer
      ),
      (
        title: 'Earn',
        subtitle: 'Grow with NowssB',
        icon: 'assets/banners/promo/earn.png',
        tap: widget.onEarn
      ),
    ];

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
            builder: (context, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment(-1 + _motion.value * 2, -0.3),
                  end: Alignment(1 - _motion.value * 2, 0.3),
                  colors: _shadeFamily(_motion.value),
                  stops: [0, .16, .33, .5, .67, .84, 1],
                ),
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
              child: Row(
                children: [
                  for (var i = 0; i < doors.length; i++) ...[
                    Expanded(
                      child: _PromoDoor(
                        phase: i / doors.length,
                        motion: _motion,
                        title: doors[i].title,
                        subtitle: doors[i].subtitle,
                        icon: doors[i].icon,
                        onTap: doors[i].tap,
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final double phase;
  final Animation<double> motion;
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: motion,
              builder: (context, _) => CustomPaint(
                painter: _RippleDiscPainter(value: (motion.value + phase) % 1),
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
          ),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 8.5)),
        ],
      ),
    );
  }
}

class _RippleDiscPainter extends CustomPainter {
  const _RippleDiscPainter({required this.value});
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
          Color(0xFFFF4D77),
          Color(0xFFFFC24D),
          Color(0xFF71E3A6),
          Color(0xFF55B8FF),
          Color(0xFFB879FF),
          Color(0xFFFF4D77),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius, ring);

    for (var i = 0; i < 3; i++) {
      final wave = (value + i / 3) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: .55 * (1 - wave));
      canvas.drawCircle(center, radius * (.54 + wave * .52), paint);
    }
  }

  @override
  bool shouldRepaint(_RippleDiscPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Small semantic hooks for focused widget tests.
class NormalPromoRailLabels {
  static const store = 'Store';
  static const player = 'Player';
  static const earn = 'Earn';
}
