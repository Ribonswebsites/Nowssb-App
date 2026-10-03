/// NowssB Rewards (Plan B 4): Today · Quests · Streaks · Mastery · Season ·
/// Leagues · Wallet · Spend · Badges. Every number is the server's.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../admin/layout/layout_sections.dart';
import '../economy/economy_api.dart';
import '../economy/play_billing.dart';
import '../economy/reward_fx.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../vault/vault_screen.dart';

const kRewardsDisclaimer =
    'Coins have no cash value. They cannot be bought, sold, transferred or exchanged for money, and they expire after 12 '
    'months of inactivity. They can cover only part of a purchase. Rewards, limits and events may change with notice.';

const kRewardsSpec = ProgramSpec(
  pageId: 'rewards.program',
  title: 'NowssB Rewards',
  mark: NwsbMarks.rewards,
  disclaimer: kRewardsDisclaimer,
  accent: ProgramAccent.rewards,
  tabs: [
    ProgramTab('today', 'Today', _today),
    ProgramTab('quests', 'Quests', _quests),
    ProgramTab('streaks', 'Streaks', _streaks),
    ProgramTab('mastery', 'Mastery', _mastery),
    ProgramTab('season', 'Season', _season),
    ProgramTab('leagues', 'Leagues', _leagues),
    ProgramTab('wallet', 'Wallet', _wallet),
    ProgramTab('spend', 'Spend', _spend),
    ProgramTab('badges', 'Badges', _badges),
  ],
);

/// Kept for every existing entry point: opens the one Rewards page.
class RewardsProgramPage extends StatelessWidget {
  const RewardsProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => VaultScreen(
        initialTab: initialTab == null ? null : kRewardsSpec.tabs[initialTab!.clamp(0, kRewardsSpec.tabs.length - 1)].id,
      );
}

Map<String, dynamic> _cfg(Map<String, dynamic> s) => sMap(s['config']);
Map<String, dynamic> _r(Map<String, dynamic> s) => sMap(_cfg(s)['rewards']);

List<Widget> _today(BuildContext context, Map<String, dynamic> s) {
  final w = sMap(s['wallet']);
  final t = sMap(s['today']);
  final ladder = sList(t['ladder']);
  final actions = sList(t['actions']);
  final free = sInt(t['freeCoins']);
  final ceiling = sInt(t['ceiling']);
  return [
    LSection('balance', 'Balance', PBalance(coins: sInt(w['coins']), caption: 'Streak ${sInt(w['streak'])} days · best ${sInt(w['bestStreak'])}')),
    LSection.group('login', 'Daily login', [
      const PHeading('Every day', 'Daily login', slot: 'rewards_program.today'),
      PCard(children: [
        PRow(
          title: t['login'] == true ? 'Collected today' : 'Today\u2019s login',
          sub: t['login'] == true ? 'Come back tomorrow for day ${sInt(w['streak']) + 1}.' : '+${sInt(w['nextLogin'])} coins · day ${sInt(w['streak']) + 1} of your streak',
          coin: true,
          trailing: PClaim(label: t['login'] == true ? 'Done' : 'Collect', action: 'claimDailyLogin', enabled: t['login'] != true, title: 'Daily login'),
        ),
        PProgress(value: free, goal: ceiling <= 0 ? 1 : ceiling, label: 'Free coins today $free / $ceiling (daily ceiling)'),
      ]),
    ]),
    LSection.group('time', 'Time ladder', [
      const PHeading('Time in the app', 'Time ladder', slot: 'rewards_program.today'),
      PCard(children: [
        PProgress(value: sInt(t['minutes']), goal: ladder.isEmpty ? 60 : sInt(ladder.last['minutes']), label: '${sInt(t['minutes'])} minutes today'),
        for (final st in ladder)
          PRow(
            title: '${sInt(st['minutes'])} minutes',
            sub: '+${sInt(st['coins'])} coins${st['box'] != null ? ' · ${st['box']} box' : ''}',
            mark: NwsbMarks.hourglass,
            trailing: st['claimed'] == true
                ? const PPill('Claimed', color: NwsbColors.goldLight)
                : PClaim(label: 'Claim', action: 'claimTimeStep', data: {'minutes': sInt(st['minutes'])}, enabled: st['reached'] == true, title: 'Time ladder'),
          ),
        const SizedBox(height: 6),
        PRow(
          title: t['boxOpened'] != null ? 'Today\u2019s gift box is open' : 'Today\u2019s free gift box',
          sub: 'The best box your minutes reached. One a day.',
          mark: NwsbMarks.gift,
          trailing: PClaim(label: 'Open', action: 'openDailyBox', enabled: t['boxOpened'] == null, title: 'Today\u2019s gift'),
        ),
      ]),
    ]),
    LSection.group('actions', 'More ways to earn', [
      const PHeading('More ways to earn', 'Daily activities', slot: 'rewards_program.today'),
      PCard(children: [
        for (final a in actions)
          PRow(
            title: '${a['title']}',
            sub: '+${sInt(a['coins'])} coins · ${a['per'] == 'once' ? 'once' : a['per'] == 'key' ? 'per item' : a['per'] == 'month' ? 'monthly' : '${sInt(a['done'])}/${sInt(a['limit'])} today'}',
            coin: true,
            trailing: (a['per'] == 'once' && sInt(a['done']) > 0) || (a['per'] == 'day' && sInt(a['done']) >= sInt(a['limit']))
                ? const PPill('Done', color: NwsbColors.goldLight)
                : const PPill('In the app'),
          ),
        const PEmpty('Activities count on their own as you use the app — the coins land as soon as you do them.', slot: 'rewards_program.today'),
      ]),
    ]),
  ];
}

