/// Normal home sections, second half — in `REG.norm.items` order.
///
/// connect · feed · trendshop · fashsw
///
/// The rest of this stretch — Quick Access, Subscription, Your Edition,
/// eBooks, the Connect banner, Personalised Healing, Choose Your Path, My
/// Routines and the footer — is in lib/screens/shared_sections.dart, written
/// once for both homes. `condisc` is the second [NmPromoDisc] and lives with
/// its twin in sections_top.dart.
///
/// Copy is transcribed from index.html rather than paraphrased. Line numbers
/// on each class say where.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';

import '../../data/content.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/neu_wrap.dart';
import '../../widgets/tv_frame.dart';

/// 15 · connect — index.html:1377. `.nmh-connect-sec` on the slim portrait
/// tablet: the clip, the scrim, the mark, the wordmark, the paragraph and
/// Enter Connect — all inside the aperture.
///
/// The frame classes go ON the section rather than in a wrapper around it,
/// because that is the element `REG.norm.items` matches.
class NmConnect extends StatelessWidget {
  const NmConnect({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TvFrame(
        asset: 'assets/video/connect-banner.mp4',
        frame: DeviceFrame.tabletSlim,
        onTap: onTap,
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x40000000), Color(0xF2000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(
                    width: 46,
                    height: 46,
                    child: NwsbImage(
                      url:
                          'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_240/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
                      fit: BoxFit.contain,
                      fallback: Icon(Icons.people_outline,
                          size: 24, color: NwsbColors.goldLight),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'NowssB '),
                        TextSpan(
                          text: 'Connect',
                          style: TextStyle(color: NwsbColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The social space of NowssB — share your daily practice, '
                    'post your frequency journey, and connect with a '
                    'community of sound healers and word-science '
                    'practitioners. Follow creators, react, and grow '
                    'together.',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xB3FFFFFF),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // White, and only as wide as its words. A stretched
                  // translucent bar reads as a panel; a small solid pill
                  // reads as the one thing to press.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Enter Connect',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: NwsbColors.ink,
                              ),
                            ),
                            SizedBox(width: 8),
                            NwsbIcon(NwsbMarks.arrow,
                                size: 14, color: NwsbColors.ink),
                          ],
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
    );
  }
}

/// 16 · feed — index.html:1332. `#ncbCarouselNm` — the Connect features
/// carousel, on its own here rather than inside a block.
class NmFeed extends StatelessWidget {
  const NmFeed({super.key, this.onTap});
  final VoidCallback? onTap;

  /// FEATURES — app/js/part049.js:200.
  static const features = [
    (
      NwsbMarks.feed,
      'Community Feed',
      'Share your daily practice with the world',
    ),
    (NwsbMarks.stories, 'Stories', 'Drop 24-hour frequency moments'),
    (NwsbMarks.reels, 'Reels', 'Watch & post short healing reels'),
    (NwsbMarks.discover, 'Discover Creators', 'Find people worth following'),
    (NwsbMarks.verified, 'Verified', 'Earn your NowssB check-mark'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: NcbCarousel(slides: features, onTap: onTap),
    );
  }
}

/// 18 · trendshop — index.html:1462. `.nmh-trend-shop-wrap`: the clip that
/// app/js/part067.js:67 drops in at the top, then the Shop Now bar carrying
/// the word it is selling.
class NmTrendShop extends StatelessWidget {
  const NmTrendShop({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final w =
        words.isEmpty ? null : words[(DateTime.now().day + 1) % words.length];

    return SecWrap(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                asset: 'assets/video/store-banner-fash.mp4',
                priority: ClipPriority.decoration,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(NwsbRadius.tile),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x17FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      size: 19, color: NwsbColors.goldLight),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        w == null ? 'HEALS' : 'HEALS ${w.organ.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                      Text(
                        w?.word ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 34, color: const Color(0x1FFFFFFF)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: NwsbColors.goldLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 15, color: NwsbColors.ink),
                      SizedBox(width: 7),
                      Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 28 · fashsw — index.html:1608. `#nmhFashSwitch` — the door to the other
/// home. The one dark card on a pale page, which is what it is offering.
class NmFashionSwitch extends StatelessWidget {
  const NmFashionSwitch({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: NwsbColors.ink,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(6, 6),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Color(0x333C3C64),
                offset: Offset(-3, -3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EXPERIENCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xA6E8D5A3),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Fashion Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Dark · Cinematic · Editorial',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0x73FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x1FE8D5A3),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x40E8D5A3)),
                ),
                child: const NwsbIcon(NwsbMarks.arrow,
                    size: 16, color: Color(0xD9E8D5A3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
