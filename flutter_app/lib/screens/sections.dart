/// The sections that carry a clip.
///
/// These are the blocks the website builds out of `.nmh-sec-wrap`,
/// `.vb-banner` and the tablet frames — a head with a round mark and two
/// lines, then either a television or a banner, then a black bar you can
/// press. Each one is a widget here rather than a template string, and each
/// one goes through [NwsbVideo], which means every clip on this page is
/// under the pool's ceiling without any of these having to know that.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/neumorphic.dart';
import '../widgets/tv_frame.dart';

/// The head every section shares: a white disc with a mark in it, a small
/// eyebrow, and the title under it.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.dark = false,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  /// The Fashion home. The disc stays white — it is the app's mark and it is
  /// white on both homes — but the type over the film has to be white too,
  /// and the raised shadow is light-home furniture that would read as a halo
  /// here. Same head, the other surface.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: dark ? null : NwsbShadows.raisedXs,
          ),
          child: Icon(icon, size: 22, color: NwsbColors.ink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: dark ? const Color(0xA6FFFFFF) : const Color(0x8C000000),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : NwsbColors.ink,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A section whose picture is a television — the streak's tablet, the store
/// trigger. The clip is the point of the block, so it claims a decoder ahead
/// of any banner beside it.
class TvSection extends StatelessWidget {
  const TvSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.asset,
    this.aspect = 1452 / 831,
    this.bannerTitle,
    this.bannerSub,
    this.onTap,
    this.dark = false,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final String asset;
  final double aspect;
  final String? bannerTitle;
  final String? bannerSub;
  final VoidCallback? onTap;

  /// On the Fashion home the block already sits on a glass pane, so it does
  /// not bring a card of its own.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(eyebrow: eyebrow, title: title, icon: icon, dark: dark),
        const SizedBox(height: 16),
        TvFrame(asset: asset, aspect: aspect, label: 'NowssB', onTap: onTap),
        if (bannerTitle != null) ...[
          const SizedBox(height: 18),
          NwsbBanner(
            title: bannerTitle!,
            sub: bannerSub ?? '',
            icon: icon,
            onTap: onTap,
            dark: dark,
          ),
        ],
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

/// A section whose picture is a full-width banner rather than a television —
/// the video banners the website injects above a block.
class BannerSection extends StatelessWidget {
  const BannerSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.asset,
    this.aspect = 16 / 10,
    this.overlay,
    this.bannerTitle,
    this.bannerSub,
    this.onTap,
    this.dark = false,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final String asset;
  final double aspect;

  /// Words laid over the clip, the way `.hvb-text` sits on the banner.
  final String? overlay;

  final String? bannerTitle;
  final String? bannerSub;
  final VoidCallback? onTap;

  /// See TvSection.dark.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          SectionHead(eyebrow: eyebrow, title: title, icon: icon, dark: dark),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: aspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NwsbVideo(asset: asset),
                    if (overlay != null) ...[
                      // The scrim is what keeps white type legible on a
                      // bright frame — same job as `.hvb-fade`.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xB3000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            overlay!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (bannerTitle != null) ...[
            const SizedBox(height: 18),
            NwsbBanner(
              title: bannerTitle!,
              sub: bannerSub ?? '',
              icon: icon,
              onTap: onTap,
              dark: dark,
            ),
          ],
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

/// The hero — the big television at the top of the page, on its own dark
/// glass panel. The one clip on the page that is always a feature.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, this.asset = 'assets/video/hero-bg.mp4'});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: NwsbVideo(asset: asset, priority: ClipPriority.feature),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0xCC000000)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Shabdapathy',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: NwsbColors.goldLight,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Natural Origin of\nWord Science',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _HeroPill(label: 'Explore', onTap: () {}),
                    const SizedBox(width: 10),
                    _HeroPill(label: 'App Guide', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: NwsbColors.ink,
          ),
        ),
      ),
    );
  }
}
