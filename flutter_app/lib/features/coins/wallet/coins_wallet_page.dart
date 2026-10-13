import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import '../../../widgets/app_backdrop.dart';
import 'coins_wallet_data.dart';
import '../../../nowssb_ui/nowssb_ui.dart';
import '../../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;


/// Lighter inner frosted panel (reference card's lower text card).
class _InnerPanel extends StatelessWidget {
  const _InnerPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: .14),
          border: Border.all(color: Colors.white.withValues(alpha: .28)),
        ),
        child: child,
      );
}

/// NowssB Coins wallet (spec §18.1). Behind `newui_coins` (see coins_flag.dart).
class CoinsWalletPage extends StatefulWidget {
  const CoinsWalletPage({super.key, required this.source, this.onOpenBoost, this.backdrop});
  final CoinsWalletSource source;
  final VoidCallback? onOpenBoost;
  /// Background override for tests only; the app always uses the shared [AppBackdrop].
  final Widget? backdrop;
  @override
  State<CoinsWalletPage> createState() => _CoinsWalletPageState();
}

enum _Phase { loading, ready, error, offline }

class _CoinsWalletPageState extends State<CoinsWalletPage> {
  _Phase _phase = _Phase.loading;
  CoinsWalletState? _s;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final s = await widget.source.load();
      if (!mounted) return;
      setState(() {
        _s = s;
        _phase = _Phase.ready;
      });
    } on SocketException {
      if (mounted) setState(() => _phase = _Phase.offline);
    } on TimeoutException {
      if (mounted) setState(() => _phase = _Phase.offline);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NowssB Coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(key: const Key('coins_help'), tooltip: 'How coins work', icon: const Icon(Icons.help_outline),
              onPressed: () => _info(context, 'Coins', 'Earn coins every day, spend up to 35% of any price, and use them before they expire.')),
          IconButton(tooltip: 'History', icon: const Icon(Icons.history),
              onPressed: _s == null ? null : () => _openHistory(context)),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        Positioned.fill(child: widget.backdrop ?? const AppBackdrop()),
        SafeArea(child: _body(context)),
      ]),
    );
  }

  Widget _body(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator(key: Key('coins_loading')));
      case _Phase.error:
      case _Phase.offline:
        final off = _phase == _Phase.offline;
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: NGlass(radius: 28,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(off ? Icons.wifi_off : Icons.error_outline, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(off ? "You're offline. Your coins are safe." : "Couldn't load your coins.",
                key: Key(off ? 'coins_offline' : 'coins_error'), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            NGlass(radius: 999, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onTap: _load, child: const Text('Try again', style: TextStyle(color: Colors.white))),
          ]))));
      case _Phase.ready:
        final s = _s!;
        return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          _hero(s),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _bigButton('Earn', Icons.add_circle_outline, const Key('coins_earn'), () => _openEarn(context))),
            const SizedBox(width: 10),
            Expanded(child: _bigButton('Use', Icons.shopping_bag_outlined, const Key('coins_use'), () => _openUse(context, s))),
            const SizedBox(width: 10),
            Expanded(child: _bigButton('History', Icons.receipt_long, const Key('coins_history'), () => _openHistory(context))),
          ]),
          const SizedBox(height: 16),
          if (s.expiringSoon > 0 && s.expiresOn != null) _expiryStrip(s),
          if (s.balance == 0 && s.ledger.isEmpty)
            const NGlass(key: Key('coins_empty'), child: Text(
                'No coins yet. Tap Earn: check in today for your first coins.',
                style: TextStyle(color: Colors.white))),
          const SizedBox(height: 16),
          NGlass(key: const Key('coins_boost'), radius: NTokens.rCard, onTap: widget.onOpenBoost,
            child: Row(children: [
              const SizedBox(width: 4),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Coin Boost', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Earn coins faster. Your spend cap stays the same.',
                    style: TextStyle(color: NTokens.textLo, fontSize: 12, height: 1.4)),
              ])),
              GlassPill(label: 'Open', style: PillStyle.white, dense: true, onTap: widget.onOpenBoost),
            ])),
        ]));
    }
  }

  Widget _hero(CoinsWalletState s) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final sub = [
      if (s.worthLabel != null) 'Worth up to ${s.worthLabel} off your next purchase.',
      '1 coin = ${s.currency}${s.coinValue.toStringAsFixed(2)} · up to ${s.capPercent}% of a price.',
    ].join(' ');
    return TweenAnimationBuilder<int>(
      key: const Key('coins_hero'),
      tween: IntTween(begin: 0, end: s.balance),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      // Approved card (UI Design MeditationCard); the round image is the app's own coin.
      builder: (_, v, __) => _CoinMeditationCard(
        title: '$v coins',
        subtitle: sub,
        secondary: 'How to earn',
        onSecondary: () => _openEarn(context),
        cta: 'Use coins',
        onCta: () => _openUse(context, s),
      ),
    );
  }

  Widget _bigButton(String label, IconData icon, Key key, VoidCallback onTap) => NGlass(key: key, radius: 24,
        onTap: onTap, padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(width: double.infinity, child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])));

  Widget _expiryStrip(CoinsWalletState s) {
    final d = s.expiresOn!;
    final days = d.difference(DateTime.now()).inDays;
    return NGlass(key: const Key('coins_expiry'), radius: NTokens.rBox,
        child: Text('${s.expiringSoon} coins expire on ${d.year}-${_two(d.month)}-${_two(d.day)} '
            '(${days < 0 ? 0 : days} days left). Use them in time.', style: const TextStyle(color: Colors.white)));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  void _info(BuildContext ctx, String title, String body) => showDialog<void>(context: ctx, builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))]));

  Future<void> _sheet(BuildContext ctx, Widget child) => showModalBottomSheet<void>(context: ctx,
      isScrollControlled: true, backgroundColor: Colors.transparent, elevation: 0,
      builder: (_) => SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + MediaQuery.of(ctx).viewInsets.bottom),
          child: NGlass(radius: 36, blur: NTokens.blurSheet, padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(child: child)))));

  void _openEarn(BuildContext ctx) {
    const rows = [
      ('Daily check-in', 'Check in today, +10 coins'),
      ('Streak', 'Keep a 7-day streak, +50 coins'),
      ('Quests', 'Finish a quest, coins shown on each quest'),
      ('Milestone chests', 'Open a chest when you hit a milestone'),
      ('Free coupon rewards', 'Buy anything, scratch your free coupon'),
      ('Partner targets', 'Reach a Partner target for bonus coins'),
      ('Referral', 'Invite a friend who buys, earn coins'),
    ];
    _sheet(ctx, Column(key: const Key('coins_earn_sheet'), mainAxisSize: MainAxisSize.min, children: [
      const Text('Ways to earn', style: TextStyle(color: Colors.white, fontSize: 20)),
      for (final r in rows) Padding(padding: const EdgeInsets.only(top: 8), child: NGlass(
          child: Row(children: [const Icon(Icons.circle, color: Colors.white70, size: 8), const SizedBox(width: 10),
            Expanded(child: Text('${r.$1}: ${r.$2}', style: const TextStyle(color: Colors.white)))]))),
    ]));
  }

  void _openUse(BuildContext ctx, CoinsWalletState s) => _sheet(ctx, _UseCalculator(state: s));

  void _openHistory(BuildContext ctx) => _sheet(ctx, _History(entries: _s?.ledger ?? const []));
}

