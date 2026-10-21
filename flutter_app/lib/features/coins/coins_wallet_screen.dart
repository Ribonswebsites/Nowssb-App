import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/earn_wallet.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/store.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../economy/daily_claim_sheet.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../programs/program_router.dart';
import '../../widgets/n_motion.dart';
import '../../screens/fashion/header.dart';
import '../../widgets/black_glass_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../nowssb_ui/app_video_backdrop.dart';
import '../../nowssb_ui/sheets_popups.dart';

/// Coin cap: coins can cover at most this share of a price (spec 18.1: 30-40%).
const double kCoinCapFraction = EarnWallet.maxCoinFraction;

/// Coins are a loyalty points balance, never money. They cannot be cashed out
/// or transferred, and are kept apart from the cash Earnings page.
const String kCoinsNotMoney =
    'Coins are reward points, not money. They cannot be cashed out, sold or '
    'transferred, and can only cover part of a price in the NowssB store.';

enum CoinsTab { overview, earn, use, history }

/// Snapshot the wallet UI reads; built from the live server mirror by default
/// and injectable for tests.
class CoinsData {
  const CoinsData({
    required this.signedIn,
    required this.coins,
    required this.claimedToday,
    required this.streak,
    this.history = const [],
    this.expiring = const [],
    this.boostPct = 0,
    this.boostUntil = 0,
  });

  final bool signedIn;
  final int coins;
  final bool claimedToday;
  final int streak;
  final List<EarnActivity> history;
  final List<(int coins, int at)> expiring;
  final int boostPct;
  final int boostUntil;

  static CoinsData live() {
    final m = EconomyMirror.instance;
    final s = m.summary;
    final exp = <(int, int)>[];
    final raw = s['coinExpiry'] ?? s['expiring'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final c = (e['coins'] as num?)?.toInt() ?? 0;
          final at = (e['at'] as num?)?.toInt() ?? 0;
          if (c > 0 && at > 0) exp.add((c, at));
        }
      }
    }
    exp.sort((a, b) => a.$2.compareTo(b.$2));
    final boost = s['coinBoost'];
    return CoinsData(
      signedIn: m.uid != null,
      coins: m.coins,
      claimedToday: m.loginToday,
      streak: m.streak,
      history: List.of(EarnWallet.instance.activity.where((a) => a.coins != 0)),
      expiring: exp,
      boostPct: boost is Map ? ((boost['pct'] as num?)?.toInt() ?? 0) : 0,
      boostUntil: boost is Map ? ((boost['until'] as num?)?.toInt() ?? 0) : 0,
    );
  }
}

class CoinsWalletScreen extends StatefulWidget {
  const CoinsWalletScreen({super.key, this.initialTab = CoinsTab.overview, this.data, this.showGuide = true});

  final CoinsTab initialTab;

  /// Test hook; null means read the live server mirror.
  final CoinsData? data;
  final bool showGuide;

  @override
  State<CoinsWalletScreen> createState() => _CoinsWalletScreenState();
}

class _CoinsWalletScreenState extends State<CoinsWalletScreen> {
  late CoinsTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    if (widget.showGuide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowCoinsGuide(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NAppBackdrop(child: EconomyPage(
      title: 'Coins',
      goodToKnow: kCoinsNotMoney,
      showBalance: false,
      // Home's own top bar; its menu button opens the coins guide here.
      header: HomeHeader(key: const Key('coinsHelp'), onMenu: () => showCoinsGuide(context)),
      child: ListenableBuilder(
        listenable: Listenable.merge([EconomyMirror.instance, EarnWallet.instance]),
        builder: (context, _) {
          final d = widget.data ?? CoinsData.live();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _HeroCard(data: d, onTab: _go),
              const SizedBox(height: 14),
              _Tabs(tab: _tab, onTab: _go),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(key: ValueKey(_tab), child: _body(d)),
              ),
            ],
          );
        },
      ),
    ));
  }

  void _go(CoinsTab t) => setState(() => _tab = t);

  Widget _body(CoinsData d) {
    switch (_tab) {
      case CoinsTab.overview:
        return _Overview(data: d, onTab: _go);
      case CoinsTab.earn:
        return _Earn(data: d);
      case CoinsTab.use:
        return _Use(coins: d.coins);
      case CoinsTab.history:
        return _History(data: d);
    }
  }
}

