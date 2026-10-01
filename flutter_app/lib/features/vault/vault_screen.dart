import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/coupon_screen.dart';
import '../economy/scratch_card.dart';
import '../economy/play_billing.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../admin/template/editable.dart';
import '../../screens/subscription.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Rewards',
      mark: NwsbMarks.rewards,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              const BrandTopBanner(
                bare: true,
                title: 'NowssB Rewards',
                mark: NwsbMarks.rewards,
              ),
              const SizedBox(height: 12),
              const _TodayCard(),
              const SizedBox(height: 12),
              const FourBanners(
                splitTitle: 'NowssB Rewards',
                splitCta: 'Claim today’s coins',
                blackTitle: 'Your coins',
                blackSub: 'Earned only. At most 30% of a Play purchase.',
              ),
              const SizedBox(height: 12),
              CoinCount(value: w.coins),
              Text('${w.plan} · streak ${w.streak} · ${w.freezesLeft} freezes left', style: const TextStyle(color: NwsbColors.mist)),
              const SizedBox(height: 12),
              const EconomyNote(
                'Coins are earned. They cover at most 30% of a Play purchase. They cannot be bought, gifted, or cashed out.',
              ),
              const SizedBox(height: 12),
              const EconomyNote(
                'Invite a friend once. If they subscribe, you get one free month when you have no plan, or coins when you already do. No tiers and no ongoing percent — that lives in NowssB Earn.',
              ),
              const SizedBox(height: 18),
              const EditableLabel('vault_screen.VaultScreen', 'QUESTS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _quest(context, 'practice5', 'Practice 5 words', w.practice, 5, 25),
              _quest(context, 'streak3', 'Hold a 3-day streak', w.streak, 3, 30),
              _quest(context, 'listen1', 'Open the player', w.playerOpens, 1, 15),
              _quest(context, 'buy1', 'Complete one purchase', w.purchases, 1, 20),
              const SizedBox(height: 18),
              const BannerMix(seed: 4),
              const SizedBox(height: 18),
              const EditableLabel('vault_screen.VaultScreen', 'COIN SPENDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _spend(context, 'Streak freeze · 40', 'freeze'),
                    _spend(context, 'Practice credit · 15', 'practice'),
                    _spend(context, 'Early access · 50', 'early'),
                    _spend(context, 'Gold frame · 80', 'cosmetic', {'cosmeticId': 'frame_gold'}),
                    _spend(context, 'Verified buyer badge · 30', 'badge', {'badge': 'verified-buyer'}),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const EditableLabel('vault_screen.VaultScreen', 'PLAY PURCHASES', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _buy(context, 'Word', 'nwsb_word', 99, 'word', 'Word', NwsbMarks.word),
              _buy(context, 'Meaning', 'nwsb_meaning', 99, 'meaning', 'Meaning', NwsbMarks.meaning),
              _buy(context, '10-word bundle', 'nwsb_bundle_10', 999, 'bundle', '10-word bundle', NwsbMarks.book),
              _buy(context, 'Meaning package', 'nwsb_package', 399, 'package', 'Meaning package', NwsbMarks.ebook),
              BlackOffer(
                title: 'Plans',
                mark: NwsbMarks.crown,
                line: '0 of 1 · Resonance, Frequency, Frequency X',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                ),
              ),
              _buy(context, 'Restore streak', 'nwsb_streak_restore', 199, 'streak', 'Streak restore', NwsbMarks.flame),
              const SizedBox(height: 18),
              const EditableLabel('vault_screen.VaultScreen', 'MILESTONE CHEST', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              const _MilestoneForm(),
              const SizedBox(height: 12),
              Text('Practice credits ${w.practiceCredits}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  Widget _quest(BuildContext context, String id, String title, int value, int goal, int reward) {
    final frac = goal == 0 ? 0.0 : (value / goal).clamp(0, 1).toDouble();
    final left = (goal - value).clamp(0, goal);
    final done = value >= goal;
    final mark = switch (id) {
      'practice5' => NwsbMarks.stages,
      'streak3' => NwsbMarks.flame,
      'listen1' => NwsbMarks.sound,
      _ => NwsbMarks.bag,
    };
    return BlackOffer(
      title: title,
      mark: mark,
      progress: frac,
      line: '$value of $goal done · $left left · $reward coins',
      onTap: done
          ? () async {
              final before = EconomyMirror.instance.coins;
              var gained = 0;
              try {
                final result = await EconomyApi.call('claimQuest', {'questId': id});
                gained = (result['coins'] as num?)?.toInt() ?? reward;
              } on EconomyException catch (e) {
                if (!EconomyApi.isMissing(e)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                  return;
                }
                gained = await EconomyMirror.instance.grantOnce('quest_$id', reward, daily: false);
              }
              if (gained > 0 && context.mounted) {
                await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
              }
            }
          : null,
    );
  }

  Widget _spend(BuildContext context, String label, String purpose, [Map<String, dynamic>? extra]) {
    final cost = int.tryParse(label.split('·').last.trim()) ?? 0;
    final have = EconomyMirror.instance.coins;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () async {
          try {
            await EconomyApi.call('spendCoins', {'purpose': purpose, ...?extra});
          } on EconomyException catch (e) {
            if (!EconomyApi.isMissing(e) || !context.mounted) return;
            final ok = await EconomyMirror.instance.spendLocal(cost);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ok ? 'Spent $cost coins.' : 'Not enough coins.')),
            );
          }
        },
        child: GlassWrap(
          margin: EdgeInsets.zero,
          child: SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.split('·').first.trim(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$cost coins', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800)),
                Text(
                  have >= cost ? 'You have $have' : 'Need ${cost - have} more',
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buy(BuildContext context, String label, String catalogId, int price, String kind, String title, String mark) {
    return FutureBuilder<String>(
      future: PlayCheckout.priceLabel(catalogId),
      builder: (context, snap) {
        final priceLabel = snap.data ?? 'Play price';
        return BlackOffer(
          title: label,
          mark: mark,
          line: '0 of 1 · $priceLabel',
          onTap: () => runPrivate(context, () async {
            final quote = CashQuote.forPrice(
              price: price,
              balance: EconomyMirror.instance.coins,
              catalogId: catalogId,
            );
            await PlayCheckout.buy(
              callable: 'verifyPlayPurchase',
              productId: quote.productId,
              payload: {
                'catalogId': catalogId,
                'coins': quote.coins,
                'listPrice': price,
                'kind': kind,
                'title': title,
                'itemId': catalogId,
              },
            );
          }),
        );
      },
    );
  }
}

class _TodayCard extends StatefulWidget {
  const _TodayCard();

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  String? _note;

  Future<void> _claim() async {
    final before = EconomyMirror.instance.coins;
    try {
      final gained = await EconomyApi.claimToday();
      if (!mounted) return;
      final after = EconomyMirror.instance.coins;
      setState(() => _note = gained > 0
          ? '+$gained coins landed on this wallet.'
          : 'Today’s coins are already on the wallet.');
      if (gained > 0 && mounted) {
        await NwsbCoinFly.show(
          context,
          coins: gained,
          from: before,
          to: after,
        );
      }
    } on EconomyException catch (e) {
      if (!mounted) return;
      final raw = e.message.toUpperCase();
      setState(() => _note = raw.contains('NOT_FOUND')
          ? 'The wallet did not answer. Tap claim again.'
          : e.message);
    }
  }

  Future<void> _scratch() async {
    final coins = 12 + DateTime.now().day % 18;
    final before = EconomyMirror.instance.coins;
    var gained = 0;
    try {
      final result = await EconomyApi.call('scratchCoupon');
      gained = (result['coins'] as num?)?.toInt() ?? 0;
    } on EconomyException catch (e) {
      if (!EconomyApi.isMissing(e)) {
        if (mounted) setState(() => _note = e.message);
        return;
      }
      gained = await EconomyMirror.instance.grantOnce('scratch', coins);
    }
    if (!mounted || gained <= 0) return;
    await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
  }

  @override
  Widget build(BuildContext context) {
    final w = EconomyMirror.instance;
    final claimed = w.loginToday;
    return GlassWrap(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NwsbCoinDisc(size: 36),
              const SizedBox(width: 8),
              Text(
                '${w.coins}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              const Text('coins', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'streak ${w.streak}',
                style: const TextStyle(color: Color(0xB3FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            claimed
                ? 'Today’s coins are already on this wallet.'
                : 'Tap claim. The coins fly after that, not before.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Text(
            w.scratchToday ? 'Today’s coupon is open.' : 'Today’s coupon is still sealed.',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
          ),
          if (_note != null) ...[
            const SizedBox(height: 8),
            Text(_note!, style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          GoldButton(
            label: claimed ? 'Collected' : 'Claim today’s coins',
            onTap: claimed ? null : _claim,
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: 'Open today’s coupon',
            filled: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CouponScreen()),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'SCRATCH',
            style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (w.scratchToday)
            const Text(
              'Today’s coupon is already open.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            )
          else
            NwsbScratchCard(
              onCleared: _scratch,
              prize: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NwsbCoinDisc(size: 64),
                  const SizedBox(height: 8),
                  Text(
                    '+${12 + DateTime.now().day % 18}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'NOWSSB COINS',
                    style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'GIFT',
            style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const GiftOpenCard(),
        ],
      ),
    );
  }
}

class _MilestoneForm extends StatefulWidget {
  const _MilestoneForm();

  @override
  State<_MilestoneForm> createState() => _MilestoneFormState();
}

class _MilestoneFormState extends State<_MilestoneForm> {
  final _word = TextEditingController();
  int _level = 1;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _word,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Word id',
            hintStyle: TextStyle(color: NwsbColors.mist),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _level.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_level',
                onChanged: (v) => setState(() => _level = v.round()),
              ),
            ),
            Text('Lv $_level', style: const TextStyle(color: NwsbColors.goldLight)),
          ],
        ),
        GoldButton(
          label: 'Open chest · ${_level * 5} coins',
          filled: false,
          onTap: () async {
            final word = _word.text.trim();
            if (word.isEmpty) return;
            final reward = _level * 5;
            final before = EconomyMirror.instance.coins;
            var gained = 0;
            try {
              final result = await EconomyApi.call('claimMilestone', {
                'wordId': word,
                'level': _level,
              });
              gained = (result['coins'] as num?)?.toInt() ?? reward;
            } on EconomyException catch (e) {
              if (!EconomyApi.isMissing(e)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
                return;
              }
              gained = await EconomyMirror.instance.grantOnce('chest_${word}_$_level', reward, daily: false);
            }
            if (gained > 0 && context.mounted) {
              await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
            }
          },
        ),
      ],
    );
  }
}
