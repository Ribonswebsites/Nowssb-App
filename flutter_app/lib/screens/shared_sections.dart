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

import '../widgets/nwsb_icon.dart';

import '../media/nwsb_image.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/home_parts.dart';
import '../widgets/neu_wrap.dart';
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
            mark: NwsbMarks.crown,
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
                NwsbMarks.crown,
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

/// 17 · edition — index.html:2197. `.nedi-blk`.
///
/// ONE SECTION, not two. This card and the promo were both showing the
/// subscription film — the same clip twice, a few inches apart, one of them
/// sitting on a still. They are folded together here under the key the
/// website's own registry already has, so nothing had to be invented and the
/// order did not move.
///
/// Built the way every other block on these homes is built: the orb and its
/// two lines, the set, and one black bar saying where it goes. The offer is
/// the only thing on the screen, set into the top-left of the film where
/// this clip stays dark, so it reads as part of the picture.
class EditionSection extends StatelessWidget {
  const EditionSection({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Free plan · upgrade any time',
            title: 'NowssB Edition',
            mark: NwsbMarks.crown,
          ),
          TvFrame(
            asset: 'assets/video/subscription-promo.mp4',
            frame: DeviceFrame.kioskPortrait,
            priority: ClipPriority.decoration,
            onTap: onTap,
            overlay: const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: _PromoOffer(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Upgrade Now',
            sub: r'From $4.99 a month · every word and frequency unlocked',
            mark: NwsbMarks.crown,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// The offer — the mark, then the number, then the small print.
///
/// Typed the way this app types a headline, which is `.login-title`
/// (app/app.css): one 42px DM Sans line split between weight 800 and weight
/// 200, with a 9px letter-spaced-4 uppercase accent line under it. Not a new
/// look — the same one the sign-in screen opens with.
///
/// The big line is scaled down to fit rather than allowed to wrap. This sits
/// inside a tablet's aperture, which is narrower than the card that holds it,
/// and "30 Days Free" at a fixed 44px runs to three lines in there.
class _PromoOffer extends StatelessWidget {
  const _PromoOffer();

  /// `text-shadow: 0 2px 20px rgba(0,0,0,0.85)`. The clip behind this is
  /// bright in places, and the headline has to hold on all ten seconds of it.
  static const _lift = [
    Shadow(color: Color(0xD9000000), blurRadius: 20, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Join today for',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xE0FFFFFF),
            height: 1.15,
            shadows: _lift,
          ),
        ),
        SizedBox(height: 2),
        // `clamp(30px, 9vw, 44px)` on the web; here the same thing, done by
        // shrinking to the width there actually is.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                height: 1.02,
                letterSpacing: -1,
                color: Colors.white,
                shadows: _lift,
              ),
              children: [
                TextSpan(text: '30 Days '),
                TextSpan(
                  text: 'Free',
                  style: TextStyle(color: NwsbColors.goldLight),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Opacity(
          opacity: 0.85,
          child: Text(
            'SUBSCRIBE · CANCEL ANYTIME',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              color: NwsbColors.goldLight,
              shadows: _lift,
            ),
          ),
        ),
      ],
    );
  }
}

/// THE SIX — every main door in the app, on one compact panel.
///
/// Three across and two down, each cell a mark over its name, with a hairline
/// standing between them. It exists so the app can be used without knowing
/// where anything is: five of these are the tab bar's own destinations and
/// the sixth is the one people look hardest for.
///
/// Both homes, one widget. [SectionPane] makes the panel glass on the Fashion
/// home and a raised neumorphic card on the Normal one, and [PaneHead] gives
/// the heading a white disc on the first and a neumorphic disc on the second
/// — so the two looks come from the skin rather than from two copies of this.
///
/// Kept SHORT on purpose. A cell is a mark, a word and the air around them;
/// the whole panel is about the height of one banner, because a menu that
/// pushes the page down is a menu that gets scrolled past.
class MainOptionsSection extends StatelessWidget {
  const MainOptionsSection({super.key, this.onGo, this.onAction});

  /// Called with the tab the option opens.
  final void Function(int tab)? onGo;

  /// Optional direct destination for an option whose label has a dedicated
  /// usable page rather than only a broad tab category.
  final void Function(String label, int tab)? onAction;

  /// A row's height. Deliberately tight: the whole panel is a menu, and a
  /// menu that pushes the page down is one that gets scrolled past.
  static const double rowHeight = 62;

