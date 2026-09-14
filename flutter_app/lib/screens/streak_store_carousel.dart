/// Streak carousel — 2 full wrappers that rotate (video + Start Building).
///
/// Used by [NmStreakVideo] / [FashStreakVideo]. Store video is NOT in this
/// carousel — Store lives in [NmStore] / [FashStore] on the home registry.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../widgets/home_parts.dart';
import '../widgets/home_skin.dart';
import '../widgets/nwsb_icon.dart';

/// One section: wrap head + PageView of two equal-height cards.
/// Card 1 = streak video + Keep Your Streak banner.
/// Card 2 = complete "Start Building Your Streak Today" wrapper ([secondCard]).
class StreakStoreCarousel extends StatefulWidget {
  const StreakStoreCarousel({
    super.key,
    required this.secondCard,
    this.onStreakTap,
    this.showHead = true,
  });

  /// Full "Start Building Your Streak Today" block (page 2).
  final Widget secondCard;

  final VoidCallback? onStreakTap;

  /// "Today, on film / Streak" head above the carousel (shared for both cards).
  final bool showHead;

  /// Landscape film aspect — matches web `.hero-vid-banner { aspect-ratio: 16/9 }`.
  static const videoAspect = 16 / 9;

  static const streakAsset =
      'assets/videos/415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk.mp4';

  @override
  State<StreakStoreCarousel> createState() => _StreakStoreCarouselState();
}

class _StreakStoreCarouselState extends State<StreakStoreCarousel> {
  late final PageController _page;
  var _index = 0;

  static const _cardCount = 2;

  /// Fixed slot under the film so page 1 height is stable.
  static const _bannerBlock = 78.0;
  static const _gap = 10.0;

  @override
  void initState() {
    super.initState();
    _page = PageController();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fashion = HomeSkinScope.of(context) == HomeSkin.fashion;

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final videoH = w / StreakStoreCarousel.videoAspect;
        // Equal viewport pages: tall enough for video card OR Start Building.
        final pageH = math.max(videoH + _gap + _bannerBlock, 300.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: pageH,
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _VideoBannerCard(
                    asset: StreakStoreCarousel.streakAsset,
                    priority: ClipPriority.feature,
                    bannerTitle: 'Keep Your Streak',
                    bannerSub: 'Practice today and the run carries on',
                    mark: NwsbMarks.flame,
                    onTap: widget.onStreakTap,
                    pageHeight: pageH,
                  ),
                  SizedBox(
                    height: pageH,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: widget.secondCard,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cardCount, (i) {
                final on = i == _index;
                return Container(
                  width: on ? 16 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: on
                        ? (fashion
                            ? Colors.white
                            : const Color(0xFF2B2D33))
                        : (fashion
                            ? Colors.white.withValues(alpha: 0.35)
                            : const Color(0x552B2D33)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );

    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHead) ...[
            const PaneHead(
              eyebrow: 'Today, on film',
              title: 'Streak',
              mark: NwsbMarks.flame,
            ),
            const SizedBox(height: 12),
          ],
          body,
        ],
      ),
    );
  }
}

class _VideoBannerCard extends StatelessWidget {
  const _VideoBannerCard({
    required this.asset,
    required this.priority,
    required this.bannerTitle,
    required this.bannerSub,
    required this.mark,
    required this.pageHeight,
    this.onTap,
  });

  final String asset;
  final ClipPriority priority;
  final String bannerTitle;
  final String bannerSub;
  final String mark;
  final double pageHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: pageHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: StreakStoreCarousel.videoAspect,
                child: NwsbVideo(
                  asset: asset,
                  priority: priority,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: _StreakStoreCarouselState._gap),
          SizedBox(
            height: _StreakStoreCarouselState._bannerBlock,
            child: Align(
              alignment: Alignment.topCenter,
              child: SecBanner(
                title: bannerTitle,
                sub: bannerSub,
                mark: mark,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
