/// Home doors for NowssB Earn, Rewards, and Gifts.
///
/// Built from the same [SectionPane], [PaneHead], [SecBanner], and
/// [ColoredSplitPromoBanner] the rest of Home already uses. The split
/// banner sits above the glass pane, not inside it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import '../../admin/layout/scopes.dart';
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
import '../economy/coupon_screen.dart';
import '../programs/coupons_program.dart';
import '../programs/gifts_program.dart';
import '../programs/partner_program.dart';
import '../programs/reference_program.dart';
import '../../admin/template/editable.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class _EarnTier {
  const _EarnTier(this.name, this.detail, this.badge, this.lines, this.mark);
  final String name;
  final String detail;
  final String badge;
  final List<String> lines;
  final String mark;
}

/// NowssB Earn ranks (the 21-page plan's ranks and rates, paid from Net
/// after tax and the Play fee). Read live from config/economy through the
/// server summary; these defaults only show before the first answer.
const _defaultRanks = <Map<String, Object>>[
  {'title': 'Assistant Officer', 'minWords': 0, 'ratePct': 15, 'leg': [0, 0]},
  {'title': 'Officer', 'minWords': 100, 'ratePct': 22, 'leg': [3, 0]},
  {'title': 'Executive Officer I', 'minWords': 500, 'ratePct': 30, 'leg': [5, 1.5]},
  {'title': 'Executive Officer II', 'minWords': 1000, 'ratePct': 38, 'leg': [5, 1.5]},
  {'title': 'Diamond I', 'minWords': 2000, 'ratePct': 45, 'leg': [7, 3]},
  {'title': 'Diamond II', 'minWords': 3000, 'ratePct': 50, 'leg': [7, 3]},
];

const _tierMarks = [NwsbMarks.piggy, NwsbMarks.crown, NwsbMarks.verified, NwsbMarks.gift, NwsbMarks.bag, NwsbMarks.crown];

