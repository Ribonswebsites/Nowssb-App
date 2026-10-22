import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import 'earnings_screen.dart';
import '../social/echo_wall_screen.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';
import '../wordprint/word_print_screen.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/coupon_screen.dart';
import '../economy/partner_screen.dart';
import '../economy/reference_screen.dart';
import '../../widgets/routine_deck.dart';
import '../programs/program_router.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';
import '../programs/coupons_program.dart';
import '../programs/earn_program.dart';
import '../programs/gifts_program.dart';
import '../programs/partner_program.dart';
import '../programs/program_kit.dart';
import '../programs/reference_program.dart';
import '../programs/rewards_program.dart';

class EarnHubScreen extends StatelessWidget {
  const EarnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kEarnDisclaimer,
      title: 'NowssB Earn',
      mark: NwsbMarks.piggy,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              RoutineDeck(
                title: 'Earn',
                banner: 'NowssB Earn',
                bannerSub: w.uid == null ? 'Sign in to see your balance' : '${w.circleTier} · ${w.code.isEmpty ? 'code paused' : w.code}',
                onBanner: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarnProgramPage())),
                cards: [
                  if (w.uid == null)
                    WorkCard(category: 'Account', title: 'Sign in', meta: 'See coins and cash', action: 'Sign in', image: 'assets/rails/earn-01.jpg', onTap: () => NwsbSignInPage.open(context))
                  else
                    WorkCard(category: 'Balance', title: '${w.coins} coins', meta: FxBook.instance.formatCents(w.cash), action: 'Open ranks', image: 'assets/rails/earn-01.jpg', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarnProgramPage()))),
                  WorkCard(category: 'Rewards', title: 'NowssB Rewards', meta: 'Daily coins, streaks, quests', action: 'Open rewards', image: 'assets/rails/rewards-01.jpg', onTap: () => Programmes.open(context, Programme.rewards)),
                  WorkCard(category: 'Coupons', title: 'NowssB Coupons', meta: 'Scratch cards and codes', action: 'Open coupons', image: 'assets/gifts/coupon-hero.png', onTap: () => Programmes.open(context, Programme.coupons)),
                  WorkCard(category: 'Gifts', title: 'NowssB Gifts', meta: 'Send a real purchase as a code', action: 'Open gifts', image: 'assets/gifts/box-gold.webp', onTap: () => Programmes.open(context, Programme.gifts)),
                  WorkCard(category: 'Reference', title: 'NowssB Reference', meta: 'Your link and the people on it', action: 'Open reference', image: 'assets/rails/earn-04.jpg', onTap: () => Programmes.open(context, Programme.reference)),
                  WorkCard(category: 'Cash', title: 'Your earning', meta: 'Payout account and requests', action: 'Open earnings', image: 'assets/rails/earnings-01.jpg', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen()))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _ledger(String collection, String? uid) {
    if (!NwsbFirebase.ready || uid == null) return const EconomyNote('Sign in to see the ledger.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).where('uid', isEqualTo: uid).limit(15).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EconomyNote('Nothing here yet.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final doc in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  collection == 'commissionLedger'
                      ? '${doc.data()['note'] ?? doc.data()['type'] ?? ''}  ₹${(((doc.data()['paise'] as num?) ?? 0) / 100).toStringAsFixed(2)}'
                      : '${doc.data()['reason'] ?? ''}  ${doc.data()['delta'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}
