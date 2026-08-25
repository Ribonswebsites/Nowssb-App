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
import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/home_skin.dart';
import 'home_normal.dart' show nwsbGreeting;
import '../shell/go.dart';
import '../widgets/tv_frame.dart';
import 'sections.dart';
import 'shared_sections.dart';
import 'assistant.dart';
import 'widgets_page.dart';
import 'fashion/header.dart';
import 'fashion/hero.dart';
import '../widgets/day_dashboard.dart';

class HomeFashion extends StatefulWidget {
  const HomeFashion({super.key, this.name = 'Healer'});

  final String name;

  @override
  State<HomeFashion> createState() => _HomeFashionState();
}

class _HomeFashionState extends State<HomeFashion> {

  static const _backgrounds = <String>[
    'assets/video/fashion-plus-bg.mp4',
    'assets/video/fashion-plus-bg-1.mp4',
    'assets/video/fashion-plus-bg-2.mp4',
    'assets/video/fashion-plus-bg-3.mp4',
    'assets/video/fashion-plus-bg-4.mp4',
    'assets/video/fashion-plus-bg-5.mp4',
    'assets/video/fashion-plus-bg-6.mp4',
  ];

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _go(int tab) => Dest.open(context, tab);

  void _push(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;

    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          // The page's own film, behind everything. Fixed in effect: it is
          // outside the scroller, so it does not move with the list.
          Positioned.fill(
            child: NwsbVideo(
              key: ValueKey(Settings.instance.fashionBackgroundIndex),
              asset: _backgrounds[Settings.instance.fashionBackgroundIndex.clamp(0, _backgrounds.length - 1).toInt()],
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
                    Color(0x66060C18),
                    Color(0x8C060C18),
                    Color(0xB3060C18),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              HomeHeader(
                notifications: 3,
                onNormalHome: () => Settings.instance.setFashionHome(false),
                onMenu: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WidgetsPage()),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 108),
                  children: [
                    HeroGreeting(name: widget.name),
                    FashionHero(
                      onExplore: () => _go(2),
                      onGuide: () => _push(const AssistantHubScreen()),
                      onSearch: () => _go(2),
                      onStore: () => _go(3),
                      onRail: _go,
                    ),
                    const HomeGutter(child: _FashPathHeading()),
                    const SizedBox(height: 14),
                    const HomeGutter(
                      child: NwsbDayDashboard(fashion: true),
                    ),
                    const SizedBox(height: 16),
                    HomeGutter(
                      child: MainOptionsSection(onGo: _go),
                    ),
                    const SizedBox(height: 16),
                    const HomeGutter(child: _FashHeroRow()),
                const SizedBox(height: 16),
                _FashWordOfDay(words: words),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Meanings and eBooks',
                    title: 'Reader',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.auto_stories_outlined,
                    asset: 'assets/video/store-banner.mp4',
                    overlay: 'Every word,\nexplained',
                    dark: true,
                    bannerTitle: 'Open the Reader',
                    bannerSub: 'Meanings and eBooks, in one place',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: TvSection(
                    eyebrow: 'Today, on film',
                    title: 'Streak Video',
                    onTap: () => Dest.open(context, Dest.practice),
                    icon: Icons.local_fire_department_outlined,
                    asset: 'assets/video/tv-screen.mp4',
                    dark: true,
                    bannerTitle: 'Daily Streak',
                    bannerSub: 'Practice daily to keep your healing streak alive',
                  ),
                ),
                const SizedBox(height: 16),
                const _FashStreak(),
                const SizedBox(height: 16),
                    const HomeGutter(child: _FashTiles()),
                const SizedBox(height: 16),
                GlassWrap(
                  child: TvSection(
                    eyebrow: 'Words and meanings',
                    title: 'The NowssB Store',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.storefront_outlined,
                    asset: 'assets/video/store-section.mp4',
                    frame: DeviceFrame.tabletPortrait,
                    dark: true,
                    bannerTitle: 'Enter the Store',
                    bannerSub: 'Word Library & Meaning Library, in one place',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: "Today's trending",
                    title: 'The Signature',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.auto_awesome_outlined,
                    asset: 'assets/video/signature-banner.mp4',
                    dark: true,
                    bannerTitle: 'One word, made only for you',
                    bannerSub: 'See the Signature',
                  ),
                ),
                const SizedBox(height: 16),
                const GlassWrap(child: CustomizePanel(dark: true)),
                const SizedBox(height: 16),
                const FashionPlusDoor(),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Your daily recommended words',
                    title: 'AI Prescription',
                    onTap: () => Dest.open(context, Dest.practice),
                    icon: Icons.auto_awesome_outlined,
                    asset: 'assets/video/rx-banner.mp4',
                    overlay: 'A word\nfor today',
                    dark: true,
                    bannerTitle: "Open today's practice",
                    bannerSub: 'Matched to the hour',
                  ),
                ),
                const SizedBox(height: 16),
                const GlassWrap(child: ConnectCard(dark: true)),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Shop the moment',
                    title: 'Trending Shop',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.local_mall_outlined,
                    asset: 'assets/video/store-banner-fash.mp4',
                    aspect: 16 / 10,
                    dark: true,
                    bannerTitle: 'Shop now',
                    bannerSub: 'Open the store',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Own the sounds that heal',
                    title: 'Store Banner',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.shopping_bag_outlined,
                    asset: 'assets/video/store-banner.mp4',
                    aspect: 16 / 10,
                    dark: true,
                    bannerTitle: 'Shop the Library',
                    bannerSub: 'Words, meanings and the origins behind them',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: TvSection(
                    eyebrow: 'The full library',
                    title: 'NowssB Subscription',
                    onTap: () => Dest.open(context, Dest.subscribe),
                    icon: Icons.workspace_premium_outlined,
                    asset: 'assets/video/subscription-a.mp4',
                    frame: DeviceFrame.tabletSlim,
                    dark: true,
                    bannerTitle: 'Every word, every meaning',
                    bannerSub: 'See what a subscription opens',
                  ),
                ),
                const SizedBox(height: 16),
                const GlassWrap(child: EditionCard(dark: true)),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Daily practice system',
                    title: 'My Routines',
                    onTap: () => Dest.open(context, Dest.routines),
                    icon: Icons.repeat_rounded,
                    asset: 'assets/video/player-liquid-splash.mp4',
                    aspect: 16 / 10,
                    dark: true,
                    bannerTitle: 'Five slots, one day',
                    bannerSub: 'Open routines',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: "Today's offer",
                    title: 'Coupon',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.local_offer_outlined,
                    asset: 'assets/video/coupon-a.mp4',
                    aspect: 16 / 10,
                    dark: true,
                    bannerTitle: 'Claim the offer',
                    bannerSub: 'Open the store',
                  ),
                ),
                const SizedBox(height: 16),
                    const HomeGutter(child: _FashQuickRow()),
                const SizedBox(height: 16),
                GlassWrap(
                  child: TvSection(
                    eyebrow: 'Featured ancient word science',
                    title: 'Shabdapathy Foundations',
                    onTap: () => Dest.open(context, Dest.library),
                    icon: Icons.menu_book_outlined,
                    asset: 'assets/video/fp-word-science.mp4',
                    dark: true,
                    bannerTitle: 'Open the foundations',
                    bannerSub: 'The system behind the words',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Deep-dive guides',
                    title: 'eBooks',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.menu_book_outlined,
                    asset: 'assets/video/word-acts.mp4',
                    dark: true,
                    bannerTitle: 'Word science and sound healing',
                    bannerSub: 'Browse the library',
                  ),
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'What Connect offers',
                    title: 'Connect Banner',
                    onTap: () => Dest.open(context, Dest.connect),
                    icon: Icons.groups_outlined,
                    asset: 'assets/video/connect-banner.mp4',
                    aspect: 16 / 10,
                    dark: true,
                    bannerTitle: 'Enter Connect',
                    bannerSub: 'People, chat, the feed',
                  ),
                ),
                const SizedBox(height: 16),
                const GlassWrap(child: HealingGrid(dark: true)),
                const SizedBox(height: 16),
                const GlassWrap(child: GenderPath(dark: true)),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'On film',
                    title: 'Promo',
                    onTap: () => Dest.open(context, Dest.store),
                    icon: Icons.play_circle_outline,
                    asset: 'assets/video/hero-bg.mp4',
                    aspect: 16 / 9,
                    dark: true,
                  ),
                ),
                const SizedBox(height: 16),
                WordSearchBlock(
                  title: 'Word Search',
                  sub: 'Discover the origin of any word',
                  asset: 'assets/video/fp-word-science.mp4',
                  dark: true,
                ),
                const SizedBox(height: 16),
                WordSearchBlock(
                  title: 'Meaning Search',
                  sub: 'Earth · Water · God · your name',
                  asset: 'assets/video/store-verify-banner.mp4',
                  dark: true,
                ),
                const SizedBox(height: 16),
                GlassWrap(
                  child: BannerSection(
                    eyebrow: 'Near the foot',
                    title: 'Shabdapathy',
                    onTap: () => Dest.open(context, Dest.library),
                    icon: Icons.auto_stories_outlined,
                    asset: 'assets/video/healing-path-bg.mp4',
                    aspect: 16 / 9,
                    dark: true,
                    bannerTitle: 'Natural Origin of Word Science',
                    bannerSub: 'Open the library',
                  ),
                ),
                const FooterMark(dark: true),
                  ],
                ),
              ),
            ],
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
          clipBehavior: Clip.antiAlias,
          child: NwsbImage(
            asset: 'assets/icons/logo-disc.webp',
            fit: BoxFit.cover,
            error: const Icon(Icons.headphones, size: 22, color: Colors.white),
          ),
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
        _FashHeaderBtn(
          icon: Icons.light_mode_outlined,
          onTap: () => Settings.instance.setFashionHome(false),
        ),
        const SizedBox(width: 8),
        _FashHeaderBtn(
          icon: Icons.menu,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WidgetsPage()),
          ),
        ),
      ],
    );
  }
}

