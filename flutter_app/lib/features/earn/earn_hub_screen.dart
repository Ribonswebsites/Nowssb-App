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
import '../../widgets/program_shelf.dart';
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
      banner: const ColoredSplitPromoBanner(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
        spec: SplitPromoSpec(
          title: 'NowssB Earn',
          cta: 'Agents, rewards, gifts',
          leftColor: Color(0xFF2A1B4D),
          rightColor: Color(0xFFC8A96E),
          art: SplitPromoArts.egyptianGold,
        ),
      ),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            // Server-driven order (Admin → UI Editor); bundled order by default.
      children: layoutChildren(context, 'earn', [
              if (w.uid == null)
                GoldButton(
                  label: 'Sign in to see your balance',
                  onTap: () => NwsbSignInPage.open(context),
                )
              else ...[
                CoinCount(value: w.coins, style: const TextStyle(fontSize: 28, color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
                MoneyCount(cents: w.cash, style: const TextStyle(color: NwsbColors.mist)),
                Text(w.plan, style: const TextStyle(color: NwsbColors.mist)),
                const SizedBox(height: 6),
                Text('${w.sellerTier} · ${w.wordsSold}/${w.nextSellerTarget} sold', style: const TextStyle(color: NwsbColors.mist)),
                Text('${w.circleTier} · ${w.code.isEmpty ? 'code paused' : w.code}', style: const TextStyle(color: NwsbColors.mist)),
              ],
              const SizedBox(height: 8),
              const LSection('note', 'Privacy note', EconomyNote('This page is only yours. Coin and cash balances are not on the public Word Print.')),
              const SizedBox(height: 8),
              const GlassLine(text: 'Earn, rewards, gifts, resell, print, the wall. Swipe the shelf.'),
              const SizedBox(height: 12),
              const CoinCollectCard(pageKey: 'hub', amount: 8, title: 'Earn hub coins'),
              const SizedBox(height: 12),
              // Each poster opens its own programme (see openPoster).
              const ProgramShelf(),
              const SizedBox(height: 14),
              // The six programs from the plan, each with its full tab set.
              LSection.group('programs', 'Programs', [
                const EditableLabel('earn_hub_screen.EarnHubScreen', 'THE PROGRAMS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
                const SizedBox(height: 8),
                ProgramLink(title: 'NowssB Earn', sub: 'Ranks, team, sales, targets, payouts', mark: NwsbMarks.piggy, page: () => const EarnProgramPage()),
                ProgramLink(title: 'NowssB Rewards', sub: 'Daily coins, streaks, quests, season, leagues', mark: NwsbMarks.rewards, page: () => const RewardsProgramPage()),
                ProgramLink(title: 'NowssB Coupons', sub: 'Scratch cards, rarity, odds, prizes', mark: NwsbMarks.coupon, page: () => const CouponsProgramPage()),
                ProgramLink(title: 'NowssB Gifts', sub: 'Free boxes, gift cards, send and redeem', mark: NwsbMarks.gift, page: () => const GiftsProgramPage()),
                ProgramLink(title: 'NowssB Reference', sub: 'Your links, friends, sharer ladder', mark: NwsbMarks.reference, page: () => const ReferenceProgramPage()),
                ProgramLink(title: 'Partner Program', sub: 'Milestones, perks, buyer discount', mark: NwsbMarks.crown, page: () => const PartnerProgramPage()),
              ]),
              const SizedBox(height: 12),
              LSection.group('more', 'More', [
                ProgramLink(title: 'Your Earning', sub: 'Balance, payout account, request a payout', mark: NwsbMarks.bars, page: () => const EarningsScreen()),
                ProgramLink(title: 'Word Print', sub: 'Your public profile of words', mark: NwsbMarks.word, page: () => WordPrintScreen(uid: w.uid)),
                ProgramLink(title: 'Echo Wall', sub: 'Posts from people on NowssB', mark: NwsbMarks.verified, page: () => const EchoWallScreen()),
              ]),
              const SizedBox(height: 18),
              const LSection('coins', 'Coin ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'COIN LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12))),
              const SizedBox(height: 8),
              _ledger('coinLedger', w.uid),
              const SizedBox(height: 16),
              const LSection('cash', 'Cash ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'CASH LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12))),
              const SizedBox(height: 8),
              _ledger('commissionLedger', w.uid),
            ]),
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
