/// Today's progress: the user's practice hero, streak / time / words, a day
/// picker with that day's practice across the hours, Start session, the
/// daily goals with their real counts and the words practised lately. Same
/// look as Settings and the Sound Library (film, glass panes, black cards).
/// Counts come from [ProgressSources] and [PracticeProgress]; nothing here
/// is made up.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../screens/daily_tasks.dart';
import '../../screens/practice_player.dart';
import '../../screens/profile_mind.dart' show kMindPalettes, kMindPalettePrefKey;
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/page_shell.dart';
import 'progress_center.dart';
import 'progress_kit.dart';
import 'progress_style.dart';
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
      title: 'Today\u2019s progress',
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
///
/// Layout from Ribon's reference (Nov 23): photo hero, three stat chips, a
/// day strip that switches the day shown, a 24-hour tick ruler for that
/// day, the Start session button, the goal grid (one card lit: the next
/// goal) and the words practised lately. All counts are real.
class TodayProgressBody extends StatefulWidget {
  const TodayProgressBody({super.key, this.center, this.clock});
  final ProgressCenter? center;

  /// Tests: a fixed "now".
  final DateTime Function()? clock;

  @override
  State<TodayProgressBody> createState() => _TodayProgressBodyState();
}

class _TodayProgressBodyState extends State<TodayProgressBody> {
  DateTime get _now => (widget.clock ?? DateTime.now)();
  late DateTime _day = _dateOnly(_now);
  int? _hour;
  var _checking = false;
  String _name = 'Practitioner';
  String? _photoPath, _photoUrl;
  String _practicePhoto = kMindPalettes.first.image;

  static String _lowerRel(String t) => t == 'Today' || t == 'Yesterday' ? t.toLowerCase() : t;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _loadWho();
  }

  Future<void> _loadWho() async {
    try {
      final p = await SharedPreferences.getInstance();
      String? account;
      try {
        if (NwsbFirebase.ready) account = FirebaseAuth.instance.currentUser?.displayName?.trim();
      } catch (_) {}
      final saved = p.getString('nowssb_name')?.trim();
      final idx = p.getInt(kMindPalettePrefKey) ?? 0;
      if (!mounted) return;
      setState(() {
        _name = saved?.isNotEmpty == true ? saved! : (account?.isNotEmpty == true ? account! : 'Practitioner');
        _photoPath = p.getString('nwsb_photo_path');
        _photoUrl = p.getString('nwsb_local_photo');
        _practicePhoto = kMindPalettes[idx.clamp(0, kMindPalettes.length - 1)].image;
      });
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
    final log = PracticeLog.now();
    final doneToday = log.on(_now).map((s) => s.word).toSet();
    final at = lib.indexWhere((w) => !doneToday.contains(w.word));
    final i = at < 0 ? 0 : at;
    await nav.push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: [...lib.skip(i), ...lib.take(i)], title: 'Practice')));
    await ProgressSources.instance.refresh();
  }

  Future<void> _openWord(Word w) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: [w], title: w.word, showIntro: false)));
    await ProgressSources.instance.refresh();
  }

  void _details(List<ProgressItem> items) {
    final pp = PracticeProgress.instance;
    final steps = items.fold<int>(0, (a, e) => a + e.done.clamp(0, e.total));
    final all = items.fold<int>(0, (a, e) => a + e.total);
    final last = pp.lastPracticed;
    final lastText = last == null ? 'Not yet' : dayTitle(DateTime.tryParse(last) ?? _now, _now);
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => ProgressDetailsSheet(rows: [
        ('Steps today', '$steps of $all'),
        ('Words finished', '${pp.totalSessions}'),
        ('Different words', '${pp.uniqueWords}'),
        ('Practice time', pp.timeLabel),
        ('This week', '${pp.weekTimeLabel} · ${pp.weekConsistencyPercent}% of days'),
        ('Last practised', lastText),
        ('Level', '${pp.level} of 10'),
      ]),
    );
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
        final next = items.where((e) => !e.complete).firstOrNull;
        final checkedIn = items.firstWhere((e) => e.kind == ProgressKind.checkin).complete;
        final routine = items.firstWhere((e) => e.kind == ProgressKind.routine);
        final grid = items.where((e) => e.kind != ProgressKind.checkin).toList();
        final lit = grid.where((e) => !e.complete).firstOrNull?.kind ?? ProgressKind.routine;
        final log = PracticeLog.now();
        final daySessions = log.on(_day);
        final isToday = dayKey(_day) == dayKey(now);
        final daySecs = daySessions.fold<int>(0, (a, s) => a + s.seconds);
        final hours = [for (final s in daySessions) if (s.at != null) s.at!.hour]..sort();
        final hour = _hour ?? (hours.isNotEmpty ? hours.last : (isToday ? now.hour : 12));
        final inHour = daySessions.where((s) => s.at?.hour == hour).toList();
        final recent = [for (final n in log.recentWords()) libraryWord(n)].whereType<Word>().toList();
        String lastDayOf(Word w) {
          final keys = log.byDay.keys.where((k) => log.byDay[k]!.any((s) => s.word == w.word)).toList()..sort();
          if (keys.isEmpty) return '';
          return 'Practised ${_lowerRel(dayTitle(DateTime.tryParse(keys.last) ?? now, now))}';
        }

        final firstKey = (log.byDay.keys.toList()..sort()).firstOrNull;
        final firstDay = firstKey == null ? null : DateTime.tryParse(firstKey);
        final dayWords = <String>{for (final s in daySessions) if (s.word.isNotEmpty && s.word != 'Streak restore') s.word};
        return LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 700;
          final hero = ProgressHero(
            key: const ValueKey('today-hero'),
            name: _name,
            photo: heroPhoto(path: _photoPath, url: _photoUrl, practice: _practicePhoto),
            level: pp.level,
            done: done,
            total: items.length,
            today: now,
            checkedIn: checkedIn,
            busy: _checking,
            onDetails: () => _details(items),
            onCheckIn: _checkIn,
            onPractice: () => ProgressRoutes.open(context, ProgressKind.routine),
            since: firstDay == null ? 'New to NowssB · your first word starts it' : 'Practising since ${_lowerRel(dayTitle(firstDay, now))}',
          );
          final stats = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ProgressStatRow(streak: pp.streak, time: pp.timeLabel, words: pp.uniqueWords),
            if (pp.totalSessions == 0)
              const Padding(
                key: ValueKey('today-empty'),
                padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Text('No practice yet. Finish your first word in the player and your streak, time and words start here.',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, height: 1.4)),
              ),
          ]);
          final dayPane = ProgressDayPane(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Text(dayTitle(_day, now),
                      key: const ValueKey('today-day-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Text(
                    daySessions.isEmpty
                        ? 'No practice'
                        : '${daySessions.length} word${daySessions.length == 1 ? '' : 's'} · ${minutesLabel(daySecs)}',
                    key: const ValueKey('today-day-summary'),
                    style: const TextStyle(color: NwsbColors.goldLight, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text(
                dayWords.isEmpty ? (isToday ? 'Nothing played yet today. The ruler fills in as you finish words.' : 'No words were finished on this day.') : dayWords.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 10),
              ProgressTickScale(sessions: daySessions, hour: hour, onHour: (h) => setState(() => _hour = h)),
              Row(children: [
                SquareGlass(size: 28, radius: 9, child: NwsbIcon(NwsbMarks.hourglass, size: 14, color: inHour.isEmpty ? Colors.white : NwsbColors.goldLight)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inHour.isEmpty
                        ? '${hourLabel(hour)} – ${hourLabel(hour + 1)} · nothing played'
                        : '${hourLabel(hour)} – ${hourLabel(hour + 1)} · ${inHour.length} word${inHour.length == 1 ? '' : 's'}, ${minutesLabel(inHour.fold<int>(0, (a, s) => a + s.seconds))}',
                    key: const ValueKey('today-hour-readout'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ]),
          );
          final start = Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ProgressStartButton(
              label: 'Start session',
              sub: routine.complete ? 'Practice done today · keep going' : ProgressSources.nextStep(routine),
              onTap: _startSession,
            ),
          );
          final goals = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProgressGoalGrid(items: grid, lit: lit, markFor: goalMark, onOpen: (k) => ProgressRoutes.open(context, k)),
          );
          final nextUp = ProgressNextUp(
            title: next == null ? 'all done' : next.title,
            line: next == null ? 'Every goal is done. See you tomorrow.' : ProgressSources.nextStep(next),
            action: next == null ? null : GoalActionFor(item: next, key: const ValueKey('today-next-action')),
          );
          final strip = ProgressDayStrip(
            today: now,
            selected: _day,
            practised: (d) => log.on(d).isNotEmpty,
            onPick: (d) => setState(() {
              _day = d;
              _hour = null;
            }),
          );
          final days = [
            ProgressLabel(title: 'Your days', trailing: ProgressDayStrip.monthLabel(_day)),
            strip,
            dayPane,
            start,
          ];
          final children = <Widget>[
            if (wide) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 5, child: hero),
                  Expanded(
                    flex: 6,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: stats),
                      ...days,
                    ]),
                  ),
                ]),
              ),
            ] else ...[
              Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: hero),
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: stats),
              ...days,
            ],
            ProgressLabel(title: 'Today\u2019s goals', trailing: '$done of ${items.length} done'),
            goals,
            const SizedBox(height: 8),
            nextUp,
            ProgressLabel(title: 'Words you practised', trailing: recent.isEmpty ? null : '${recent.length}'),
            ProgressWordCarousel(words: recent, lastDay: lastDayOf, onOpen: _openWord),
          ];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          );
        });
      },
    );
  }
}

