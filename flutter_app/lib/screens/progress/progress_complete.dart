/// My Progress — complete, working page (tabs, sub-pages, pop-ups, first-use
/// guide). Approved frosted glass card (radius 30, soft white border, no
/// violet) over the app's original background video. Real data only: every
/// number comes from [PracticeProgress].
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/practice_progress.dart';
import 'progress_feedback.dart';
import '../../widgets/n_motion.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/black_glass_banner.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/routine_deck.dart' show kRoutineArts;
import '../fashion/header.dart';
import '../../shell/nav_shell.dart';
import '../../widgets/nwsb_icon.dart';

const kProgressGuideSeenKey = 'nowssb_progress_guide_seen_v1';

const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFFB9BCC2);
const _dim = Color(0xFF8C9096);

// ── Shared pieces ─────────────────────────────────────────────────────────

/// Approved frosted card: see-through glass, radius 30, soft white border.
class PgCard extends StatelessWidget {
  const PgCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap, this.radius = 30});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: r,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: r,
                // Home's dark glass over the film.
                color: const Color(0x8C0B0F17),
                border: Border.all(color: const Color(0x29FFFFFF)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small white rounded pill (the approved "Next" pill).
class PgPill extends StatelessWidget {
  const PgPill(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(label, style: const TextStyle(color: Color(0xFF111214), fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

const _title = TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15);
const _body = TextStyle(color: _grey, fontSize: 13, height: 1.4);
const _gold = Color(0xFFE9C987);
/// Home's small gold uppercase eyebrow.
const _label = TextStyle(color: _gold, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700);

/// Original background video (the app's subscription-bg film) plus a soft
/// dark shade. [backdrop] lets tests and screenshots pass a still frame.
class PgScaffold extends StatelessWidget {
  const PgScaffold({super.key, required this.title, required this.body, this.backdrop, this.actions = const [], this.onSettings, this.bottom});
  final Widget? bottom;
  final VoidCallback? onSettings;
  final String title;
  final Widget body;
  final Widget? backdrop;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bg = backdrop ?? ProgressBackdropScope.of(context) ?? const Positioned.fill(child: AppBackdrop());
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        bg,
        const IgnorePointer(child: ColoredBox(color: Color(0x40000000))),
        HomeSkinScope(
          skin: HomeSkin.fashion,
          child: Column(children: [
            // Home's own top bar (white glass, logo, bell, gear, menu).
            HomeHeader(onSettings: onSettings, onMenu: () => Navigator.of(context).maybePop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                _RoundIcon(icon: Icons.arrow_back_ios_new_rounded, tooltip: 'Back', onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w700))),
                ...actions,
              ]),
            ),
            Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: body)),
          ]),
        ),
        if (bottom != null) Positioned(left: 14, right: 14, bottom: 0, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: bottom!))),
      ]),
    );
  }
}

/// Carries the background widget to pushed sub-pages so they share it.
class ProgressBackdropScope extends InheritedWidget {
  const ProgressBackdropScope({super.key, required this.backdrop, required super.child});
  final Widget backdrop;
  static Widget? of(BuildContext context) => context.getInheritedWidgetOfExactType<ProgressBackdropScope>()?.backdrop;
  @override
  bool updateShouldNotify(ProgressBackdropScope oldWidget) => false;
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0x2EFFFFFF),
          shape: const CircleBorder(side: BorderSide(color: Color(0x52FFFFFF))),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: _white, size: 18))),
        ),
      );
}

// ── Data helpers (real data only) ─────────────────────────────────────────

class Milestone {
  const Milestone(this.id, this.title, this.blurb, this.kind, this.target);
  final String id, title, blurb, kind; // kind: streak | sessions | minutes | words
  final int target;
  int current(PracticeProgress p) => switch (kind) {
        'streak' => p.streak,
        'sessions' => p.totalSessions,
        'minutes' => p.totalMinutes,
        _ => p.uniqueWords,
      };
  bool done(PracticeProgress p) => current(p) >= target;
  double ratio(PracticeProgress p) => (current(p) / target).clamp(0.0, 1.0);
  String unit() => switch (kind) { 'streak' => 'days in a row', 'sessions' => 'sessions', 'minutes' => 'minutes', _ => 'different words' };
}

