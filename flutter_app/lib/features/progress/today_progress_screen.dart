/// My progress, in the CliniQ layout Ribon sent (Nov 23) and NowssB's dark
/// glass: the word you practised last as the photo hero, Details / Listen /
/// Practice / Share, streak · time · words, "Your days" with a month
/// switcher, that day's practice across the hours, Start session, the
/// words practised lately and today's goals as a 2x2 grid with the next one
/// lit. It is about your practice, not your profile: no name, no account
/// photo. Counts come from [ProgressSources] and [PracticeProgress];
/// nothing here is made up.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../data/word_voice.dart';
import '../../screens/daily_tasks.dart';
import '../../screens/practice_player.dart';
import '../../widgets/page_shell.dart';
import 'my_progress_kit.dart';
import 'progress_center.dart';
import 'progress_kit.dart';
import 'progress_sources.dart';

String goalMark(ProgressKind k) => switch (k) {
      ProgressKind.tasks => GoalMarks.tasks,
      ProgressKind.routine => GoalMarks.practice,
      ProgressKind.coins => GoalMarks.coins,
      ProgressKind.quest => GoalMarks.quest,
      ProgressKind.checkin => GoalMarks.checkin,
    };

class TodayProgressScreen extends StatefulWidget {
  const TodayProgressScreen({super.key, this.center});
  final ProgressCenter? center;

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TodayProgressScreen()));

  @override
  State<TodayProgressScreen> createState() => _TodayProgressScreenState();
}

class _TodayProgressScreenState extends State<TodayProgressScreen> {
  @override
  void initState() {
    super.initState();
    ProgressSources.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PageShell(
      eyebrow: 'NowssB',
      title: 'My progress',
      film: 'assets/video/subscription-bg.mp4',
      usePageFilm: true,
      quietFilm: true,
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: 40 + bottom),
          sliver: SliverToBoxAdapter(child: TodayProgressBody(center: widget.center)),
        ),
      ],
    );
  }
}

/// The page content (split out so tests can render it without the film).
class TodayProgressBody extends StatefulWidget {
  const TodayProgressBody({super.key, this.center, this.clock});
  final ProgressCenter? center;

  /// Tests: a fixed "now".
  final DateTime Function()? clock;

  @override
  State<TodayProgressBody> createState() => _TodayProgressBodyState();
}

class _TodayProgressBodyState extends State<TodayProgressBody> {
  static const _likedKey = 'nwsb_liked_words';

  DateTime get _now => (widget.clock ?? DateTime.now)();
  late DateTime _day = dateOnly(_now);
  late DateTime _month = DateTime(_now.year, _now.month);
  int? _hour;
  int _heroAt = 0;
  var _checking = false;
  var _listening = false;
  Set<String> _liked = const {};

  @override
  void initState() {
    super.initState();
    _loadLiked();
  }

