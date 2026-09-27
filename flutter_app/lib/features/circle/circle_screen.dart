import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn — Referrals',
      banner: ColoredSplitPromoBanner(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        spec: SplitPromoSpec(
          title: 'NowssB Earn\nReferrals',
          cta: 'See the ladder',
          leftColor: const Color(0xFF1A3A3C),
          rightColor: const Color(0xFF2EC4B6),
          art: SplitPromoArts.blondeLotus,
        ),
      ),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && w.uid != null;
          final next = w.paidReferrals >= 100
              ? 100
              : w.paidReferrals >= 50
                  ? 100
                  : w.paidReferrals >= 20
                      ? 50
                      : w.paidReferrals >= 5
                          ? 20
                          : 5;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              const Text('TIER LADDER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              for (final step in const [
                ('Member', 'Before 5 paid referrals'),
                ('Bronze', '5 paid referrals · 20%'),
                ('Silver', '20 paid referrals · 25%'),
                ('Gold', '50 paid referrals · 30%'),
                ('Platinum', '100 paid referrals · 35%'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      NwsbIcon(
                        NwsbMarks.verified,
                        size: 18,
                        color: signedIn && w.circleTier == step.$1 ? NwsbColors.goldLight : NwsbColors.mist,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${step.$1} · ${step.$2}',
                          style: TextStyle(
                            color: signedIn && w.circleTier == step.$1 ? Colors.white : NwsbColors.mist,
                            fontWeight: signedIn && w.circleTier == step.$1 ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (signedIn) ...[
                LinearProgressIndicator(
                  value: (w.paidReferrals / next).clamp(0, 1),
                  color: NwsbColors.gold,
                  backgroundColor: const Color(0x22FFFFFF),
                ),
                const SizedBox(height: 6),
                Text('${w.paidReferrals} / $next toward the next tier', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const EconomyNote(
                'A code pays only while that member’s plan is active. After 5 paid referrals the rate is 20%, then 25, 30, and 35. The second level is 5%, and only while both plans are active. An invite alone pays nothing.',
              ),
              const SizedBox(height: 14),
              if (!signedIn)
                GoldButton(
                  label: 'Sign in to see your code',
                  onTap: () => NwsbSignInPage.open(context),
                )
              else if (!w.subscribed) ...[
                const EconomyNote('Your code stays paused until a paid plan is active. The count you already have is kept.'),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'See plans',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
              ] else ...[
                Text(w.code.isEmpty ? '—' : w.code, style: const TextStyle(fontSize: 32, color: NwsbColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: 2)),
                Text('${w.circleTier} · ${w.paidReferrals} paid referrals', style: const TextStyle(color: NwsbColors.mist)),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Copy code',
                  filled: false,
                  onTap: w.code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: w.code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
                          }
                        },
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Enter a referral code', hintStyle: TextStyle(color: NwsbColors.mist)),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: w.referredBy.isEmpty ? 'Apply code' : 'Code already applied',
                onTap: signedIn && w.referredBy.isEmpty
                    ? () => runPrivate(context, () => EconomyApi.call('applyReferralCode', {'code': _code.text.trim()}))
                    : signedIn
                        ? null
                        : () => NwsbSignInPage.open(context),
              ),
              const SizedBox(height: 18),
              const Text('LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              if (!NwsbFirebase.ready || w.uid == null)
                const EconomyNote('Sign in to see referral payments.')
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('referralLedger')
                      .where('referrerUid', isEqualTo: w.uid)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const EconomyNote('No referral payments yet.');
                    return Column(
                      children: [
                        for (final doc in docs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'L${doc.data()['level']} · ${doc.data()['status']} · ${FxBook.instance.formatCents((doc.data()['commissionAmount'] as num?)?.toInt() ?? 0)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
