/// Today's progress: the five daily goals with their real counts, a bar
/// each, what to do next and a button that does it. Same look as Settings
/// and the Sound Library (film, glass panes with badge headings, black
/// cards). Counts come from [ProgressSources]; nothing here is made up.
library;

import 'package:flutter/material.dart';

import '../../screens/daily_tasks.dart';
import '../../widgets/page_shell.dart';
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
class TodayProgressBody extends StatelessWidget {
  const TodayProgressBody({super.key, this.center});
  final ProgressCenter? center;

  @override
  Widget build(BuildContext context) {
    final c = center ?? ProgressCenter.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([c, DailyTasks.items]),
      builder: (context, _) {
        final items = c.items;
        final done = items.where((e) => e.complete).length;
        final steps = items.fold<int>(0, (a, e) => a + e.done.clamp(0, e.total));
        final all = items.fold<int>(0, (a, e) => a + e.total);
        final next = items.where((e) => !e.complete).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GoalSection(
            key: const ValueKey('today-hero'),
            mark: GoalMarks.check,
            eyebrow: 'Today',
            title: '$done of ${items.length} goals done',
            children: [
              GoalCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Text('$steps of $all steps', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Text('${all == 0 ? 0 : (steps * 100 / all).round()}%', style: const TextStyle(color: Color(0xFFE8D5A3), fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(child: GoalBar(value: items[i].value, height: 8)),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const NwsbNext(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(next == null ? 'Every goal is done. See you tomorrow.' : 'Next up · ${ProgressSources.nextStep(next)}',
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5, height: 1.35)),
                    ),
                    if (next != null) ...[
                      const SizedBox(width: 8),
                      GoalActionFor(item: next, key: const ValueKey('today-next-action')),
                    ],
                  ]),
                ]),
              ),
            ],
          ),
          GoalSection(
            mark: GoalMarks.tasks,
            eyebrow: 'Daily goals',
            title: 'Your five for today',
            children: [for (final e in items) GoalRow(item: e)],
          ),
        ]);
      },
    );
  }
}

class NwsbNext extends StatelessWidget {
  const NwsbNext({super.key});
  @override
  Widget build(BuildContext context) => const GoalBadge(mark: GoalMarks.next, size: 30);
}

/// One goal: badge, title, count, bar, next step and its button. Tapping
/// the card opens the goal's place.
class GoalRow extends StatelessWidget {
  const GoalRow({super.key, required this.item});
  final ProgressItem item;
  @override
  Widget build(BuildContext context) {
    return GoalCard(
      key: ValueKey('today-goal-${item.kind.name}'),
      onTap: () => ProgressRoutes.open(context, item.kind),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          GoalBadge(mark: goalMark(item.kind), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(ProgressSources.nextStep(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 8),
          Text('${item.done.clamp(0, item.total)}/${item.total}',
              key: ValueKey('today-count-${item.kind.name}'),
              style: TextStyle(color: item.complete ? const Color(0xFFE8D5A3) : Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        GoalBar(value: item.value),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(item.complete ? 'Done today' : '${item.total - item.done} to go',
                style: TextStyle(color: item.complete ? const Color(0xFFE8D5A3) : const Color(0x80FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          GoalActionFor(item: item, key: ValueKey('today-action-${item.kind.name}')),
        ]),
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
