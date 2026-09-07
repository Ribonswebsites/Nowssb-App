/// Stats row, week grid, milestones for My Progress.
library;

import 'package:flutter/material.dart';

import '../../data/practice_progress.dart';
import 'progress_tokens.dart';

class ProgressStatsRow extends StatelessWidget {
  const ProgressStatsRow({super.key, required this.progress});
  final PracticeProgress progress;

  @override
  Widget build(BuildContext context) {
    final streak = progress.streak;
    final consistency = progress.weekConsistencyPercent;
    final weekLabel = progress.weekTimeLabel;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            num: '$streak',
            name: 'Day Streak',
            desc: streak == 0 ? 'Start today' : streak == 1 ? 'Started' : 'Days in a row',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _Stat(
            num: '$consistency%',
            name: 'Consistency',
            desc: 'Practice consistency',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _Stat(
            num: weekLabel,
            name: 'This Week',
            desc: 'Meditation time',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.num, required this.name, required this.desc});
  final String num;
  final String name;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return ProgressGlass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      minHeight: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.6,
              color: MpColors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.7,
              color: Color(0xFFDDD6B7),
            ),
          ),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(fontSize: 11, color: MpColors.dim)),
        ],
      ),
    );
  }
}

class ProgressWeekGrid extends StatelessWidget {
  const ProgressWeekGrid({super.key, required this.progress});
  final PracticeProgress progress;

  @override
  Widget build(BuildContext context) {
    final days = progress.thisWeekDays;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: days[i].done
                        ? Colors.white.withOpacity(0.095)
                        : MpColors.glass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: days[i].done || days[i].isToday
                          ? Colors.white.withOpacity(0.26)
                          : MpColors.line,
                    ),
                  ),
                  child: Text(
                    letters[i],
                    style: TextStyle(
                      color: days[i].done ? Colors.white : const Color(0xFF8D9294),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  names[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: days[i].isToday ? MpColors.white : const Color(0xFF8D9294),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ProgressLastPracticed extends StatelessWidget {
  const ProgressLastPracticed({super.key, required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: MpColors.gold, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          'Last practiced ${_fmt(date)}',
          style: const TextStyle(fontSize: 12, color: MpColors.soft),
        ),
      ],
    );
  }

  static String _fmt(String isoDay) {
    try {
      final d = DateTime.parse(isoDay);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return isoDay;
    }
  }
}

class ProgressMilestones extends StatelessWidget {
  const ProgressMilestones({super.key, required this.progress});
  final PracticeProgress progress;

  @override
  Widget build(BuildContext context) {
    final streak = progress.streak;
    final sessions = progress.totalSessions;
    final words = progress.uniqueWords;
    final items = <(String, String, bool)>[
      ('First Session', 'Complete 1 session', sessions >= 1),
      ('3-Day Spark', '3-day streak', streak >= 3),
      ('Week Keeper', '7-day streak', streak >= 7),
      ('Deep Resonance', '21-day streak', streak >= 21),
      ('Word Weaver', '10 unique words', words >= 10),
      ('Session Stack', '21 sessions', sessions >= 21),
      ('Century', '100 sessions logged', sessions >= 100),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            width: (MediaQuery.sizeOf(context).width - 48) / 2,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: item.$3 ? Colors.white.withOpacity(0.10) : MpColors.glass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.$3 ? Colors.white.withOpacity(0.28) : MpColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$3 ? 'UNLOCKED' : 'LOCKED',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: item.$3 ? MpColors.gold : MpColors.dim,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MpColors.white)),
                const SizedBox(height: 4),
                Text(item.$2, style: const TextStyle(fontSize: 11, color: MpColors.dim)),
              ],
            ),
          ),
      ],
    );
  }
}
