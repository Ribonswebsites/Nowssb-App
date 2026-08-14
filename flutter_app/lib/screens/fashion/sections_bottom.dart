/// Fashion home sections 16-30, in registry order.
///
/// subvid · edition · routines · offer · cube · shabda · ebooks ·
/// connectban · healing · genderpath · promovid · wsearch · msearch ·
/// shabvid · footer
///
/// Four of these — routines, shabda, wsearch, msearch — are `defOff` in
/// `REG.fash.items`: built, and hidden on a fresh install. They are widgets
/// here like any other; `home_fashion.dart` decides whether to place them.
///
/// Copy is transcribed from index.html rather than paraphrased. Line numbers
/// on each class say where.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/tv_frame.dart';
import 'parts.dart';

/// 16 · subvid — index.html:2166. `.nsub-blk` — head, the tall clip on the
/// slim landscape tablet with Subscribe Today on it, then the bar.
class FashSubscription extends StatelessWidget {
  const FashSubscription({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
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
                child: _ScreenCta(label: 'Subscribe Today', onTap: onTap),
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

/// `.fash-banner-cta` — the dark chip that sits ON a clip.
///
/// The mark is the cart on every one of them: `.nmh-cta-go` carries the same
/// trolley whether the chip says Subscribe Today or Shop Now, because both
/// end at the same till.
class _ScreenCta extends StatelessWidget {
  const _ScreenCta({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 13, color: Color(0xEBFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 17 · edition — index.html:2197. `#sub-promo-card` on the slim portrait
/// tablet: the plan labels pinned to the head of the screen, the promise and
/// the benefits above the button, Upgrade Now and the price at the foot.
class FashEdition extends StatelessWidget {
  const FashEdition({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
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
class FashRoutines extends StatelessWidget {
  const FashRoutines({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
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

/// 19 · offer — index.html:2252. The coupon art — a clip, not a picture,
/// since app/js/part067.js:110 turned it into one — with Shop Now on it, and
/// Today's Offer underneath.
class FashOffer extends StatelessWidget {
  const FashOffer({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const NwsbVideo(
                      asset: 'assets/video/coupon-a.mp4',
                      priority: ClipPriority.decoration,
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _ScreenCta(label: 'Shop Now', onTap: onTap),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: "Today's Offer",
            sub: "Rotating store coupons — tap to redeem today's deal",
            icon: Icons.local_offer_outlined,
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
class FashQuickAccess extends StatelessWidget {
  const FashQuickAccess({super.key, this.onCart, this.onWishlist, this.onOrders});

  final VoidCallback? onCart;
  final VoidCallback? onWishlist;
  final VoidCallback? onOrders;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
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

/// 21 · shabda — index.html:2347. `defOff`. Featured / Shabdapathy
/// Foundations, and its bar.
class FashShabdapathy extends StatelessWidget {
  const FashShabdapathy({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhotoCard(
            background: const NwsbImage(
              url:
                  'https://res.cloudinary.com/eenvubod/image/upload/v1785054819/file_000000002a1481fbae984a694c298783_lkwus2.png',
              fallback: ColoredBox(color: Color(0xFF060C18)),
            ),
            label: 'Featured',
            title: 'Shabdapathy Foundations',
            sub: 'Ancient word science meets modern wellness. Explore the '
                'healing power of natural word origins.',
            onTap: onTap,
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Shabdapathy Foundations',
            sub: 'Ancient word science, meets modern wellness',
            icon: Icons.auto_stories_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 22 · ebooks — index.html:1845. The same spill / clip / copy / banner
/// order the Reader has.
class FashEbooks extends StatelessWidget {
  const FashEbooks({super.key, this.onTap});
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
class FashConnectBanner extends StatelessWidget {
  const FashConnectBanner({super.key, this.onTap});
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
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
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
class FashHealing extends StatelessWidget {
  const FashHealing({super.key, this.onTap});
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
class FashGenderPath extends StatelessWidget {
  const FashGenderPath({super.key, this.onFemale, this.onMale, this.onTap});

  final VoidCallback? onFemale;
  final VoidCallback? onMale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
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

/// 26 · promovid — index.html:2400. `#fashPromoVid` — the promo clip on the
/// landscape tablet, and nothing else.
///
/// It used to be a bare 16:9 box whose wrapper was `background: transparent`,
/// which is why it had nothing behind it.
class FashPromoVideo extends StatelessWidget {
  const FashPromoVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: TvFrame(
        asset: 'assets/video/orb-loop.mp4',
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.decoration,
        onTap: onTap,
      ),
    );
  }
}

/// 27 · wsearch — index.html:2411. `defOff`. The promo picture, then Word
/// Search: the clip, the copy and the field.
class FashWordSearch extends StatelessWidget {
  const FashWordSearch({super.key, this.onOpen});

  /// Called with whatever is in the field, empty when the section itself is
  /// tapped — the website opens the page either way and only runs a search
  /// when there is something to search for.
  final void Function(String query)? onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRect(
              child: NwsbImage(
                url:
                    'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778656121/grok_image_1778655491471_ss3vax.jpg',
                fallback: ColoredBox(color: Color(0xFF0A0F1C)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchPanel(
            eyebrow: 'Shabdapathy',
            title: 'Word Search',
            sub: 'Discover the natural origin and healing frequency of any '
                'word.',
            hint: 'Enter a word...',
            clip: 'assets/video/word-acts.mp4',
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

/// 28 · msearch — index.html:2438. `defOff`. The promo picture, then Know
/// The Real Meaning: the clip, the field at its foot, and the hint.
class FashMeaningSearch extends StatelessWidget {
  const FashMeaningSearch({super.key, this.onOpen});
  final void Function(String query)? onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRect(
              child: NwsbImage(
                url:
                    'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778656146/grok_image_1778656028544_cih9iy.jpg',
                fallback: ColoredBox(color: Color(0xFF0A0F1C)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchPanel(
            eyebrow: 'Sound Before Meaning',
            title: 'Know The Real Meaning',
            sub: 'Earth · Water · God · Your Name · Your Country',
            hint: 'Type any word, name or country...',
            clip: 'assets/video/orb-loop.mp4',
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

/// The shape both search sections take: a clip, the copy over it, and a
/// field that opens the page with whatever was typed.
class _SearchPanel extends StatefulWidget {
  const _SearchPanel({
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.hint,
    required this.clip,
    this.onOpen,
  });

  final String eyebrow, title, sub, hint, clip;
  final void Function(String query)? onOpen;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go() => widget.onOpen?.call(_c.text.trim());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onOpen?.call(''),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(asset: widget.clip, priority: ClipPriority.decoration),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0xF2000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.eyebrow,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sub,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xB3FFFFFF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        border: Border.all(color: const Color(0x2EFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _c,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _go(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: widget.hint,
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0x73FFFFFF),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _go,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              child: const Icon(Icons.arrow_forward,
                                  size: 16, color: NwsbColors.ink),
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
      ),
    );
  }
}

/// 29 · shabvid — index.html:2547. The 16:9 banner above the footer, on the
/// landscape tablet, with the three lines and the wordmark.
class FashShabdaVideo extends StatelessWidget {
  const FashShabdaVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: TvFrame(
        asset: 'assets/video/word-acts.mp4',
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.decoration,
        onTap: onTap,
        overlay: const Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xD9000000), Color(0x1A000000)],
                ),
              ),
            ),
            // The copy and the wordmark are placed against the screen, not
            // stacked in a Flex. A tablet aperture is a FIXED box — a
            // vertical Column inside one overflows the moment the type is a
            // line taller than expected, which at a large text scale it is.
            // `.hvb-text` and `.hvb-label` are absolutely positioned on the
            // web for exactly this reason.
            Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shabdapathy',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 20, height: 1.25),
                          children: [
                            TextSpan(
                              text: 'Before language\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w200,
                                color: Color(0xEBFFFFFF),
                              ),
                            ),
                            TextSpan(
                              text: 'was written,\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'it was sound.',
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
                        'Natural Origin of Word Science',
                        style:
                            TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Nowsbansiu',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 30 · footer — index.html:2571. Across Every Language: the intro, the ten
/// moving pictures with the tablet fixed at the centre of them, and the
/// brand panel.
class FashFooter extends StatefulWidget {
  const FashFooter({super.key, this.onLink});

  /// Called with the link's key — about · word-science · sound-library ·
  /// meaning-store · practice · profile.
  final void Function(String key)? onLink;

  @override
  State<FashFooter> createState() => _FashFooterState();
}

class _FashFooterState extends State<FashFooter> {
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