// ── Frosted pieces (approved meditation-card style) ─────────────────────────

class CoinsGlass extends StatelessWidget {
  const CoinsGlass({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 28, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kNotifGlassSigma, sigmaY: kNotifGlassSigma),
        child: Material(
          color: const Color(0x8C05060A),
          shape: RoundedRectangleBorder(borderRadius: r, side: const BorderSide(color: Color(0x26FFFFFF))),
          child: InkWell(onTap: onTap, borderRadius: r, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.onTap, this.filled = true, super.key});
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : const Color(0x22FFFFFF),
      shape: StadiumBorder(side: BorderSide(color: filled ? Colors.transparent : const Color(0x55FFFFFF))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: filled ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}

const _title = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800);
const _body2 = TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4);

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.onTab});
  final CoinsData data;
  final ValueChanged<CoinsTab> onTab;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiring = data.expiring.where((e) => e.$2 > now).fold<int>(0, (a, e) => a + e.$1);
    return CoinsGlass(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Column(
        children: [
          GestureDetector(onTap: () => _coinInfo(context), child: const NwsbCoinDisc(size: 128)),
          const SizedBox(height: 18),
          Text(data.signedIn ? 'Your NowssB coins' : 'Sign in to see your coins', style: _title),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(children: [
              Expanded(
                child: _BigStat(
                  label: 'Balance',
                  child: TweenAnimationBuilder<double>(
                    key: const Key('coinsBalance'),
                    tween: Tween(begin: 0, end: data.coins.toDouble()),
                    duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('${v.round()}', style: _huge),
                  ),
                ),
              ),
              const VerticalDivider(color: Color(0x33FFFFFF), thickness: 1, width: 24),
              Expanded(child: _BigStat(label: 'Expiring soon', child: Text('$expiring', key: const Key('heroExpiring'), style: _huge))),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _Pill('Use', key: const Key('heroUse'), filled: false, onTap: () => showUseSheet(context, data.coins))),
            const SizedBox(width: 10),
            Expanded(child: _Pill('Earn', key: const Key('heroEarn'), onTap: () => showEarnSheet(context, data))),
          ]),
          const SizedBox(height: 8),
          TextButton(key: const Key('heroHistory'), onPressed: () => onTab(CoinsTab.history), child: const Text('See history', style: TextStyle(color: Color(0xCCFFFFFF)))),
          if (!data.signedIn) _Pill('Sign in', onTap: () => NwsbSignInPage.open(context)),
        ],
      ),
    );
  }
}

const _huge = TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1.05);

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(children: [
        FittedBox(child: child),
        const SizedBox(height: 4),
        Text(label, style: _body2),
      ]);
}

/// SBI-style sheet: big coin, huge stats split by a divider, Close / primary buttons.
Future<void> _heroSheet(BuildContext context, {required String title, required String body, required (String, String) left, required (String, String) right, required String primary, required VoidCallback onPrimary, Key? key}) =>
    showGlassSheet<void>(
      context,
      accent: const Color(0xFFE4C56A),
      builder: (c) => Column(key: key, mainAxisSize: MainAxisSize.min, children: [
        const NwsbCoinDisc(size: 120),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: _body2),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _BigStat(label: left.$2, child: Text(left.$1, style: _huge))),
            const VerticalDivider(color: Color(0x33FFFFFF), thickness: 1, width: 24),
            Expanded(child: _BigStat(label: right.$2, child: Text(right.$1, style: _huge))),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _Pill('Close', filled: false, onTap: () => Navigator.of(c).pop())),
          const SizedBox(width: 10),
          Expanded(child: _Pill(primary, onTap: () {
            Navigator.of(c).pop();
            onPrimary();
          })),
        ]),
      ]),
    );

