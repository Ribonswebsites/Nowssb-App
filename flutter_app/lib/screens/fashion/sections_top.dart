/// Fashion home sections 1-6, in registry order.
///
/// greet · herorow · practice · reader · herovid · streak
///
/// Copy is transcribed from index.html rather than paraphrased, so the two
/// can be read side by side. Line numbers on each class say where.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';

import '../../data/settings.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/tv_frame.dart';
import '../../widgets/black_glass_banner.dart';
import '../../widgets/home_parts.dart';
import '../start_today_carousel.dart';
import '../streak_store_carousel.dart';

/// 1 · greet — index.html:1758. Not wrapped; it sits loose under the hero.
class FashGreeting extends StatelessWidget {
  const FashGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Begin Your\nHealing Path',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.12,
            ),
          ),
          SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, color: Color(0xA6FFFFFF)),
              children: [
                TextSpan(text: 'Natural Origin of '),
                TextSpan(
                  text: 'Word Science',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2 · herorow — index.html:1766. `.hhr-blk` — three buttons on a strip of
/// `word-acts.mp4`, separated by hairlines.
class FashHeroRow extends StatelessWidget {
  const FashHeroRow(
      {super.key, this.onCustomize, this.onFeatures, this.onEarn});

  final VoidCallback? onCustomize;
  final VoidCallback? onFeatures;
  final VoidCallback? onEarn;

  @override
  Widget build(BuildContext context) {
    // `.hhr-tab` IS a frame — the white bezel in assets/frames, with the
    // clip inside its aperture and the three buttons on top of that. It was
    // a plain dark box here, which is why this strip did not look like the
    // one on the phone.
    return SectionPane(
      child: TvFrame(
        asset: 'assets/video/word-acts.mp4',
        frame: DeviceFrame.wordActs,
        priority: ClipPriority.feature,
        autoplay: true,
        showVideo: true,
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x40000000)),
            ),
            Row(
              children: [
                Expanded(
                  child: _HhrButton(
                    icon: Icons.tune,
                    label: 'Customize',
                    onTap: onCustomize,
                  ),
                ),
                const _HhrSep(),
                Expanded(
                  child: _HhrButton(
                    icon: Icons.grid_view,
                    label: 'Features',
                    onTap: onFeatures,
                  ),
                ),
                const _HhrSep(),
                Expanded(
                  child: _HhrButton(
                    icon: Icons.savings_outlined,
                    label: 'Earn',
                    onTap: onEarn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The three glass boxes — index.html:1913, `.fash-streak`.
///
/// On the web this is ONE picture: a render of three glass blocks, with the
/// label, the number and the call to action placed over it at 17%, 50% and
/// 83% of its width. The picture is remote, so until the download runs the
/// blocks are drawn — and drawn rather than left out, because three empty
/// spaces where the count should be is not what this section says.
class _StreakBoxes extends StatelessWidget {
  const _StreakBoxes({required this.days, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1536 / 450,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: NwsbImage(
                url:
                    'https://media.nowssb.com/migrated-images/8bed0983f1e9348c_file_00000000c4e072079f68c8cac5eb7d0d_lshcoa.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                fallback: const Row(
                  children: [
                    Expanded(child: _GlassBox(child: SizedBox.expand())),
                    SizedBox(width: 10),
                    Expanded(child: _GlassBox(child: SizedBox.expand())),
                    SizedBox(width: 10),
                    Expanded(child: _GlassBox(child: SizedBox.expand())),
                  ],
                ),
              ),
            ),
            const Align(
              alignment: Alignment(-0.66, -0.08),
              child: _BoxLabel('DAY\nSTREAK'),
            ),
            Align(
              alignment: const Alignment(0, -0.08),
              child: Text(
                '$days',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Color(0xFF1A2230),
                ),
              ),
            ),
            const Align(
              alignment: Alignment(0.66, -0.08),
              child: _BoxLabel('KEEP\nGOING', color: Color(0xFF9C7B3A)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A block of glass: pale, lit from the top left, with a thick bright edge.
class _GlassBox extends StatelessWidget {
  const _GlassBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xCCFFFFFF), width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2F4F6FA), Color(0xD9C6CDDA), Color(0xF2E8ECF3)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x61000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _BoxLabel extends StatelessWidget {
  const _BoxLabel(this.text, {this.color = const Color(0xFF2A3140)});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        height: 1.15,
        color: color,
      ),
    );
  }
}

class _HhrSep extends StatelessWidget {
  const _HhrSep();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: const Color(0x24FFFFFF));
}

class _HhrButton extends StatelessWidget {
  const _HhrButton({required this.icon, required this.label, this.onTap});
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
          Icon(icon, size: 21, color: Colors.white),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3 · practice — index.html:1842 + app/js/part066.js PRACTICE_VID.
/// `.fash-plyr-wrap`: spill, then the card. With Fashion Plus on (the web
/// default) the card's media is the looping practice film, not the still.
///
/// Cleanup: no large practice-name headline over the film. Supporting ritual
/// copy sits *below* the media. Glass Enter sits middle-right over the video.
class FashPractice extends StatelessWidget {
  const FashPractice({super.key, this.onTap});
  final VoidCallback? onTap;

  /// Website `PRACTICE_VID` — part066.js. Bundled under assets/video/.
  static const practiceVid =
      'assets/video/09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: RoutineStyleBlackBanner(
            title: "Today's Practice",
            subtitle: 'Begin your healing path',
            onTap: onTap,
          ),
        ),
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
                playerCard: ListenableBuilder(
                  listenable: Settings.instance,
                  builder: (context, _) {
                    final motion = Settings.instance.fashionPlus;
                    final media = motion
                        ? const NwsbVideo(
                            asset: practiceVid,
                            priority: ClipPriority.feature,
                            fit: BoxFit.cover,
                          )
                        : const NwsbImage(url: practiceStill);
                    // Card 1 — NowssB Player exactly as before (no redesign).
                    return GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(child: media),
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
                              child: Text(
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
                    );
                  },
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
      ],
    );
  }
}

/// 4 · reader — index.html:1817. `.fash-rdsec-wrap`: spill, clip, the text
/// block, then the banner.
class FashReader extends StatelessWidget {
  const FashReader({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Meanings and eBooks, in one place',
            mark: NwsbMarks.reader,
            markViewBox: 22,
            onTap: onTap,
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                asset: 'assets/video/reader-section.mp4',
                poster: 'assets/video/reader-section-poster.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NowssB',
                style: TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
              ),
              TitleWithGlassEnter(title: 'Reader', onTap: onTap),
              const SizedBox(height: 6),
              const Text(
                'Read every meaning, and every eBook.',
                style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecBanner(
            title: 'Reader',
            sub: 'Meanings and eBooks, in one place',
            mark: NwsbMarks.reader,
            markViewBox: 22,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 5 · herovid — streak VIDEO on the landscape tablet, matching website
/// `.nsvb-blk`. Cubes live in [FashStreak], not as a second carousel page.
class FashStreakVideo extends StatelessWidget {
  const FashStreakVideo({super.key, this.onTap, this.onStoreTap});
  final VoidCallback? onTap;

  /// Kept for call-site compatibility; Store is restored on [FashStore].
  final VoidCallback? onStoreTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: TvFrame(
        asset: StreakStoreCarousel.streakAsset,
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.feature,
        onTap: onTap,
      ),
    );
  }
}

/// Start Building Your Streak Today — heading, cubes, Daily Streak banner.
class FashStreakBody extends StatelessWidget {
  const FashStreakBody({super.key, this.days = 0, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Start Building Your Streak Today',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Practice daily to keep it alive — and unlock exclusive offers',
          style: TextStyle(
            fontSize: 13,
            color: Color(0x99FFFFFF),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        _StreakBoxes(days: days, onTap: onTap),
        const SizedBox(height: 12),
        SecBanner(
          title: 'Daily Streak',
          sub: 'Practice daily to keep your healing streak alive',
          mark: NwsbMarks.flame,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// 6 · streak — Start Building cubes, full width, matching website
/// `.nmh-streak-glass-section`. Not stuffed into the video carousel.
class FashStreak extends StatelessWidget {
  const FashStreak({super.key, this.days = 0, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: FashStreakBody(days: days, onTap: onTap),
    );
  }
}
