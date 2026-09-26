import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/play_billing.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Vault',
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Text('${w.coins}', style: const TextStyle(fontSize: 42, color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
              Text('${w.plan} · streak ${w.streak} · ${w.freezesLeft} freezes left', style: const TextStyle(color: NwsbColors.mist)),
              const SizedBox(height: 12),
              const EconomyNote(
                'Coins are earned. They cover at most 30% of a Play purchase. They cannot be bought, gifted, or cashed out.',
              ),
              const SizedBox(height: 18),
              GoldButton(
                label: 'Claim daily login',
                onTap: () => runEconomy(context, () => EconomyApi.call('claimDailyLogin')),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Log a practice',
                filled: false,
                onTap: () => runEconomy(context, () => EconomyApi.call('reportPractice')),
              ),
              const SizedBox(height: 22),
              const Text('QUESTS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _quest(context, 'practice5', 'Practice 5 words', w.practice, 5, 25),
              _quest(context, 'streak3', 'Hold a 3-day streak', w.streak, 3, 30),
              _quest(context, 'listen1', 'Open the player', w.playerOpens, 1, 15),
              _quest(context, 'buy1', 'Complete one purchase', w.purchases, 1, 20),
              const SizedBox(height: 18),
              const Text('COIN SPENDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _spend(context, 'Streak freeze · 40', 'freeze'),
              _spend(context, 'Practice credit · 15', 'practice'),
              _spend(context, 'Early access · 50', 'early'),
              _spend(context, 'Gold frame · 80', 'cosmetic', {'cosmeticId': 'frame_gold'}),
              _spend(context, 'Verified buyer badge · 30', 'badge', {'badge': 'verified-buyer'}),
              const SizedBox(height: 18),
              const Text('PLAY PURCHASES', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
              const SizedBox(height: 8),
              _buy(context, 'Word', 'nwsb_word', 49, 'word', 'Word'),
              _buy(context, 'Meaning', 'nwsb_meaning', 49, 'meaning', 'Meaning'),
              _buy(context, '10-word bundle', 'nwsb_bundle_10', 490, 'bundle', '10-word bundle'),
              _buy(context, 'Meaning package', 'nwsb_package', 199, 'package', 'Meaning package'),
              _buy(context, 'Resonance', 'nwsb_sub_resonance', 249, 'subscription', 'Resonance'),
              _buy(context, 'Frequency', 'nwsb_sub_frequency', 499, 'subscription', 'Frequency'),
              _buy(context, 'Frequency X', 'nwsb_sub_frequency_x', 999, 'subscription', 'Frequency X'),
              _buy(context, 'Restore streak', 'nwsb_streak_restore', 99, 'streak', 'Streak restore'),
              const SizedBox(height: 18),
              const Text('MILESTONE CHEST', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 12)),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: '$title · $value/$goal · $reward coins',
        filled: false,
        onTap: value >= goal
            ? () => runEconomy(context, () => EconomyApi.call('claimQuest', {'questId': id}))
            : null,
      ),
    );
  }

  Widget _spend(BuildContext context, String label, String purpose, [Map<String, dynamic>? extra]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: label,
        filled: false,
        onTap: () => runEconomy(context, () => EconomyApi.call('spendCoins', {'purpose': purpose, ...?extra})),
      ),
    );
  }

  Widget _buy(BuildContext context, String label, String catalogId, int price, String kind, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: '$label · ₹$price',
        filled: false,
        onTap: () => runEconomy(context, () async {
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
          onTap: () => runEconomy(context, () => EconomyApi.call('claimMilestone', {
                'wordId': _word.text.trim(),
                'level': _level,
              })),
        ),
      ],
    );
  }
}
