/// R27 sections and pages wired to live data and real screens.
/// Rewards, Gifts, NowssB Earn and Coupons: one section each on BOTH homes
/// (`fashion:`), each opening its own stand-alone page.
library;

import 'package:flutter/material.dart';

import '../../../features/economy/coupon_screen.dart';
import '../../../features/economy/economy_api.dart';
import '../../../features/earn/earn_hub_screen.dart';
import '../../../features/gifts/gifts_screen.dart';
import '../../../features/programs/reference_program.dart';
import '../../../features/vault/vault_screen.dart';
import '../../../screens/nwsb_sign_in_sheet.dart';
import 'data.dart';
import 'pages.dart';
import 'sections.dart';

void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

Future<void> _claim(BuildContext c) async {
  try {
    final n = await EconomyApi.claimToday();
    await EconomyMirror.instance.refresh();
    if (!c.mounted) return;
    ScaffoldMessenger.maybeOf(c)?.showSnackBar(SnackBar(content: Text(n > 0 ? '+$n coins claimed' : 'Already claimed today')));
  } catch (_) {
    if (c.mounted) _push(c, const VaultScreen());
  }
}

class _Live extends StatelessWidget {
  const _Live({required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([EconomyMirror.instance, GiftBook.instance]), builder: (c, _) => builder(c));
}

// ── pages ──
class R27RewardsLivePage extends StatelessWidget {
  const R27RewardsLivePage({super.key});
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => R27RewardsPage(
        data: R27Live.rewards(),
        onBack: () => Navigator.of(c).maybePop(),
        onClaim: () => _claim(c),
        onVault: () => _push(c, const VaultScreen()),
        onSignIn: () => NwsbSignInPage.open(c),
        onHowItWorks: () => _push(c, const VaultScreen()),
      ));
}

class R27GiftsLivePage extends StatelessWidget {
  const R27GiftsLivePage({super.key});
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => R27GiftsPage(
        data: R27Live.gifts(),
        onBack: () => Navigator.of(c).maybePop(),
        onGift: (id) => showGiftCardSheet(c, id),
        onRedeem: () => _push(c, const GiftsScreen(startOnRedeem: true)),
        onHistory: () => _push(c, const GiftsScreen()),
      ));
}

class R27EarnLivePage extends StatelessWidget {
  const R27EarnLivePage({super.key});
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => R27EarnPage(
        data: R27Live.earn(),
        onBack: () => Navigator.of(c).maybePop(),
        onHub: () => _push(c, const EarnHubScreen()),
        onInvite: () => _push(c, const ReferenceProgramPage()),
        onRank: (_) => _push(c, const EarnHubScreen()),
      ));
}

class R27CouponsLivePage extends StatelessWidget {
  const R27CouponsLivePage({super.key});
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => R27CouponsPage(
        data: R27Live.coupons(),
        onBack: () => Navigator.of(c).maybePop(),
        onScratch: () => _push(c, const CouponScreen(initialTab: 'scratch')),
        onCoupon: (_) => _push(c, const CouponScreen()),
        onSealed: (_) => _push(c, const CouponScreen(initialTab: 'scratch')),
        onRules: () => _push(c, const CouponScreen()),
      ));
}

// ── sections (both homes) ──
class R27LiveSections extends StatelessWidget {
  const R27LiveSections({super.key, this.fashion = false});
  final bool fashion;
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        R27RewardsSection(
            key: ValueKey('r27-rewards-$fashion'),
            fashion: fashion,
            data: R27Live.rewards(),
            onOpen: () => _push(c, const R27RewardsLivePage()),
            onClaim: () => _claim(c),
            onSignIn: () => NwsbSignInPage.open(c)),
        const SizedBox(height: 22),
        R27GiftsSection(
            key: ValueKey('r27-gifts-$fashion'),
            fashion: fashion,
            data: R27Live.gifts(),
            onGift: (id) => showGiftCardSheet(c, id),
            onRedeem: () => _push(c, const GiftsScreen(startOnRedeem: true)),
            onOpen: () => _push(c, const R27GiftsLivePage())),
        const SizedBox(height: 22),
        R27EarnSection(
            key: ValueKey('r27-earn-$fashion'),
            fashion: fashion,
            data: R27Live.earn(),
            onOpen: () => _push(c, const R27EarnLivePage()),
            onRank: (_) => _push(c, const R27EarnLivePage())),
        const SizedBox(height: 22),
        R27CouponsSection(
            key: ValueKey('r27-coupons-$fashion'),
            fashion: fashion,
            data: R27Live.coupons(),
            onScratch: () => _push(c, const CouponScreen(initialTab: 'scratch')),
            onOpen: () => _push(c, const R27CouponsLivePage()),
            onCoupon: (_) => _push(c, const R27CouponsLivePage())),
      ]));
}
