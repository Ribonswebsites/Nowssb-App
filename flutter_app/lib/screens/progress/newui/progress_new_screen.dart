/// My Progress, new meditation glass UI (flag `newui_progress`).
/// Data comes only from [PracticeProgress] (one source of truth, spec 24).
library;

import 'package:flutter/material.dart';

import '../../../data/practice_progress.dart';
import 'progress_glass.dart';

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
  const ProgressNewScreen({super.key, required this.load, this.view, this.onBack, this.onRetry, this.onStart});
  final ProgressLoad load;
  final ProgressView? view;
  final VoidCallback? onBack, onRetry, onStart;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: PgColors.bg,
        body: Stack(fit: StackFit.expand, children: [
          const PgAura(),
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
          child: CircularProgressIndicator(color: PgColors.lilac),
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
        return _Ready(view: v, offline: load == ProgressLoad.offline);
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PgGlass(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: PgColors.lilac, size: 40),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: PgColors.ink, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: PgColors.sub)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: PgColors.violet, foregroundColor: PgColors.bg),
                onPressed: onTap,
                child: Text(action),
              ),
            ]),
          ),
        ),
      );
}

class _Ready extends StatelessWidget {
  const _Ready({required this.view, required this.offline});
  final ProgressView view;
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
              Icon(Icons.wifi_off_rounded, color: PgColors.lilac, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text("You're offline. Showing progress saved on this phone.", style: TextStyle(color: PgColors.sub))),
            ]),
          ),
        ),
      // Hero: streak + weekly consistency ring.
      PgGlass(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Current streak', style: TextStyle(color: PgColors.sub)),
              Text('${v.streak} ${v.streak == 1 ? 'day' : 'days'}',
                  key: const Key('pg-streak'), style: const TextStyle(color: PgColors.ink, fontSize: 34, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(v.todaySessions > 0 ? 'Practised today. Lovely.' : 'One calm practice keeps it going.',
                  style: const TextStyle(color: PgColors.lilac)),
            ]),
          ),
          Semantics(label: 'This week ${v.weekPercent} percent', child: PgRing(value: v.weekPercent / 100, label: '${v.weekPercent}%')),
        ]),
      ),
      const SizedBox(height: 12),
      // Week strip.
      PgGlass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('This week', style: TextStyle(color: PgColors.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < v.week.length && i < 7; i++)
              Column(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: v.week[i].done ? PgColors.violet : const Color(0x14FFFFFF),
                    border: Border.all(color: v.week[i].isToday ? PgColors.lilac : Colors.transparent, width: 2),
                  ),
                  child: v.week[i].done ? const Icon(Icons.check_rounded, size: 16, color: PgColors.bg) : null,
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
      if (v.recent.isNotEmpty) ...[
        const SizedBox(height: 12),
        PgGlass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent practice', style: TextStyle(color: PgColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in v.recent)
                Chip(label: Text(w), backgroundColor: const Color(0x1AFFFFFF), side: const BorderSide(color: PgColors.edge)),
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
        child: Column(children: [
          Text(value, style: const TextStyle(color: PgColors.ink, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: PgColors.sub, fontSize: 12)),
        ]),
      );
}
