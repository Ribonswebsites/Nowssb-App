/// Profile > "Your practice mind": the cognitive-cards layout from Ribon's
/// reference, rebuilt in the two Editeaze styles (orange-box cards and the
/// two-photo strip) in NowssB gold. Every number is the user's own practice
/// record from [PracticeProgress]; nothing is estimated, and nothing here is
/// a brain or medical measurement. With no sessions yet it says so.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/practice_progress.dart';
import '../widgets/editeaze.dart';

/// NowssB gold (tokens: gold C8A96E, profile accent E3BD7D), deepened so
/// white type reads on it.
const kMindGold = Color(0xFFB8924F);
const _mindImage = 'assets/home/ez/ez-med-lotus-white.webp';

/// Real numbers for the section, computed from session records.
class MindStats {
  MindStats.from(PracticeProgress p)
      : total = p.totalSessions,
        today = p.todaySessions,
        goal = PracticeProgress.dailyPracticeGoal,
        streak = p.streak,
        minutes = p.totalMinutes,
        words = p.uniqueWords,
        byPart = _parts(p.sessionsSnapshot),
        week = _week(p);

  final int total, today, goal, streak, minutes, words;
  /// Sessions started in the morning, afternoon, evening and night.
  final List<int> byPart;
  /// Sessions on each of the last 7 days, oldest first.
  final List<int> week;

  /// Today's sessions against the daily plan, 0..100.
  int get focusPercent => goal <= 0 ? 0 : ((today.clamp(0, goal) / goal) * 100).round();

  static List<int> _parts(List<Map<String, dynamic>> s) {
    final out = [0, 0, 0, 0];
    for (final x in s) {
      final t = DateTime.tryParse('${x['completedAt'] ?? ''}')?.toLocal();
      if (t == null) continue;
      final h = t.hour;
      out[h >= 5 && h < 12 ? 0 : h >= 12 && h < 17 ? 1 : h >= 17 && h < 21 ? 2 : 3]++;
    }
    return out;
  }

  static List<int> _week(PracticeProgress p) {
    final now = DateTime.now();
    String day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final counts = <String, int>{};
    for (final x in p.sessionsSnapshot) {
      final d = '${x['date'] ?? ''}';
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return [for (var i = 6; i >= 0; i--) counts[day(DateTime(now.year, now.month, now.day - i))] ?? 0];
  }
}

class ProfileMind extends StatelessWidget {
  const ProfileMind({super.key, this.onPractice, this.onProgress});
  final VoidCallback? onPractice;
  final VoidCallback? onProgress;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PracticeProgress.instance,
        builder: (context, _) {
          final m = MindStats.from(PracticeProgress.instance);
          return Column(
            key: const ValueKey('profile-mind'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text('Your practice mind', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              if (m.total == 0) _empty() else ..._cards(m),
            ],
          );
        },
      );

  Widget _empty() => EzOrangeCard(
        key: const ValueKey('mind-empty'),
        color: kMindGold,
        title: 'Practice once to see this',
        subtitle: 'Your rhythm, focus and streak appear after a session',
        image: _mindImage,
        alignment: const Alignment(0, -.2),
        height: 220,
        icons: [EzIcon(Icons.play_arrow_rounded, label: 'Practise now', onTap: onPractice)],
        onTap: onPractice,
      );

