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
import '../shell/go.dart';

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
    this.frame = DeviceFrame.tabletLandscape,
    this.bannerTitle,
    this.bannerSub,
    this.onTap,
    this.dark = false,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final String asset;

  /// Which device the clip is shown in — a real bezel out of assets/frames,
  /// with its own aperture. See lib/widgets/tv_frame.dart.
  final DeviceFrame frame;

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
        TvFrame(asset: asset, frame: frame, onTap: onTap),
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
      child: AspectRatio(
        aspectRatio: 16 / 10,
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
                    _HeroPill(label: 'Explore', onTap: () => Dest.open(context, Dest.store)),
                    const SizedBox(width: 10),
                    _HeroPill(label: 'Help & Coach', onTap: () => Dest.open(context, Dest.assistant)),
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

/// Rotating store/connect promo disc — `.npc-card` on the website.
class PromoDisc extends StatelessWidget {
  const PromoDisc({
    super.key,
    required this.asset,
    required this.title,
    required this.sub,
    required this.onTap,
    this.dark = false,
  });

  final String asset;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final disc = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(asset: asset, priority: ClipPriority.feature),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (dark) return disc;
    return NeuCard(padding: const EdgeInsets.all(18), child: disc);
  }
}

/// `.nedi-blk` — current plan.
class EditionCard extends StatelessWidget {
  const EditionCard({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'Your plan',
          title: 'Your Edition',
          icon: Icons.workspace_premium_outlined,
          dark: dark,
        ),
        const SizedBox(height: 16),
        Text(
          '15-day Frequency trial',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : NwsbColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Every word, every meaning, while the trial is open. Upgrade to keep it.',
          style: TextStyle(
            fontSize: 13,
            color: dark ? const Color(0xB3FFFFFF) : NwsbColors.inkFaint,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        NwsbBanner(
          title: 'Resonance · Frequency · Frequency X',
          sub: 'See what a subscription opens',
          icon: Icons.workspace_premium_outlined,
          onTap: () => Dest.open(context, Dest.subscribe),
          dark: dark,
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

/// Personalised Healing — 10 category tiles.
class HealingGrid extends StatelessWidget {
  const HealingGrid({super.key, this.dark = false});

  final bool dark;

  static const items = [
    ('Fitness', Icons.fitness_center_outlined),
    ('Heart', Icons.favorite_border),
    ('Skin & Glow', Icons.spa_outlined),
    ('Gut', Icons.water_drop_outlined),
    ('Liver', Icons.healing_outlined),
    ('Mind', Icons.psychology_outlined),
    ('Hormones', Icons.science_outlined),
    ('Immunity', Icons.shield_outlined),
    ('Breath', Icons.air),
    ('Balance', Icons.self_improvement),
  ];

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'Choose your health journey',
          title: 'Personalised Healing',
          icon: Icons.favorite_border,
          dark: dark,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final (title, icon) in items)
              GestureDetector(
                onTap: () => Dest.open(context, Dest.healing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.black : NwsbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: dark
                        ? Border.all(color: const Color(0x14FFFFFF))
                        : null,
                    boxShadow: dark ? null : NwsbShadows.raisedXs,
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: dark ? NwsbColors.goldLight : NwsbColors.ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : NwsbColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

/// Female / Male path on the laptop frame.
class GenderPath extends StatelessWidget {
  const GenderPath({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'Female and Male',
          title: 'Choose Your Path',
          icon: Icons.people_outline,
          dark: dark,
        ),
        const SizedBox(height: 16),
        TvFrame(
          asset: 'assets/video/healing-path-bg.mp4',
          frame: DeviceFrame.laptop,
          onTap: () => Dest.open(context, Dest.healing),
        ),
        const SizedBox(height: 18),
        NwsbBanner(
          title: 'A path made for you',
          sub: 'Ten categories, matched to the body',
          icon: Icons.people_outline,
          onTap: () => Dest.open(context, Dest.healing),
          dark: dark,
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

class CustomizePanel extends StatelessWidget {
  const CustomizePanel({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'Quick Access · Quick Links',
          title: 'Customize',
          icon: Icons.tune,
          dark: dark,
        ),
        const SizedBox(height: 14),
        Text(
          'Which blocks appear on this home, and in what order — open Settings to rearrange them.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: dark ? const Color(0xB3FFFFFF) : NwsbColors.inkFaint,
          ),
        ),
        const SizedBox(height: 16),
        NwsbBanner(
          title: 'Set as you like',
          sub: 'Open widgets and shortcuts',
          icon: Icons.tune,
          onTap: () => Dest.open(context, Dest.settings),
          dark: dark,
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

class FeedCarousel extends StatelessWidget {
  const FeedCarousel({super.key, this.dark = false});

  final bool dark;

  static const cards = [
    ('AAROGYA', 'Perfect health — freedom from all disease'),
    ('PRANA', 'Life force, breath — the pulse of all living'),
    ('TEJAS', 'Radiance of a well-held practice'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'Swipe the feed',
          title: 'Community',
          icon: Icons.groups_outlined,
          dark: dark,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (title, sub) = cards[i];
              return GestureDetector(
                onTap: () => Dest.open(context, Dest.connect),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xB3FFFFFF),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

class FashionPlusDoor extends StatelessWidget {
  const FashionPlusDoor({super.key, this.dark = true});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Dest.open(context, Dest.fashionPlus),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const NwsbVideo(
                asset: 'assets/video/fashion-plus-bg.mp4',
                priority: ClipPriority.feature,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xCC000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'FASHION PLUS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.gold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'The still ones\nstart moving.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
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

class FooterMark extends StatelessWidget {
  const FooterMark({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(
            'NowssB',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : NwsbColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Across every language.',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.4,
              color: dark ? const Color(0x99FFFFFF) : NwsbColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectCard extends StatelessWidget {
  const ConnectCard({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          eyebrow: 'The social space',
          title: 'NowssB Connect',
          icon: Icons.groups_outlined,
          dark: dark,
        ),
        const SizedBox(height: 12),
        Text(
          'Practice with other healers. Share a word, keep a streak together, sit in the same frequency.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: dark ? const Color(0xB3FFFFFF) : NwsbColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        NwsbBanner(
          title: 'Enter Connect',
          sub: 'People, chat, the feed',
          icon: Icons.groups_outlined,
          onTap: () => Dest.open(context, Dest.connect),
          dark: dark,
        ),
      ],
    );
    if (dark) return body;
    return NeuCard(padding: const EdgeInsets.all(16), child: body);
  }
}

class WordSearchBlock extends StatelessWidget {
  const WordSearchBlock({
    super.key,
    required this.title,
    required this.sub,
    required this.asset,
    this.dark = false,
  });
  final String title;
  final String sub;
  final String asset;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return BannerSection(
      eyebrow: sub,
      title: title,
      icon: Icons.search,
      asset: asset,
      aspect: 16 / 9,
      onTap: () => Dest.open(context, Dest.library),
      dark: dark,
      bannerTitle: title,
      bannerSub: 'Open the library',
    );
  }
}
