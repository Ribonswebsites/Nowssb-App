/// The sections BOTH homes carry.
///
/// index.html writes each of these once and shows it on `#home` and
/// `#home-nm` alike; only the pane around it and the head on top of it
/// differ, and `widgets/home_skin.dart` is what decides those. Writing them
/// twice would mean two places to fix every time a word changes, and the two
/// would drift — which is the problem the website avoids by scoping its
/// stylesheet rather than forking its markup.
///
/// Subscription · Your Edition · My Routines · Quick Access · eBooks ·
/// Connect Banner · Personalised Healing · Choose Your Path · the footer
///
/// Copy is transcribed from index.html rather than paraphrased. Line numbers
/// on each class say where; the Fashion home's line is quoted, and the
/// Normal home's twin of it is listed beside it where they differ.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../media/nwsb_image.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/home_parts.dart';
import '../widgets/home_skin.dart';
import '../widgets/tv_frame.dart';

/// 16 · subvid — index.html:2166. `.nsub-blk` — head, the tall clip on the
/// slim landscape tablet with Subscribe Today on it, then the bar.
class SubscriptionSection extends StatelessWidget {
  const SubscriptionSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'The Full Library',
            title: 'NowssB Subscription',
            icon: Icons.workspace_premium_outlined,
          ),
          TvFrame(
            asset: 'assets/video/subscription-a.mp4',
            frame: DeviceFrame.tabletSlimLandscape,
            onTap: onTap,
            overlay: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ScreenCta(label: 'Subscribe Today', onTap: onTap),
              ),
            ),
          ),
          const SizedBox(height: 14),
          NcbCarousel(
            onTap: onTap,
            slides: const [
              (
                Icons.workspace_premium_outlined,
                'Subscribe Today',
                'Every word and every frequency, unlocked',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 17 · edition — index.html:2197. `#sub-promo-card` on the slim portrait
/// tablet: the plan labels pinned to the head of the screen, the promise and
/// the benefits above the button, Upgrade Now and the price at the foot.
class EditionSection extends StatelessWidget {
  const EditionSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: TvFrame(
        asset: 'assets/video/subscription-a.mp4',
        frame: DeviceFrame.tabletSlim,
        priority: ClipPriority.decoration,
        onTap: onTap,
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00060C18),
                    Color(0x26060C18),
                    Color(0xB8060C18),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Text(
                        'NOWSSB EDITION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'FREE PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Color(0xBFC8E8F5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Unlock your full\nhealing potential',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '50+ premium words · AI pronunciation scoring · '
                    '5 custom routines · Priority access to new word drops',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Color(0xD1FFFFFF),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: Colors.white,
                          child: const Text(
                            'Upgrade Now',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: NwsbColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        r'from $4.99/mo',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: Color(0xD9E8D5A3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 18 · routines — index.html:2223. `defOff`. The Daily Practice card and
/// the My Routines bar, in one wrapper.
class RoutinesSection extends StatelessWidget {
  const RoutinesSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhotoCard(
            background: const NwsbImage(
              url:
                  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778078302/grok_image_1778070967319_ys14eq.jpg',
              fallback: ColoredBox(color: Color(0xFF060C18)),
            ),
            label: 'My Routines',
            title: 'Daily Practice System',
            sub: '5 customizable routines — Morning, Midday, Afternoon, '
                'Evening, Night. Build your personal healing schedule.',
            onTap: onTap,
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'My Routines',
            sub: 'Five routines — build your healing schedule',
            icon: Icons.checklist_rtl,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 20 · cube — index.html:2281. `#fashCubeSec` — Quick Access. The head, the
/// three buttons on the landscape television, and a bar that cycles with
/// them.
///
/// The rotating cube and the 2x2 grid are gone from the markup; this is the
/// television block the Normal home has, in glass.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key, this.onCart, this.onWishlist, this.onOrders});

  final VoidCallback? onCart;
  final VoidCallback? onWishlist;
  final VoidCallback? onOrders;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Everything You Own',
            title: 'On One Screen',
            icon: Icons.grid_view_rounded,
          ),
          TvFrame(
            asset: 'assets/video/tv-screen.mp4',
            frame: DeviceFrame.tvLandscape,
            overlay: Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Cart',
                    onTap: onCart,
                  ),
                ),
                const _QuickRule(),
                Expanded(
                  child: _QuickButton(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    onTap: onWishlist,
                  ),
                ),
                const _QuickRule(),
                Expanded(
                  child: _QuickButton(
                    icon: Icons.work_outline,
                    label: 'Order',
                    onTap: onOrders,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // "Its contents cycle through Cart, Wishlist and Order" —
          // index.html:2329.
          NcbCarousel(
            onTap: onCart,
            slides: const [
              (
                Icons.shopping_cart_outlined,
                'Your Cart',
                "Everything you're ready to buy",
              ),
              (
                Icons.favorite_border,
                'Your Wishlist',
                'The words you are saving for later',
              ),
              (
                Icons.work_outline,
                'Your Orders',
                'Everything you have unlocked so far',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickRule extends StatelessWidget {
  const _QuickRule();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: const Color(0x1AFFFFFF));
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xB8FFFFFF)),
          ),
        ],
      ),
    );
  }
}

/// 22 · ebooks — index.html:1845. The same spill / clip / copy / banner
/// order the Reader has.
class EbooksSection extends StatelessWidget {
  const EbooksSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Deep-dive guides, yours to keep',
            icon: Icons.menu_book_outlined,
            onTap: onTap,
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: NwsbImage(
                  url:
                      'https://res.cloudinary.com/eenvubod/video/upload/v1785406073/grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
                  fallback: NwsbVideo(
                    asset: 'assets/video/word-acts.mp4',
                    priority: ClipPriority.decoration,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NowssB',
                style: TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
              ),
              Text(
                'eBooks',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Word science and sound healing, read anywhere.',
                style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: EnterPill(onTap: onTap)),
          const SizedBox(height: 16),
          SecBanner(
            title: 'eBooks',
            sub: 'Deep-dive guides, yours to keep',
            icon: Icons.menu_book_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 23 · connectban — index.html:1878. `.nc-blk` — the head, the banner clip
/// on the curved landscape tablet, and the features carousel.
class ConnectBannerSection extends StatelessWidget {
  const ConnectBannerSection({super.key, this.onTap});
  final VoidCallback? onTap;

  /// FEATURES — app/js/part049.js:200. Connect's own five.
  static const _features = [
    (
      Icons.dynamic_feed_outlined,
      'Community Feed',
      'Share your daily practice with the world',
    ),
    (Icons.circle_outlined, 'Stories', 'Drop 24-hour frequency moments'),
    (
      Icons.video_library_outlined,
      'Reels',
      'Watch & post short healing reels',
    ),
    (Icons.explore_outlined, 'Discover Creators', 'Find people worth following'),
    (Icons.verified_outlined, 'Verified', 'Earn your NowssB check-mark'),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'The Social Space',
            title: 'NowssB Connect',
            icon: Icons.people_outline,
          ),
          TvFrame(
            asset: 'assets/video/connect-banner.mp4',
            frame: DeviceFrame.tabletCurveLandscape,
            onTap: onTap,
          ),
          const SizedBox(height: 14),
          NcbCarousel(slides: _features, onTap: onTap),
        ],
      ),
    );
  }
}

/// 24 · healing — index.html:2377. `.health-journey-card` — the clip behind
/// everything, the mark and the label at the head, the title, the copy and
/// Explore at the foot.
class HealingSection extends StatelessWidget {
  const HealingSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const NwsbImage(
                  url:
                      'https://res.cloudinary.com/eenvubod/video/upload/v1784888091/grok_video_2026-07-24-15-42-55_lknomr.mp4',
                  fallback: NwsbVideo(
                    asset: 'assets/video/healing-path-bg.mp4',
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x73000000), Color(0xF2000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0x1FFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border,
                                size: 17, color: NwsbColors.goldLight),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Personalised Healing',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Your Health\nJourney',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Choose your path — body, organ & mind wellness '
                        'decoded through word science.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xB3FFFFFF),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        color: Colors.white,
                        child: const Text(
                          'Explore →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: NwsbColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 25 · genderpath — injected by app/js/part067.js:49. The head, the clip on
/// the laptop with Female and Male over their own halves of it, and the bar.
///
/// No panel behind the two words: the point of the section is the film, and
/// a card over it would cover the thing being chosen between.
class GenderPathSection extends StatelessWidget {
  const GenderPathSection({super.key, this.onFemale, this.onMale, this.onTap});

  final VoidCallback? onFemale;
  final VoidCallback? onMale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Body, organ and mind',
            title: 'Choose Your Path',
            icon: Icons.transgender,
          ),
          TvFrame(
            asset: 'assets/video/healing-path-bg.mp4',
            frame: DeviceFrame.laptop,
            onTap: onTap,
            overlay: Row(
              children: [
                Expanded(child: _GenderSide(label: 'Female', onTap: onFemale)),
                Expanded(child: _GenderSide(label: 'Male', onTap: onMale)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Female or Male',
            sub: 'Your wellness, decoded for your body',
            icon: Icons.transgender,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _GenderSide extends StatelessWidget {
  const _GenderSide({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xCC000000), blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EnterPill(onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 30 · footer — index.html:2571. Across Every Language: the intro, the ten
/// moving pictures with the tablet fixed at the centre of them, and the
/// brand panel.
class HomeFooterSection extends StatefulWidget {
  const HomeFooterSection({super.key, this.onLink});

  /// Called with the link's key — about · word-science · sound-library ·
  /// meaning-store · practice · profile.
  final void Function(String key)? onLink;

  @override
  State<HomeFooterSection> createState() => _HomeFooterSectionState();
}

class _HomeFooterSectionState extends State<HomeFooterSection> {
  /// The ten in `#footerTrack` — index.html:2596.
  static const _shots = [
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931241446_2_oqn7z0.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931251298_2_nuhjin.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931991083_2_eyvogv.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776932343988_3_bofj1s.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931659181_2_l3dxyi.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931253654_2_hrtsra.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934920/grok_image_1776932830246_2_x0yyb6.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776933033268_2_m3fmo9.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776932933365_2_jb1lch.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776932486772_2_spplq4.jpg',
  ];

  static const _links = [
    ('About', 'about'),
    ('Word Science', 'word-science'),
    ('Sound Library', 'sound-library'),
    ('Meaning Store', 'meaning-store'),
    ('Practice', 'practice'),
    ('Profile', 'profile'),
  ];

  final _rail = PageController(viewportFraction: 0.62);
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (!_rail.hasClients) return;
      _i = (_i + 1) % _shots.length;
      _rail.animateToPage(
        _i,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _rail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Across Every Language',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.goldLight,
                  ),
                ),
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 25, height: 1.25),
                    children: [
                      TextSpan(
                        text: 'Every civilization\n',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Color(0xE0FFFFFF),
                        ),
                      ),
                      TextSpan(
                        text: 'heard the same\n',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: 'original sound.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Different words. One root. All languages descend from the '
                  'same vibrational origin.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0x99FFFFFF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // The pictures move; the tablet does not. It is drawn over the
          // middle of the rail rather than around any one card, which is
          // what `.fc-tab` is on the web.
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _rail,
                  itemCount: _shots.length,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (context, i) => AnimatedScale(
                    duration: const Duration(milliseconds: 320),
                    scale: i == _i ? 1 : 0.86,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ClipRect(
                        child: NwsbImage(
                          url: _shots[i],
                          fallback: const ColoredBox(color: Color(0xFF0A0F1C)),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    child: Image.asset(
                      'assets/frames/tab-nowss8-portrait.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _shots.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _i
                          ? NwsbColors.goldLight
                          : const Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              children: [
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 26, color: Colors.white),
                    children: [
                      TextSpan(
                        text: 'Nowsb',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'ansiu',
                        style: TextStyle(fontWeight: FontWeight.w200),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                    children: [
                      TextSpan(text: 'Natural Origin of '),
                      TextSpan(
                        text: 'Word Science',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xBFC8E8F5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: const Color(0x14FFFFFF)),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    for (final (label, key) in _links)
                      GestureDetector(
                        onTap: () => widget.onLink?.call(key),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  '© 2026 Adv. Sanjaykumar Gadge · Shabdapathy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0x73FFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