/// Details sheet: the record behind the hero. Closes on an outside tap, a
/// swipe down and back (a plain modal bottom sheet).
class ProgressDetailsSheet extends StatelessWidget {
  const ProgressDetailsSheet({super.key, required this.rows});
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('today-details-sheet'),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(color: const Color(0xF20B0B10), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0x2EFFFFFF))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x4DFFFFFF), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        const Text('Your practice record', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Kept from the words you finish in the player.', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5)),
        const SizedBox(height: 12),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF)))),
            child: Row(children: [
              Text(r.$1, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(r.$2, textAlign: TextAlign.right, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// The button that does a goal's next step.
class GoalActionFor extends StatefulWidget {
  const GoalActionFor({super.key, required this.item});
  final ProgressItem item;
  @override
  State<GoalActionFor> createState() => _GoalActionForState();
}

class _GoalActionForState extends State<GoalActionFor> {
  var _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    switch (it.kind) {
      case ProgressKind.checkin:
        return GoalAction(
          label: it.complete ? 'Checked in' : 'Check in',
          filled: !it.complete,
          busy: _busy,
          onTap: it.complete ? null : () => _run(() => ProgressRoutes.checkIn(context)),
        );
      case ProgressKind.coins when !it.complete && ProgressSources.signedIn:
        final loginDone = ProgressSources.serverLoginToday;
        return GoalAction(
          label: loginDone ? 'Scratch card' : 'Check in',
          busy: _busy,
          onTap: () => _run(() => loginDone ? ProgressRoutes.scratchToday(context) : ProgressRoutes.checkIn(context)),
        );
      default:
        return GoalAction(
          label: ProgressSources.actionLabel(it.kind),
          filled: !it.complete,
          onTap: () => ProgressRoutes.open(context, it.kind),
        );
    }
  }
}