Future<void> showEarnSheet(BuildContext context, CoinsData d) => _heroSheet(
      context,
      key: const Key('earnSheet'),
      title: d.claimedToday ? 'Today is claimed' : 'Collect today\'s coins',
      body: 'Check in daily and keep your streak to earn more.',
      left: ('${d.streak}', 'Day streak'),
      right: (d.claimedToday ? 'Done' : 'Ready', 'Check-in'),
      primary: d.claimedToday ? 'More ways' : 'Claim',
      onPrimary: () {
        if (!d.signedIn) {
          NwsbSignInPage.open(context);
        } else if (!d.claimedToday) {
          DailyClaimSheet.offer(context, mounted: () => context.mounted);
        } else {
          Programmes.open(context, Programme.rewards);
        }
      },
    );

Future<void> showUseSheet(BuildContext context, int coins) {
  final pct = (kCoinCapFraction * 100).round();
  return _heroSheet(
    context,
    key: const Key('useSheet'),
    title: 'Use coins at checkout',
    body: 'Coins cover up to $pct% of a price in the NowssB store. The rest is paid normally.',
    left: ('$coins', 'Your coins'),
    right: ('$pct%', 'Max per price'),
    primary: 'Shop',
    onPrimary: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoreScreen())),
  );
}

void _coinInfo(BuildContext context) {
  showNSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: CoinsGlass(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const NwsbCoinDisc(size: 56),
          const SizedBox(height: 10),
          const Text('NowssB coin', style: _title),
          const SizedBox(height: 6),
          Text('$kCoinsNotMoney Coins can cover up to ${(kCoinCapFraction * 100).round()}% of a price.', style: _body2, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _Pill('Got it', onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onTab});
  final CoinsTab tab;
  final ValueChanged<CoinsTab> onTab;

  static const _labels = {CoinsTab.overview: 'Overview', CoinsTab.earn: 'Earn', CoinsTab.use: 'Use', CoinsTab.history: 'History'};

  @override
  Widget build(BuildContext context) {
    return CoinsGlass(
      radius: 30,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final t in CoinsTab.values)
            Expanded(
              child: GestureDetector(
                key: Key('coinsTab_${t.name}'),
                onTap: () => onTab(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(color: t == tab ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(24)),
                  child: Text(_labels[t]!, textAlign: TextAlign.center, style: TextStyle(color: t == tab ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _date(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class _Overview extends StatelessWidget {
  const _Overview({required this.data, required this.onTab});
  final CoinsData data;
  final ValueChanged<CoinsTab> onTab;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final boostLive = data.boostPct > 0 && data.boostUntil > now;
    final soon = data.expiring.where((e) => e.$2 > now).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoinsGlass(
          key: const Key('coinBoost'),
          // Coin Boost lives in Rewards (its owner); this banner only links there.
          onTap: () => Programmes.open(context, Programme.rewards, tab: 'boost'),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(boostLive ? 'Coin Boost +${data.boostPct}%' : 'Coin Boost', style: _title),
                const SizedBox(height: 4),
                Text(boostLive ? 'Every coin you earn counts extra until ${_date(data.boostUntil)}.' : 'No boost running right now. Tap to open Coin Boost in Rewards.', style: _body2),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        CoinsGlass(
          key: const Key('coinExpiry'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Expiring soon', style: _title),
            const SizedBox(height: 6),
            if (soon.isEmpty)
              const Text('None of your coins are about to expire.', style: _body2)
            else
              for (final e in soon.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const NwsbCoinDisc(size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${e.$1} coins expire on ${_date(e.$2)}', style: _body2)),
                  ]),
                ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: _Pill('Use them', onTap: () => onTab(CoinsTab.use))),
          ]),
        ),
        const SizedBox(height: 12),
        BlackGlassBanner(
          title: 'Coin rules',
          subtitle: 'What coins are and how the cap works.',
          mark: NwsbMarks.book,
          margin: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CoinRulesPage())),
        ),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner.forSurface(SplitPromoSurface.normalHome, margin: EdgeInsets.zero, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoreScreen()))),
      ],
    );
  }
}

class _Earn extends StatelessWidget {
  const _Earn({required this.data});
  final CoinsData data;

  @override
  Widget build(BuildContext context) {
    Widget row(String title, String body, String action, VoidCallback onTap, {Key? key}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CoinsGlass(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: _title),
              const SizedBox(height: 4),
              Text(body, style: _body2),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: _Pill(action, key: key, onTap: onTap)),
            ]),
          ),
        );
    return Column(children: [
      row('Daily check-in', data.claimedToday ? 'Claimed today. Come back tomorrow.' : 'Open the app each day to collect your daily coins. Streak: ${data.streak} days.',
          data.claimedToday ? 'Done' : 'Claim', () {
        if (!data.signedIn) {
          NwsbSignInPage.open(context);
          return;
        }
        if (!data.claimedToday) DailyClaimSheet.offer(context, mounted: () => context.mounted);
      }, key: const Key('earnClaim')),
      row('Rewards quests', 'Practice, streaks and quests pay coins.', 'Open', () => Programmes.open(context, Programme.rewards)),
      row('Scratch cards', 'Scratch a coupon card for a chance at coins.', 'Open', () => Programmes.open(context, Programme.coupons)),
      row('Invite friends', 'Share your link from NowssB Reference.', 'Open', () => Programmes.open(context, Programme.reference)),
    ]);
  }
}

