/// NowssB Rewards (spec 14.3): Check-in · Chests · Coin Boost · Coin Store ·
/// My Rewards · first-use guide. Every number comes from the server summary;
/// the coin spend cap is enforced server-side, never here.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../admin/layout/layout_sections.dart';
import 'program_kit.dart';

Map<String, dynamic> _r(Map<String, dynamic> s) => sMap(sMap(s['config'])['rewards']);

const _mist = TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.35);
const _title = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800);

/// Daily check-in: a 7-day calendar for the current streak week.
List<Widget> rewardsCheckin(BuildContext context, Map<String, dynamic> s) {
  final w = sMap(s['wallet']);
  final t = sMap(s['today']);
  final streak = sInt(w['streak']);
  final done = t['login'] == true;
  final week = sList(_r(s)['checkinWeek']);
  final dayInWeek = streak % 7; // days already checked in this 7-day cycle
  return [
    const RewardsGuide(),
    LSection('checkin', 'Daily check-in', PCard(children: [
      const PHeading('Every day', 'Daily check-in', slot: 'rewards_more.checkin'),
      Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayDot(
                day: i + 1,
                coins: i < week.length ? sInt(week[i]['coins']) : null,
                state: i < dayInWeek ? _Day.done : (i == dayInWeek && !done ? _Day.today : _Day.later),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      PRow(
        title: done ? 'Checked in today' : 'Check in for today',
        sub: done ? 'Come back tomorrow to keep your $streak-day streak.' : '+${sInt(w['nextLogin'])} coins · day ${streak + 1} of your streak',
        coin: true,
        trailing: PClaim(label: done ? 'Done' : 'Check in', action: 'claimDailyLogin', enabled: !done, title: 'Daily check-in'),
      ),
      const PEmpty('Miss a day and the streak resets, unless a hold or freeze covers it (see Streaks).', slot: 'rewards_more.checkin'),
    ])),
  ];
}

enum _Day { done, today, later }

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.state, this.coins});
  final int day;
  final _Day state;
  final int? coins;
  @override
  Widget build(BuildContext context) {
    final on = state == _Day.done;
    final today = state == _Day.today;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: on ? Colors.white : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: today ? NwsbColors.goldLight : const Color(0x33FFFFFF), width: today ? 1.6 : 1),
      ),
      child: Column(children: [
        Text('D$day', style: TextStyle(color: on ? Colors.black : Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 2),
        on
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
            : Text(coins == null ? '·' : '+$coins', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Milestone chests: unlock by streak / active days; opened server-side.
List<Widget> rewardsChests(BuildContext context, Map<String, dynamic> s) {
  final chests = sList(s['chests']).isNotEmpty ? sList(s['chests']) : sList(_r(s)['chests']);
  final streak = sInt(sMap(s['wallet'])['streak']);
  return [
    LSection.group('chests', 'Milestone chests', [
      const PHeading('Keep going', 'Milestone chests', slot: 'rewards_more.chests'),
      PCard(children: [
        if (chests.isEmpty) const PEmpty('No chests are set up right now. Check back soon.'),
        for (final c in chests)
          Builder(builder: (context) {
            final goal = sInt(c['day']);
            final value = c.containsKey('value') ? sInt(c['value']) : streak;
            final opened = c['opened'] == true;
            final ready = !opened && (c['ready'] == true || (goal > 0 && value >= goal));
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PRow(
                title: '${c['title'] ?? 'Day $goal chest'}',
                sub: opened ? 'Opened' : ready ? 'Ready to open' : '${goal - value} more day${goal - value == 1 ? '' : 's'} to unlock',
                mark: NwsbMarks.gift,
                trailing: opened
                    ? const PPill('Opened', color: NwsbColors.goldLight)
                    : ready
                        ? PClaim(label: 'Open', action: 'openChest', data: {'id': c['id'] ?? 'day$goal'}, title: '${c['title'] ?? 'Chest'}')
                        : const PPill('Locked'),
              ),
              PProgress(value: value.clamp(0, goal <= 0 ? 1 : goal), goal: goal <= 0 ? 1 : goal),
            ]);
          }),
        const PEmpty('What is inside each chest is decided by the server when you open it; odds are listed in Rules.', slot: 'rewards_more.chests'),
      ]),
    ]),
  ];
}

/// Coin Boost: multiplies coin EARNING for a while. Never raises the spend cap.
List<Widget> rewardsBoost(BuildContext context, Map<String, dynamic> s) {
  final b = sMap(s['boost']);
  final cfg = sMap(_r(s)['boost']);
  final mult = sNum(b['multiplier'] ?? cfg['multiplier']);
  final active = b['active'] == true;
  final example = sInt(cfg['exampleCoins']) > 0 ? sInt(cfg['exampleCoins']) : 10;
  return [
    LSection('boost', 'Coin Boost', PCard(glow: NwsbColors.gold, children: [
      const PHeading('Earn faster', 'Coin Boost', slot: 'rewards_more.boost'),
      if (mult <= 0)
        const PEmpty('Coin Boost is not available right now.')
      else ...[
        Text('${mult}x coins earned', style: _title),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: PPill('Example: a +$example coin activity gives +${(example * mult).round()}', color: NwsbColors.goldLight)),
        const SizedBox(height: 10),
        Text(active ? 'Active until ${shortDate(b['endsAt'])}.' : 'Lasts ${sInt(cfg['hours'])} hours once switched on.', style: _mist),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: active
              ? const PPill('Boost on', color: NwsbColors.goldLight)
              : PClaim(label: 'Switch on boost', action: 'activateBoost', enabled: b['available'] == true, title: 'Coin Boost'),
        ),
      ],
      const PEmpty('Boost only changes how many coins you earn. It never changes how much of a price coins can cover — that limit is set by the server.',
          slot: 'rewards_more.boost'),
    ])),
  ];
}