  /// (mark, the box that mark was drawn in, label, tab).
  static const options = <(String, double, String, int)>[
    (NwsbMarks.play, 22, 'Practice', 1),
    (NwsbMarks.sound, 24, 'Sound Library', 2),
    (NwsbMarks.word, 24, 'Word Science', 2),
    (NwsbMarks.bag, 24, 'The Store', 3),
    (NwsbMarks.people, 24, 'Connect', 0),
    (NwsbMarks.trending, 22, 'My Progress', 4),
  ];

  @override
  Widget build(BuildContext context) {
    final fashion = HomeSkinScope.of(context) == HomeSkin.fashion;
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Everything, one tap away',
            title: 'Where to Begin',
            mark: NwsbMarks.sliders,
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color:
                  fashion ? const Color(0x0FFFFFFF) : const Color(0x081A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    fashion ? const Color(0x1FFFFFFF) : const Color(0x141A1A2E),
              ),
            ),
            child: Column(
              children: [
                _OptRow(
                  options.sublist(0, 3),
                  fashion: fashion,
                  onGo: onGo,
                  onAction: onAction,
                ),
                _OptRow(
                  options.sublist(3, 6),
                  fashion: fashion,
                  onGo: onGo,
                  onAction: onAction,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Find Your Way Around',
            sub: 'Every screen in the app, and what each one is for',
            mark: NwsbMarks.sliders,
            onTap: () => onGo?.call(4),
          ),
        ],
      ),
    );
  }
}

/// Three cells with a hairline between each.
class _OptRow extends StatelessWidget {
  const _OptRow(this.items,
      {required this.fashion, this.onGo, this.onAction});

  final List<(String, double, String, int)> items;
  final bool fashion;
  final void Function(int tab)? onGo;
  final void Function(String label, int tab)? onAction;

