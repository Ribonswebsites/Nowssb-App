/// Native Flutter translation of app/widgets/neomorphic_dashboard.html.
///
/// It is shown only on Normal Home, immediately after NmSearch. The labels,
/// values and card order intentionally mirror the supplied dashboard file.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/neumorphic.dart';

class NmSuppliedDashboard extends StatelessWidget {
  const NmSuppliedDashboard({super.key, this.onStart});

  final VoidCallback? onStart;

  static const _surface = Color(0xFFF5F5F5);
  static const _textDark = Color(0xFF1C1C1C);
  static const _textMid = Color(0xFF767676);
  static const _purple = Color(0xFF6D5BD0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // This is the requested breathing room directly beneath the search bar.
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FocusCard(onStart: onStart),
          const SizedBox(height: 26),
          const _SectionHeader(title: 'Your progress'),
          const SizedBox(height: 14),
          const _ProgressCard(),
          const SizedBox(height: 26),
          const _SectionHeader(title: 'Up next'),
          const SizedBox(height: 14),
          const _UpNextCard(),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({this.onStart});
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
                  "Today's focus",
                  style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Deep work session',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: NmSuppliedDashboard._textDark,
                  ),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FocusDot(),
                    Text('2h 0m', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NmSuppliedDashboard._textDark)),
                    _FocusDot(),
                    Text('High priority', style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid)),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onStart,
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Start session', style: TextStyle(color: Color(0xFFF3F0FF), fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, size: 16, color: Color(0xFFF3F0FF)),
                      ],
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
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NmSuppliedDashboard._textDark)),
          const Row(
            children: [
              Text('View all', style: TextStyle(fontSize: 13, color: NmSuppliedDashboard._textMid)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: NmSuppliedDashboard._textMid),
            ],
          ),
        ],
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      color: NmSuppliedDashboard._surface,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
      child: const Row(
        children: [
          Expanded(child: _Metric(icon: Icons.check, iconColor: Color(0xFF3BA55D), value: '12', label: 'Tasks done', delta: '+20% ↑', deltaColor: Color(0xFF3BA55D))),
          _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.schedule_outlined, iconColor: Color(0xFF8A8A8A), value: '8h 45m', label: 'Focused time', delta: '+15% ↑', deltaColor: Color(0xFF767676))),
          _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.local_fire_department_outlined, iconColor: Color(0xFFE78A3E), value: '5', label: 'Day streak', delta: '+1 ↑', deltaColor: Color(0xFFE78A3E))),
          _MetricDivider(),
          Expanded(child: _Metric(icon: Icons.track_changes, iconColor: Color(0xFF8A6FE0), value: '78%', label: 'Goal progress', delta: '+8% ↑', deltaColor: Color(0xFF8A6FE0))),
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
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: NmSuppliedDashboard._textMid)),
            const SizedBox(height: 6),
            Text(delta, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: deltaColor)),
          ],
        ),
      );
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard();

  @override
  Widget build(BuildContext context) => NeuCard(
        color: NmSuppliedDashboard._surface,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Column(
          children: [
            _UpNextRow(icon: Icons.calendar_today_outlined, color: Color(0xFFE78A3E), title: 'Team stand-up', subtitle: '10:00 AM · 30 min', status: 'Soon'),
            Divider(height: 1, color: Color(0x99D9D9D9)),
            _UpNextRow(icon: Icons.description_outlined, color: Color(0xFF8A8A8A), title: 'Design review', subtitle: '2:00 PM · 1h 0m'),
          ],
        ),
      );
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.icon, required this.color, required this.title, required this.subtitle, this.status});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? status;

  @override
  Widget build(BuildContext context) => Padding(
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
      );
}