const kMilestones = <Milestone>[
  Milestone('first', 'First sit', 'Finish your first practice session.', 'sessions', 1),
  Milestone('streak3', 'Three calm days', 'Practice three days in a row.', 'streak', 3),
  Milestone('streak7', 'A full week', 'Practice seven days in a row.', 'streak', 7),
  Milestone('sessions10', 'Ten sessions', 'Complete ten practice sessions.', 'sessions', 10),
  Milestone('minutes60', 'One quiet hour', 'Meditate for 60 minutes in total.', 'minutes', 60),
  Milestone('words10', 'Ten sounds', 'Practice ten different words.', 'words', 10),
  Milestone('streak30', 'Thirty days', 'Practice thirty days in a row.', 'streak', 30),
];

Map<String, List<Map<String, dynamic>>> sessionsByDay(PracticeProgress p) {
  final out = <String, List<Map<String, dynamic>>>{};
  for (final s in p.sessionsSnapshot) {
    out.putIfAbsent('${s['date'] ?? ''}', () => []).add(s);
  }
  return out;
}

String prettyDay(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String durationLabel(Map<String, dynamic> s) {
  final d = s['durationSec'];
  if (d is! num || d <= 0) return 'Time not recorded';
  final m = (d / 60).round();
  return m < 1 ? '${d.round()}s' : '${m}m';
}

// ── Main view ─────────────────────────────────────────────────────────────

class ProgressCompleteView extends StatefulWidget {
  const ProgressCompleteView({super.key, this.backdrop, this.onPractice, this.progress, this.onNav});
  final ValueChanged<int>? onNav;
  final Widget? backdrop;
  final VoidCallback? onPractice;
  final PracticeProgress? progress;

  @override
  State<ProgressCompleteView> createState() => ProgressCompleteViewState();
}

class ProgressCompleteViewState extends State<ProgressCompleteView> {
  int tab = 0;
  bool showGuide = false;
  int guideStep = 0;
  PracticeProgress get p => widget.progress ?? PracticeProgress.instance;

  @override
  void initState() {
    super.initState();
    p.addListener(_changed);
    p.start();
    _checkGuide();
  }

  Future<void> _checkGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(kProgressGuideSeenKey) ?? false) && mounted) setState(() => showGuide = true);
    } catch (_) {}
  }

  Future<void> _closeGuide() async {
    setState(() => showGuide = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kProgressGuideSeenKey, true);
    } catch (_) {}
  }

  @override
  void dispose() {
    p.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _goTab(int i) {
    if (widget.onNav != null) return widget.onNav!(i);
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
    NavScope.goTo(context, i);
  }

  void _practice() {
    if (widget.onPractice != null) {
      widget.onPractice!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _push(Widget page) {
    final bg = widget.backdrop;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => bg == null ? page : ProgressBackdropScope(backdrop: bg, child: page),
    ));
  }

  void openStreak() => _push(StreakDetailPage(progress: p, onPractice: _practice));
  void openStats() => _push(StatsDetailPage(progress: p));
  void openHistory() => setState(() => tab = 1);
  void openTab(int i) => setState(() => tab = i);
  void openMilestone(Milestone m) => _push(MilestoneDetailPage(progress: p, milestone: m, onPractice: _practice));

  void showDay(String ymd) {
    final list = sessionsByDay(p)[ymd] ?? const [];
    showNSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: PgCard(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prettyDay(ymd), style: _title),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Text('No practice on this day.', style: _body)
            else
              for (final s in list) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${s['word']}  ·  ${durationLabel(s)}', style: const TextStyle(color: _white, fontSize: 14))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = PgScaffold(
      title: 'My Progress',
      bottom: ProgressNav(onTab: _goTab),
      backdrop: widget.backdrop,
      actions: [
        _RoundIcon(icon: Icons.help_outline_rounded, tooltip: 'Show guide', onTap: () => setState(() {
              guideStep = 0;
              showGuide = true;
            })),
      ],
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: _Tabs(index: tab, onTap: (i) => setState(() => tab = i))),
        Expanded(
          child: switch (tab) {
            1 => HistoryList(progress: p, onPractice: _practice),
            2 => _MilestonesList(progress: p, onOpen: openMilestone),
            _ => _Overview(state: this),
          },
        ),
      ]),
    );
    return Stack(fit: StackFit.expand, children: [
      page,
      if (showGuide)
        _Guide(
          step: guideStep,
          onNext: () => guideStep >= _guideSteps.length - 1 ? _closeGuide() : setState(() => guideStep++),
          onSkip: _closeGuide,
        ),
    ]);
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    const labels = ['Overview', 'History', 'Milestones'];
    return PgCard(
      radius: 30,
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              key: ValueKey('progress-tab-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: i == index ? _white : Colors.transparent, borderRadius: BorderRadius.circular(26)),
                alignment: Alignment.center,
                child: Text(labels[i], style: TextStyle(color: i == index ? const Color(0xFF111214) : _white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});
  final ProgressCompleteViewState state;
  @override
  Widget build(BuildContext context) {
    final p = state.p;
    final week = p.thisWeekDays;
    final empty = p.totalSessions == 0;
    const dayL = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return ListView(key: const ValueKey('progress-overview'), padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
      PgCard(
        onTap: state.openStreak,
        child: Column(children: [
          SizedBox(width: 150, height: 150, child: CustomPaint(painter: WeekRingPainter(p.weekConsistencyPercent / 100), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${p.streak}', style: const TextStyle(color: _white, fontSize: 44, fontWeight: FontWeight.w800)),
            Text(p.streak == 1 ? 'day streak' : 'day streak', style: _body),
          ])))),
          const SizedBox(height: 16),
          PgCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(empty ? 'Begin your first sit' : '${p.weekConsistencyPercent}% of this week', style: _title),
              const SizedBox(height: 6),
              Text(empty ? 'Your streak, minutes and milestones appear here after your first practice.' : '${p.weekTimeLabel} meditated this week. Today: ${p.todaySessions} session${p.todaySessions == 1 ? '' : 's'}.', style: _body),
              const SizedBox(height: 14),
              Row(children: [
                GestureDetector(onTap: state.openStreak, child: const Text('Details', style: TextStyle(color: _grey, fontSize: 13, decoration: TextDecoration.underline, decorationColor: _grey))),
                const Spacer(),
                PgPill('Practice', onTap: state._practice),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Home's wide 3D render (existing Home art) with an outlined Begin Practice pill.
      Banner3D(
        key: const ValueKey('progress-banner'),
        art: 'assets/video/store-orb-box-poster.webp',
        eyebrow: 'DAILY PRACTICE',
        title: p.todaySessions == 0 ? 'Today is still open' : 'Today is done',
        sub: p.todaySessions == 0 ? 'One session keeps your streak going.' : '${p.todaySessions} session${p.todaySessions == 1 ? '' : 's'} today. Go again any time.',
        cta: OutlinePill('Begin Practice', onTap: state._practice),
      ),
      const SizedBox(height: 16),
      // Home's My Routine pattern, on real data.
      HomeDeck(
        key: const ValueKey('deck-streaks'),
        title: 'Streaks',
        eyebrow: 'KEEP IT GOING',
        mark: NwsbMarks.flame,
        onArrow: state.openStreak,
        banner: '${p.streak} day streak',
        bannerSub: '${p.weekConsistencyPercent}% of this week',
        cards: [
          DeckCard('STREAK', '${p.streak}', p.streak == 1 ? 'Day in a row' : 'Days in a row', 'Streak details', state.openStreak),
          DeckCard('THIS WEEK', '${p.thisWeekDays.where((d) => d.done).length}', 'Days practiced · ${p.weekTimeLabel}', 'See the week', state.openStreak),
          DeckCard('TODAY', '${p.todaySessions}', p.todaySessions == 1 ? 'Session today' : 'Sessions today', p.todaySessions == 0 ? 'Practice now' : 'Practice again', state._practice),
        ],
      ),
      const SizedBox(height: 16),
      HomeDeck(
        key: const ValueKey('deck-history'),
        title: 'History',
        eyebrow: 'EVERY SESSION',
        mark: NwsbMarks.hourglass,
        onArrow: state.openHistory,
        banner: empty ? 'No sessions yet' : '${p.totalSessions} sessions',
        bannerSub: empty ? 'Your practice appears here' : '${p.timeLabel} in total',
        cards: empty
            ? [DeckCard('HISTORY', '0', 'Finish a session to begin', 'Practice now', state._practice)]
            : [
                for (final s in p.sessionsSnapshot.take(6))
                  DeckCard(prettyDay('${s['date']}').toUpperCase(), durationLabel(s) == 'Time not recorded' ? '–' : durationLabel(s), '${s['word']}', 'Open day', () => state.showDay('${s['date']}')),
              ],
      ),
      const SizedBox(height: 16),
      HomeDeck(
        key: const ValueKey('deck-milestones'),
        title: 'Milestones',
        eyebrow: 'WORKING TOWARD',
        mark: NwsbMarks.crown,
        onArrow: () => state.openTab(2),
        banner: '${kMilestones.where((m) => m.done(p)).length} of ${kMilestones.length} reached',
        bannerSub: 'From real practice',
        cards: [
          for (final m in kMilestones)
            DeckCard(m.done(p) ? 'REACHED' : 'IN PROGRESS', m.done(p) ? '✓' : '${(m.ratio(p) * 100).round()}%', m.title, 'View milestone', () => state.openMilestone(m)),
        ],
      ),
      const SizedBox(height: 16),
      PgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('THIS WEEK', style: _label),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < week.length; i++)
              GestureDetector(
                key: ValueKey('progress-day-$i'),
                onTap: week[i].isFuture ? null : () => state.showDay(week[i].date),
                child: Column(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: week[i].done ? _white : Colors.transparent,
                      border: Border.all(color: week[i].isToday ? _white : const Color(0x52FFFFFF), width: week[i].isToday ? 2 : 1),
                    ),
                    child: week[i].done ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF111214)) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(dayL[i], style: TextStyle(color: week[i].isFuture ? _dim : _white, fontSize: 12)),
                ]),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      PgCard(
        onTap: state.openStats,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Text('YOUR NUMBERS', style: _label), Spacer(), Icon(Icons.chevron_right_rounded, color: _grey)]),
          const SizedBox(height: 12),
          Row(children: [
            _Num('${p.totalSessions}', 'Sessions'),
            _Num(p.timeLabel, 'Time'),
            _Num('${p.uniqueWords}', 'Words'),
            _Num('${p.level}', 'Level'),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      PgCard(
        onTap: () => state._push(const FeedbackPage()),
        child: const Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('How is practice feeling?', style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Share a quick reflection.', style: _body),
          ])),
          Icon(Icons.chevron_right_rounded, color: _grey),
        ]),
      ),
    ]);
  }
}