  @override
  Widget build(BuildContext context) {
    final rule = fashion ? const Color(0x1FFFFFFF) : const Color(0x141A1A2E);
    return SizedBox(
      height: MainOptionsSection.rowHeight,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: rule),
            Expanded(
              child: _Opt(
                items[i],
                fashion: fashion,
                onGo: onGo,
                onAction: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One door: the mark, and the word under it.
class _Opt extends StatelessWidget {
  const _Opt(this.item,
      {required this.fashion, this.onGo, this.onAction});

  final (String, double, String, int) item;
  final bool fashion;
  final void Function(int tab)? onGo;
  final void Function(String label, int tab)? onAction;

  @override
  Widget build(BuildContext context) {
    final (mark, box, label, tab) = item;
    return GestureDetector(
      onTap: () {
        if (onAction != null) {
          onAction!(label, tab);
        } else {
          onGo?.call(tab);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          NwsbIcon(
            mark,
            size: 21,
            viewBox: box,
            color: fashion ? NwsbColors.goldLight : WrapHead.markGold,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: fashion ? const Color(0xE6FFFFFF) : NwsbColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 15 · storeban — index.html:2155. `.fash-storeban-wrap` — the head, the
/// clip, and the Shop the Library bar.
///
/// BOTH HOMES. app/js/part062.js:82 registers 'storeban' on the Normal home
/// too, against this same selector, and for a long time there was no element
/// for it to match there: the Normal home just dropped a bare clip above its
/// store card, with no heading, no device and no bar under it, while the
/// Fashion home carried the same thing as a proper block. app/js/part067.js
/// builds it on both now, and so does this.
///
/// [framed] is the one difference. The Normal home shows the clip on the
/// landscape tablet; the Fashion home's runs full-bleed, which is what its
/// markup has always done.
class StoreBannerSection extends StatelessWidget {
  const StoreBannerSection({super.key, this.onTap, this.framed = false});
  final VoidCallback? onTap;
  final bool framed;

  static const _clip = 'assets/video/store-banner-fash.mp4';

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Own the sounds that heal',
            title: 'Inside the Store',
            mark: NwsbMarks.bag,
          ),
          if (framed)
            TvFrame(
              asset: _clip,
              frame: DeviceFrame.tabletLandscape,
              priority: ClipPriority.decoration,
              onTap: onTap,
            )
          else
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: const AspectRatio(
                aspectRatio: 1136 / 800,
                child: ClipRect(child: NwsbVideo(asset: _clip)),
              ),
            ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Shop the Library',
            sub: 'Words, meanings and the origins behind them',
            mark: NwsbMarks.bag,
            onTap: onTap,
          ),
        ],
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
                  'https://media.nowssb.com/migrated-images/4f13105270db8787_grok_image_1778070967319_ys14eq.jpg',
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
            mark: NwsbMarks.play,
            markViewBox: 22,
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
  const QuickAccessSection(
      {super.key, this.onCart, this.onWishlist, this.onOrders});

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
            mark: NwsbMarks.order,
            markViewBox: 22,
          ),
          TvFrame(
            asset: 'assets/video/tv-screen.mp4',
            frame: DeviceFrame.tvLandscape,
            overlay: Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    mark: NwsbMarks.cart,
                    markViewBox: 22,
                    label: 'Cart',
                    onTap: onCart,
                  ),
                ),
                const _QuickRule(),
                Expanded(
                  child: _QuickButton(
                    mark: NwsbMarks.wishlist,
                    markViewBox: 22,
                    label: 'Wishlist',
                    onTap: onWishlist,
                  ),
                ),
                const _QuickRule(),
                Expanded(
                  child: _QuickButton(
                    mark: NwsbMarks.order,
                    markViewBox: 22,
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
                NwsbMarks.cart,
                'Your Cart',
                "Everything you're ready to buy",
              ),
              (
                NwsbMarks.wishlist,
                'Your Wishlist',
                'The words you are saving for later',
              ),
              (
                NwsbMarks.order,
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
  const _QuickButton({
    required this.mark,
    this.markViewBox = 22,
    required this.label,
    this.onTap,
  });
  final String mark;
  final double markViewBox;
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
          NwsbIcon(mark, size: 22, viewBox: markViewBox),
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
            mark: NwsbMarks.ebook,
            markViewBox: 22,
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
                      'assets/videos/beaf11ea10561d43_grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
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
          Align(
              alignment: Alignment.centerLeft, child: EnterPill(onTap: onTap)),
          const SizedBox(height: 16),
          SecBanner(
            title: 'eBooks',
            sub: 'Deep-dive guides, yours to keep',
            mark: NwsbMarks.ebook,
            markViewBox: 22,
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
      NwsbMarks.feed,
      'Community Feed',
      'Share your daily practice with the world',
    ),
    (NwsbMarks.stories, 'Stories', 'Drop 24-hour frequency moments'),
    (
      NwsbMarks.reels,
      'Reels',
      'Watch & post short healing reels',
    ),
    (NwsbMarks.discover, 'Discover Creators', 'Find people worth following'),
    (NwsbMarks.verified, 'Verified', 'Earn your NowssB check-mark'),
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
            mark: NwsbMarks.people,
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
                      'assets/videos/28eb0c85b5fd748e_grok_video_2026-07-24-15-42-55_lknomr.mp4',
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
            mark: NwsbMarks.gender,
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
            mark: NwsbMarks.gender,
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
    'https://media.nowssb.com/migrated-images/de6f1331af862c18_grok_image_1776931241446_2_oqn7z0.jpg',
    'https://media.nowssb.com/migrated-images/c63fd60894cef334_grok_image_1776931251298_2_nuhjin.jpg',
    'https://media.nowssb.com/migrated-images/7b69c8d374502725_grok_image_1776931991083_2_eyvogv.jpg',
    'https://media.nowssb.com/migrated-images/ef785a342307f508_grok_image_1776932343988_3_bofj1s.jpg',
    'https://media.nowssb.com/migrated-images/f67dedbd317ef3c3_grok_image_1776931659181_2_l3dxyi.jpg',
    'https://media.nowssb.com/migrated-images/43cdce970c2897dd_grok_image_1776931253654_2_hrtsra.jpg',
    'https://media.nowssb.com/migrated-images/e4a21614b9e3d1c0_grok_image_1776932830246_2_x0yyb6.jpg',
    'https://media.nowssb.com/migrated-images/378e89b2f157b2a9_grok_image_1776933033268_2_m3fmo9.jpg',
    'https://media.nowssb.com/migrated-images/4ef4e116dedc8ef6_grok_image_1776932933365_2_jb1lch.jpg',
    'https://media.nowssb.com/migrated-images/c37c1f7e2c2a1fa0_grok_image_1776932486772_2_spplq4.jpg',
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