/// Coin-cap calculator: coins cover at most [kCoinCapFraction] of a price.
class _Use extends StatefulWidget {
  const _Use({required this.coins});
  final int coins;
  @override
  State<_Use> createState() => _UseState();
}

class _UseState extends State<_Use> {
  final _ctl = TextEditingController(text: '500');

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = int.tryParse(_ctl.text.trim()) ?? 0;
    final q = coinQuote(price, widget.coins);
    final pct = (kCoinCapFraction * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CoinsGlass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Coin cap calculator', style: _title),
          const SizedBox(height: 4),
          Text('Coins can cover up to $pct% of an item price, in price points. The rest is paid normally.', style: _body2),
          const SizedBox(height: 12),
          TextField(
            key: const Key('capPrice'),
            controller: _ctl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Item price (points)',
              labelStyle: _body2,
              filled: true,
              fillColor: const Color(0x18FFFFFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          _line('Most coins allowed ($pct%)', '${q.maxCoins}'),
          _line('Coins you would use', '${q.coins}', key: const Key('capUse')),
          _line('Left to pay', '${q.cash}', key: const Key('capRest')),
        ]),
      ),
      const SizedBox(height: 12),
      _Pill('Shop in the store', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StoreScreen()))),
    ]);
  }

  Widget _line(String a, String b, {Key? key}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(child: Text(a, style: _body2)),
          Text(b, key: key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
      );
}

/// Pure cap math: at most [kCoinCapFraction] of [price], limited by [have].
({int maxCoins, int coins, int cash}) coinQuote(int price, int have) {
  final p = price < 0 ? 0 : price;
  final cap = (p * kCoinCapFraction).floor();
  final use = have < cap ? (have < 0 ? 0 : have) : cap;
  return (maxCoins: cap, coins: use, cash: p - use);
}

class _History extends StatelessWidget {
  const _History({required this.data});
  final CoinsData data;