/// One card in a Home "My Routine"-style deck. Real values only.
class DeckCard {
  const DeckCard(this.category, this.badge, this.title, this.action, this.onTap);
  final String category, badge, title, action;
  final VoidCallback onTap;
}

/// Home's My Routine section: a title row with an arrow button, the black
/// routine banner, an orange and grey step-dot track, and snapping image
/// cards with a circle badge. Art is the app's existing routine images.
class HomeDeck extends StatefulWidget {
  const HomeDeck({super.key, required this.title, required this.banner, required this.bannerSub, required this.cards, required this.onArrow, this.eyebrow = 'PROGRESS', this.mark = NwsbMarks.flame});
  final String title, banner, bannerSub, eyebrow, mark;
  final List<DeckCard> cards;
  final VoidCallback onArrow;
  @override
  State<HomeDeck> createState() => _HomeDeckState();
}

class _HomeDeckState extends State<HomeDeck> {
  final _pc = PageController(viewportFraction: 0.84);
  int _i = 0;
  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    return SectionPane(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          HomeSectionHeadMark(mark: widget.mark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EyebrowPill(widget.eyebrow),
              const SizedBox(height: 4),
              Text(widget.title, style: const TextStyle(color: _white, fontSize: 21, fontWeight: FontWeight.w700)),
            ]),
          ),
          Tooltip(
            message: 'Open ${widget.title}',
            child: GestureDetector(
              onTap: widget.onArrow,
              child: Container(width: 38, height: 38, decoration: const BoxDecoration(color: _white, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF060C18), size: 20)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        RoutineStyleBlackBanner(title: widget.banner, subtitle: widget.bannerSub, onTap: widget.onArrow),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) Expanded(child: Container(height: 2, color: i <= _i ? const Color(0xFFFF8A2A) : const Color(0x33FFFFFF))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _i ? 14 : 10,
                height: i == _i ? 14 : 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: i <= _i ? const Color(0xFFFF8A2A) : const Color(0xFFD7D7DE)),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pc,
            padEnds: false,
            itemCount: n,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 12), child: _DeckFace(card: widget.cards[i], art: kRoutineArts[i % kRoutineArts.length])),
          ),
        ),
      ]),
    );
  }
}

