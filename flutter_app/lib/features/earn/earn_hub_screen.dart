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
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            // Server-driven order (Admin → UI Editor); bundled order by default.
      children: layoutChildren(context, 'earn', [
              _CalmBalanceCard(w: w),
              const SizedBox(height: 24),
              const LSection('note', 'Privacy note', Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('This page is only yours. Coin and cash balances are not on the public Word Print.',
                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.5)),
              )),
              const SizedBox(height: 24),
              const CoinCollectCard(pageKey: 'hub', amount: 8, title: 'Earn hub coins'),
              const SizedBox(height: 24),
              // The six programs from the plan, each with its full tab set.
              LSection.group('programs', 'Programs', [
                const EditableLabel('earn_hub_screen.EarnHubScreen', 'THE PROGRAMS', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ProgramLink(title: 'NowssB Earn', sub: 'Ranks, team, sales, targets, payouts', mark: NwsbMarks.piggy, page: () => const EarnProgramPage()),
                ProgramLink(title: 'NowssB Rewards', sub: 'Daily coins, streaks, quests, season, leagues', mark: NwsbMarks.rewards, page: () => const RewardsProgramPage()),
                ProgramLink(title: 'NowssB Coupons', sub: 'Scratch cards, rarity, odds, prizes', mark: NwsbMarks.coupon, page: () => const CouponsProgramPage()),
                ProgramLink(title: 'NowssB Gifts', sub: 'Free boxes, gift cards, send and redeem', mark: NwsbMarks.gift, page: () => const GiftsProgramPage()),
                ProgramLink(title: 'NowssB Reference', sub: 'Your links, friends, sharer ladder', mark: NwsbMarks.reference, page: () => const ReferenceProgramPage()),
                ProgramLink(title: 'Partner Program', sub: 'Milestones, perks, buyer discount', mark: NwsbMarks.crown, page: () => const PartnerProgramPage()),
              ]),
              const SizedBox(height: 24),
              LSection.group('more', 'More', [
                ProgramLink(title: 'Your Earning', sub: 'Balance, payout account, request a payout', mark: NwsbMarks.bars, page: () => const EarningsScreen()),
                ProgramLink(title: 'Word Print', sub: 'Your public profile of words', mark: NwsbMarks.word, page: () => WordPrintScreen(uid: w.uid)),
                ProgramLink(title: 'Echo Wall', sub: 'Posts from people on NowssB', mark: NwsbMarks.verified, page: () => const EchoWallScreen()),
              ]),
              const SizedBox(height: 24),
              const LSection('coins', 'Coin ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'COIN LEDGER', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500))),
              const SizedBox(height: 8),
              _ledger('coinLedger', w.uid),
              const SizedBox(height: 24),
              const LSection('cash', 'Cash ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'CASH LEDGER', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500))),
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

/// One calm accent for the Rewards page (sage), per the Oct 12 brief.
const Color _kCalmAccent = Color(0xFF9FB8A8);

/// Play Points style balance card: black glass, lots of air, one accent.
/// Read-only mirror of server state (EconomyMirror); grants nothing.
class _CalmBalanceCard extends StatelessWidget {
  const _CalmBalanceCard({required this.w});
  final EconomyMirror w;

  @override
  Widget build(BuildContext context) {
    const soft = TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xCC0A0A0A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _BreathDot(),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('YOUR REWARDS', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 18),
          if (w.uid == null) ...[
            const Text('Breathe in. Your coins, gifts and coupons wait here.', style: soft),
            const SizedBox(height: 18),
            GoldButton(label: 'Sign in to see your balance', onTap: () => NwsbSignInPage.open(context)),
          ] else ...[
            CoinCount(value: w.coins, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            MoneyCount(cents: w.cash, style: soft),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: w.nextSellerTarget <= 0 ? 0 : (w.wordsSold / w.nextSellerTarget).clamp(0, 1).toDouble(),
                backgroundColor: const Color(0x1AFFFFFF),
                valueColor: const AlwaysStoppedAnimation(_kCalmAccent),
              ),
            ),
            const SizedBox(height: 10),
            Text('${w.sellerTier} · ${w.wordsSold}/${w.nextSellerTarget} sold', style: soft),
            Text('${w.plan} · ${w.circleTier} · ${w.code.isEmpty ? 'code paused' : w.code}', style: soft),
          ],
        ],
      ),
    );
  }
}

/// A slow 'breathe in, breathe out' dot (4 s cycle) — the page's one motion.
class _BreathDot extends StatefulWidget {
  const _BreathDot();
  @override
  State<_BreathDot> createState() => _BreathDotState();
}

class _BreathDotState extends State<_BreathDot> with SingleTickerProviderStateMixin {
  // Three calm breaths, then rest (no endless ticker).
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true, count: 6);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_c.value);
          return Center(
            child: Container(
              width: 8 + 8 * t,
              height: 8 + 8 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCalmAccent.withValues(alpha: 0.35 + 0.65 * (1 - t)),
                border: Border.all(color: _kCalmAccent.withValues(alpha: 0.6)),
              ),
            ),
          );
        },
      ),
    );
  }
}
