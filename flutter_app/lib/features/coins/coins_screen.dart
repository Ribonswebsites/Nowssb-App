/// Coins: today's activities, earned vs left to earn, the daily caps (per
/// activity and overall), where coins came from and how to use them.
/// Every number comes from the server `summary` (EconomyMirror); nothing is
/// a default shown as live. Coins are never money: the Store rule below is
/// how much of a price they may cover, enforced by the server checkout.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  @override
  void initState() {
    super.initState();
    if (EconomyMirror.instance.uid != null) EconomyMirror.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Coins',
      showBalance: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([EconomyMirror.instance, FxBook.instance]),
        builder: (context, _) {
          final m = EconomyMirror.instance;
          if (m.uid == null) {
            return const Center(
              child: EconomyMessage(title: 'Sign in to see your coins', body: 'Coins are kept on your account, so they follow you to any phone.'),
            );
          }
          final s = m.summary;
          if (s['today'] is! Map) return const EconomySkeleton();
          return RefreshIndicator(
            onRefresh: m.refresh,
            child: CoinsBody(summary: s),
          );
        },
      ),
    );
  }
}

/// The page content for one server summary (split out so tests can render it).
class CoinsBody extends StatelessWidget {
  const CoinsBody({super.key, required this.summary});
  final Map<String, dynamic> summary;

  static const _gold = Color(0xFFE4C56A);
  static const _dim = Color(0xB3FFFFFF);

  Map get _today => (summary['today'] as Map?) ?? const {};
  Map get _config => (summary['config'] as Map?) ?? const {};
  int get _coins => ((summary['wallet'] as Map?)?['coins'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final earned = (_today['freeCoins'] as num?)?.toInt() ?? 0;
    final cap = ((_today['ceilingNow'] ?? _today['ceiling']) as num?)?.toInt() ?? 0;
    final acts = [
      for (final a in (_today['actions'] as List? ?? const []))
        if (a is Map && a['per'] != 'once' && a['per'] != 'month') a,
    ];
    final once = [
      for (final a in (_today['actions'] as List? ?? const []))
        if (a is Map && (a['per'] == 'once' || a['per'] == 'month') && ((a['done'] as num?) ?? 0) < ((a['limit'] as num?) ?? 1)) a,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        _hero(earned, cap),
        _section('Today\u2019s activities', [
          for (final a in acts) _activity(a),
          if (acts.isEmpty) const Text('No coin activities are switched on today.', style: TextStyle(color: _dim)),
        ]),
        if (_ladder.isNotEmpty) _section('Time in the app today', [for (final t in _ladder) _ladderRow(t)]),
        if (once.isNotEmpty) _section('One-time coins still open', [for (final a in once) _activity(a)]),
        _section('Where your coins came from', _sources()),
        _section('How to use coins', _uses(context)),
      ],
    );
  }