class _DeckFace extends StatelessWidget {
  const _DeckFace({required this.card, required this.art});
  final DeckCard card;
  final String art;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: PgCard(
                radius: 24,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.category, maxLines: 1, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 12)),
                  const SizedBox(height: 8),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(art, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)))),
                  const SizedBox(height: 30),
                  Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            // Circle badge (Home's store-dot shape) holding the real value.
            Positioned(
              left: 0,
              right: 0,
              bottom: 38,
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE9C1A5), shape: BoxShape.circle, border: Border.all(color: _white, width: 3)),
                  child: card.badge == '✓'
                      ? const Icon(Icons.check_rounded, color: Color(0xFF060C18), size: 26, semanticLabel: 'Reached')
                      : FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: Text(card.badge, style: const TextStyle(color: Color(0xFF060C18), fontSize: 16, fontWeight: FontWeight.w800)))),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(child: Text(card.action, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w600))),
            // Home's Enter pill.
            const Text('Enter', style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(width: 26, height: 26, decoration: const BoxDecoration(color: _white, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF111111))),
          ]),
        ),
      ]),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: _body),
        ]),
      );
}

/// White weekly ring (no violet).
class WeekRingPainter extends CustomPainter {
  WeekRingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = const Color(0x33FFFFFF);
    canvas.drawCircle(c, r, base);
    final arc = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round..color = _white;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(WeekRingPainter old) => old.value != value;
}

