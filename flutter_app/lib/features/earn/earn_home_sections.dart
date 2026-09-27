/// NowssB Earn on Home, built from the same pane, head, and split banner
/// the rest of Home already uses.
library;

import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../theme/tokens.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import 'earn_hub_screen.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../vault/vault_screen.dart';

class EarnUmbrellaSection extends StatelessWidget {
  const EarnUmbrellaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'NowssB Earn',
            title: 'Rewards, referrals, resell',
            mark: NwsbMarks.earn,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: PageView(
              children: [
                ColoredSplitPromoBanner(
                  margin: EdgeInsets.zero,
                  height: 148,
                  spec: SplitPromoSpec(
                    title: 'NowssB Earn\nRewards',
                    cta: 'Open rewards',
                    leftColor: const Color(0xFF2A1B4D),
                    rightColor: const Color(0xFFC8A96E),
                    art: SplitPromoArts.egyptianGold,
                    onTap: () => _open(context, const VaultScreen()),
                  ),
                ),
                ColoredSplitPromoBanner(
                  margin: EdgeInsets.zero,
                  height: 148,
                  spec: SplitPromoSpec(
                    title: 'NowssB Earn\nReferrals',
                    cta: 'See referrals',
                    leftColor: const Color(0xFF1A3A3C),
                    rightColor: const Color(0xFF2EC4B6),
                    art: SplitPromoArts.blondeLotus,
                    onTap: () => _open(context, const CircleScreen()),
                  ),
                ),
                ColoredSplitPromoBanner(
                  margin: EdgeInsets.zero,
                  height: 148,
                  spec: SplitPromoSpec(
                    title: 'NowssB Earn\nResell',
                    cta: 'Open resell',
                    leftColor: const Color(0xFF3D2914),
                    rightColor: const Color(0xFFE07A3D),
                    art: SplitPromoArts.redLotus,
                    onTap: () => _open(context, const BazaarScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SecBanner(
            title: 'Rewards',
            sub: 'Daily coins, quests, and chests',
            mark: NwsbMarks.earn,
            onTap: () => _open(context, const VaultScreen()),
          ),
          const SizedBox(height: 8),
          SecBanner(
            title: 'Referrals',
            sub: 'A code that pays when someone subscribes',
            mark: NwsbMarks.verified,
            onTap: () => _open(context, const CircleScreen()),
          ),
          const SizedBox(height: 8),
          SecBanner(
            title: 'Resell',
            sub: 'List a word you already own',
            mark: NwsbMarks.bag,
            onTap: () => _open(context, const BazaarScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class YourRewardsSection extends StatelessWidget {
  const YourRewardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && w.uid != null;
          final nextChest = 40 - (w.coins % 40);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaneHead(
                eyebrow: 'Your Rewards',
                title: 'Coins and streak',
                mark: NwsbMarks.earn,
              ),
              const SizedBox(height: 12),
              if (!signedIn)
                SecBanner(
                  title: 'Sign in to see your rewards',
                  sub: 'Your coins and streak stay on your account',
                  mark: NwsbMarks.user,
                  onTap: () => NwsbSignInPage.open(context),
                )
              else ...[
                CoinCount(
                  value: w.coins,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: HomeSkinScope.of(context) == HomeSkin.normal ? NwsbColors.ink : NwsbColors.goldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Streak ${w.streak} · $nextChest coins to the next chest',
                  style: TextStyle(
                    color: HomeSkinScope.of(context) == HomeSkin.normal ? NwsbColors.inkSoft : NwsbColors.mist,
                  ),
                ),
                const SizedBox(height: 10),
                SecBanner(
                  title: 'Open rewards',
                  sub: 'History, quests, and chests',
                  mark: NwsbMarks.earn,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const EarnHubScreen()),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
