/// NowssB Rewards hub, new UI (spec 14.3). Page-local glass pieces live in
/// rewards_glass.dart until Bug Hunter's shared kit (14.2) is on main.
library;

import 'package:flutter/material.dart';

import '../../widgets/app_backdrop.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import 'rewards_data.dart';
import 'rewards_glass.dart';

class RewardsNewUiPage extends StatefulWidget {
  const RewardsNewUiPage({super.key, this.loader = loadRewardsFromServer, this.onOpen, this.background});
  final RewardsLoader loader;

  /// Called with a destination id ('checkin', 'streaks', 'quests', 'chests',
  /// 'boost', 'store', 'coins', 'earn'); wired to AppRoutes once it exists.
  final void Function(String id)? onOpen;

  /// Defaults to the app's shared AppBackdrop; tests pass its poster.
  final Widget? background;

  @override
  State<RewardsNewUiPage> createState() => _RewardsNewUiPageState();
}

class _RewardsNewUiPageState extends State<RewardsNewUiPage> {
  late Future<RewardsData> _future = widget.loader();
  String _filter = 'All';

  void _reload() {
    final f = widget.loader();
    setState(() {
      _future = f;
    });
  }

  void _open(String id) => widget.onOpen?.call(id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RGlass.bgBottom,
      body: Stack(children: [
        Positioned.fill(child: widget.background ?? const AppBackdrop()),
        SafeArea(
          child: FutureBuilder<RewardsData>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(key: Key('rewards.loading')));
              }
              if (snap.hasError) {
                final offline = snap.error is RewardsOffline;
                return RStateMessage(
                  key: Key(offline ? 'rewards.offline' : 'rewards.error'),
                  icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  title: offline ? 'You\u2019re offline' : 'Rewards didn\u2019t load',
                  body: offline ? 'Connect to the internet to see your coins and rewards.' : 'Something went wrong on our side.',
                  action: 'Try again',
                  onAction: _reload,
                );
              }
              return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future.catchError((_) => RewardsData.fromSummary(const {}));
                  },
                  child: _hub(snap.data!));
            },
          ),
        ),
      ]),
    );
  }

  Widget _hub(RewardsData d) {
    final shown = d.items
        .where((i) => switch (_filter) {
              'Coupons' => i.kind == RewardKind.coupon && !i.expired,
              'Gifts' => i.kind == RewardKind.gift && !i.expired,
              'Chests' => i.kind == RewardKind.chest && !i.expired,
              'Expired' => i.expired,
              _ => true,
            })
        .toList();
    return CustomScrollView(key: const Key('rewards.scroll'), slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            if (Navigator.of(context).canPop()) const BackButton(color: Colors.white),
            const Expanded(child: Text('Rewards', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))),
            RCoinChip(coins: d.coins, onTap: () => _open('coins')),
          ]),
          const SizedBox(height: 12),
          const RHeroCarousel(slides: [
            ('Check in daily', 'Keep your streak glowing'),
            ('Finish quests', 'Small steps, steady coins'),
            ('Open chests', 'Milestones hold surprises'),
            ('Boost your coins', 'Earn faster, same fair caps'),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RShortcutTile(icon: Icons.event_available_rounded, label: 'Daily\nCheck-in', dot: !d.checkedInToday, onTap: () => _open('checkin')),
            RShortcutTile(icon: Icons.local_fire_department_rounded, label: 'Streaks\n${d.streak} days', onTap: () => _open('streaks')),
            RShortcutTile(icon: Icons.flag_rounded, label: 'Quests\n${d.questsOpen} open', onTap: () => _open('quests')),
            RShortcutTile(icon: Icons.inventory_2_rounded, label: 'Chests\n${d.chestsReady} ready', dot: d.chestsReady > 0, onTap: () => _open('chests')),
            RShortcutTile(icon: Icons.bolt_rounded, label: 'Coin\nBoost', onTap: () => _open('boost')),
          ]),
          const SizedBox(height: 16),
          if (d.dealTitle != null) ...[
            RDealStrip(title: d.dealTitle!, endsAt: d.dealEndsAt, onTap: () => _open('store')),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 150,
            child: Row(children: [
              Expanded(child: RTallCard(title: 'Coin Store', body: 'Earn coins back on words, bundles and e-books', onTap: () => _open('store'))),
              const SizedBox(width: 12),
              const Expanded(child: RTallCard(title: 'Tomorrow\u2019s chest', body: 'Unlocks tomorrow', locked: true)),
            ]),
          ),
          const SizedBox(height: 12),
          RArrowBar(label: 'Earn & Save', onTap: () => _open('earn')),
          const SizedBox(height: 8),
          Text('Coins have no cash value and can cover only part of a price. Boosts speed up earning, never the spend cap.',
              style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 11)),
          const SizedBox(height: 20),
          const Text('MY REWARDS', style: TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
          const SizedBox(height: 8),
          RFilterChips(options: const ['All', 'Coupons', 'Gifts', 'Chests', 'Expired'], selected: _filter, onSelect: (f) => setState(() => _filter = f)),
          const SizedBox(height: 12),
        ]),
      ),
      if (shown.isEmpty)
        SliverToBoxAdapter(
          child: RStateMessage(
            key: const Key('rewards.empty'),
            icon: Icons.card_giftcard_rounded,
            title: _filter == 'All' ? 'No rewards yet' : 'Nothing here',
            body: 'Check in today to start earning coins and rewards.',
            action: d.checkedInToday ? null : 'Check in',
            onAction: () => _open('checkin'),
            compact: true,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.separated(
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, k) => RGiftTile(item: shown[k]),
          ),
        ),
    ]);
  }
}