// ── History ───────────────────────────────────────────────────────────────

class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.progress, required this.onPractice});
  final PracticeProgress progress;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final byDay = sessionsByDay(progress);
    if (byDay.isEmpty) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        PgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('No history yet', style: _title),
          const SizedBox(height: 6),
          const Text('Every session you finish is listed here by day.', style: _body),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: PgPill('Practice', onTap: onPractice)),
        ])),
      ]);
    }
    return ListView(key: const ValueKey('progress-history'), padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
      for (final e in byDay.entries) ...[
        const SizedBox(height: 12),
        SectionPane(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prettyDay(e.key).toUpperCase(), style: _label),
            const SizedBox(height: 4),
            for (var i = 0; i < e.value.length; i++)
              TimelineEntry(
                title: '${e.value[i]['word']}',
                sub: durationLabel(e.value[i]),
                last: i == e.value.length - 1,
                onTap: () => showSessionDialog(context, e.value[i]),
              ),
          ]),
        ),
      ],
    ]);
  }
}

void showSessionDialog(BuildContext context, Map<String, dynamic> s) {
  final at = DateTime.tryParse('${s['completedAt'] ?? ''}');
  final time = at == null ? '' : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  final source = switch ('${s['source'] ?? ''}') { 'native-player' => 'Practice player', 'coin-restore' => 'Streak restore', '' => 'Synced', final o => o };
  showNDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: PgCard(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s['word']}', style: _title),
          const SizedBox(height: 10),
          Text('${prettyDay('${s['date']}')}${time.isEmpty ? '' : ' at $time'}', style: _body),
          Text('Length: ${durationLabel(s)}', style: _body),
          Text('From: $source', style: _body),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: PgPill('Close', onTap: () => Navigator.of(ctx).pop())),
        ]),
      ),
    ),
  );
}

// ── Milestones ────────────────────────────────────────────────────────────

class _MilestonesList extends StatelessWidget {
  const _MilestonesList({required this.progress, required this.onOpen});
  final PracticeProgress progress;
  final ValueChanged<Milestone> onOpen;
  @override
  Widget build(BuildContext context) {
    final done = kMilestones.where((m) => m.done(progress)).length;
    return ListView(key: const ValueKey('progress-overview'), padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
      Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 12), child: Text('$done of ${kMilestones.length} reached', style: _body)),
      for (final m in kMilestones) ...[
        PgCard(
          key: ValueKey('milestone-${m.id}'),
          onTap: () => onOpen(m),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: m.done(progress) ? _white : Colors.transparent, border: Border.all(color: const Color(0x80FFFFFF))),
              child: Icon(m.done(progress) ? Icons.check_rounded : Icons.lock_outline_rounded, color: m.done(progress) ? const Color(0xFF111214) : _grey, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: m.ratio(progress), minHeight: 4, backgroundColor: const Color(0x33FFFFFF), color: _white)),
              const SizedBox(height: 4),
              Text('${math.min(m.current(progress), m.target)} / ${m.target} ${m.unit()}', style: _body),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

class MilestoneDetailPage extends StatelessWidget {
  const MilestoneDetailPage({super.key, required this.progress, required this.milestone, required this.onPractice});
  final PracticeProgress progress;
  final Milestone milestone;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final left = math.max(0, m.target - m.current(progress));
    return PgScaffold(
      title: 'Milestone',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        PgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: SizedBox(width: 120, height: 120, child: CustomPaint(painter: WeekRingPainter(m.ratio(progress)), child: Center(child: Text('${(m.ratio(progress) * 100).round()}%', style: const TextStyle(color: _white, fontSize: 26, fontWeight: FontWeight.w800)))))),
          const SizedBox(height: 16),
          Text(m.title, style: _title),
          const SizedBox(height: 6),
          Text(m.blurb, style: _body),
          const SizedBox(height: 10),
          Text(m.done(progress) ? 'Reached. Well done.' : '$left more ${m.unit()} to go.', style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (!m.done(progress)) Align(alignment: Alignment.centerRight, child: PgPill('Practice', onTap: () {
            Navigator.of(context).pop();
            onPractice();
          })),
        ])),
      ]),
    );
  }
}