/// Coin Store: items priced in coins, plus products that give coins back.
List<Widget> rewardsStore(BuildContext context, Map<String, dynamic> s) {
  final spend = sMap(_r(s)['spend']);
  final back = sList(_r(s)['coinsBack']);
  final coins = sInt(sMap(s['wallet'])['coins']);
  return [
    LSection('balance', 'Balance', PBalance(coins: coins, caption: 'Coins have no cash value. At checkout they cover only part of a price.')),
    LSection('store', 'Coin Store', PCard(children: [
      const PHeading('Use your coins', 'Coin Store', slot: 'rewards_more.store'),
      if (spend.isEmpty) const PEmpty('Nothing to spend coins on yet.'),
      for (final e in spend.entries)
        PRow(
          title: '${sMap(e.value)['title']}',
          sub: '${sInt(sMap(e.value)['coins'])} coins',
          coin: true,
          trailing: _ConfirmSpend(item: e.key, title: '${sMap(e.value)['title']}', price: sInt(sMap(e.value)['coins']), have: coins),
        ),
    ])),
    if (back.isNotEmpty)
      LSection('back', 'Earn coins back', PCard(children: [
        const PHeading('Shop and earn', 'Earn coins back', slot: 'rewards_more.store'),
        for (final x in back) PRow(title: '${x['title']}', sub: 'Earn ${sInt(x['coins'])} coins back', mark: NwsbMarks.word, trailing: PPill('+${sInt(x['coins'])}', color: NwsbColors.goldLight)),
      ])),
  ];
}