List<Widget> _quests(BuildContext context, Map<String, dynamic> s) {
  final q = sMap(s['quests']);
  final starter = sList(q['starter']);
  final weekly = sList(q['weekly']);
  final chest = sMap(q['chest']);
  final wg = sMap(q['weeklyGift']);
  final mq = sMap(q['monthly']);
  final mg = sMap(q['monthlyGift']);
  Widget quest(Map<String, dynamic> x, String action, Map<String, dynamic> data) {
    final done = sNum(x['value']) >= sNum(x['goal']);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PRow(
        title: '${x['title']}',
        sub: '+${sInt(x['coins'])} coins${x['coupon'] != null ? ' · ${rarityTitle('${x['coupon']}')} scratch card' : ''}',
        mark: NwsbMarks.rewards,
        trailing: x['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: action, data: data, enabled: done, title: '${x['title']}'),
      ),
      PProgress(value: sNum(x['value']), goal: sNum(x['goal'])),
    ]);
  }

  return [
    if (starter.any((x) => x['claimed'] != true))
      LSection.group('starter', 'Starter quests', [
        const PHeading('New here', 'Starter quests', slot: 'rewards_program.quests'),
        PCard(children: [for (final x in starter) quest(x, 'claimQuest', {'kind': 'starter', 'id': x['id']})]),
      ]),
    LSection.group('weekly', 'Weekly quests', [
      const PHeading('This week', 'Weekly quests', slot: 'rewards_program.quests'),
      PCard(children: [
        for (final x in weekly) quest(x, 'claimQuest', {'kind': 'weekly', 'id': x['id']}),
        const Divider(color: Color(0x22FFFFFF)),
        PRow(
          title: 'Weekly chest',
          sub: 'Finish every weekly quest to open it.',
          mark: NwsbMarks.gift,
          trailing: chest['open'] == true ? const PPill('Opened', color: NwsbColors.goldLight) : PClaim(label: 'Open', action: 'claimWeeklyChest', enabled: chest['ready'] == true, title: 'Weekly chest'),
        ),
        PRow(
          title: 'Weekly gift',
          sub: '${sInt(wg['daysAt20'])} days with 20+ minutes this week',
          mark: NwsbMarks.gift,
          trailing: wg['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimWeeklyGift', enabled: wg['ready'] == true, title: 'Weekly gift'),
        ),
      ]),
    ]),
    LSection.group('monthly', 'Monthly', [
      const PHeading('This month', 'Monthly quest and gift', slot: 'rewards_program.quests'),
      PCard(children: [
        if (mq.isNotEmpty) quest(mq, 'claimQuest', {'kind': 'monthly', 'id': mq['id']}),
        PRow(
          title: 'Monthly gift',
          sub: '${sInt(mg['activeDays'])} of ${sInt(mg['goal'])} active days',
          mark: NwsbMarks.gift,
          trailing: mg['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimMonthlyGift', enabled: sInt(mg['activeDays']) >= sInt(mg['goal']) && sInt(mg['goal']) > 0, title: 'Monthly gift'),
        ),
        PProgress(value: sInt(mg['activeDays']), goal: sInt(mg['goal']) == 0 ? 1 : sInt(mg['goal'])),
        PRow(title: 'Monthly mark', sub: 'Coins for each full week you practised this month.', mark: NwsbMarks.crown, trailing: const PClaim(label: 'Claim', action: 'claimMonthlyMark', title: 'Monthly mark')),
      ]),
    ]),
  ];
}

