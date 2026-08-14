/// The Fashion home — #home, the dark one.
///
/// The app has two homes and they are not skins of each other. The Normal
/// home is a pale neumorphic surface where every card is raised out of the
/// page by a shadow pair. This one is the opposite: a dark page with the
/// film running behind it and every block sitting on it as a pane of glass.
/// Same sections, same order, different language — which is why this is its
/// own file rather than a flag on the other one.
///
/// The film behind it is the point. On the website that is #fpBgVideo, one
/// fixed element under every screen; here it is one [NwsbVideo] behind the
/// list, marked as a feature so it keeps its decoder while the banners
/// further down come and go.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import 'home_normal.dart' show nwsbGreeting;
import 'sections.dart';

class HomeFashion extends StatefulWidget {
  const HomeFashion({super.key, this.name = 'Healer'});

  final String name;

  @override
  State<HomeFashion> createState() => _HomeFashionState();
}

class _HomeFashionState extends State<HomeFashion> {
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;

    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          // The page's own film, behind everything. Fixed in effect: it is
          // outside the scroller, so it does not move with the list.
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/fashion-plus-bg-6.mp4',
              priority: ClipPriority.feature,
            ),
          ),
          // A scrim, or nothing on top of it is readable. The film is busy
          // and bright in places and the whole page is white type.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9060C18),
                    Color(0xF2060C18),
                    Color(0xFA060C18),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
              children: [
                const _FashTopRow(),
                const SizedBox(height: 18),
                _FashGreeting(name: widget.name),
                const SizedBox(height: 16),
                const _FashSearch(),
                const SizedBox(height: 18),

                // Every block below is a glass pane over the film.
                const GlassWrap(child: HeroSection()),
                const SizedBox(height: 16),

                const GlassWrap(
                  child: TvSection(
                    eyebrow: 'Today, on film',
                    title: 'Streak',
                    icon: Icons.local_fire_department_outlined,
                    asset: 'assets/video/tv-screen.mp4',
                    dark: true,
                    bannerTitle: 'Daily Streak',
                    bannerSub: 'Practice daily to keep your healing streak alive',
                  ),
                ),
                const SizedBox(height: 16),

                _FashWordOfDay(words: words),
                const SizedBox(height: 16),

                const GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Words and meanings',
                    title: 'The NowssB Store',
                    icon: Icons.storefront_outlined,
                    asset: 'assets/video/store-section.mp4',
                    aspect: 768 / 1168,
                    dark: true,
                    bannerTitle: 'Enter the Store',
                    bannerSub: 'Word Library & Meaning Library, in one place',
                  ),
                ),
                const SizedBox(height: 16),

                const _FashTiles(),
                const SizedBox(height: 16),

                const GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Own the sounds that heal',
                    title: 'Inside the Store',
                    icon: Icons.shopping_bag_outlined,
                    asset: 'assets/video/store-banner-fash.mp4',
                    aspect: 1136 / 800,
                    dark: true,
                    bannerTitle: 'Shop the Library',
                    bannerSub: 'Words, meanings and the origins behind them',
                  ),
                ),
                const SizedBox(height: 16),

                const GlassWrap(
                  child: TvSection(
                    eyebrow: 'The full library',
                    title: 'NowssB Subscription',
                    icon: Icons.workspace_premium_outlined,
                    asset: 'assets/video/subscription-a.mp4',
                    dark: true,
                    bannerTitle: 'Every word, every meaning',
                    bannerSub: 'See what a subscription opens',
                  ),
                ),
                const SizedBox(height: 16),

                const GlassWrap(
                  child: BannerSection(
                    eyebrow: 'The rarest word',
                    title: 'The Signature',
                    icon: Icons.auto_awesome_outlined,
                    asset: 'assets/video/signature-banner.mp4',
                    dark: true,
                    bannerTitle: 'One word, made only for you',
                    bannerSub: 'See the Signature',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The glass pane every Fashion block sits on — .glass-wrap.
class GlassWrap extends StatelessWidget {
  const GlassWrap({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x2E0E1524),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: child,
    );
  }
}

class _FashTopRow extends StatelessWidget {
  const _FashTopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Icon(Icons.headphones, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NowssB',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'NOWSBANSIU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: NwsbColors.goldLight,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _FashHeaderBtn(icon: Icons.notifications_none, badge: 3),
        const SizedBox(width: 8),
        const _FashHeaderBtn(icon: Icons.home_outlined),
        const SizedBox(width: 8),
        const _FashHeaderBtn(icon: Icons.menu),
      ],
    );
  }
}

class _FashHeaderBtn extends StatelessWidget {
  const _FashHeaderBtn({required this.icon, this.badge});
  final IconData icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE0342B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FashGreeting extends StatelessWidget {
  const _FashGreeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x2EFFFFFF)),
          ),
          child: const Icon(Icons.wb_twilight,
              size: 26, color: NwsbColors.goldLight),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nwsbGreeting(),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w300,
                  color: Color(0xB3FFFFFF),
                ),
              ),
              Text(
                name,
                style: const TextStyle(
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
    );
  }
}

class _FashSearch extends StatelessWidget {
  const _FashSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 20, color: Color(0x99FFFFFF)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search any word or meaning…',
              style: TextStyle(fontSize: 14, color: Color(0x8CFFFFFF)),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward,
                size: 18, color: NwsbColors.ink),
          ),
        ],
      ),
    );
  }
}

/// The word of the day, read from the same Firestore library the website
/// reads. Proof the content layer is wired all the way to a screen.
class _FashWordOfDay extends StatelessWidget {
  const _FashWordOfDay({required this.words});
  final List<dynamic> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    // Same word all day, and a different one tomorrow — the day number
    // rather than a random pick, so it does not change as you scroll.
    final w = words[DateTime.now().day % words.length];

    return GlassWrap(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S WORD",
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              color: NwsbColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            w.word as String,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          if ((w.phonetic as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              w.phonetic as String,
              style: const TextStyle(
                fontSize: 13,
                color: NwsbColors.goldLight,
                letterSpacing: 1.2,
              ),
            ),
          ],
          if ((w.meaning as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              w.meaning as String,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xB3FFFFFF),
                height: 1.5,
              ),
            ),
          ],
          if ((w.organ as String).isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.favorite_border,
                    size: 15, color: NwsbColors.goldLight),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    w.organ as String,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FashTiles extends StatelessWidget {
  const _FashTiles();

  static const _items = [
    ('Word Science', 'The system', Icons.science_outlined),
    ('NowssB Profile', 'You, so far', Icons.person_outline),
    ('Sound Library', 'Root frequencies', Icons.graphic_eq),
    ('My Routines', '5 routine slots', Icons.repeat_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        for (final (title, sub, icon) in _items)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: NwsbColors.goldLight),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0x8CFFFFFF)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
