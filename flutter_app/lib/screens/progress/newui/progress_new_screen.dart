/// My Progress, new meditation glass UI (flag `newui_progress`).
/// Data comes only from [PracticeProgress] (one source of truth, spec 24).
library;

import 'package:flutter/material.dart';

import '../../../data/practice_progress.dart';
import '../../../widgets/app_backdrop.dart';
import 'progress_glass.dart';
import 'progress_milestones.dart';
import 'progress_motion.dart';

enum ProgressLoad { loading, ready, error, offline }

/// Plain snapshot so the UI is testable without Firebase.
class ProgressView {
  const ProgressView({
    required this.streak,
    required this.totalSessions,
    required this.totalMinutes,
    required this.uniqueWords,
    required this.todaySessions,
    required this.weekPercent,
    required this.week,
    required this.recent,
  });
  final int streak, totalSessions, totalMinutes, uniqueWords, todaySessions, weekPercent;
  final List<({String date, bool done, bool isToday, bool isFuture})> week;
  final List<String> recent;

  bool get isEmpty => totalSessions == 0;

  factory ProgressView.from(PracticeProgress p) => ProgressView(
        streak: p.streak,
        totalSessions: p.totalSessions,
        totalMinutes: p.totalMinutes,
        uniqueWords: p.uniqueWords,
        todaySessions: p.todaySessions,
        weekPercent: p.weekConsistencyPercent,
        week: p.thisWeekDays,
        recent: p.sessionsSnapshot.map((m) => '${m['word'] ?? ''}').where((w) => w.isNotEmpty).take(6).toList(),
      );
}

class ProgressNewScreen extends StatelessWidget {
  const ProgressNewScreen({super.key, required this.load, this.view, this.onBack, this.onRetry, this.onStart, this.background});
  final ProgressLoad load;
  final ProgressView? view;
  final VoidCallback? onBack, onRetry, onStart;

