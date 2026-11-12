/// Quests: starter, weekly and monthly quests from the server summary, each
/// with its real count and a Claim button once it is finished. A claim goes
/// to the server (claimQuest) and moves the Quest goal on Today's progress.
library;

import 'package:flutter/material.dart';

import '../../widgets/page_shell.dart';
import '../economy/economy_api.dart';
import '../programs/program_kit.dart' show PClaim;
import 'progress_kit.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});
  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  @override
  void initState() {
    super.initState();
    if (EconomyMirror.instance.uid != null) EconomyMirror.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PageShell(
      eyebrow: 'NowssB',
      title: 'Quests',
      film: 'assets/video/subscription-bg.mp4',
      usePageFilm: true,
      quietFilm: true,
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: 40 + bottom),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: EconomyMirror.instance,
              builder: (context, _) => QuestsBody(summary: EconomyMirror.instance.summary, signedIn: EconomyMirror.instance.uid != null),
            ),
          ),
        ),
      ],
    );
  }
}

/// The page content for one summary (split out so tests can render it).
class QuestsBody extends StatelessWidget {
  const QuestsBody({super.key, required this.summary, required this.signedIn});
  final Map<String, dynamic> summary;
  final bool signedIn;

  static List<Map> _list(Object? v) => [for (final e in (v as List? ?? const [])) if (e is Map) e];

  @override
  Widget build(BuildContext context) {
    if (!signedIn) {
      return const GoalSection(mark: GoalMarks.quest, eyebrow: 'Quests', title: 'Sign in to start', children: [
        GoalCard(child: Text('Quests are kept on your account. Sign in from Profile and your quests appear here with their coins.', style: TextStyle(color: Color(0xCCFFFFFF), height: 1.4))),
      ]);
    }
    final q = summary['quests'];
    if (q is! Map) {
      return const GoalSection(mark: GoalMarks.quest, eyebrow: 'Quests', title: 'Loading your quests', children: [
        GoalCard(child: LinearProgressIndicator(minHeight: 4)),
      ]);
    }
    final starter = _list(q['starter']);
    final weekly = _list(q['weekly']);
    final monthly = q['monthly'] is Map ? q['monthly'] as Map : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (starter.isNotEmpty)
        GoalSection(mark: GoalMarks.quest, eyebrow: 'One time', title: 'Starter quests', children: [for (final e in starter) QuestRow(quest: e)]),
      if (weekly.isNotEmpty)
        GoalSection(mark: GoalMarks.checkin, eyebrow: 'This week', title: 'Weekly quests', children: [for (final e in weekly) QuestRow(quest: e)]),
      if (monthly != null) GoalSection(mark: GoalMarks.coins, eyebrow: 'This month', title: 'Monthly quest', children: [QuestRow(quest: monthly)]),
    ]);
  }
}

class QuestRow extends StatelessWidget {
  const QuestRow({super.key, required this.quest});
  final Map quest;
  @override
  Widget build(BuildContext context) {
    final goal = (quest['goal'] as num?)?.toInt() ?? 1;
    final value = ((quest['value'] as num?)?.toInt() ?? 0).clamp(0, goal);
    final claimed = quest['claimed'] == true;
    final ready = !claimed && value >= goal;
    final id = '${quest['id'] ?? ''}';
    return GoalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${quest['title'] ?? 'Quest'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$value of $goal · +${quest['coins'] ?? 0} coins', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 10),
          if (claimed)
            const Text('Claimed', style: TextStyle(color: Color(0xFFE8D5A3), fontWeight: FontWeight.w800, fontSize: 12))
          else if (ready)
            PClaim(key: ValueKey('quest-claim-$id'), label: 'Claim', action: 'claimQuest', data: {'questId': id})
          else
            Text('${goal - value} to go', key: ValueKey('quest-left-$id'), style: const TextStyle(color: Color(0xB3FFFFFF), fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        GoalBar(value: goal == 0 ? 0 : value / goal),
      ]),
    );
  }
}
