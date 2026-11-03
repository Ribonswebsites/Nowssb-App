/// Fashion home sections 1-6, in registry order.
///
/// greet · herorow · practice · reader · herovid · streak
///
/// Copy is transcribed from index.html rather than paraphrased, so the two
/// can be read side by side. Line numbers on each class say where.
library;

import 'package:nowssb/screens/normal/home_v4.dart' show kStreakLottie, kReaderLottie;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../features/progress/progress_popup.dart';
import '../../theme/tokens.dart';
import '../../widgets/auto_cycle.dart';
import '../../widgets/black_glass_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/tv_frame.dart';
import '../start_today_carousel.dart';
import '../../widgets/concept/r27/anims.dart' show R27BreathFlame;
import '../../data/practice_progress.dart' show PracticeProgress;
import '../../admin/template/editable.dart';

/// 1 · greet — index.html:1758. Not wrapped; it sits loose under the hero.
class FashGreeting extends StatelessWidget {
  const FashGreeting({super.key, this.below});

  /// Rendered directly under the glass heading (Today's Practice), so the
  /// two always travel together even if a saved server layout reorders keys.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    // Same glass as the Fashion Hero header (fashion/hero.dart GlassWrap).
    final head = GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Flexible(
                      child: EditableLabel('fashion_sections_top.FashGreeting',
                        'Begin Your\nHealing Path',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: NwsbIcon(NwsbMarks.sound, size: 22, color: NwsbColors.goldLight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const RotatingSubtitle(),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
    if (below == null) return head;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [head, below!],
    );
  }
}

/// Subtitles that slide/fade through under the heading.
class RotatingSubtitle extends StatefulWidget {
  const RotatingSubtitle({super.key});
  static const lines = [
    ('Natural Origin of ', 'Word Science'),
    ('Every word carries a ', 'healing sound'),
    ('Speak it, feel it, ', 'heal with it'),
    ('Ancient roots, ', 'modern practice'),
    ('One word a day ', 'changes the day'),
  ];
  @override
  State<RotatingSubtitle> createState() => _RotatingSubtitleState();
}

class _RotatingSubtitleState extends State<RotatingSubtitle>
    with SingleTickerProviderStateMixin, AutoCycle<RotatingSubtitle> {
  var _i = 0;
  @override
  Duration get period => const Duration(milliseconds: 2800);
  @override
  void onTick() => setState(() => _i = (_i + 1) % RotatingSubtitle.lines.length);

  @override
  Widget build(BuildContext context) {
    final (a, b) = RotatingSubtitle.lines[_i];
    return SizedBox(
      height: 18,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        layoutBuilder: (cur, prev) => Stack(alignment: Alignment.centerLeft, children: [...prev, if (cur != null) cur]),
        transitionBuilder: (c, an) => FadeTransition(
          opacity: an,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(an), child: c),
        ),
        child: Text.rich(
          key: ValueKey(_i),
          TextSpan(
            style: const TextStyle(fontSize: 12, color: Color(0xA6FFFFFF)),
            children: [TextSpan(text: a), TextSpan(text: b, style: const TextStyle(fontWeight: FontWeight.w800))],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Today's Practice: 3 same-size black banners, auto-scrolling, texts from a
/// date-seeded pool; each opens a real page.
class PracticeBannerSpec {
  const PracticeBannerSpec(this.title, this.subtitle, this.onTap);
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

List<PracticeBannerSpec> dailyPracticeBanners(List<PracticeBannerSpec> pool, {DateTime? day, int count = 3}) {
  final d = day ?? DateTime.now();
  final list = [...pool]..shuffle(math.Random(d.year * 10000 + d.month * 100 + d.day + 7));
  return list.take(count).toList();
}

class PracticeBannerCarousel extends StatefulWidget {
  const PracticeBannerCarousel({super.key, required this.banners});
  final List<PracticeBannerSpec> banners;
  @override
  State<PracticeBannerCarousel> createState() => _PracticeBannerCarouselState();
}

class _PracticeBannerCarouselState extends State<PracticeBannerCarousel>
    with SingleTickerProviderStateMixin, AutoCycle<PracticeBannerCarousel> {
  final _pager = PageController();
  var _page = 0;
  @override
  Duration get period => const Duration(seconds: 4);
  @override
  void onTick() {
    if (!_pager.hasClients || widget.banners.length < 2) return;
    _page = (_page + 1) % widget.banners.length;
    _pager.animateToPage(_page, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.banners;
    return Column(children: [
      SizedBox(
        height: 96,
        child: PageView.builder(
          controller: _pager,
          itemCount: b.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RoutineStyleBlackBanner(title: b[i].title, subtitle: b[i].subtitle, onTap: b[i].onTap, heavy: true),
          ),
        ),
      ),
      const SizedBox.shrink(),
    ]);
  }
}

/// 3 · practice — index.html:1842 + app/js/part066.js PRACTICE_VID.
/// `.fash-plyr-wrap`: spill, then the card. With Fashion Plus on (the web
/// default) the card's media is the looping practice film, not the still.
///
/// Cleanup: no large practice-name headline over the film. Supporting ritual
/// copy sits *below* the media. Glass Enter sits middle-right over the video.
class FashPractice extends StatelessWidget {
  const FashPractice({super.key, this.onTap, this.banners});
  final VoidCallback? onTap;

  /// When given, the black banner becomes a 3-banner auto carousel.
  final List<PracticeBannerSpec>? banners;

  /// Website `PRACTICE_VID` — part066.js. Bundled under assets/video/.
  static const practiceVid = 'assets/video/practice-halo.mp4';

  static const practiceStill =
      'https://media.nowssb.com/migrated-images/4daad1a85b624fed_grok_image_1778052232385_qpdmgh.jpg';

  static const ritualLine = 'Your personalized word ritual for right now.';

  @override
  Widget build(BuildContext context) {
    // Word of the day still drives the destination; it is no longer painted
    // as a giant title over the film (ANANDA / AAROGYA etc.).
    // Black My Routine–style banner ABOVE/OUTSIDE the glass SectionPane
    // (sibling, not nested), then Spill + 3-card carousel inside the pane
    // (Player → Practice Today art → Device).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spill(
                label: 'Your daily word ritual',
                mark: NwsbMarks.play,
                markViewBox: 22,
                onTap: onTap,
              ),
              PracticeCarousel(
                fashion: true,
                onTap: onTap,
                playerCard: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned.fill(
                          child: NwsbVideo(
                            asset: practiceVid,
                            priority: ClipPriority.feature,
                            fit: BoxFit.cover,
                            slot: 'fashion_sections_top.FashPractice',
                          ),
                        ),
                            // Light left-edge scrim only — keep the film readable.
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x99060C18),
                                    Color(0x33060C18),
                                    Color(0x14060C18),
                                  ],
                                  stops: [0, 0.45, 1],
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 16,
                              top: 14,
                              child: EditableLabel('fashion_sections_top.FashPractice',
                                "TODAY'S PRACTICE",
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE8D5A3),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: GlassEnterPill(onTap: onTap),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                ritualLine,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xB3FFFFFF),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (banners != null && banners!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 12), child: PracticeBannerCarousel(banners: banners!))
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RoutineStyleBlackBanner(
              title: "Today's Practice",
              subtitle: 'Begin today’s session',
              onTap: onTap,
            ),
          ),
      ],
    );
  }
}