  Widget _hero(int earned, int cap) {
    final left = (cap - earned).clamp(0, cap);
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const NwsbCoinDisc(size: 52),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_coins', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 4),
            const Text('coins in your wallet', style: TextStyle(color: _dim, fontSize: 13)),
          ]),
        ]),
        if (cap > 0) ...[
          const SizedBox(height: 18),
          Row(children: [
            Text('Earned today $earned', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(left > 0 ? '$left left to earn' : 'Today\u2019s cap reached', style: const TextStyle(color: _dim, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          _bar(earned / cap),
          const SizedBox(height: 6),
          Text('Daily cap for activity coins: $cap', style: const TextStyle(color: _dim, fontSize: 12)),
        ],
      ]),
    );
  }

  static Widget _bar(double v) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: v.clamp(0.0, 1.0), minHeight: 4, color: _gold, backgroundColor: const Color(0x33FFFFFF)),
      );

  Widget _section(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GlassWrap(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: rows),
          ),
        ]),
      );

  Widget _activity(Map a) {
    final coins = (a['coins'] as num?)?.toInt() ?? 0;
    final limit = (a['limit'] as num?)?.toInt() ?? 1;
    final done = ((a['done'] as num?)?.toInt() ?? 0).clamp(0, limit);
    final per = '${a['per']}';
    final capText = switch (per) {
      'once' => 'once',
      'month' => '$limit a month',
      _ => '$done of $limit today',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(done >= limit ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18, color: done >= limit ? _gold : _dim),
          const SizedBox(width: 8),
          Expanded(child: Text('${a['title'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          Text('+$coins', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 26),
          Expanded(child: _bar(limit == 0 ? 0 : done / limit)),
          const SizedBox(width: 10),
          Text('${done * coins} of ${limit * coins} · $capText', style: const TextStyle(color: _dim, fontSize: 11)),
        ]),
      ]),
    );
  }

  List<Map> get _ladder {
    final steps = (_today['timeLadder'] as List? ?? const []).whereType<Map>().toList();
    return steps;
  }

  Widget _ladderRow(Map t) {
    final mins = (t['minutes'] as num?)?.toInt() ?? 0;
    final now = (_today['minutes'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(now >= mins ? Icons.check_circle_rounded : Icons.timer_outlined, size: 18, color: now >= mins ? _gold : _dim),
        const SizedBox(width: 8),
        Expanded(child: Text('$mins minutes', style: const TextStyle(color: Colors.white))),
        Text('+${t['coins']}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  static String reasonLabel(String r) {
    const names = {
      'login': 'Daily login', 'action': 'Activities', 'ladder': 'Time in the app', 'time': 'Time in the app',
      'quest': 'Quests', 'chest': 'Weekly chest', 'box': 'Gift boxes', 'scratch': 'Scratch cards', 'spin': 'Spin wheel',
      'gift': 'Gifts', 'ref': 'Referrals', 'season': 'Season', 'league': 'League', 'checkout': 'Spent in Store',
      'expired': 'Expired', 'reverse': 'Reversed', 'streak': 'Streak',
    };
    for (final e in names.entries) {
      if (r.startsWith(e.key)) return e.value;
    }
    return r.isEmpty ? 'Coins' : r[0].toUpperCase() + r.substring(1).replaceAll(RegExp(r'[_:-]'), ' ');
  }

  List<Widget> _sources() {
    final rows = (summary['recentCoins'] as List? ?? const []).whereType<Map>();
    final by = <String, int>{};
    for (final r in rows) {
      final d = (r['delta'] as num?)?.toInt() ?? 0;
      if (d > 0) by.update(reasonLabel('${r['reason'] ?? ''}'), (v) => v + d, ifAbsent: () => d);
    }
    if (by.isEmpty) return const [Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Coins you earn will be listed here by where they came from.', style: TextStyle(color: _dim)))];
    final list = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in list)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white))),
            Text('+${e.value}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
          ]),
        ),
      const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('From your latest coin activity.', style: TextStyle(color: _dim, fontSize: 11))),
    ];
  }

  List<Widget> _uses(BuildContext context) {
    final cart = (_config['cart'] as Map?) ?? const {};
    final perRupee = (_config['coinsPerRupee'] as num?)?.toDouble();
    final noCoupon = (cart['noCouponCoinPct'] as num?)?.toInt() ?? 30;
    final bands = (cart['coinCapBands'] as List? ?? const []).whereType<Map>().map((b) => (b['pct'] as num?)?.toInt() ?? 0).toList();
    final withCoupon = bands.isEmpty ? null : bands.reduce((a, b) => a > b ? a : b);
    final fx = FxBook.instance;
    Widget row(IconData i, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 18, color: _gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: _dim, fontSize: 13, height: 1.35)),
              ]),
            ),
          ]),
        );
    return [
      row(Icons.storefront_rounded, 'Store: up to $noCoupon% of a price',
          'Without a coupon, coins cover at most $noCoupon% of a Store price${withCoupon != null && withCoupon > noCoupon ? '; with a coupon, up to $withCoupon%' : ''}. You pay the rest.'
              '${perRupee != null && perRupee > 0 ? ' ${perRupee.round()} coins take ${fx.formatPrice(1, whole: true)} off.' : ''}'
              '${perRupee != null && perRupee > 0 && _coins > 0 ? ' Your coins can take up to ${fx.formatPrice((_coins / perRupee).floor(), whole: true)} off.' : ''}'),
      row(Icons.local_fire_department_rounded, 'Keep a streak', 'Repair a missed day with coins when the streak screen offers it.'),
      row(Icons.style_rounded, 'Scratch cards', 'Buy an extra scratch card with coins in Coupons.'),
      row(Icons.info_outline_rounded, 'Coins are not money', 'They can\u2019t be cashed out or sent, and expire after a long time without opening the app.'),
    ];
  }
}

/// Keeps the [NwsbColors] import honest for themes that read it.
const coinsGold = NwsbColors.gold;
