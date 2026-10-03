import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/coupon_screen.dart';
import '../economy/play_billing.dart';
import '../economy/reward_fx.dart';
import '../programs/program_kit.dart';
import '../programs/rewards_program.dart';
import '../programs/program_heroes.dart';
import '../programs/program_router.dart';
import '../../data/practice_progress.dart';
import '../../shell/nwsb_links.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../admin/template/editable.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key, this.initialTab});

  /// Opens the Rewards page scrolled to one programme tab (e.g. 'wallet').
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kRewardsDisclaimer,
      title: 'NowssB Rewards',
      mark: NwsbMarks.rewards,
      child: _VaultBody(initialTab: initialTab),
    );
  }
}

class _VaultBody extends StatefulWidget {
  const _VaultBody({this.initialTab});
  final String? initialTab;
  @override
  State<_VaultBody> createState() => _VaultBodyState();
}

class _VaultBodyState extends State<_VaultBody> {
  final _go = ValueNotifier<void Function(String)?>(null);

  @override
  void dispose() {
    _go.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        const RewardsHero(),
        const SizedBox(height: 12),
        BrandTopBanner(
          bare: true,
          title: 'NowssB Rewards',
          mark: NwsbMarks.rewards,
          onTap: () => _go.value?.call('today'),
        ),
        const SizedBox(height: 12),
        const _TodayCard(),
        const SizedBox(height: 12),
        const FourBanners(
          current: Programme.rewards,
          splitTitle: 'NowssB Rewards',
          splitCta: 'Claim today’s coins',
          blackTitle: 'Your coins',
          blackSub: 'Earned only. At most 30% of a Play purchase.',
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: EconomyMirror.instance,
          builder: (context, _) {
            final w = EconomyMirror.instance;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CoinCount(value: w.coins),
              Text('${w.plan} · streak ${w.streak} · ${w.freezesLeft} freezes left', style: const TextStyle(color: NwsbColors.mist)),
            ]);
          },
        ),
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
        const _StarterQuests(),
        const SizedBox(height: 18),
        const BannerMix(seed: 4),
        const SizedBox(height: 18),
        const EditableLabel('vault_screen.VaultScreen', 'COIN SPENDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        const _SpendRail(),
        const SizedBox(height: 18),
        const EditableLabel('vault_screen.VaultScreen', 'PLAY PURCHASES', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        BlackOffer(title: 'Words', mark: NwsbMarks.word, line: 'Every word, priced on Google Play', onTap: () => NwsbLinks.tab(context, 3)),
        BlackOffer(title: 'Meanings', mark: NwsbMarks.meaning, line: 'The meaning store', onTap: () => NwsbLinks.meanings(context)),
        BlackOffer(title: 'Ebooks', mark: NwsbMarks.ebook, line: 'The ebook store', onTap: () => NwsbLinks.ebooks(context)),
        BlackOffer(
          title: 'Plans',
          mark: NwsbMarks.crown,
          line: 'Resonance, Frequency, Frequency X',
          onTap: () => NwsbLinks.subscription(context),
        ),
        const _PlayBuy(label: 'Restore streak', catalogId: 'nwsb_streak_restore', mark: NwsbMarks.flame),
        const SizedBox(height: 18),
        const EditableLabel('vault_screen.VaultScreen', 'MILESTONE CHEST', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        const _MilestoneForm(),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: EconomyMirror.instance,
          builder: (context, _) => Text('Practice credits ${EconomyMirror.instance.practiceCredits}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
        ),
        const SizedBox(height: 18),
        ProgramTabsBlock(spec: kRewardsSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, goRef: _go, showDisclaimer: false),
      ],
    );
  }
}

/// Starter quests straight from the server summary (titles, goals, coins).
class _StarterQuests extends StatelessWidget {
  const _StarterQuests();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final q = sMap(EconomyMirror.instance.summary['quests']);
          final list = sList(q['starter']);
          if (list.isEmpty) {
            return const EconomyNote('Starter quests are done. Weekly and monthly quests are in the Quests tab below.');
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final x in list)
              BlackOffer(
                title: '${x['title'] ?? 'Quest'}',
                mark: NwsbMarks.rewards,
                progress: sNum(x['goal']) <= 0 ? 0 : (sNum(x['value']) / sNum(x['goal'])).clamp(0, 1).toDouble(),
                line: x['claimed'] == true
                    ? 'Claimed · +${sInt(x['coins'])} coins'
                    : '${sInt(x['value'])} of ${sInt(x['goal'])} done · +${sInt(x['coins'])} coins',
                onTap: x['claimed'] != true && sNum(x['value']) >= sNum(x['goal'])
                    ? () => runReward(context, () => EconomyApi.call('claimQuest', {'kind': 'starter', 'id': x['id']}), title: '${x['title']}')
                    : null,
              ),
          ]);
        },
      );
}

