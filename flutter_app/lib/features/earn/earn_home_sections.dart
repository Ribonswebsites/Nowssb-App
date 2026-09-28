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
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/flip_portrait.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/neumorphic.dart';
import '../../widgets/nwsb_icon.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';
import '../../admin/template/editable.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class _EarnTier {
  const _EarnTier(this.name, this.detail, this.badge, this.lines);
  final String name;
  final String detail;
  final String badge;
  final List<String> lines;
}

const _earnTiers = <_EarnTier>[
  _EarnTier('Starter', '0–99 units · 10% of net', '10%', [
    'Your code on any purchase',
    '10% of net after the store fee',
    'Paid plan required',
  ]),
  _EarnTier('Rising', '100 units · 15% of net', '15%', [
    'Same code, higher rate',
    '15% of net after the store fee',
    'Units you already have stay',
  ]),
  _EarnTier('Pro', '300 units · 20% of net', '20%', [
    '20% of net after the store fee',
    'Direct recruits pay 5% of their commission',
    'Only while both plans are active',
  ]),
  _EarnTier('Elite', '500 units · 25% of net', '25%', [
    '25% of net after the store fee',
    'Two levels. There is no third',
    'An invite by itself pays nothing',
  ]),
  _EarnTier('Master', '1000 units · 30% of net', '30%', [
    '30% of net. The cap',
    'Never a percent of the sticker price',
    'Payouts wait for review',
  ]),
];

class EarnUmbrellaSection extends StatefulWidget {
  const EarnUmbrellaSection({super.key});

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  State<EarnUmbrellaSection> createState() => _EarnUmbrellaSectionState();
}

class _EarnUmbrellaSectionState extends State<EarnUmbrellaSection> {
  late final PageController _pager;
  Timer? _auto;
  var _page = 0;
  var _userPaging = false;

  @override
  void initState() {
    super.initState();
    _pager = PageController(viewportFraction: 0.92);
    if (_flutterTest) return;
    _auto = Timer.periodic(const Duration(milliseconds: 4800), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % 3;
      _pager.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pager.dispose();
    super.dispose();
  }

  void _openEarn() => EarnUmbrellaSection._open(context, const CircleScreen());

  @override
  Widget build(BuildContext context) {
    final neu = HomeSkinScope.of(context) == HomeSkin.normal;
    return SizedBox(
      height: 660,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _userPaging = true;
          } else if (n is ScrollEndNotification) {
            _userPaging = false;
          }
          return false;
        },
        child: PageView(
          controller: _pager,
          onPageChanged: (i) {
            if (_page == i) return;
            setState(() => _page = i);
          },
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(neu, 0, _intro()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(neu, 1, _overview()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(neu, 2, _how()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shell(bool neu, int i, Widget child) {
    if (neu) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: 16 + (i % 3) * 4,
        elevation: i.isEven ? NwsbElevation.md : NwsbElevation.sm,
        child: child,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: i.isEven ? 18 : 26,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: child,
    );
  }

  Widget _intro() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'NowssB Earn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.02,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'Commission on net. Two levels. Never a third.',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: ClipRect(
                child: EditableImage.asset(
                  'assets/banners/brand-cleo.png',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  slot: 'earn_home_sections.EarnUmbrellaSection',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: EditableLabel('earn_home_sections.EarnUmbrellaSection',
                    'Join today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openEarn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const EditableLabel('earn_home_sections.EarnUmbrellaSection',
                      'Open Earn',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _openEarn,
          child: Container(
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const NwsbIcon(NwsbMarks.piggy, size: 26, color: Colors.black),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EditableLabel('earn_home_sections.EarnUmbrellaSection',
                          'NowssB',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        EditableLabel('earn_home_sections.EarnUmbrellaSection',
                          'Earn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: EditableImage.asset(
                    'assets/banners/earn/bag-blonde.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment(0.1, -0.05),
                    slot: 'earn_home_sections.EarnUmbrellaSection',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 118,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  child: FlipPortrait(
                    front: 'assets/banners/earn/hands-light.png',
                    back: 'assets/banners/earn/hands-dark.png',
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -0.05),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  child: FlipPortrait(
                    front: 'assets/banners/earn/sit-light.png',
                    back: 'assets/banners/earn/sit-dark.png',
                    fit: BoxFit.cover,
                    alignment: Alignment(0, 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _earnTiers.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Expanded(child: _tierBox(_earnTiers[i])),
        ],
      ],
    );
  }

  Widget _tierBox(_EarnTier tier) {
    return GestureDetector(
      onTap: _openEarn,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                  ),
                ],
              ),
            ),
            _badge(tier.badge),
          ],
        ),
      ),
    );
  }

  Widget _how() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'How you get paid',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'Net after the store fee. Not the sticker price.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14, fontWeight: FontWeight.w600, height: 1.25),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final tier in _earnTiers)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tier.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.05),
                                  ),
                                  Text(
                                    tier.lines.first,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _openEarn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const EditableLabel('earn_home_sections.EarnUmbrellaSection',
                                'Open Earn',
                                style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    flex: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      child: FlipPortrait(
                        front: 'assets/banners/earn/sit-light.png',
                        back: 'assets/banners/earn/sit-dark.png',
                        fit: BoxFit.cover,
                        alignment: Alignment(0, 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5A3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: EditableLabel('earn_home_sections.EarnUmbrellaSection',
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
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
                  const SizedBox(height: 10),
                  const BrandTopBanner(
                    bare: true,
                    compact: true,
                    title: 'NowssB Rewards',
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
                mark: NwsbMarks.gift,
              ),
              const SizedBox(height: 10),
              const BrandTopBanner(
                bare: true,
                compact: true,
                title: 'NowssB Gifts',
                mark: NwsbMarks.gift,
              ),
              const SizedBox(height: 12),
              SecBanner(
                title: 'Send a gift',
                sub: 'A word, meaning, bundle, or plan. Paid with Play, not coins.',
                mark: NwsbMarks.gift,
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
      const SnackBar(content: EditableLabel('earn_home_sections.shared', 'Friend invite copied.')),
    );
  }
}