  @override
  Widget build(BuildContext context) {
    if (!data.signedIn) return const CoinsGlass(child: Text('Sign in to see your coin history.', style: _body2));
    if (data.history.isEmpty) {
      return const CoinsGlass(child: Text('No coin activity yet. Earned and used coins show up here.', style: _body2, key: Key('historyEmpty')));
    }
    return CoinsGlass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        for (final a in data.history.take(50))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const NwsbCoinDisc(size: 30),
            title: Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            subtitle: Text('${a.detail.isEmpty ? '' : '${a.detail} · '}${_date(a.at)}', style: _body2),
            trailing: Text(a.coins > 0 ? '+${a.coins}' : '${a.coins}', style: TextStyle(color: a.coins > 0 ? Colors.white : const Color(0xFFFFB4B4), fontWeight: FontWeight.w800)),
            onTap: () => showNDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(a.title),
                content: Text('${a.coins > 0 ? '+' : ''}${a.coins} coins\n${a.detail}\n${_date(a.at)}'),
                actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))],
              ),
            ),
          ),
      ]),
    );
  }
}

/// Sub-page: plain rules for coins.
class CoinRulesPage extends StatelessWidget {
  const CoinRulesPage({super.key});

  static const rules = <(String, String)>[
    ('What coins are', kCoinsNotMoney),
    ('Earning', 'Daily check-ins, streaks, quests and scratch cards add coins. Amounts are set by NowssB and shown before you claim.'),
    ('Using', 'At checkout, coins can cover part of a price, up to the cap shown in the calculator.'),
    ('Expiry', 'Some coins expire. Any coins close to expiring are listed on the Overview tab.'),
    ('Coin Boost', 'Coin Boost is part of NowssB Rewards. During a boost, earned coins count extra; it never raises the spend cap.'),
  ];

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Coin rules',
      showBalance: false,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        for (final (t, b) in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CoinsGlass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: _title), const SizedBox(height: 4), Text(b, style: _body2)])),
          ),
      ]),
    );
  }
}

// ── First-use guide ─────────────────────────────────────────────────────────

const kCoinsGuideKey = 'coins.guide.seen.v1';
const kCoinsGuideSteps = <(String, String)>[
  ('Your coins', 'Your balance sits at the top. Tap the coin any time for what coins are.'),
  ('Earn', 'Claim your daily check-in and finish quests to collect coins.'),
  ('Use', 'Coins can cover part of a price. The calculator shows exactly how much.'),
  ('History', 'Every coin earned or used is listed here, with expiry notices on Overview.'),
];

Future<void> maybeShowCoinsGuide(BuildContext context) async {
  try {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(kCoinsGuideKey) == true || !context.mounted) return;
    await p.setBool(kCoinsGuideKey, true);
    if (context.mounted) await showCoinsGuide(context);
  } catch (_) {}
}

Future<void> showCoinsGuide(BuildContext context) => showNDialog<void>(context: context, barrierColor: const Color(0x66000000), builder: (_) => const CoinsGuide());

class CoinsGuide extends StatefulWidget {
  const CoinsGuide({super.key});
  @override
  State<CoinsGuide> createState() => _CoinsGuideState();
}

class _CoinsGuideState extends State<CoinsGuide> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final (title, body) = kCoinsGuideSteps[_i];
    final last = _i == kCoinsGuideSteps.length - 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Material(
          color: Colors.transparent,
          child: CoinsGlass(
            radius: 32,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const NwsbCoinDisc(size: 72),
              const SizedBox(height: 16),
              Text(title, key: const Key('coinsGuideTitle'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: _body2),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var k = 0; k < kCoinsGuideSteps.length; k++)
                  Container(margin: const EdgeInsets.all(3), width: k == _i ? 16 : 6, height: 6, decoration: BoxDecoration(color: k == _i ? Colors.white : const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(3))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Skip', style: TextStyle(color: Color(0xCCFFFFFF)))),
                const Spacer(),
                _Pill(last ? 'Done' : 'Next', onTap: () => last ? Navigator.of(context).pop() : setState(() => _i++)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