  Future<void> _loadLiked() async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = (p.getStringList(_likedKey) ?? const <String>[]).toSet();
      if (mounted) setState(() => _liked = l);
    } catch (_) {}
  }

  Future<void> _toggleLike(Word w) async {
    final next = {..._liked};
    if (!next.remove(w.word)) next.add(w.word);
    setState(() => _liked = next);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_likedKey, next.toList()..sort());
    } catch (_) {}
  }

  Future<void> _checkIn() async {
    setState(() => _checking = true);
    try {
      await ProgressRoutes.checkIn(context);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _startSession() async {
    final nav = Navigator.of(context);
    final lib = ContentStore.instance.library;
    if (lib.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Pick a few words for your routine first.')));
      ProgressRoutes.goTab(context, 1);
      return;
    }
    // Start on the first word not finished today, so a session moves on.
    final doneToday = PracticeLog.now().on(_now).map((s) => s.word).toSet();
    final at = lib.indexWhere((w) => !doneToday.contains(w.word));
    final i = at < 0 ? 0 : at;
    await nav.push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: [...lib.skip(i), ...lib.take(i)], title: 'Practice')));
    await ProgressSources.instance.refresh();
  }

  Future<void> _practise(Word w) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: [w], title: w.word, showIntro: false)));
    await ProgressSources.instance.refresh();
  }

  Future<void> _listen(Word w) async {
    if (_listening) {
      await WordVoice.instance.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!WordVoice.hasVoice(w)) {
      messenger?.showSnackBar(SnackBar(content: Text('The recording for ${wordTitle(w.word)} has not been added yet.')));
      return;
    }
    setState(() => _listening = true);
    var ok = false;
    try {
      ok = await WordVoice.instance.play(w);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _listening = false);
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text('The recording for ${wordTitle(w.word)} could not be loaded.')));
  }

  Future<void> _share(Word w) async {
    final m = w.meaning.trim();
    final text = 'I\u2019m practising ${wordTitle(w.word)} on NowssB${m.isEmpty ? '' : ' \u2014 $m'}. https://nowssb.com';
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: 'NowssB'));
    } catch (_) {}
  }

  void _wordDetails(Word w, PracticeLog log, bool practised) {
    final mine = log.of(w.word);
    final now = _now;
    MpSheet.show(context, title: wordTitle(w.word), note: w.meaning, rows: [
      if (w.phonetic.isNotEmpty) ('Say it', w.phonetic),
      if (w.organ.isNotEmpty) ('Works on', w.organ),
      if (w.benefit.isNotEmpty) ('Benefit', w.benefit),
      if (w.tip.isNotEmpty) ('Tip', w.tip),
      ('You finished it', practised ? '${mine.times} time${mine.times == 1 ? '' : 's'}' : 'Not yet'),
      if (mine.seconds > 0) ('Time on it', minutesLabel(mine.seconds)),
      if (mine.last != null) ('Last practised', dayTitle(DateTime.tryParse(mine.last!) ?? now, now)),
    ]);
  }

  void _progressDetails(List<ProgressItem> items) {
    final pp = PracticeProgress.instance;
    final steps = items.fold<int>(0, (a, e) => a + e.done.clamp(0, e.total));
    final all = items.fold<int>(0, (a, e) => a + e.total);
    final last = pp.lastPracticed;
    MpSheet.show(context, title: 'Your progress', rows: [
      ('Steps today', '$steps of $all'),
      for (final e in items) (e.title, '${e.done.clamp(0, e.total)}/${e.total}'),
      ('Words finished', '${pp.totalSessions}'),
      ('Different words', '${pp.uniqueWords}'),
      ('Practice time', pp.timeLabel),
      ('This week', '${pp.weekTimeLabel} \u00b7 ${pp.weekConsistencyPercent}% of days'),
      ('Last practised', last == null ? 'Not yet' : dayTitle(DateTime.tryParse(last) ?? _now, _now)),
      ('Level', '${pp.level} of 10'),
    ]);
  }

  void _pickMonth(int delta, DateTime? first) {
    final now = _now;
    final m = DateTime(_month.year, _month.month + delta);
    final cur = DateTime(now.year, now.month);
    if (m.isAfter(cur)) return;
    if (first != null && m.isBefore(DateTime(first.year, first.month))) return;
    // Land on the month's last practised day (else today / its last day).
    final prefix = '${m.year}-${m.month.toString().padLeft(2, '0')}-';
    final keys = PracticeLog.now().byDay.keys.where((k) => k.startsWith(prefix)).toList()..sort();
    final practised = keys.isEmpty ? null : DateTime.tryParse(keys.last);
    setState(() {
      _month = m;
      _day = practised != null ? dateOnly(practised) : (m == cur ? dateOnly(now) : DateTime(m.year, m.month + 1, 0));
      _hour = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.center ?? ProgressCenter.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([c, DailyTasks.items, PracticeProgress.instance, DailyCheckIn.instance]),
      builder: (context, _) {
        final now = _now;
        final pp = PracticeProgress.instance;
        final items = c.items;
        final done = items.where((e) => e.complete).length;
        final checkedIn = items.firstWhere((e) => e.kind == ProgressKind.checkin).complete;
        final grid = items.where((e) => e.kind != ProgressKind.checkin).toList();
        final lit = grid.where((e) => !e.complete).firstOrNull?.kind ?? ProgressKind.routine;
        final log = PracticeLog.now();

        // The hero: the word practised last (swap through the recent ones);
        // a new account sees its first routine word.
        final recent = [for (final n in log.recentWords()) libraryWord(n)].whereType<Word>().toList();
        final lib = ContentStore.instance.library;
        final heroWord = recent.isNotEmpty ? recent[_heroAt % recent.length] : lib.firstOrNull;
        final practised = recent.isNotEmpty;

        // The chosen day.
        final daySessions = log.on(_day);
        final isToday = dayKey(_day) == dayKey(now);
        final hours = [for (final s in daySessions) if (s.at != null) s.at!.hour]..sort();
        final hour = _hour ?? (hours.isNotEmpty ? hours.last : (isToday ? now.hour : 12));
        final inHour = daySessions.where((s) => s.at?.hour == hour).toList();
        final daySecs = daySessions.fold<int>(0, (a, s) => a + s.seconds);
        final first = log.firstDay;
        final cur = DateTime(now.year, now.month);
        final canPrev = first != null && DateTime(_month.year, _month.month).isAfter(DateTime(first.year, first.month));
        final canNext = DateTime(_month.year, _month.month).isBefore(cur);

        String lastLine(Word w) {
          final l = log.of(w.word).last;
          if (l == null) return '';
          final t = dayTitle(DateTime.tryParse(l) ?? now, now);
          return 'Practised ${t == 'Today' || t == 'Yesterday' ? t.toLowerCase() : t}';
        }

        String chipFor(Word w) {
          final n = log.of(w.word).times;
          return n <= 0 ? '' : '\u00d7$n';
        }

        return LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 700;
          const pad = EdgeInsets.symmetric(horizontal: 16);

          final hero = heroWord == null
              ? const SizedBox.shrink()
              : MpHero(
                  key: const ValueKey('today-hero'),
                  art: playerCoverArtFor(heroWord, 0),
                  title: wordTitle(heroWord.word),
                  second: heroWord.organ.isNotEmpty ? heroWord.organ : (heroWord.categories.firstOrNull ?? ''),
                  lineA: practised ? lastLine(heroWord) : 'Your first word',
                  lineB: heroWord.meaning,
                  chip: 'Level ${pp.level}',
                  liked: _liked.contains(heroWord.word),
                  onLike: () => _toggleLike(heroWord),
                  onSwap: recent.length > 1 ? () => setState(() => _heroAt = (_heroAt + 1) % recent.length) : null,
                );
          final actions = heroWord == null
              ? const SizedBox.shrink()
              : MpActionRow(
                  listening: _listening,
                  onDetails: () => _wordDetails(heroWord, log, practised),
                  onListen: () => _listen(heroWord),
                  onPractice: () => _practise(heroWord),
                  onShare: () => _share(heroWord),
                );
          final stats = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            MpStatStrip(streak: pp.streak, time: pp.timeLabel, words: pp.uniqueWords),
            if (pp.totalSessions == 0)
              const Padding(
                key: ValueKey('today-empty'),
                padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Text('No practice yet. Finish your first word in the player and your streak, time and words start here.',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, height: 1.4)),
              ),
          ]);
          final days = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            MpMonthBar(
              title: 'Your days',
              month: _month,
              onPrev: canPrev ? () => _pickMonth(-1, first) : null,
              onNext: canNext ? () => _pickMonth(1, first) : null,
            ),
            const SizedBox(height: 10),
            MpDayTiles(
              month: _month,
              today: now,
              selected: _day,
              practised: (d) => log.on(d).isNotEmpty,
              onPick: (d) => setState(() {
                _day = d;
                _hour = null;
              }),
            ),
            const SizedBox(height: 10),
            Text(
              daySessions.isEmpty
                  ? (isToday ? 'Nothing played yet today. The ruler fills in as you finish words.' : 'No words were finished on ${dayTitle(_day, now)}.')
                  : '${dayTitle(_day, now)} \u00b7 ${daySessions.length} word${daySessions.length == 1 ? '' : 's'} \u00b7 ${minutesLabel(daySecs)}',
              key: const ValueKey('today-day-summary'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 18),
            MpLabel(
              'Practice hours',
              trailing: inHour.isEmpty
                  ? '${hourLabel(hour)} \u2013 ${hourLabel(hour + 1)}'
                  : '${hourLabel(hour)} \u00b7 ${inHour.length} word${inHour.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            MpHourRuler(sessions: daySessions, hour: hour, onHour: (h) => setState(() => _hour = h)),
            const SizedBox(height: 14),
            MpStartButton(onTap: _startSession),
          ]);
          final words = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: MpLabel('Words you practised')),
            MpWordCarousel(
              words: recent,
              artFor: playerCoverArtFor,
              lineFor: lastLine,
              chipFor: chipFor,
              onOpen: _practise,
            ),
          ]);
          final goals = Padding(
            padding: pad,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              MpGoalsHeading(
                done: done,
                total: items.length,
                checkedIn: checkedIn,
                busy: _checking,
                onInfo: () => _progressDetails(items),
                onCheckIn: _checkIn,
              ),
              const SizedBox(height: 16),
              MpGoalGrid(items: grid, lit: lit, markFor: goalMark, onOpen: (k) => ProgressRoutes.open(context, k)),
            ]),
          );

          if (wide) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 5,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hero, const SizedBox(height: 14), actions]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [stats, const SizedBox(height: 22), days]),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              words,
              const SizedBox(height: 28),
              goals,
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: hero),
            const SizedBox(height: 14),
            Padding(padding: pad, child: actions),
            const SizedBox(height: 14),
            Padding(padding: pad, child: stats),
            const SizedBox(height: 22),
            Padding(padding: pad, child: days),
            const SizedBox(height: 28),
            words,
            const SizedBox(height: 28),
            goals,
          ]);
        });
      },
    );
  }
}