List<_EarnTier> get _earnTiers {
  final cfg = EconomyMirror.instance.summary['config'];
  final earn = cfg is Map ? cfg['earn'] : null;
  final raw = earn is Map && earn['ranks'] is List && (earn['ranks'] as List).isNotEmpty ? (earn['ranks'] as List) : _defaultRanks;
  String n(Object? v) => v is num ? (v == v.roundToDouble() ? '${v.round()}' : '$v') : '${v ?? 0}';
  final out = <_EarnTier>[];
  for (var i = 0; i < raw.length; i++) {
    final r = raw[i];
    if (r is! Map) continue;
    final rate = n(r['ratePct']);
    final leg = r['leg'] is List ? r['leg'] as List : const [0, 0];
    final l1 = leg.isNotEmpty ? n(leg[0]) : '0';
    final l2 = leg.length > 1 ? n(leg[1]) : '0';
    out.add(_EarnTier(
      '${r['title'] ?? 'Rank ${i + 1}'}',
      '${n(r['minWords'])}+ words · $rate% of Net',
      '$rate%',
      [
        '$rate% of Net (after tax and the Play fee)',
        if (l1 != '0') 'Team level 1: $l1%${l2 != '0' ? ' · level 2: $l2%' : ''}',
        'Paid plan required · money lock applies',
      ],
      _tierMarks[i % _tierMarks.length],
    ));
  }
  return out;
}

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
      if (editorHoldsStill(context)) return;
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
      height: 440,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _userPaging = true;
          } else if (n is ScrollEndNotification) {
            _userPaging = false;
          }
          return false;
        },
        child: Listener(
          // A finger on the card pauses the auto-slide until it lifts.
          onPointerDown: (_) => _userPaging = true,
          onPointerUp: (_) => _userPaging = false,
          onPointerCancel: (_) => _userPaging = false,
          child: PageView(
          controller: _pager,
          physics: const ClampingScrollPhysics(),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 7,
                    child: EditableImage.asset(
                      'assets/banners/brand-cleo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      slot: 'earn_home_sections.EarnUmbrellaSection',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EditableLabel(
                          'earn_home_sections.EarnUmbrellaSection',
                          'Join today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openEarn,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const EditableLabel(
                              'earn_home_sections.EarnUmbrellaSection',
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
                  ),
                ],
              ),
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
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const NwsbIcon(NwsbMarks.piggy, size: 20, color: Colors.black),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 6, 6),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        EditableLabel('earn_home_sections.EarnUmbrellaSection',
                          'Earn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: ColoredBox(
                    color: Color(0xFF000000),
                    child: EditableImage.asset(
                      'assets/banners/earn/bag-blonde.jpg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      slot: 'earn_home_sections.EarnUmbrellaSection',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlipPortrait(
                        front: 'assets/banners/earn/hands-light.png',
                        back: 'assets/banners/earn/hands-dark.png',
                        fit: BoxFit.cover,
                        alignment: Alignment(0, -0.08),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Color(0xCC000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: EditableLabel('earn_home_sections.EarnUmbrellaSection',
                            'Your share\nof the net.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 13,
                child: Column(
                  children: [
                    for (var i = 0; i < _earnTiers.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      Expanded(child: _tierBox(_earnTiers[i])),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tier.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
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
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'How you get paid',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const EditableLabel('earn_home_sections.EarnUmbrellaSection',
              'Net after the store fee. Not the sticker price.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: const Stack(
                        fit: StackFit.expand,
                        children: [
                          FlipPortrait(
                            front: 'assets/banners/earn/sit-light.png',
                            back: 'assets/banners/earn/sit-dark.png',
                            fit: BoxFit.cover,
                            alignment: Alignment(0, 0.82),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: [Color(0xCC000000), Color(0x00000000)],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: EditableLabel('earn_home_sections.EarnUmbrellaSection',
                                'Your code.\nPaid on net.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, height: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 12,
                    child: Column(
                      children: [
                        for (final tier in _earnTiers)
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: NwsbIcon(tier.mark, size: 14, color: Colors.black),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tier.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.05),
                                      ),
                                      Text(
                                        tier.lines.first,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 10, height: 1.15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _openEarn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const EditableLabel('earn_home_sections.EarnUmbrellaSection',
                                'Open Earn',
                                style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    mark: NwsbMarks.rewards,
                  ),
                  const SizedBox(height: 10),
                  const BrandTopBanner(
                    bare: true,
                    compact: true,
                    title: 'NowssB Rewards',
                    mark: NwsbMarks.rewards,
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
                      mark: NwsbMarks.rewards,
                      onTap: () => EarnUmbrellaSection._open(context, const VaultScreen()),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SecBanner(
                    title: 'Invite a friend',
                    sub: 'Share your link. Your friend gets a discount; you earn when they buy for real.',
                    mark: NwsbMarks.verified,
                    onTap: () => EarnUmbrellaSection._open(context, const ReferenceProgramPage()),
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
                title: 'Gift rules and history',
                sub: 'Free boxes, gift cards, what you sent and received',
                mark: NwsbMarks.bag,
                onTap: () => EarnUmbrellaSection._open(context, const GiftsProgramPage()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Dest { earn, rewards, gifts, resell, reference }

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
        if (editorHoldsStill(context)) return;
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
      _Dest.reference => const ReferenceProgramPage(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _banner(_Slide slide) => ColoredSplitPromoBanner(
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
      );

  @override
  Widget build(BuildContext context) {
    // One slide: just the banner, nothing to swipe or bounce.
    if (widget.slides.length == 1) return _banner(widget.slides.first);
    return SizedBox(
      height: 148,
      child: PageView(
        controller: _pages,
        physics: const ClampingScrollPhysics(),
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


/// Home door for NowssB Coupons (scratch cards, odds, your coupons).
class CouponsHomeSection extends StatelessWidget {
  const CouponsHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaneHead(eyebrow: 'NowssB Coupons', title: 'Scratch, reveal, save', mark: NwsbMarks.coupon),
              const SizedBox(height: 12),
              SecBanner(
                title: 'Today\'s free card',
                sub: 'Drawn by NowssB. Odds are listed before you scratch.',
                mark: NwsbMarks.coupon,
                onTap: () => EarnUmbrellaSection._open(context, const CouponScreen()),
              ),
              const SizedBox(height: 8),
              SecBanner(
                title: 'Your coupons and odds',
                sub: 'Rarity shelves, codes and what each card can hold',
                mark: NwsbMarks.verified,
                onTap: () => EarnUmbrellaSection._open(context, const CouponsProgramPage()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Home door for NowssB Reference (your links, friend discount, ladder).
class ReferenceHomeSection extends StatelessWidget {
  const ReferenceHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OutsidePromo(
          slides: [
            _Slide(
              title: 'NowssB Reference',
              cta: 'Share a link',
              left: Color(0xFF14283D),
              right: Color(0xFF3D7AE0),
              art: SplitPromoArts.whiteRobot,
              dest: _Dest.reference,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionPane(
          child: ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PaneHead(eyebrow: 'NowssB Reference', title: 'Your links', mark: NwsbMarks.reference),
                const SizedBox(height: 12),
                SecBanner(
                  title: EconomyMirror.instance.code.isEmpty ? 'Get your link' : 'Your code ${EconomyMirror.instance.code}',
                  sub: 'Friends get a discount on their first real purchase. You earn coins and rewards.',
                  mark: NwsbMarks.reference,
                  onTap: () => EarnUmbrellaSection._open(context, const ReferenceProgramPage()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Home door for the NowssB Partner Program (Spark, Glow, Radiant).
class PartnerHomeSection extends StatelessWidget {
  const PartnerHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PaneHead(eyebrow: 'NowssB Partner', title: 'Spark · Glow · Radiant', mark: NwsbMarks.crown),
            const SizedBox(height: 12),
            SecBanner(
              title: '${EconomyMirror.instance.partnerPoints} partner points',
              sub: 'Points come only from real purchases through your links.',
              mark: NwsbMarks.crown,
              onTap: () => EarnUmbrellaSection._open(context, const PartnerProgramPage()),
            ),
          ],
        ),
      ),
    );
  }
}
