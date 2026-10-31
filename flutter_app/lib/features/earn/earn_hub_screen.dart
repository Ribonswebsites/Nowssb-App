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
import '../../widgets/editeaze.dart';
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
          void open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
          // Simpler than the old six-card swipe deck: the balance first, the
          // two everyday programmes side by side, the rest as plain rows.
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              EzOrangeCard(
                key: const ValueKey('earn-ez-balance'),
                title: 'NowssB Earn',
                subtitle: w.uid == null ? 'Sign in to see your balance' : '${w.circleTier} · ${w.code.isEmpty ? 'code paused' : w.code}',
                image: 'assets/rails/earn-01.jpg',
                height: 220,
                icons: [EzIcon(Icons.leaderboard_rounded, label: 'Open ranks', onTap: () => open(const EarnProgramPage()))],
                comment: w.uid == null
                    ? const EzComment(name: 'Account', text: 'Sign in to see coins and cash', icon: Icons.person_rounded)
                    : EzComment(name: '${w.coins} coins', text: FxBook.instance.formatCents(w.cash), icon: Icons.savings_rounded),
                onTap: () => w.uid == null ? NwsbSignInPage.open(context) : open(const EarnProgramPage()),
              ),
              const SizedBox(height: 16),
              EzSplitStrip(
                key: const ValueKey('earn-ez-strip'),
                left: EzTile(image: 'assets/rails/rewards-01.jpg', label: 'Rewards', onTap: () => Programmes.open(context, Programme.rewards)),
                right: EzTile(image: 'assets/gifts/coupon-hero.png', label: 'Coupons', onTap: () => Programmes.open(context, Programme.coupons)),
                addLabel: 'All programmes',
                addIcon: Icons.grid_view_rounded,
                onAdd: () => open(const EarnProgramPage()),
              ),
              const SizedBox(height: 16),
              _row(context, Icons.card_giftcard_rounded, 'NowssB Gifts', 'Send a real purchase as a code', () => Programmes.open(context, Programme.gifts)),
              _row(context, Icons.link_rounded, 'NowssB Reference', 'Your link and the people on it', () => Programmes.open(context, Programme.reference)),
              _row(context, Icons.account_balance_wallet_rounded, 'Your earning', 'Payout account and requests', () => open(const EarningsScreen())),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: kEzOrange, borderRadius: BorderRadius.circular(11)),
                    child: Icon(icon, size: 18, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: Color(0x99FFFFFF)),
              ]),
            ),
          ),
        ),
      );
}