// ── Streak detail ─────────────────────────────────────────────────────────

class StreakDetailPage extends StatelessWidget {
  const StreakDetailPage({super.key, required this.progress, required this.onPractice});
  final PracticeProgress progress;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final days = sessionsByDay(progress).keys.toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final practicedToday = days.contains(key(today));
    // Longest streak from real days.
    final sorted = days.map(DateTime.tryParse).whereType<DateTime>().toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d) ? run + 1 : 1;
      best = math.max(best, run);
      prev = d;
    }
    return PgScaffold(
      title: 'Streak',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        PgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${progress.streak} day streak', style: _title),
          const SizedBox(height: 6),
          Text('Longest: $best day${best == 1 ? '' : 's'}', style: _body),
          const SizedBox(height: 6),
          Text(practicedToday ? 'Today is done. Come back tomorrow to keep it going.' : 'Practice today to keep your streak.', style: _body),
          const SizedBox(height: 14),
          if (!practicedToday) Align(alignment: Alignment.centerRight, child: PgPill('Practice', onTap: () {
            Navigator.of(context).pop();
            onPractice();
          })),
        ])),
        const SizedBox(height: 16),
        PgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('LAST 28 DAYS', style: _label),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 27; i >= 0; i--)
                Builder(builder: (_) {
                  final d = DateTime(today.year, today.month, today.day - i);
                  final on = days.contains(key(d));
                  return Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: on ? _white : const Color(0x14FFFFFF), border: Border.all(color: i == 0 ? _white : const Color(0x33FFFFFF))),
                    alignment: Alignment.center,
                    child: Text('${d.day}', style: TextStyle(color: on ? const Color(0xFF111214) : _grey, fontSize: 11)),
                  );
                }),
            ],
          ),
        ])),
      ]),
    );
  }
}

// ── Stats detail ──────────────────────────────────────────────────────────

class StatsDetailPage extends StatelessWidget {
  const StatsDetailPage({super.key, required this.progress});
  final PracticeProgress progress;
  @override
  Widget build(BuildContext context) {
    final p = progress;
    final counts = <String, int>{};
    for (final s in p.sessionsSnapshot) {
      final w = '${s['word'] ?? ''}';
      if (w.isNotEmpty && s['source'] != 'coin-restore') counts[w] = (counts[w] ?? 0) + 1;
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    Widget row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Text(l, style: _body)), Text(v, style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700))]));
    return PgScaffold(
      title: 'Your numbers',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        PgCard(child: Column(children: [
          row('Sessions', '${p.totalSessions}'),
          row('Total time', p.timeLabel),
          row('This week', p.weekTimeLabel),
          row('Week consistency', '${p.weekConsistencyPercent}%'),
          row('Different words', '${p.uniqueWords}'),
          row('Current streak', '${p.streak} days'),
          row('Level', '${p.level} of 10'),
          row('Last practiced', p.lastPracticed == null ? 'Never' : prettyDay(p.lastPracticed!)),
        ])),
        const SizedBox(height: 16),
        PgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MOST PRACTICED', style: _label),
          const SizedBox(height: 8),
          if (top.isEmpty) const Text('Nothing yet.', style: _body),
          for (final e in top.take(5)) row(e.key, '${e.value}×'),
        ])),
        const SizedBox(height: 12),
        const Text('Level rises by one for every 30 minutes meditated.', style: _body),
      ]),
    );
  }
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});
  @override
  Widget build(BuildContext context) => PgScaffold(
        title: 'Your feedback',
        body: ListView(padding: const EdgeInsets.all(20), children: const [PgCard(child: ProgressFeedbackSection())]),
      );
}

