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
import '../economy/coupon_screen.dart';
import '../economy/partner_screen.dart';
import '../economy/reference_screen.dart';
import '../../widgets/program_shelf.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

class EarnHubScreen extends StatelessWidget {
  const EarnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn',
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
              ProgramShelf(
                onTap: (poster) {
                  final page = switch (poster.title) {
                    'Rewards' => const VaultScreen(),
                    'Gift' => const GiftsScreen(),
                    'Partner' => WordPrintScreen(uid: w.uid),
                    'Bonus' => const EchoWallScreen(),
                    _ => const CircleScreen(),
                  };
                  _open(context, page);
                },
              ),
              const SizedBox(height: 14),
              LSection('earn', 'NowssB Earn', GoldButton(label: 'NowssB Earn', onTap: () => _open(context, const CircleScreen()))),
              const SizedBox(height: 8),
              LSection('rewards', 'Rewards', GoldButton(label: 'Rewards', filled: false, onTap: () => _open(context, const VaultScreen()))),
              const SizedBox(height: 8),
              LSection('gifts', 'Gifts', GoldButton(label: 'Gifts', filled: false, onTap: () => _open(context, const GiftsScreen()))),
              const SizedBox(height: 8),
              LSection('resell', 'Resell', GoldButton(label: 'Resell', filled: false, onTap: () => _open(context, const BazaarScreen()))),
              const SizedBox(height: 8),
              LSection('wordprint', 'Word Print', GoldButton(label: 'Word Print', filled: false, onTap: () => _open(context, WordPrintScreen(uid: w.uid)))),
              const SizedBox(height: 8),
              LSection('echo', 'Echo Wall', GoldButton(label: 'Echo Wall', filled: false, onTap: () => _open(context, const EchoWallScreen()))),
              const SizedBox(height: 14),
              LSection('earnings', 'Earnings', GoldButton(label: 'Earnings', filled: false, onTap: () => _open(context, const EarningsScreen()))),
              const SizedBox(height: 8),
              LSection('coupon', 'Coupon', GoldButton(label: 'Coupon', filled: false, onTap: () => _open(context, const CouponScreen()))),
              const SizedBox(height: 8),
              LSection('reference', 'Reference', GoldButton(label: 'Reference', filled: false, onTap: () => _open(context, const ReferenceScreen()))),
              const SizedBox(height: 8),
              LSection('partner', 'Partner', GoldButton(label: 'Partner', filled: false, onTap: () => _open(context, const PartnerScreen()))),
              const SizedBox(height: 18),
              const LSection('coins', 'Coin ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'COIN LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12))),
              const SizedBox(height: 8),
              _ledger('coinLedger', w.uid),
              const SizedBox(height: 16),
              const LSection('cash', 'Cash ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'CASH LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12))),
              const SizedBox(height: 8),
              _ledger('cashLedger', w.uid),
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
                  '${doc.data()['reason'] ?? ''}  ${doc.data()['delta'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}
