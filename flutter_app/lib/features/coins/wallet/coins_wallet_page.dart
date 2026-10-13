import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'coins_wallet_data.dart';
import 'coins_wallet_glass.dart';

const _gold = Color(0xFFE0A526);
const _violet = Color(0xFFB39DFF);

/// NowssB Coins wallet (spec §18.1). Behind `newui_coins` (see coins_flag.dart).
class CoinsWalletPage extends StatefulWidget {
  const CoinsWalletPage({super.key, required this.source, this.onOpenBoost});
  final CoinsWalletSource source;
  final VoidCallback? onOpenBoost;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NowssB Coins'),
        actions: [
          IconButton(key: const Key('coins_help'), tooltip: 'How coins work', icon: const Icon(Icons.help_outline),
              onPressed: () => _info(context, 'Coins', 'Earn coins every day, spend up to 35% of any price, and use them before they expire.')),
          IconButton(tooltip: 'History', icon: const Icon(Icons.history),
              onPressed: _s == null ? null : () => _openHistory(context)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1F4F), Color(0xFF4B3A8C), Color(0xFF1B1533)])),
        child: SafeArea(child: _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator(key: Key('coins_loading')));
      case _Phase.error:
      case _Phase.offline:
        final off = _phase == _Phase.offline;
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: CoinsGlass(radius: 28,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(off ? Icons.wifi_off : Icons.error_outline, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(off ? "You're offline. Your coins are safe." : "Couldn't load your coins.",
                key: Key(off ? 'coins_offline' : 'coins_error'), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            CoinsGlass(radius: 999, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            const CoinsGlass(key: Key('coins_empty'), child: Text(
                'No coins yet. Tap Earn: check in today for your first coins.',
                style: TextStyle(color: Colors.white))),
          const SizedBox(height: 16),
          CoinsGlass(key: const Key('coins_boost'), radius: 28, accent: _gold, onTap: widget.onOpenBoost,
            child: const Row(children: [
              Icon(Icons.bolt, color: _gold, size: 32), SizedBox(width: 12),
              Expanded(child: Text('Coin Boost: earn coins faster. Your spend cap stays the same.',
                  style: TextStyle(color: Colors.white))),
              Icon(Icons.chevron_right, color: Colors.white),
            ])),
        ]));
    }
  }

  Widget _hero(CoinsWalletState s) => CoinsGlass(radius: 30, blur: 22, accent: _gold, padding: const EdgeInsets.all(24),
        child: Column(children: [
          const LotusCoin(size: 72),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: s.balance),
            duration: const Duration(milliseconds: 900),
            builder: (_, v, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$v', key: const Key('coins_balance'),
                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700)),
              IconButton(icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  onPressed: () => _info(context, 'Coin balance',
                      'Coins you can spend now. Example: price \$10, coins cover up to \$3.50, you pay \$6.50.')),
            ]),
          ),
          const Text('coins', style: TextStyle(color: Colors.white70)),
          if (s.worthLabel != null) ...[
            const SizedBox(height: 6),
            Text('Worth up to ${s.worthLabel} off your next purchase', style: const TextStyle(color: Colors.white)),
          ],
        ]));

  Widget _bigButton(String label, IconData icon, Key key, VoidCallback onTap) => CoinsGlass(key: key, radius: 24,
        accent: _violet, onTap: onTap, padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]));

  Widget _expiryStrip(CoinsWalletState s) {
    final d = s.expiresOn!;
    final days = d.difference(DateTime.now()).inDays;
    return CoinsGlass(key: const Key('coins_expiry'), accent: Colors.orange,
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
      isScrollControlled: true, backgroundColor: const Color(0xFF231A44),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 16, 16,
          16 + MediaQuery.of(ctx).viewInsets.bottom), child: child)));

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
      for (final r in rows) Padding(padding: const EdgeInsets.only(top: 8), child: CoinsGlass(
          child: Row(children: [const Icon(Icons.circle, color: _gold, size: 10), const SizedBox(width: 10),
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
    final c = CoinCalc.of(price: _price, balance: widget.state.balance, capPercent: widget.state.capPercent);
    return Column(key: const Key('coins_use_sheet'), mainAxisSize: MainAxisSize.min, children: [
      Text('Coins can cover up to ${widget.state.capPercent}% of a price',
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 12),
      CoinsGlass(child: TextField(key: const Key('coins_price_field'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Item price', border: InputBorder.none),
          onChanged: (v) => setState(() => _price = double.tryParse(v) ?? 0))),
      const SizedBox(height: 12),
      CoinsGlass(accent: _gold, child: Text(
          'Coins you can use: ${c.coinsUsable}, You pay: \$${c.youPay.toStringAsFixed(2)}',
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
          ChoiceChip(key: Key('coins_filter_${f?.name ?? 'all'}'), label: Text(f == null ? 'All' : f.name),
              selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
      ]),
      const SizedBox(height: 8),
      if (list.isEmpty) const Padding(padding: EdgeInsets.all(16),
          child: Text('Nothing here yet.', key: Key('coins_history_empty'), style: TextStyle(color: Colors.white70))),
      ConstrainedBox(constraints: const BoxConstraints(maxHeight: 360), child: ListView(shrinkWrap: true, children: [
        for (final e in list) Padding(padding: const EdgeInsets.only(top: 6), child: CoinsGlass(
            child: Row(children: [
              Expanded(child: Text(e.label, style: const TextStyle(color: Colors.white))),
              Text('${e.kind == LedgerKind.earned ? '+' : '-'}${e.amount}',
                  style: TextStyle(color: e.kind == LedgerKind.earned ? _gold : Colors.white60)),
            ]))),
      ])),
    ]);
  }
}