/// Coin spends priced by the server config (rewards.spend).
class _SpendRail extends StatelessWidget {
  const _SpendRail();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final m = EconomyMirror.instance;
          final spend = sMap(sMap(sMap(m.summary['config'])['rewards'])['spend']);
          if (spend.isEmpty) return const EconomyNote('Coin spends load with your wallet.');
          final have = m.coins;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in spend.entries)
              Builder(builder: (context) {
                final item = sMap(e.value);
                final cost = sInt(item['coins']);
                return GestureDetector(
                  onTap: () => runReward(context, () => EconomyApi.call('spendCoins', {'item': e.key}), title: '${item['title'] ?? 'Coins spent'}'),
                  child: GlassWrap(
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                      width: 140,
                      height: 92,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${item['title'] ?? e.key}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('$cost coins', style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800)),
                        Text(have >= cost ? 'You have $have' : 'Need ${cost - have} more', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                      ]),
                    ),
                  ),
                );
              }),
          ]);
        },
      );
}

/// One Play product with its real store price (future cached once).
class _PlayBuy extends StatefulWidget {
  const _PlayBuy({required this.label, required this.catalogId, required this.mark});
  final String label;
  final String catalogId;
  final String mark;
  @override
  State<_PlayBuy> createState() => _PlayBuyState();
}

class _PlayBuyState extends State<_PlayBuy> {
  late final Future<String> _price = PlayCheckout.priceLabel(widget.catalogId);

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _price,
        builder: (context, snap) => BlackOffer(
          title: widget.label,
          mark: widget.mark,
          line: snap.data ?? 'Google Play price',
          onTap: () => runPrivate(context, () async {
            final r = await PlayCheckout.purchase({'kind': 'product', 'productId': widget.catalogId});
            if (context.mounted) await celebrate(context, r, title: 'Thank you');
          }),
        ),
      );
}

class _TodayCard extends StatefulWidget {
  const _TodayCard();

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  String? _note;

  Future<void> _claim() async {
    try {
      final gained = await EconomyApi.claimToday();
      if (!mounted) return;
      final after = EconomyMirror.instance.coins;
      setState(() => _note = gained > 0
          ? '+$gained coins landed on this wallet.'
          : 'Today’s coins are already on the wallet.');
      if (gained > 0) unawaited(playCoins(context, gained, balanceAfter: after, title: 'Today’s coins'));
    } on EconomyException catch (e) {
      if (!mounted) return;
      final raw = e.message.toUpperCase();
      setState(() => _note = raw.contains('NOT_FOUND')
          ? 'The wallet did not answer. Tap claim again.'
          : e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: EconomyMirror.instance, builder: (context, _) => _card(context));
  }

  Widget _card(BuildContext context) {
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
              const EditableLabel('vault_screen.TodayCard', 'coins', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
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
            onTap: () => Programmes.open(context, Programme.coupons),
          ),
          const SizedBox(height: 14),
          const EditableLabel('vault_screen.TodayCard',
            'SCRATCH',
            style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // The one real daily card: persistent, never re-seals.
          const DailyScratchCard(),
          const SizedBox(height: 14),
          const EditableLabel('vault_screen.TodayCard',
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
  String? _word;
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PracticeProgress.instance,
      builder: (context, _) {
        // Only words actually practised on this phone can be picked.
        final words = <String>{
          for (final x in PracticeProgress.instance.sessionsSnapshot)
            if ('${x['word'] ?? ''}'.trim().isNotEmpty) '${x['word']}'.trim(),
        }.take(24).toList();
        if (words.isEmpty) {
          return const EconomyNote('Practise a word in the player first. Its mastery chest opens here.');
        }
        final pick = _word != null && words.contains(_word) ? _word! : words.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in words)
                ChoiceChip(
                  label: Text(w),
                  selected: w == pick,
                  onSelected: (_) => setState(() => _word = w),
                  labelStyle: TextStyle(color: w == pick ? Colors.black : Colors.white, fontWeight: FontWeight.w700),
                  selectedColor: NwsbColors.goldLight,
                  backgroundColor: const Color(0x14FFFFFF),
                  side: const BorderSide(color: Color(0x44E4C56A)),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                ),
            ]),
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
              onTap: () => runReward(context, () => EconomyApi.call('claimMilestone', {
                    'wordId': pick.toLowerCase(),
                    'level': _level,
                  }), title: 'Mastery chest'),
            ),
          ],
        );
      },
    );
  }
}