  /// Defaults to the app's own [AppBackdrop] (original background video /
  /// saved still). Tests inject a still frame because video can't play there.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          background ?? const AppBackdrop(),
          SafeArea(
            child: Column(children: [
              _Header(onBack: onBack),
              Expanded(child: _body()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _body() {
    switch (load) {
      case ProgressLoad.loading:
        return const Center(
          key: Key('pg-loading'),
          child: CircularProgressIndicator(color: Colors.white),
        );
      case ProgressLoad.error:
        return _Message(
          key: const Key('pg-error'),
          icon: Icons.cloud_off_rounded,
          title: "We couldn't load your progress",
          body: 'Your sessions are safe. Try again in a moment.',
          action: 'Try again',
          onTap: onRetry,
        );
      case ProgressLoad.offline:
      case ProgressLoad.ready:
        final v = view;
        if (v == null || v.isEmpty) {
          return _Message(
            key: const Key('pg-empty'),
            icon: Icons.spa_rounded,
            title: 'Your journey starts here',
            body: 'Finish one practice and your streak, minutes and week appear here.',
            action: 'Start a practice',
            onTap: onStart,
          );
        }
        return _Ready(view: v, offline: load == ProgressLoad.offline, onStart: onStart);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onBack});
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
        child: Row(children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PgColors.ink),
          ),
          const Text('My Progress', style: TextStyle(color: PgColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.title, required this.body, required this.action, this.onTap});
  final IconData icon;
  final String title, body, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PgGlass(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _CardTop(),
              const SizedBox(height: 12),
              _Circle(child: Icon(icon, color: Colors.white, size: 64)),
              const SizedBox(height: 18),
              PgPanel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: _title),
                  const SizedBox(height: 8),
                  Text(body, style: _body),
                  const SizedBox(height: 18),
                  Align(alignment: Alignment.centerRight, child: PgPill(label: action, onTap: onTap)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

const _title = TextStyle(color: PgColors.ink, fontSize: 24, height: 1.15, fontWeight: FontWeight.w800);
const _body = TextStyle(color: PgColors.sub, fontSize: 12.5, height: 1.4);
const _label = TextStyle(color: PgColors.ink, fontWeight: FontWeight.w700);

/// Status-bar-style top row with a heart, as in the reference card.
class _CardTop extends StatelessWidget {
  const _CardTop({this.text = 'NowssB'});
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text, style: const TextStyle(color: PgColors.sub, fontSize: 11, fontWeight: FontWeight.w600)),
        const Spacer(),
        const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
      ]);
}

/// Big round "photo" slot near the top of the card. No new art: filled with
/// real data (ring) or an existing Material icon.
class _Circle extends StatelessWidget {
  const _Circle({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x33FFFFFF),
          border: Border.all(color: PgColors.edge),
        ),
        child: Center(child: child),
      );
}

class _Ready extends StatelessWidget {
  const _Ready({required this.view, required this.offline, this.onStart});
  final ProgressView view;
  final VoidCallback? onStart;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final v = view;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return ListView(key: const Key('pg-ready'), padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      if (offline)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: PgGlass(
            key: Key('pg-offline'),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text("You're offline. Showing progress saved on this phone.", style: TextStyle(color: PgColors.sub))),
            ]),
          ),
        ),
      PgEnter(
        index: 0,
        child: PgGlass(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(children: [
            const _CardTop(text: 'This week'),
            const SizedBox(height: 12),
            Semantics(
              label: 'This week ${v.weekPercent} percent',
              child: _Circle(child: PgRing(value: v.weekPercent / 100, label: '${v.weekPercent}%', size: 150)),
            ),
            const SizedBox(height: 18),
            PgPanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PgCount(key: const Key('pg-streak'), value: v.streak, suffix: v.streak == 1 ? ' day' : ' days', style: _title),
                const Text('Meditation streak', style: _title),
                const SizedBox(height: 8),
                Text(v.todaySessions > 0 ? 'Practised today. Lovely.' : 'One calm practice keeps it going.', style: _body),
                const SizedBox(height: 16),
                Row(children: [
                  Text('${v.totalSessions} sessions', style: const TextStyle(color: PgColors.sub, fontSize: 12)),
                  const Spacer(),
                  PgPill(label: 'Practice', onTap: onStart),
                ]),
                const SizedBox(height: 12),
                Center(child: PgDots(done: [for (final d in v.week.take(7)) d.done], current: v.week.indexWhere((d) => d.isToday))),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      // Week strip.
      PgGlass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('This week', style: _label),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < v.week.length && i < 7; i++)
              Column(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: v.week[i].done ? Colors.white : const Color(0x1FFFFFFF),
                    border: Border.all(color: v.week[i].isToday ? Colors.white : Colors.transparent, width: 2),
                  ),
                  child: v.week[i].done ? const Icon(Icons.check_rounded, size: 16, color: PgColors.pillInk) : null,
                ),
                const SizedBox(height: 4),
                Text(days[i], style: const TextStyle(color: PgColors.sub, fontSize: 12)),
              ]),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Stats.
      Row(children: [
        Expanded(child: _Stat(label: 'Sessions', value: '${v.totalSessions}')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(label: 'Minutes', value: '${v.totalMinutes}')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(label: 'Words', value: '${v.uniqueWords}')),
      ]),
      const SizedBox(height: 12),
      PgEnter(
        index: 3,
        child: PgMilestoneRail(items: pgMilestones(streak: v.streak, sessions: v.totalSessions, minutes: v.totalMinutes)),
      ),
      if (v.recent.isNotEmpty) ...[
        const SizedBox(height: 12),
        PgGlass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent practice', style: _label),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in v.recent)
                Chip(label: Text(w), backgroundColor: const Color(0x26FFFFFF), side: const BorderSide(color: PgColors.edge)),
            ]),
          ]),
        ),
      ],
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => PgGlass(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: SizedBox(width: double.infinity, child: Column(children: [
          Text(value, style: const TextStyle(color: PgColors.ink, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: PgColors.sub, fontSize: 12)),
        ])),
      );
}
