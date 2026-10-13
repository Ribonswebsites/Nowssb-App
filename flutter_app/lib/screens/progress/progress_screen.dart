/// My Progress — REBUILD-C (Oct 12, 2026): Play Points layout in original NowssB colours and page videos.
///
/// Not server-layout driven: layoutChildren() is intentionally not used so
/// no ui_overrides/server layout can re-add the old video/orb sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../shell/nav_shell.dart';
import 'progress_body_map.dart';
import 'progress_feedback.dart';
import 'progress_hero.dart';
import 'progress_insight.dart';
import 'progress_tokens.dart';
import 'progress_week_ring.dart';
import 'newui/progress_flag.dart';
import 'newui/progress_new_screen.dart';

class PracticeProgressScreen extends StatefulWidget {
  const PracticeProgressScreen({super.key, this.words = const []});

  final List<Word> words;

  @override
  State<PracticeProgressScreen> createState() => _PracticeProgressScreenState();
}

class _PracticeProgressScreenState extends State<PracticeProgressScreen> {
  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_onProgress);
    PracticeProgress.instance.start();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_onProgress);
    _scroll.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    NavScope.goTo(context, 0);
  }

  int _tab = 0;

  // REBUILD-C 8:22: original NowssB tokens (MpColors) + original page videos.
  static const _ink = MpColors.white;
  static const _sub = MpColors.muted;
  static const _tabInk = MpColors.gold;
  static const _chip = MpColors.line;
  static const _green = MpColors.gold, _yellow = MpColors.gold, _red = MpColors.gold, _blue = MpColors.gold;
  final _scroll = ScrollController();
  double _scrollBg = 0;

  void _onScroll() {
    final t = (_scroll.offset / (ProgressOrbHero.height * 0.72)).clamp(0.0, 1.0);
    if ((t - _scrollBg).abs() > 0.02) setState(() => _scrollBg = t);
  }

  // REBUILD-C (7:55 rule): copies the Play Points layout — big number header
  // with a medal, a meta line, underline tabs, chips and coloured tiles —
  // in its own Google-palette colour world. Every value is PracticeProgress.
  @override
  Widget build(BuildContext context) {
    final p = PracticeProgress.instance;
    if (newUiProgressEnabled()) {
      return ProgressNewScreen(load: ProgressLoad.ready, view: ProgressView.from(p), onBack: _handleBack, onStart: _handleBack);
    }
    final organFor = <String, String>{
      for (final w in widget.words)
        if (w.word.isNotEmpty && w.organ.isNotEmpty) w.word: w.organ,
    };
    final sessions = p.sessionsSnapshot.where((m) => '${m['word'] ?? ''}'.isNotEmpty).take(12).toList();
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: MpColors.bg,
        body: Stack(fit: StackFit.expand, children: [
          // Original page media from main 235ae99.
          ProgressHeroBgVideo(opacity: (1.0 - _scrollBg).clamp(0.0, 1.0)),
          ProgressScrollBgVideo(opacity: 0.15 + 0.85 * _scrollBg),
          const ProgressVideoShade(),
          Column(children: [
          ProgressHeader(onBack: _handleBack),
          Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 120),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ProgressWeekRing(days: p.thisWeekDays, streak: p.streak, size: 76, compact: true),
                const SizedBox(width: 14),
                Text('${p.streak}', style: const TextStyle(fontSize: 64, height: 1, fontWeight: FontWeight.w500, color: _ink)),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(top: 22), child: Text(p.streak == 1 ? 'day' : 'days', style: const TextStyle(fontSize: 16, color: _sub))),
              ]).animate().fadeIn(duration: 600.ms).slideY(begin: .1, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.military_tech_outlined, size: 18, color: _ink),
                const SizedBox(width: 6),
                Text('Level ${p.level}', style: const TextStyle(fontSize: 15, color: _ink)),
                const SizedBox(width: 28),
                InkWell(
                  onTap: () => setState(() => _tab = 1),
                  child: const Row(children: [Icon(Icons.history, size: 18, color: _ink), SizedBox(width: 6), Text('See history', style: TextStyle(fontSize: 15, color: _ink))]),
                ),
              ]),
              const SizedBox(height: 22),
              _tabs(),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: switch (_tab) {
                      0 => Column(children: [_weekTab(p), if (sessions.isNotEmpty) ...[const SizedBox(height: 18), _journeyTab(sessions.take(3).toList(), organFor)]]),
                      1 => _journeyTab(sessions, organFor),
                      2 => _milestonesTab(p),
                      _ => _mindTab(p),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ]),
        ]),
      ),
    );
  }

  Widget _tabs() {
    const names = ['Week', 'Journey', 'Milestones', 'Mind'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xB3050607), borderRadius: BorderRadius.circular(18), border: Border.all(color: _chip)),
      child: Row(children: [
        for (var i = 0; i < names.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = i),
              child: Column(children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(names[i], style: TextStyle(fontSize: 15, fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400, color: _tab == i ? _tabInk : _sub))),
                AnimatedContainer(duration: const Duration(milliseconds: 220), height: 3, width: _tab == i ? 28 : 0, decoration: const BoxDecoration(color: _tabInk, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _tile(Color c, IconData icon, String value, String label) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: MpColors.glass, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x24FFFFFF))),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: const Color(0x1FD9C98F), shape: BoxShape.circle, border: Border.all(color: const Color(0x55D9C98F))),
                  child: Icon(icon, color: c, size: 26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink))),
          Text(label, style: const TextStyle(fontSize: 12.5, color: _sub)),
        ]),
      );

  Widget _weekTab(PracticeProgress p) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = p.thisWeekDays;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _tile(_green, Icons.self_improvement, '${p.totalSessions}', 'Sessions'),
        const SizedBox(width: 10),
        _tile(_yellow, Icons.timer_outlined, p.timeLabel, 'Time'),
        const SizedBox(width: 10),
        _tile(_red, Icons.spellcheck, '${p.uniqueWords}', 'Words'),
      ]),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: MpColors.glass, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x24FFFFFF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('This week', style: TextStyle(fontSize: 18, color: _ink)),
            const Spacer(),
            Text(p.weekTimeLabel, style: const TextStyle(fontSize: 14, color: _sub)),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 7; i++)
              Column(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: days[i].done ? MpColors.gold : Colors.transparent, border: Border.all(color: days[i].isToday ? _ink : _chip, width: days[i].isToday ? 1.6 : 1)),
                  child: days[i].done ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                ),
                const SizedBox(height: 6),
                Text(letters[i], style: TextStyle(fontSize: 12, color: days[i].isToday ? _ink : _sub)),
              ]),
          ]),
        ]),
      ),
    ]);
  }

  Widget _journeyTab(List<Map<String, dynamic>> sessions, Map<String, String> organFor) {
    if (sessions.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No sessions yet', style: TextStyle(fontSize: 15, color: _sub))));
    }
    return Column(children: [
      for (var i = 0; i < sessions.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: Color(0x1FD9C98F), child: Icon(Icons.graphic_eq, color: MpColors.gold, size: 20)),
          title: Text('${sessions[i]['word']}', style: const TextStyle(fontSize: 16, color: _ink)),
          subtitle: Text(['${sessions[i]['date'] ?? ''}', organFor['${sessions[i]['word']}'] ?? ''].where((x) => x.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12.5, color: _sub)),
        ),
    ]);
  }

  Widget _milestonesTab(PracticeProgress p) {
    final streak = p.streak, sessions = p.totalSessions, words = p.uniqueWords;
    final items = <(String, bool, Color)>[
      ('First session', sessions >= 1, _green),
      ('3-day streak', streak >= 3, _yellow),
      ('7-day streak', streak >= 7, _red),
      ('21-day streak', streak >= 21, _blue),
      ('10 words', words >= 10, _green),
      ('21 sessions', sessions >= 21, _yellow),
      ('100 sessions', sessions >= 100, _red),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      childAspectRatio: .82,
      children: [
        for (final it in items)
          Column(children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(color: it.$2 ? const Color(0x26D9C98F) : MpColors.glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: it.$2 ? const Color(0x66D9C98F) : MpColors.line)),
                child: Icon(it.$2 ? Icons.emoji_events : Icons.lock_outline, color: it.$2 ? MpColors.gold : _sub, size: 30),
              ),
            ),
            const SizedBox(height: 6),
            Text(it.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _ink)),
          ]),
      ],
    );
  }

  Widget _mindTab(PracticeProgress p) => Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        decoration: BoxDecoration(color: MpColors.glass, borderRadius: BorderRadius.circular(22), border: Border.all(color: MpColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ProgressBodyMap(progress: p, words: widget.words),
          const SizedBox(height: 20),
          ProgressInsight(progress: p),
          const SizedBox(height: 8),
          const ProgressFeedbackSection(),
        ]),
      );
}