List<Widget> _streaks(BuildContext context, Map<String, dynamic> s) {
  final w = sMap(s['wallet']);
  final R = _r(s);
  final ms = sList(R['streakMilestones']);
  final broken = sMap(w['brokenStreak']);
  final restore = sMap(R['streakRestore']);
  final streak = sInt(w['streak']);
  return [
    LSection('streak', 'Streak', PCard(glow: const Color(0xFFFF8A3D), children: [
      Row(children: [
        const NwsbIcon(NwsbMarks.flame, size: 40, color: Color(0xFFFFA24C)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CountUp(streak, suffix: ' days', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            Text('Best ${sInt(w['bestStreak'])} · holds ${sInt(w['holds'])} · freezes ${sInt(w['freezes'])} · restores ${sInt(w['restores'])}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ]),
        ),
      ]),
    ])),
    if (broken.isNotEmpty)
      LSection('restore', 'Restore streak', PCard(children: [
        PRow(title: 'Bring back your ${sInt(broken['value'])}-day streak', sub: 'Within ${sInt(restore['maxMissedDays'])} days of the break. Use a Streak Restore, or ${sInt(restore['coinsPart'])} coins.', mark: NwsbMarks.flame),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (sInt(w['restores']) > 0) const PClaim(label: 'Use a Restore', action: 'restoreStreak', title: 'Streak restored'),
          PClaim(label: 'Use ${sInt(restore['coinsPart'])} coins', action: 'restoreStreak', data: const {'withCoins': true}, filled: false, title: 'Streak restored'),
          _BuyButton(label: 'Buy a Restore', checkout: {'kind': 'product', 'productId': '${restore['productId'] ?? 'nowssb_streak_restore'}'}, after: 'restoreStreak'),
        ]),
      ])),
    LSection.group('milestones', 'Milestones', [
      const PHeading('Streak milestones', 'Never ending', slot: 'rewards_program.streaks'),
      PCard(children: [
        for (final m in ms)
          PRow(
            title: 'Day ${sInt(m['day'])}',
            sub: '+${sInt(m['coins'])} coins${m['coupon'] != null ? ' · ${rarityTitle('${m['coupon']}')} card' : ''}${m['badge'] != null ? ' · badge' : ''}',
            mark: NwsbMarks.flame,
            trailing: streak >= sInt(m['day']) ? const PPill('Reached', color: NwsbColors.goldLight) : PPill('${sInt(m['day']) - streak} to go'),
          ),
        const PEmpty('After day 365 the ladder keeps going: every 100 days adds a milestone. A hold is earned every 14 days and covers one missed day.', slot: 'rewards_program.streaks'),
      ]),
    ]),
  ];
}