  List<Widget> _cards(MindStats m) {
    const parts = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final best = m.byPart.reduce(math.max);
    final bestPart = best == 0 ? null : parts[m.byPart.indexOf(best)];
    return [
      // Focus: today's sessions against the daily plan.
      EzOrangeCard(
        key: const ValueKey('mind-focus'),
        color: kMindGold,
        title: 'Focus today',
        subtitle: '${m.today} of ${m.goal} planned sessions',
        height: 230,
        icons: [EzIcon(Icons.insights_rounded, label: 'See progress', onTap: onProgress)],
        comment: EzComment(name: '${m.streak} day streak', text: '${m.minutes} min · ${m.words} words practised', icon: Icons.local_fire_department_rounded),
        onTap: onProgress,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(_mindImage, fit: BoxFit.cover, alignment: const Alignment(0, -.25), cacheWidth: 800,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Positioned(right: 14, bottom: 14, child: _Ring(percent: m.focusPercent)),
        ]),
      ),
      const SizedBox(height: 14),
      // Rhythm + load, the reference's curve and wave cards.
      Row(children: [
        Expanded(
          child: EzOrangeCard(
            key: const ValueKey('mind-rhythm'),
            color: kMindGold,
            title: 'Rhythm',
            subtitle: bestPart == null ? 'No times recorded' : 'Mostly $bestPart',
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: _Graph(values: m.byPart, labels: const ['AM', 'PM', 'Eve', 'Night'], curve: true),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: EzOrangeCard(
            key: const ValueKey('mind-week'),
            color: kMindGold,
            title: 'This week',
            subtitle: '${m.week.fold<int>(0, (a, b) => a + b)} sessions in 7 days',
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: _Graph(values: m.week, labels: const ['', '', '', '', '', '', 'Today'], curve: false),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      // Two-photo strip: morning vs evening practice, counted.
      EzSplitStrip(
        key: const ValueKey('mind-strip'),
        tileColor: kMindGold,
        left: EzTile(image: 'assets/home/ez/ez-med-beach.webp', label: 'Morning · ${m.byPart[0]}', alignment: const Alignment(0, .2), onTap: onProgress),
        right: EzTile(image: 'assets/home/ez/ez-med-candle.webp', label: 'Evening · ${m.byPart[2] + m.byPart[3]}', onTap: onProgress),
        addLabel: 'Practise now',
        addIcon: Icons.play_arrow_rounded,
        onAdd: onPractice,
      ),
    ];
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.percent});
  final int percent;
  @override
  Widget build(BuildContext context) => Container(
        width: 84, height: 84,
        decoration: const BoxDecoration(color: kEzPill, shape: BoxShape.circle),
        child: CustomPaint(
          painter: _RingPainter(percent / 100),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
              const Text('of plan', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9)),
            ]),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f);
  final double f;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawArc(r.deflate(7), 0, math.pi * 2, false, p..color = const Color(0x26FFFFFF));
    if (f > 0) c.drawArc(r.deflate(7), -math.pi / 2, math.pi * 2 * f.clamp(0, 1), false, p..color = const Color(0xFFE3BD7D));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.f != f;
}

class _Graph extends StatelessWidget {
  const _Graph({required this.values, required this.labels, required this.curve});
  final List<int> values;
  final List<String> labels;
  final bool curve;
  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(child: CustomPaint(painter: _GraphPainter(values, curve), size: Size.infinite)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final l in labels) Text(l, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 9)),
        ]),
      ]);
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.v, this.curve);
  final List<int> v;
  final bool curve;
  @override
  void paint(Canvas c, Size s) {
    if (v.isEmpty) return;
    final top = math.max(1, v.reduce(math.max));
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(v.length == 1 ? s.width / 2 : s.width * i / (v.length - 1), s.height - 4 - (s.height - 10) * v[i] / top),
    ];
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (curve) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mx = (a.dx + b.dx) / 2;
        path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }
      c.drawPath(path, line);
      for (final p in pts) {
        c.drawCircle(p, 3, Paint()..color = Colors.white);
      }
    } else {
      final w = math.min(10.0, s.width / v.length * .5);
      for (final p in pts) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(p.dx - w / 2, p.dy, p.dx + w / 2, s.height), const Radius.circular(4)),
            Paint()..color = p.dy >= s.height - 4.5 ? const Color(0x40FFFFFF) : Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_GraphPainter o) => o.v.toString() != v.toString() || o.curve != curve;
}
