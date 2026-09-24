/// Progress courses board and the sound-age ring.
/// The ring is the same block on home, the sound library, and profile.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/practice_progress.dart';
import '../shell/nav_shell.dart';

/// Courses board from the reference, filled with NowssB practice paths.
class PracticeCoursesPanel extends StatelessWidget {
  const PracticeCoursesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = PracticeProgress.instance;
    final done = progress.uniqueWords;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4C9A), Color(0xFF3A2458), Color(0xFF1A1028)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/icons/logo-disc.webp',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(
                    radius: 21,
                    backgroundColor: Color(0xFF2A1840),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              _seg('My Practice', true),
              const SizedBox(width: 6),
              _seg('Progress', false),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 214,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF8AD8), Color(0xFFB14CFF), Color(0xFF6A35C8)],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/banners/promo/pose-02.png',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _faces('+12'),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text('Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Origin Words',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.05),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: Colors.white, size: 15),
                            const SizedBox(width: 4),
                            Text(progress.timeLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 10),
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD15C), size: 16),
                            const Text(' 4.7', style: TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 10),
                            const Icon(Icons.play_circle_outline, color: Colors.white, size: 15),
                            Text(' $done', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              done == 0 ? '0 of 5' : '1 of 5',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => NavScope.goTo(context, 1),
                              child: const Text(
                                'Continue  ›',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip('All Paths', '12', true),
              _chip('Completed', '$done', false),
              _chip('In practice', '${progress.todaySessions}', false),
              _chip('Saved', '${progress.streak}', false),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => NavScope.goTo(context, 1),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16121F),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/footer/tab-still-mind-still-style.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 96, height: 96, color: const Color(0xFF3A2458)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From\nSound to\nStillness',
                          style: TextStyle(color: Colors.white, fontSize: 18, height: 1.05, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text('12h 24m   ★ 4.8', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: on ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? Colors.white30 : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(color: on ? Colors.white : Colors.white60, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _chip(String label, String count, bool on) {
    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: TextStyle(color: on ? Colors.white : Colors.white54, fontWeight: FontWeight.w700, fontSize: 10),
              children: [
                TextSpan(text: ' $count', style: const TextStyle(fontSize: 9, color: Color(0xFFB9A0FF))),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(height: 2, color: on ? Colors.white : Colors.transparent),
        ],
      ),
    );
  }

  Widget _faces(String extra) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icons/logo-disc.webp',
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22),
            ),
          ),
          const SizedBox(width: 4),
          Text(extra, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Biological-age board. Numbers come from recorded practice.
class SoundAgePanel extends StatefulWidget {
  const SoundAgePanel({super.key, this.onSnapshot});

  /// Opens the full progress page. Falls back to the practice tab.
  final VoidCallback? onSnapshot;

  @override
  State<SoundAgePanel> createState() => _SoundAgePanelState();
}

class _SoundAgePanelState extends State<SoundAgePanel> {
  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_on);
    PracticeProgress.instance.start();
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = PracticeProgress.instance;
    final streak = p.streak;
    final age = p.totalSessions == 0 ? p.level : (36 - streak.clamp(0, 14));
    final younger = p.totalSessions == 0 ? 'Start today' : '$streak days sharper';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07080D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/icons/logo-disc.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40),
                ),
              ),
              const Expanded(
                child: Text(
                  'Estimated\nSound Age',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, height: 1.15, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16181F),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CustomPaint(size: Size(210, 210), painter: _AgeRingPainter()),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$age',
                      style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w600, height: 1),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A120E),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0x66FF6A2A)),
                      ),
                      child: Text(
                        younger,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 18,
            child: Row(
              children: [
                for (var i = 0; i < 36; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: i == (streak % 36) ? 16 : 8,
                      color: i == (streak % 36) ? const Color(0xFFFF4D2E) : const Color(0x33FFFFFF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: widget.onSnapshot ?? () => NavScope.goTo(context, 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF1A1C24), Color(0xFF101218)]),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Practice\nSnapshot',
                          style: TextStyle(color: Colors.white, fontSize: 20, height: 1.1, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Text('Recommendations  ›', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _mini(
                  const Color(0xFF3A0D12),
                  const Color(0xFF7A1D24),
                  Icons.lightbulb_outline,
                  'Your\nInsights',
                  '${p.todaySessions} today',
                  () => NavScope.goTo(context, 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mini(
                  const Color(0xFF3A220C),
                  const Color(0xFFC65A12),
                  Icons.calendar_today_outlined,
                  'Action\nPlan',
                  'Details',
                  () => NavScope.goTo(context, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(Color a, Color b, IconData icon, String title, String cta, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 158,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.05, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
              child: Text('$cta  →', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeRingPainter extends CustomPainter {
  const _AgeRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0x55FF3B1F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final ticks = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF5A32);
    for (var i = 0; i < 90; i++) {
      final a = (i / 90) * math.pi * 2 - 1.2;
      final inner = r - 6 - (i % 5) * 1.2;
      final outer = r + 8 + (i % 7);
      canvas.drawLine(
        c + Offset(inner * math.cos(a), inner * math.sin(a)),
        c + Offset(outer * math.cos(a), outer * math.sin(a)),
        ticks,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