List<Widget> _mastery(BuildContext context, Map<String, dynamic> s) {
  final R = _r(s);
  final m = sMap(R['mastery']);
  final sets = sList(R['sets']);
  return [
    LSection.group('how', 'Mastery', [
      const PHeading('Practice to master', 'Word mastery', slot: 'rewards_program.mastery'),
      PCard(children: [
        PRow(title: '+${sInt(m['coinsPerLevel'])} coins per mastery level', sub: 'A word levels up as your pronunciation scores rise in the practice player. Up to ${sInt(m['maxLevelUpsPerDay'])} level-ups a day.', mark: NwsbMarks.word),
        PRow(title: 'Level ${sInt(m['chestAtLevel'])} chest', sub: '${rarityTitle('${m['chestCoupon']}')} scratch card when a word reaches level ${sInt(m['chestAtLevel'])}.', mark: NwsbMarks.gift),
      ]),
    ]),
    LSection.group('sets', 'Word sets', [
      const PHeading('Collections', 'Word sets', slot: 'rewards_program.mastery'),
      PCard(children: [
        for (final x in sets)
          PRow(title: '${x['title']}', sub: '${(x['words'] as List?)?.join(', ') ?? ''} · +${sInt(x['coins'])} coins and a badge when every word reaches level 5', mark: NwsbMarks.book),
        if (sets.isEmpty) const PEmpty('No sets this season yet.'),
      ]),
    ]),
  ];
}

