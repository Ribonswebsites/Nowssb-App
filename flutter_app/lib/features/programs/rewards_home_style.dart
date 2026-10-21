/// Rewards in NowssB Home's style: Home's film backdrop and top bar, plus a
/// frosted quest board (course-style card + counted state tabs). Reuses
/// Home's widgets; quest numbers are the server's.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/notifications.dart';
import '../../screens/app_settings.dart';
import '../../screens/fashion/header.dart';
import '../../screens/notifications_sheet.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/home_menu_drawer.dart';
import '../../widgets/nwsb_icon.dart';
import '../coupons/coupon_home_style.dart' show HomeTimelineRow;
import 'program_kit.dart';

/// Home's frame: the same film, Home's veil weight and Home's header
/// (logo, bell, gear, menu). [child] scrolls under the header.
class RewardsHomeShell extends StatelessWidget {
  const RewardsHomeShell({super.key, required this.child, this.backdrop});
  final Widget child;

  /// Test hook: tests can't decode video, so they pass a still.
  final Widget? backdrop;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NwsbColors.deep,
        body: Stack(children: [
          Positioned.fill(child: backdrop ?? const AppBackdrop()),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x42000000), Color(0x00000000), Color(0x00000000), Color(0x57000000)],
                    stops: [0, 0.20, 0.76, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Column(children: [
            ListenableBuilder(
              listenable: NotifStore.instance,
              builder: (context, _) => HomeHeader(
                notifications: NotifStore.instance.unreadRaw,
                onNotifications: () => showNotificationsSheet(context),
                onSettings: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AppSettingsScreen())),
                onMenu: () => showHomeMenuDrawer(context, goTab: (i) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  NwsbLinks.tab(context, i);
                }),
              ),
            ),
            Expanded(child: child),
          ]),
        ]),
      );
}

enum QuestFilter { all, completed, incomplete, ready }

const questFilterLabels = {
  QuestFilter.all: 'All',
  QuestFilter.completed: 'Completed',
  QuestFilter.incomplete: 'Incomplete',
  QuestFilter.ready: 'Ready',
};

/// One quest with the claim action it needs.
class RQuest {
  RQuest(this.x, this.kind);
  final Map<String, dynamic> x;
  final String kind;
  bool get claimed => x['claimed'] == true;
  bool get reached => sNum(x['goal']) > 0 && sNum(x['value']) >= sNum(x['goal']);
  bool get ready => reached && !claimed;
  bool get incomplete => !reached && !claimed;
  String get title => '${x['title'] ?? 'Quest'}';
}

List<RQuest> questsOf(Map<String, dynamic> s) {
  final q = sMap(s['quests']);
  return [
    for (final x in sList(q['starter'])) RQuest(x, 'starter'),
    for (final x in sList(q['weekly'])) RQuest(x, 'weekly'),
    if (sMap(q['monthly']).isNotEmpty) RQuest(sMap(q['monthly']), 'monthly'),
  ];
}

Map<QuestFilter, int> questCounts(List<RQuest> qs) => {
      QuestFilter.all: qs.length,
      QuestFilter.completed: qs.where((q) => q.claimed).length,
      QuestFilter.incomplete: qs.where((q) => q.incomplete).length,
      QuestFilter.ready: qs.where((q) => q.ready).length,
    };

/// The frosted quest board: a course-style card for the active quest and
/// counted tabs over the list.
class RewardsQuestBoard extends StatefulWidget {
  const RewardsQuestBoard(this.s, {super.key, this.onContinue});
  final Map<String, dynamic> s;
  final VoidCallback? onContinue;
  @override
  State<RewardsQuestBoard> createState() => _RewardsQuestBoardState();
}

class _RewardsQuestBoardState extends State<RewardsQuestBoard> {
  var _f = QuestFilter.all;

