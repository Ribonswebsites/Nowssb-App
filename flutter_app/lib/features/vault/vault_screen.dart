import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/play_billing.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../admin/template/editable.dart';
import '../../screens/subscription.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Rewards',
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
                mark: NwsbMarks.earn,
              ),
              const SizedBox(height: 12),
              const ColoredSplitPromoBanner(
                margin: EdgeInsets.zero,
                spec: SplitPromoSpec(
                  title: 'NowssB Rewards',
                  cta: 'Claim today’s coins',
                  leftColor: Color(0xFF2A1B4D),
                  rightColor: Color(0xFFC8A96E),
                  art: SplitPromoArts.egyptianGold,
                ),
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
              const SizedBox(height: 8),
              GoldButton(
                label: 'Copy friend invite',
                filled: false,
                onTap: () async {
                  final code = w.code;
                  final text = code.isEmpty
                      ? 'Practice with me on NowssB.'
                      : 'Practice with me on NowssB. Friend invite $code';
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: EditableLabel('vault_screen.VaultScreen', 'Friend invite copied.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 18),
              GoldButton(
                label: 'Claim daily login',
                onTap: () => runPrivate(context, () => EconomyApi.call('claimDailyLogin')),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Log a practice',
                filled: false,
                onTap: () => runPrivate(context, () => EconomyApi.call('reportPractice')),
              ),
              const SizedBox(height: 22),
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
              _spend(context, 'Streak freeze · 40', 'freeze'),
              _spend(context, 'Practice credit · 15', 'practice'),
              _spend(context, 'Early access · 50', 'early'),
              _spend(context, 'Gold frame · 80', 'cosmetic', {'cosmeticId': 'frame_gold'}),
              _spend(context, 'Verified buyer badge · 30', 'badge', {'badge': 'verified-buyer'}),
              const SizedBox(height: 18),
              const EditableLabel('vault_screen.VaultScreen', 'PLAY PURCHASES', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _buy(context, 'Word', 'nwsb_word', 99, 'word', 'Word'),
              _buy(context, 'Meaning', 'nwsb_meaning', 99, 'meaning', 'Meaning'),
              _buy(context, '10-word bundle', 'nwsb_bundle_10', 999, 'bundle', '10-word bundle'),
              _buy(context, 'Meaning package', 'nwsb_package', 399, 'package', 'Meaning package'),
              // Plans are Google Play subscriptions, bought and verified on
              // the Subscription screen (lib/data/play_subscriptions.dart).
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GoldButton(
                  label: 'Plans · Resonance, Frequency, Frequency X',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
              ),
              _buy(context, 'Restore streak', 'nwsb_streak_restore', 199, 'streak', 'Streak restore'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title · $value/$goal · $reward coins', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal == 0 ? 0 : (value / goal).clamp(0, 1),
            color: NwsbColors.gold,
            backgroundColor: const Color(0x22FFFFFF),
          ),
          const SizedBox(height: 6),
          GoldButton(
            label: value >= goal ? 'Open chest' : 'In progress',
            filled: false,
            onTap: value >= goal
                ? () => runPrivate(context, () => EconomyApi.call('claimQuest', {'questId': id}))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _spend(BuildContext context, String label, String purpose, [Map<String, dynamic>? extra]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: label,
        filled: false,
        onTap: () => runPrivate(context, () => EconomyApi.call('spendCoins', {'purpose': purpose, ...?extra})),
      ),
    );
  }

  Widget _buy(BuildContext context, String label, String catalogId, int price, String kind, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FutureBuilder<String>(
        future: PlayCheckout.priceLabel(catalogId),
        builder: (context, snap) {
          return GoldButton(
            label: '${label} · ${snap.data ?? 'Play price'}',
            filled: false,
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
          onTap: () => runPrivate(context, () => EconomyApi.call('claimMilestone', {
                'wordId': _word.text.trim(),
                'level': _level,
              })),
        ),
      ],
    );
  }
}
