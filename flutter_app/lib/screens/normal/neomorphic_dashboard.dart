/// Native Flutter translation of app/widgets/neomorphic_dashboard.html.
///
/// It is shown only on Normal Home, immediately after NmSearch. The labels,
/// values and card order intentionally mirror the supplied dashboard file.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../theme/tokens.dart';
import '../../widgets/neumorphic.dart';
import '../practice.dart';

typedef DashboardPracticeLauncher = void Function(List<Word> words, String title);

const _dashboardSlotTitles = <String, String>{
  'morning': 'Morning Ritual',
  'afternoon': 'Afternoon Session',
  'evening': 'Evening Practice',
  'night': 'Night Restoration',
};

class NmSuppliedDashboard extends StatelessWidget {
  const NmSuppliedDashboard({super.key, this.onStart, this.onProgress});

  final DashboardPracticeLauncher? onStart;
  final VoidCallback? onProgress;

  static const _surface = Color(0xFFF5F5F5);
  static const _textDark = Color(0xFF1C1C1C);
  static const _textMid = Color(0xFF767676);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ContentStore.instance, PracticeProgress.instance]),
      builder: (context, _) {
        final slot = nwsbSlot();
        final all = ContentStore.instance.library;
        final active = all.where((word) => word.time == slot || word.time == 'any').toList();
        final nextSlot = slot == 'morning' ? 'afternoon' : slot == 'afternoon' ? 'evening' : 'night';
        final next = all.where((word) => word.time == nextSlot || word.time == 'any').toList();
        final title = _dashboardSlotTitles[slot] ?? 'Practice';
        final progress = PracticeProgress.instance;
        final completed = progress.completedTodayFor(active);
        final goal = active.isEmpty ? 0 : (completed / active.length * 100).round().clamp(0, 100).toInt();
        final launch = () => onStart?.call(active, title);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FocusCard(title: title, count: active.length, onStart: launch),
              const SizedBox(height: 26),
              _SectionHeader(title: 'Your progress', onTap: onProgress),
              const SizedBox(height: 14),
              _ProgressCard(today: progress.todaySessions, total: progress.totalSessions, streak: progress.streak, goal: goal, completed: completed, target: active.length),
              const SizedBox(height: 26),
              _SectionHeader(title: 'Up next', onTap: launch),
              const SizedBox(height: 14),
              _UpNextCard(activeTitle: '$title Word Ritual', activeSub: _routineSummary(active), nextTitle: '${_dashboardSlotTitles[nextSlot] ?? 'Next'} Word Ritual', nextSub: _routineSummary(next), onTap: launch),
            ],
          ),
        );
      },
    );
  }

  static String _routineSummary(List<Word> words) => words.isEmpty ? 'No words available yet' : '${words.length} word${words.length == 1 ? '' : 's'} ready to play';
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.title, required this.count, this.onStart});
  final String title;
  final int count;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      color: NmSuppliedDashboard._surface,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 78),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's practice",
                  style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: NmSuppliedDashboard._textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _FocusDot(),
                    Text(count == 0 ? 'No words yet' : '$count word${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NmSuppliedDashboard._textDark)),
                    const _FocusDot(),
                    const Text('Plays aloud', style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid)),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: count == 0 ? null : onStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: [Color(0xFF333A4A), Color(0xFF232833)]),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFB9BFC9), offset: Offset(6, 6), blurRadius: 14),
                        BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 14),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Play session', style: TextStyle(color: Color(0xFFF3F0FF), fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(width: 10),
                          Icon(Icons.play_arrow_rounded, size: 17, color: Color(0xFFF3F0FF)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(right: -4, top: -4, child: _FocusBlob()),
        ],
      ),
    );
  }
}

class _FocusDot extends StatelessWidget {
  const _FocusDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Color(0xFFA79AE8), shape: BoxShape.circle),
      );
}

class _FocusBlob extends StatelessWidget {
  const _FocusBlob();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 26,
            child: Transform.rotate(
              angle: .48,
              child: Container(
                width: 78,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: const LinearGradient(colors: [Color(0xFFC9C2F0), Color(0xFFE7E2FB)]),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 4,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF7C6AE0), Color(0xFF9384E8)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NmSuppliedDashboard._textDark)),
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text('View all', style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: NmSuppliedDashboard._textMid),
              ],
            ),
          ),
        ],
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.today, required this.total, required this.streak, required this.goal, required this.completed, required this.target});
  final int today;
  final int total;
  final int streak;
  final int goal;
  final int completed;
  final int target;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      color: NmSuppliedDashboard._surface,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
      child: Row(
        children: [
          Expanded(child: _Metric(icon: Icons.check, iconColor: const Color(0xFF3BA55D), value: '$today', label: 'Today', delta: today == 0 ? 'Start now' : 'Completed', deltaColor: const Color(0xFF3BA55D))),
          const _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.schedule_outlined, iconColor: const Color(0xFF8A8A8A), value: '$total', label: 'Sessions', delta: total == 0 ? 'None yet' : 'All time', deltaColor: NmSuppliedDashboard._textMid)),
          const _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.local_fire_department_outlined, iconColor: const Color(0xFFE78A3E), value: '$streak', label: 'Day streak', delta: streak == 0 ? 'Start today' : 'In a row', deltaColor: const Color(0xFFE78A3E))),
          const _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.track_changes, iconColor: const Color(0xFF8A6FE0), value: target == 0 ? '—' : '$goal%', label: 'Today’s goal', delta: target == 0 ? 'No routine' : '$completed of $target', deltaColor: const Color(0xFF8A6FE0))),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 38, color: const Color(0x99D9D9D9));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.iconColor, required this.value, required this.label, required this.delta, required this.deltaColor});
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: NwsbShadows.raisedXs),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(height: 10),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: NmSuppliedDashboard._textDark)),
            const SizedBox(height: 3),
            Text(label, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: NmSuppliedDashboard._textMid)),
            const SizedBox(height: 6),
            Text(delta, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: deltaColor)),
          ],
        ),
      );
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.activeTitle, required this.activeSub, required this.nextTitle, required this.nextSub, this.onTap});
  final String activeTitle;
  final String activeSub;
  final String nextTitle;
  final String nextSub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => NeuCard(
        color: NmSuppliedDashboard._surface,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _UpNextRow(icon: Icons.play_circle_outline, color: const Color(0xFFE78A3E), title: activeTitle, subtitle: activeSub, status: 'Now', onTap: onTap),
            const Divider(height: 1, color: Color(0x99D9D9D9)),
            _UpNextRow(icon: Icons.schedule_outlined, color: const Color(0xFF8A8A8A), title: nextTitle, subtitle: nextSub, onTap: onTap),
          ],
        ),
      );
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.icon, required this.color, required this.title, required this.subtitle, this.status, this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: NwsbShadows.raisedXs),
              child: Icon(icon, color: color, size: 21),
            ),
            Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 14), color: const Color(0x99D9D9D9)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NmSuppliedDashboard._textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: NmSuppliedDashboard._textMid)),
                ],
              ),
            ),
            if (status != null)
              Row(children: [Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA8A8A8), width: 2))), const SizedBox(width: 6), Text(status!, style: const TextStyle(fontSize: 12.5, color: NmSuppliedDashboard._textMid))])
            else
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA8A8A8)),
          ],
        ),
        ),
      );
}
