/// Fashion home sections 1-6, in registry order.
///
/// greet · herorow · practice · reader · herovid · streak
///
/// Copy is transcribed from index.html rather than paraphrased, so the two
/// can be read side by side. Line numbers on each class say where.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/tv_frame.dart';
import '../../widgets/home_parts.dart';

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
  const FashHeroRow({super.key, this.onCustomize, this.onFeatures, this.onEarn});

  final VoidCallback? onCustomize;
  final VoidCallback? onFeatures;
  final VoidCallback? onEarn;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NwsbVideo(asset: 'assets/video/word-acts.mp4'),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x99060C18)),
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

/// 3 · practice — index.html:1791. `.fash-plyr-wrap`: the spill, then the
/// card. The title is the word for this hour, read from the library.
class FashPractice extends StatelessWidget {
  const FashPractice({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final word = words.isEmpty
        ? 'Loading...'
        : words[DateTime.now().day % words.length].word;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Your daily word ritual',
            icon: Icons.play_arrow,
            onTap: onTap,
          ),
          PhotoCard(
            background: const NwsbImage(
              url:
                  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052547/grok_image_1778052232385_qpdmgh.jpg',
              fallback: NwsbVideo(
                asset: 'assets/video/player-liquid-splash.mp4',
                autoplay: false,
              ),
            ),
            label: "TODAY'S PRACTICE",
            title: word,
            sub: 'Your personalized word ritual for right now.',
            onTap: onTap,
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Meanings and eBooks, in one place',
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
                      'https://res.cloudinary.com/eenvubod/video/upload/v1785403688/grok_video_2026-07-30-14-57-37_tbzpox.mp4',
                  fallback: NwsbVideo(
                    asset: 'assets/video/word-acts.mp4',
                  ),
                ),
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
              const Text(
                'Reader',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Read every meaning, and every eBook.',
                style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 14),
              EnterPill(onTap: onTap),
            ],
          ),
          const SizedBox(height: 16),
          SecBanner(
            title: 'Reader',
            sub: 'Meanings and eBooks, in one place',
            icon: Icons.menu_book_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 5 · herovid — index.html:1903. `.nsvb-blk` — the streak clip, on the
/// landscape tablet.
class FashStreakVideo extends StatelessWidget {
  const FashStreakVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: TvFrame(
        asset: 'assets/video/tv-screen.mp4',
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.feature,
        onTap: onTap,
      ),
    );
  }
}

/// 6 · streak — index.html:1910. The day count, "Keep Going", and the
/// Daily Streak bar.
class FashStreak extends StatelessWidget {
  const FashStreak({super.key, this.days = 0, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      padding: const EdgeInsets.all(18),
      child: Column(
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x24FFFFFF)),
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      size: 20, color: NwsbColors.gold),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: NwsbColors.gold,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'Day Streak',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0x8CFFFFFF),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Keep Going',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Daily Streak',
            sub: 'Practice daily to keep your healing streak alive',
            icon: Icons.local_fire_department_outlined,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