// ── First-use guide ───────────────────────────────────────────────────────

const _guideSteps = <(String, String)>[
  ('Your streak', 'The ring fills as you practice on more days this week. Tap the card for your streak details.'),
  ('Three views', 'Overview shows today, History lists every session, and Milestones shows what you are working toward.'),
  ('Tap to go deeper', 'Tap a day, a number or a milestone to open it. You can reopen this guide with the ? button.'),
];

class _Guide extends StatelessWidget {
  const _Guide({required this.step, required this.onNext, required this.onSkip});
  final int step;
  final VoidCallback onNext, onSkip;
  @override
  Widget build(BuildContext context) {
    final s = _guideSteps[step];
    final last = step == _guideSteps.length - 1;
    return Material(
      key: const ValueKey('progress-guide'),
      color: const Color(0x99000000),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: PgCard(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$1, style: _title),
                const SizedBox(height: 8),
                Text(s.$2, style: _body),
                const SizedBox(height: 18),
                Row(children: [
                  GestureDetector(onTap: onSkip, child: const Text('Skip', style: TextStyle(color: _grey, fontSize: 13))),
                  const Spacer(),
                  for (var i = 0; i < _guideSteps.length; i++)
                    Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: i == step ? _white : const Color(0x55FFFFFF))),
                  const Spacer(),
                  PgPill(last ? 'Done' : 'Next', onTap: onNext),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Home pieces (Home style order, Oct 21) ────────────────────────────────

/// Home's section-head mark: a round white button holding the section icon.
class HomeSectionHeadMark extends StatelessWidget {
  const HomeSectionHeadMark({super.key, required this.mark});
  final String mark;
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
        child: Center(child: NwsbIcon(mark, size: 20, color: const Color(0xFF1A1A2E))),
      );
}

/// Small gold uppercase caption in a thin pill.
class EyebrowPill extends StatelessWidget {
  const EyebrowPill(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x66E9C987))),
        child: Text(text.toUpperCase(), style: _label.copyWith(fontSize: 9.5)),
      );
}

/// Home's outlined "Begin Practice" pill.
class OutlinePill extends StatelessWidget {
  const OutlinePill(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: const StadiumBorder(side: BorderSide(color: _white, width: 1.3)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label, style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

/// Home's wide 3D banner: one of Home's own renders, bold white title.
class Banner3D extends StatelessWidget {
  const Banner3D({super.key, required this.art, required this.eyebrow, required this.title, required this.sub, required this.cta});
  final String art, eyebrow, title, sub;
  final Widget cta;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(art, fit: BoxFit.cover, alignment: const Alignment(0.6, 0), errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)], stops: [0.3, 0.75]))),
            DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x29FFFFFF)))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eyebrow, style: _label),
                const SizedBox(height: 6),
                SizedBox(width: 210, child: Text(title, style: const TextStyle(color: _white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1))),
                const SizedBox(height: 6),
                SizedBox(width: 200, child: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: _body)),
                const Spacer(),
                cta,
              ]),
            ),
          ]),
        ),
      );
}

/// Home's list row: purple dot on a vertical line, uppercase title, grey
/// subtitle, thin divider.
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({super.key, required this.title, required this.sub, this.last = false, this.onTap});
  final String title, sub;
  final bool last;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 22,
              child: Column(children: [
                const SizedBox(height: 16),
                Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF9B6BFF))),
                if (!last) Expanded(child: Container(width: 1.5, color: const Color(0x669B6BFF))) else const Spacer(),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .8)),
                      Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _body),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _grey, size: 20),
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Home's floating pill nav (AppBottomNav) with Home's own nav art.
class ProgressNav extends StatelessWidget {
  const ProgressNav({super.key, required this.onTab});
  final ValueChanged<int> onTab;
  static const _items = <(String, String)>[
    ('Connect', 'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png'),
    ('Practice', 'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png'),
    ('Library', 'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png'),
    ('Store', 'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'),
    ('Profile', 'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png'),
  ];
  @override
  Widget build(BuildContext context) => AppBottomNav(
        key: const ValueKey('progress-nav'),
        items: [
          for (var i = 0; i < _items.length; i++) AppNavItem(image: _items[i].$2, label: _items[i].$1, asHome: i == 0),
        ],
        onTap: onTab,
      );
}
