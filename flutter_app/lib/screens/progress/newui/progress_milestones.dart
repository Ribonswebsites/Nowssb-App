/// Honest milestones: computed only from real streak/session counts.
/// No purchases, no countdown pressure, no fake rewards.
library;

import 'package:flutter/material.dart';

import 'progress_glass.dart';

class PgMilestone {
  const PgMilestone(this.title, this.target, this.current, this.icon);
  final String title;
  final int target, current;
  final IconData icon;
  bool get done => current >= target;
  double get fraction => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

List<PgMilestone> pgMilestones({required int streak, required int sessions, required int minutes}) => [
      PgMilestone('First practice', 1, sessions, Icons.spa_rounded),
      PgMilestone('3-day streak', 3, streak, Icons.local_fire_department_rounded),
      PgMilestone('7-day streak', 7, streak, Icons.self_improvement_rounded),
      PgMilestone('60 calm minutes', 60, minutes, Icons.timer_rounded),
      PgMilestone('25 sessions', 25, sessions, Icons.auto_awesome_rounded),
    ];

class PgMilestoneRail extends StatelessWidget {
  const PgMilestoneRail({super.key, required this.items});
  final List<PgMilestone> items;
  @override
  Widget build(BuildContext context) {
    final next = items.where((m) => !m.done).firstOrNull;
    return PgGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Milestones', style: TextStyle(color: PgColors.ink, fontWeight: FontWeight.w600)),
        if (next != null) ...[
          const SizedBox(height: 4),
          Text('Next: ${next.title} (${next.current}/${next.target})',
              key: const Key('pg-next-milestone'), style: const TextStyle(color: PgColors.sub, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _Badge(m: items[i]),
          ),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.m});
  final PgMilestone m;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '${m.title}, ${m.done ? 'earned' : '${m.current} of ${m.target}'}',
        child: SizedBox(
          width: 72,
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: m.fraction,
                  strokeWidth: 3,
                  color: PgColors.lilac,
                  backgroundColor: const Color(0x22FFFFFF),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: m.done
                      ? const RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFFEDE8FF), PgColors.violet, Color(0xFF4B3A9E)])
                      : null,
                  color: m.done ? null : const Color(0x14FFFFFF),
                ),
                child: Icon(m.icon, size: 22, color: m.done ? PgColors.bg : PgColors.sub),
              ),
            ]),
            const SizedBox(height: 6),
            Text(m.title, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(color: PgColors.sub, fontSize: 11)),
          ]),
        ),
      );
}