class _FashHeaderBtn extends StatelessWidget {
  const _FashHeaderBtn({required this.icon, this.badge, this.onTap});
  final IconData icon;
  final int? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
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
      ),
    );
  }
}

class _FashPathHeading extends StatelessWidget {
  const _FashPathHeading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Begin Your Healing Path',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -.6,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'NATURAL ORIGIN OF WORD SCIENCE',
            style: TextStyle(
              color: Color(0xB3E8D5A3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.1,
            ),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () => Dest.open(context, Dest.library),
      behavior: HitTestBehavior.opaque,
      child: Container(
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

  // (title, sub, icon, destination) — 1 Practice · 2 Library · 3 Store ·
  // 4 Profile. A tile that goes nowhere is a tile that is not finished.
  static const _items = [
    ('Word Science', 'The system', Icons.science_outlined, Dest.library),
    ('NowssB Profile', 'You, so far', Icons.person_outline, Dest.profile),
    ('Sound Library', 'Root frequencies', Icons.graphic_eq, Dest.sound),
    ('My Routines', '5 routine slots', Icons.repeat_rounded, Dest.routines),
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
        for (final (title, sub, icon, dest) in _items)
          GestureDetector(
            onTap: () => Dest.open(context, dest),
            behavior: HitTestBehavior.opaque,
            child: Container(
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
          ),
      ],
    );
  }
}

class _FashStreak extends StatelessWidget {
  const _FashStreak();

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start Building Your Streak Today',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Practice daily to keep it alive — and unlock exclusive offers',
            style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department_outlined,
                    color: NwsbColors.goldLight, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: NwsbColors.goldLight,
                          height: 1,
                        ),
                      ),
                      Text(
                        'day streak',
                        style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'KEEP GOING',
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
        ],
      ),
    );
  }
}

class _FashHeroRow extends StatelessWidget {
  const _FashHeroRow();

  static const _items = [
    ('Customize', Icons.tune, Dest.settings),
    ('Features', Icons.auto_awesome_outlined, Dest.fashionPlus),
    ('Earn', Icons.workspace_premium_outlined, Dest.subscribe),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Dest.open(context, _items[i].$3),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: Column(
                  children: [
                    Icon(_items[i].$2, size: 18, color: NwsbColors.goldLight),
                    const SizedBox(height: 6),
                    Text(
                      _items[i].$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FashQuickRow extends StatelessWidget {
  const _FashQuickRow();

  static const _items = [
    ('Cart', Icons.shopping_cart_outlined, Dest.cart),
    ('Wishlist', Icons.favorite_border, Dest.wishlist),
    ('Order', Icons.shopping_bag_outlined, Dest.orders),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Dest.open(context, _items[i].$3),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Column(
                  children: [
                    Icon(_items[i].$2, size: 22, color: NwsbColors.goldLight),
                    const SizedBox(height: 7),
                    Text(
                      _items[i].$1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