class _ConfirmSpend extends StatelessWidget {
  const _ConfirmSpend({required this.item, required this.title, required this.price, required this.have});
  final String item;
  final String title;
  final int price;
  final int have;
  @override
  Widget build(BuildContext context) {
    final can = have >= price;
    return TextButton(
      key: ValueKey('spend-$item'),
      onPressed: !can
          ? null
          : () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xEE111118),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  title: Text('Get $title?', style: const TextStyle(color: Colors.white)),
                  content: Text('This uses $price of your $have coins. Coins cannot be refunded as cash.', style: _mist),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: NwsbColors.mist))),
                    PClaim(label: 'Confirm', action: 'spendCoins', data: {'item': item}, title: title, onDone: (_) => Navigator.of(context).maybePop()),
                  ],
                ),
              ),
      style: TextButton.styleFrom(backgroundColor: can ? Colors.white : const Color(0x22FFFFFF), shape: const StadiumBorder()),
      child: Text(can ? 'Get' : 'Need ${price - have}', style: TextStyle(color: can ? Colors.black : NwsbColors.mist, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// My Rewards: coupons, gifts and chests the account holds, with filters.
class RewardsMine extends StatefulWidget {
  const RewardsMine(this.s, {super.key});
  final Map<String, dynamic> s;
  @override
  State<RewardsMine> createState() => _RewardsMineState();
}

class _RewardsMineState extends State<RewardsMine> {
  static const filters = ['All', 'Coupons', 'Gifts', 'Chests', 'Expired'];
  var _f = 'All';

  List<(String, Map<String, dynamic>)> get _items {
    final s = widget.s;
    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <(String, Map<String, dynamic>)>[
      for (final c in sList(s['coupons'])) ('Coupons', c),
      for (final g in sList(s['gifts'])) ('Gifts', g),
      for (final c in sList(s['chests']).where((c) => c['opened'] == true)) ('Chests', c),
    ];
    bool expired(Map<String, dynamic> x) => x['expired'] == true || (sInt(x['expiresAt']) > 0 && sInt(x['expiresAt']) < now);
    return out.where((e) => _f == 'All' ? true : _f == 'Expired' ? expired(e.$2) : e.$1 == _f && !expired(e.$2)).map((e) => (expired(e.$2) ? 'Expired' : e.$1, e.$2)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return PCard(children: [
      const PHeading('Yours', 'My Rewards', slot: 'rewards_more.mine'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in filters)
          ChoiceChip(
            label: Text(f),
            selected: _f == f,
            onSelected: (_) => setState(() => _f = f),
            selectedColor: Colors.white,
            backgroundColor: const Color(0x14FFFFFF),
            labelStyle: TextStyle(color: _f == f ? Colors.black : Colors.white, fontWeight: FontWeight.w700),
            shape: const StadiumBorder(side: BorderSide(color: Color(0x33FFFFFF))),
            showCheckmark: false,
          ),
      ]),
      const SizedBox(height: 12),
      if (items.isEmpty)
        PEmpty(_f == 'All' ? 'Nothing here yet. Coupons, gifts and opened chests show up here.' : 'No ${_f.toLowerCase()} right now.')
      else
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [for (final (kind, x) in items) _Tile(kind: kind, x: x)],
        ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.kind, required this.x});
  final String kind;
  final Map<String, dynamic> x;
  @override
  Widget build(BuildContext context) {
    final off = kind == 'Expired';
    final title = '${x['title'] ?? x['code'] ?? kind}';
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xEE111118),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: _title),
            const SizedBox(height: 6),
            Text('${x['detail'] ?? x['sub'] ?? kind}', style: _mist),
            if (sInt(x['expiresAt']) > 0) Text('${off ? 'Expired' : 'Expires'} ${shortDate(x['expiresAt'])}', style: _mist),
            if (x['code'] != null) ...[const SizedBox(height: 10), SelectableText('Code: ${x['code']}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))],
          ]),
        ),
      ),
      child: Opacity(
        opacity: off ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kind == 'Coupons' ? Colors.white : const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NwsbIcon(kind == 'Gifts' || kind == 'Chests' ? NwsbMarks.gift : NwsbMarks.rewards, size: 24, color: kind == 'Coupons' ? Colors.black : NwsbColors.goldLight),
            const Spacer(),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: kind == 'Coupons' ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
            Text(off ? 'Expired' : kind, style: TextStyle(color: kind == 'Coupons' ? const Color(0xFF666666) : NwsbColors.mist, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

List<Widget> rewardsMine(BuildContext context, Map<String, dynamic> s) => [LSection('mine', 'My Rewards', RewardsMine(s))];

/// First-use guide: a frosted card (Skip / Next pill + page dots), shown once.
class RewardsGuide extends StatefulWidget {
  const RewardsGuide({super.key});
  static const prefKey = 'rewards_guide_seen_v1';
  static const steps = [
    ('Check in daily', 'Tap Check in once a day to earn coins and grow your streak.'),
    ('Quests and chests', 'Finish quests and streak milestones to unlock chests.'),
    ('Coin Boost', 'A boost multiplies coins you earn for a while. It never changes the spend limit.'),
    ('Use your coins', 'Coins have no cash value. In the Coin Store or at checkout they cover only part of a price.'),
  ];
  @override
  State<RewardsGuide> createState() => _RewardsGuideState();
}

class _RewardsGuideState extends State<RewardsGuide> {
  bool _show = false;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted && p.getBool(RewardsGuide.prefKey) != true) setState(() => _show = true);
    });
  }

  Future<void> _close() async {
    setState(() => _show = false);
    (await SharedPreferences.getInstance()).setBool(RewardsGuide.prefKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final (t, b) = RewardsGuide.steps[_i];
    final last = _i == RewardsGuide.steps.length - 1;
    return PCard(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < RewardsGuide.steps.length; k++)
          Container(width: k == _i ? 18 : 6, height: 6, margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: k == _i ? Colors.white : const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(3))),
      ]),
      const SizedBox(height: 10),
      Text(t, style: _title),
      const SizedBox(height: 4),
      Text(b, style: _mist),
      const SizedBox(height: 10),
      Row(children: [
        TextButton(onPressed: _close, child: const Text('Skip', style: TextStyle(color: NwsbColors.mist))),
        const Spacer(),
        TextButton(
          onPressed: last ? _close : () => setState(() => _i++),
          style: TextButton.styleFrom(backgroundColor: Colors.white, shape: const StadiumBorder()),
          child: Text(last ? 'Got it' : 'Next', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        ),
      ]),
    ]);
  }
}