class _UseCalculator extends StatefulWidget {
  const _UseCalculator({required this.state});
  final CoinsWalletState state;
  @override
  State<_UseCalculator> createState() => _UseCalculatorState();
}

class _UseCalculatorState extends State<_UseCalculator> {
  double _price = 10;
  @override
  Widget build(BuildContext context) {
    final c = CoinCalc.of(price: _price, balance: widget.state.balance, capPercent: widget.state.capPercent,
        coinValue: widget.state.coinValue);
    return Column(key: const Key('coins_use_sheet'), mainAxisSize: MainAxisSize.min, children: [
      Text('Coins can cover up to ${widget.state.capPercent}% of a price',
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 12),
      NGlass(child: TextField(key: const Key('coins_price_field'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Item price', border: InputBorder.none),
          onChanged: (v) => setState(() => _price = double.tryParse(v) ?? 0))),
      const SizedBox(height: 12),
      NGlass(radius: NTokens.rBox, child: Text(
          'Coins you can use: ${c.coinsUsable}, You pay: ${widget.state.currency}${c.youPay.toStringAsFixed(2)}',
          key: const Key('coins_calc_result'), style: const TextStyle(color: Colors.white))),
      const SizedBox(height: 6),
      const Text('Final price is confirmed at checkout.', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

class _History extends StatefulWidget {
  const _History({required this.entries});
  final List<LedgerEntry> entries;
  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  LedgerKind? _filter;
  @override
  Widget build(BuildContext context) {
    final list = widget.entries.where((e) => _filter == null || e.kind == _filter).toList();
    return Column(key: const Key('coins_history_sheet'), mainAxisSize: MainAxisSize.min, children: [
      Wrap(spacing: 8, children: [
        for (final f in <LedgerKind?>[null, ...LedgerKind.values])
          GlassPill(key: Key('coins_filter_${f?.name ?? 'all'}'),
              label: f == null ? 'All' : '${f.name[0].toUpperCase()}${f.name.substring(1)}',
              style: _filter == f ? PillStyle.white : PillStyle.glass, dense: true,
              onTap: () => setState(() => _filter = f)),
      ]),
      const SizedBox(height: 8),
      if (list.isEmpty) const Padding(padding: EdgeInsets.all(16),
          child: Text('Nothing here yet.', key: Key('coins_history_empty'), style: TextStyle(color: Colors.white70))),
      ConstrainedBox(constraints: const BoxConstraints(maxHeight: 360), child: ListView(shrinkWrap: true, children: [
        for (final e in list) Padding(padding: const EdgeInsets.only(top: 6), child: NGlass(radius: NTokens.rBox,
            child: Row(children: [
              Expanded(child: Text(e.label, style: const TextStyle(color: Colors.white))),
              Text('${e.kind == LedgerKind.earned ? '+' : '-'}${e.amount}',
                  style: TextStyle(color: e.kind == LedgerKind.earned ? Colors.white : NTokens.textLo, fontWeight: FontWeight.w700)),
            ]))),
      ])),
    ]);
  }
}

/// Same structure, radii, spacing and type as the kit's approved
/// [MeditationCard], but the round slot holds the app's own coin widget
/// ([NwsbCoinDisc], with its built-in fallback) instead of an ImageProvider.
/// Swap to MeditationCard if the kit gains a `leading` widget slot.
class _CoinMeditationCard extends StatelessWidget {
  const _CoinMeditationCard({required this.title, required this.subtitle, required this.secondary,
      required this.cta, this.onCta, this.onSecondary});
  final String title, subtitle, secondary, cta;
  final VoidCallback? onCta, onSecondary;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rHero, blur: NTokens.blurLarge, padding: const EdgeInsets.all(18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 140, height: 140, alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08),
                border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2)),
            child: const NwsbCoinDisc(size: 104)),
        const SizedBox(height: 20),
        NGlass(radius: NTokens.rCard, elevation: .3, padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: NTokens.textLo, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: GestureDetector(onTap: onSecondary, child: Text(secondary, maxLines: 1,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)))),
                const SizedBox(width: 8),
                GlassPill(label: cta, style: PillStyle.white, dense: true, onTap: onCta),
              ]),
            ])),
      ]));
}