List<Widget> _season(BuildContext context, Map<String, dynamic> s) {
  final se = sMap(s['season']);
  final tier = sInt(se['tier']);
  final tiers = sInt(se['tiers']);
  final per = sInt(se['xpPerTier']);
  final xp = sInt(se['xp']);
  final claimed = ((se['claimed'] as List?) ?? const []).map((e) => '$e').toSet();
  final premium = se['premium'] == true;
  final id = '${se['id'] ?? ''}';
  return [
    LSection('header', 'Season', PCard(glow: const Color(0xFFC08BFF), children: [
      Text('${se['title'] ?? 'Season'}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      Text('Tier $tier of $tiers · $xp XP · ends ${'${se['endsAt'] ?? ''}'.split('T').first}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
      PProgress(value: per == 0 ? 0 : xp % per, goal: per == 0 ? 1 : per, label: 'XP to the next tier'),
      const PEmpty('Free coins you earn are your season XP. Plan holders also unlock the premium track.', slot: 'rewards_program.season'),
    ])),
    LSection('tiers', 'Tiers', PCard(children: [
      for (var n = 1; n <= tiers; n++)
        PRow(
          title: 'Tier $n',
          sub: 'Free ${20 + 5 * n} coins${n % 5 == 0 ? ' + ${n >= 25 ? 'Epic' : n >= 15 ? 'Rare' : 'Common'} card' : ''} · Premium ${(20 + 5 * n) * 2} coins${n % 10 == 0 ? ' + gift box' : ''}',
          mark: NwsbMarks.rewards,
          trailing: Wrap(spacing: 6, children: [
            claimed.contains('$id:f:$n') ? const PPill('Free ✓', color: NwsbColors.goldLight) : PClaim(label: 'Free', action: 'claimSeason', data: {'tier': n}, enabled: n <= tier, title: 'Season tier $n'),
            if (premium) claimed.contains('$id:p:$n') ? const PPill('Plan ✓', color: NwsbColors.goldLight) : PClaim(label: 'Plan', action: 'claimSeason', data: {'tier': n, 'premium': true}, enabled: n <= tier, filled: false, title: 'Season tier $n'),
          ]),
        ),
    ])),
  ];
}

List<Widget> _leagues(BuildContext context, Map<String, dynamic> s) {
  final L = sMap(_r(s)['leagues']);
  return [
    LSection('board', 'League board', ServerView(
      action: 'league',
      builder: (context, r, reload) {
        final top = sList(r['top']);
        return PCard(children: [
          Text('${r['title'] ?? 'League'} league', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(sInt(r['rank']) > 0 ? 'You are #${sInt(r['rank'])} of ${sInt(r['size'])} · ${sInt(r['xp'])} XP this week' : 'Earn free coins this week to join the board.', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          const SizedBox(height: 8),
          for (final row in top)
            PRow(title: '#${sInt(row['rank'])} ${row['name'] ?? 'Listener'}${row['me'] == true ? ' (you)' : ''}', trailing: Text('${sInt(row['xp'])} XP', style: const TextStyle(color: NwsbColors.goldLight))),
          if (top.isEmpty) const PEmpty('Nobody is on this week\u2019s board yet.'),
          const SizedBox(height: 6),
          const Align(alignment: Alignment.centerLeft, child: PClaim(label: 'Claim last week\u2019s prize', action: 'claimLeague', title: 'League prize')),
        ]);
      },
    )),
    LSection('rules', 'League rules', PRules([
      'Weekly leagues by free coins earned: ${((L['tiers'] as List?) ?? const []).map((t) => sMap(L['titles'])['$t'] ?? t).join(' → ')}.',
      'Top ${sInt(L['promoteTop'])} move up; under ${sInt(L['demoteBelowXp'])} XP moves down.',
      'Prizes for places 1–10: ${((L['prizes'] as List?) ?? const []).join(', ')} coins.',
    ], slot: 'rewards_program.leagues')),
  ];
}

List<Widget> _wallet(BuildContext context, Map<String, dynamic> s) {
  final w = sMap(s['wallet']);
  final uid = EconomyMirror.instance.uid;
  return [
    LSection('balance', 'Balance', PBalance(coins: sInt(w['coins']), caption: 'Lifetime ${sInt(w['lifetimeCoins'])} coins · coins back bonus +${sInt(w['coinsBackBonusPct'])}%')),
    LSection('ledger', 'Coin ledger', PCard(children: [
      const PHeading('Append-only', 'Coin ledger', slot: 'rewards_program.wallet'),
      if (!NwsbFirebase.ready || uid == null)
        const PEmpty('Sign in to see the ledger.')
      else
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ledger(uid),
          builder: (context, snap) {
            final docs = [...?snap.data?.docs]..sort((a, b) => sInt(b.data()['at']).compareTo(sInt(a.data()['at'])));
            if (docs.length > 40) docs.removeRange(40, docs.length);
            if (docs.isEmpty) return const PEmpty('Nothing here yet. Every coin in or out shows here.');
            return Column(children: [
              for (final d in docs)
                PRow(
                  title: _reason('${d.data()['reason'] ?? ''}'),
                  sub: shortDate(d.data()['at']),
                  trailing: Text('${sInt(d.data()['delta']) > 0 ? '+' : ''}${sInt(d.data()['delta'])}', style: TextStyle(color: sInt(d.data()['delta']) >= 0 ? NwsbColors.goldLight : const Color(0xFFFF8A8A), fontWeight: FontWeight.w800)),
                ),
            ]);
          },
        ),
    ])),
  ];
}

// One ledger stream per account, not a new listener on every rebuild.
final _ledgers = <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};
Stream<QuerySnapshot<Map<String, dynamic>>> _ledger(String uid) => _ledgers.putIfAbsent(
    uid, () => FirebaseFirestore.instance.collection('coinLedger').where('uid', isEqualTo: uid).limit(200).snapshots().asBroadcastStream());

String _reason(String r) {
  if (r.startsWith('act:')) return 'Activity · ${r.substring(4).replaceAll('_', ' ')}';
  if (r.startsWith('spend:')) return 'Spent · ${r.substring(6).replaceAll('_', ' ')}';
  if (r.startsWith('season')) return 'Season reward';
  if (r.startsWith('league')) return 'League prize';
  if (r.startsWith('time-')) return 'Time ladder';
  if (r.startsWith('reverse')) return 'Refund reversal';
  if (r.isEmpty) return 'Coins';
  return r.replaceAll('-', ' ').replaceAll('_', ' ').replaceAll(':', ' · ');
}

List<Widget> _spend(BuildContext context, Map<String, dynamic> s) {
  final spend = sMap(_r(s)['spend']);
  final w = sMap(s['wallet']);
  final have = ((w['cosmetics'] as List?) ?? const []).map((e) => '$e').toSet();
  return [
    LSection('balance', 'Balance', PBalance(coins: sInt(w['coins']), caption: 'Coins never buy cash. In a cart they cover part of the price.')),
    LSection('items', 'Spend coins', PCard(children: [
      for (final e in spend.entries)
        PRow(
          title: '${sMap(e.value)['title']}',
          sub: '${sInt(sMap(e.value)['coins'])} coins',
          coin: true,
          trailing: have.contains('${sMap(e.value)['cosmetic']}')
              ? const PPill('Owned', color: NwsbColors.goldLight)
              : PClaim(label: 'Get', action: 'spendCoins', data: {'item': e.key}, enabled: sInt(w['coins']) >= sInt(sMap(e.value)['coins']), title: '${sMap(e.value)['title']}'),
        ),
    ])),
    LSection('scratch', 'Scratch cards for coins', const PEmpty('Scratch cards can also be bought with coins in Coupons → Coupon Shop.', slot: 'rewards_program.spend')),
  ];
}

List<Widget> _badges(BuildContext context, Map<String, dynamic> s) {
  final badges = sList(s['badges']);
  final got = badges.where((b) => b['have'] == true).length;
  return [
    LSection('count', 'Badges', PCard(children: [
      Text('$got of ${badges.length} badges', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      PProgress(value: got, goal: badges.isEmpty ? 1 : badges.length),
    ])),
    LSection('grid', 'Badge grid', GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        for (final b in badges)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: b['have'] == true ? NwsbColors.goldLight : const Color(0x22FFFFFF)),
              boxShadow: b['have'] == true ? [BoxShadow(color: NwsbColors.gold.withValues(alpha: 0.3), blurRadius: 14)] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              NwsbIcon(NwsbMarks.rewards, size: 24, color: b['have'] == true ? NwsbColors.goldLight : const Color(0x55FFFFFF)),
              const SizedBox(height: 6),
              Text('${b['title'] ?? ''}', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: b['have'] == true ? Colors.white : const Color(0x88FFFFFF), fontSize: 11, fontWeight: FontWeight.w700)),
              if (b['have'] != true && sInt(b['goal']) > 0) Text('${sInt(b['value'])}/${sInt(b['goal'])}', style: const TextStyle(color: NwsbColors.mist, fontSize: 10)),
            ]),
          ),
      ],
    )),
  ];
}

/// Buys a Play product, then optionally runs a follow-up action.
class _BuyButton extends StatefulWidget {
  const _BuyButton({required this.label, required this.checkout, this.after});
  final String label;
  final Map<String, dynamic> checkout;
  final String? after;
  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> {
  var _busy = false;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  final r = await PlayCheckout.purchase(widget.checkout);
                  if (!context.mounted) return;
                  await celebrate(context, r, title: 'Thank you');
                  if (widget.after != null && context.mounted) await runReward(context, () => EconomyApi.call(widget.after!, {}));
                } catch (e) {
                  if (context.mounted) showEconomyError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: Text(_busy ? 'Waiting for Play…' : widget.label, style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

/// Public so other programs can reuse the Play buy button.
class PlayBuyButton extends _BuyButton {
  const PlayBuyButton({required super.label, required super.checkout, super.after});
}