  @override
  Widget build(BuildContext context) {
    final qs = questsOf(widget.s);
    final counts = questCounts(qs);
    final active = qs.where((q) => q.ready).followedBy(qs.where((q) => q.incomplete)).firstOrNull;
    final shown = switch (_f) {
      QuestFilter.all => qs,
      QuestFilter.completed => qs.where((q) => q.claimed).toList(),
      QuestFilter.incomplete => qs.where((q) => q.incomplete).toList(),
      QuestFilter.ready => qs.where((q) => q.ready).toList(),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (active != null) _CourseCard(q: active, all: qs, onContinue: widget.onContinue),
      const SizedBox(height: 12),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in QuestFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                key: ValueKey('qf-${f.name}'),
                onTap: () => setState(() => _f = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _f == f ? Colors.white : const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x40FFFFFF)),
                  ),
                  child: Text('${questFilterLabels[f]} ${counts[f]}',
                      style: TextStyle(color: _f == f ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      _Frost(
        child: shown.isEmpty
            ? Text(qs.isEmpty ? 'No quests right now. New ones arrive each week.' : 'Nothing in ${questFilterLabels[_f]!.toLowerCase()}.',
                style: const TextStyle(color: NwsbColors.mist))
            : Column(children: [
                for (var i = 0; i < shown.length; i++)
                  HomeTimelineRow(
                    title: shown[i].title,
                    subtitle: '+${sInt(shown[i].x['coins'])} coins · ${shown[i].kind} · ${sInt(shown[i].x['value'])} of ${sInt(shown[i].x['goal'])}',
                    active: shown[i].ready,
                    last: i == shown.length - 1,
                    trailing: shown[i].claimed
                        ? const PPill('Claimed', color: NwsbColors.goldLight)
                        : PClaim(label: 'Claim', action: 'claimQuest', data: {'kind': shown[i].kind, 'id': shown[i].x['id']}, enabled: shown[i].ready, title: shown[i].title),
                  ),
              ]),
      ),
    ]);
  }
}

class _Frost extends StatelessWidget {
  const _Frost({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0x29FFFFFF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x4DFFFFFF)),
            ),
            child: child,
          ),
        ),
      );
}

/// Course-style card: Active pill, avatar stack (the quests in this set,
/// gold when claimed), progress and a Continue button.
class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.q, required this.all, this.onContinue});
  final RQuest q;
  final List<RQuest> all;
  final VoidCallback? onContinue;
  @override
  Widget build(BuildContext context) {
    final goal = sNum(q.x['goal']) <= 0 ? 1 : sNum(q.x['goal']);
    final pct = (sNum(q.x['value']) / goal).clamp(0, 1).toDouble();
    final set = all.where((o) => o.kind == q.kind).toList();
    final av = set.take(3).toList();
    return _Frost(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
            child: Text(q.ready ? 'Ready' : 'Active', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const Spacer(),
          SizedBox(
            width: 24.0 * av.length + 14 + (set.length > 3 ? 30 : 0),
            height: 34,
            child: Stack(children: [
              for (var i = 0; i < av.length; i++)
                Positioned(
                  left: i * 24.0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: av[i].claimed ? NwsbColors.goldLight : const Color(0xFF26262E),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(child: NwsbIcon(NwsbMarks.rewards, size: 16, color: av[i].claimed ? Colors.black : Colors.white)),
                  ),
                ),
              if (set.length > 3)
                Positioned(left: av.length * 24.0 + 8, top: 8, child: Text('+${set.length - 3}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Text(q.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${q.kind[0].toUpperCase()}${q.kind.substring(1)} quest · +${sInt(q.x['coins'])} coins · ${sInt(q.x['value'])} of ${sInt(goal)}',
            style: const TextStyle(color: NwsbColors.mist, fontSize: 13)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: const Color(0x33FFFFFF), valueColor: const AlwaysStoppedAnimation(Colors.white)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const ValueKey('quest-continue'),
            onPressed: onContinue,
            style: TextButton.styleFrom(backgroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}
