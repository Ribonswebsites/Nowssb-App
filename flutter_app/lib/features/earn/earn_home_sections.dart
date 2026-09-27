/// Home doors for NowssB Earn, Rewards, and Gifts.
///
/// Built from the same [SectionPane], [PaneHead], [SecBanner], and
/// [ColoredSplitPromoBanner] the rest of Home already uses. The split
/// banner sits above the glass pane, not inside it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/firebase.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../theme/tokens.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/nwsb_icon.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';

class EarnUmbrellaSection extends StatelessWidget {
  const EarnUmbrellaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OutsidePromo(
          slides: [
            _Slide(
              title: 'NowssB Earn\nAgents',
              cta: 'Open Earn',
              left: Color(0xFF1A3A3C),
              right: Color(0xFF2EC4B6),
              art: SplitPromoArts.blondeLotus,
              dest: _Dest.earn,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaneHead(
                eyebrow: 'NowssB Earn',
                title: 'Agents, codes, commission',
                mark: NwsbMarks.earn,
              ),
              const SizedBox(height: 12),
              SecBanner(
                title: 'Become an agent',
                sub: 'Paid plan required. Commission is on net, after the store fee.',
                mark: NwsbMarks.verified,
                onTap: () => _open(context, const CircleScreen()),
              ),
              const SizedBox(height: 8),
              SecBanner(
                title: 'Your code',
                sub: 'Any purchase with your code counts. Two levels, never a third.',
                mark: NwsbMarks.earn,
                onTap: () => _open(context, const CircleScreen()),
              ),
              const SizedBox(height: 8),
              SecBanner(
                title: 'Downline',
                sub: 'Your legs, their volume, and a 5% override while both plans are active.',
                mark: NwsbMarks.user,
                onTap: () => _open(context, const CircleScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class YourRewardsSection extends StatelessWidget {
  const YourRewardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutsidePromo(
          slides: const [
            _Slide(
              title: 'NowssB Rewards',
              cta: 'Open rewards',
              left: Color(0xFF2A1B4D),
              right: Color(0xFFC8A96E),
              art: SplitPromoArts.egyptianGold,
              dest: _Dest.rewards,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionPane(
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
                    eyebrow: 'NowssB Rewards',
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
                        color: HomeSkinScope.of(context) == HomeSkin.normal
                            ? NwsbColors.ink
                            : NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Streak ${w.streak} · $nextChest coins to the next chest',
                      style: TextStyle(
                        color: HomeSkinScope.of(context) == HomeSkin.normal
                            ? NwsbColors.inkSoft
                            : NwsbColors.mist,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SecBanner(
                      title: 'Open rewards',
                      sub: 'Daily coins, quests, and chests',
                      mark: NwsbMarks.earn,
                      onTap: () => EarnUmbrellaSection._open(context, const VaultScreen()),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SecBanner(
                    title: 'Invite a friend',
                    sub: 'They subscribe once. You get a free month, or coins if you already have a plan.',
                    mark: NwsbMarks.verified,
                    onTap: () => EarnUmbrellaSection._open(context, const VaultScreen()),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class GiftsHomeSection extends StatelessWidget {
  const GiftsHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OutsidePromo(
          slides: [
            _Slide(
              title: 'NowssB Gifts',
              cta: 'Send a gift',
              left: Color(0xFF3D2914),
              right: Color(0xFFE07A3D),
              art: SplitPromoArts.redLotus,
              dest: _Dest.gifts,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaneHead(
                eyebrow: 'NowssB Gifts',
                title: 'Send a real purchase',
                mark: NwsbMarks.bag,
              ),
              const SizedBox(height: 12),
              SecBanner(
                title: 'Send a gift',
                sub: 'A word, meaning, bundle, or plan. Paid with Play, not coins.',
                mark: NwsbMarks.bag,
                onTap: () => EarnUmbrellaSection._open(context, const GiftsScreen()),
              ),
              const SizedBox(height: 8),
              SecBanner(
                title: 'Redeem a code',
                sub: 'Open a gift on this account',
                mark: NwsbMarks.verified,
                onTap: () => EarnUmbrellaSection._open(context, const GiftsScreen(startOnRedeem: true)),
              ),
              const SizedBox(height: 8),
              SecBanner(
                title: 'Resell',
                sub: 'List a word you already own. This is the Store, not Earn.',
                mark: NwsbMarks.bag,
                onTap: () => EarnUmbrellaSection._open(context, const BazaarScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Dest { earn, rewards, gifts, resell }

class _Slide {
  const _Slide({
    required this.title,
    required this.cta,
    required this.left,
    required this.right,
    required this.art,
    required this.dest,
  });

  final String title;
  final String cta;
  final Color left;
  final Color right;
  final String art;
  final _Dest dest;
}

class _OutsidePromo extends StatefulWidget {
  const _OutsidePromo({required this.slides});
  final List<_Slide> slides;

  @override
  State<_OutsidePromo> createState() => _OutsidePromoState();
}

class _OutsidePromoState extends State<_OutsidePromo> {
  late final PageController _pages = PageController();
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3400), (_) {
        if (!mounted || !_pages.hasClients) return;
        _index = (_index + 1) % widget.slides.length;
        _pages.animateToPage(
          _index,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _go(_Slide slide) {
    final page = switch (slide.dest) {
      _Dest.earn => const CircleScreen(),
      _Dest.rewards => const VaultScreen(),
      _Dest.gifts => const GiftsScreen(),
      _Dest.resell => const BazaarScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: PageView(
        controller: _pages,
        children: [
          for (final slide in widget.slides)
            ColoredSplitPromoBanner(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 148,
              spec: SplitPromoSpec(
                title: slide.title,
                cta: slide.cta,
                leftColor: slide.left,
                rightColor: slide.right,
                art: slide.art,
                onTap: () => _go(slide),
              ),
            ),
        ],
      ),
    );
  }
}

/// Copies a one-time friend invite. Not an agent code and not a commission.
Future<void> copyFriendInvite(BuildContext context) async {
  final code = EconomyMirror.instance.code;
  final text = code.isEmpty
      ? 'Practice with me on NowssB. One invite, one reward.'
      : 'Practice with me on NowssB. Friend invite $code — one reward, not a commission.';
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend invite copied.')),
    );
  }
}
