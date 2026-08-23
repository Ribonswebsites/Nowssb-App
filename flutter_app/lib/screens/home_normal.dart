/// The Normal home — #home-nm, in real widgets.
///
/// Section for section, in the order app/js/part062.js ships them.
/// Greeting, search, dashboard, practice, library, healing, path, and footer.
/// Nothing here is a WebView and nothing here is HTML.
library;

import 'package:flutter/material.dart';
import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../theme/tokens.dart';
import '../widgets/neumorphic.dart';
import '../shell/go.dart';
import '../widgets/tv_frame.dart';
import 'practice.dart' show nwsbSlotTitle;
import 'sections.dart';
import '../widgets/day_dashboard.dart';

/// The website derives this from the hour in app/js/part026.js and the same
/// three windows are used here, so the two never disagree.
///
/// Top-level, not a getter on HomeNormal. It was a getter, and _Greeting
/// reached it by building its own `const HomeNormal()` — which also meant
/// it read that throwaway's default name rather than the one passed in, so
/// the greeting always said "Healer" no matter who was signed in.
String nwsbGreeting([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h >= 5 && h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  if (h < 21) return 'Good Evening';
  return 'Good Night';
}

class HomeNormal extends StatelessWidget {
  const HomeNormal({super.key, this.name = 'Healer'});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NwsbSpace.pageX,
            NwsbSpace.pageTop,
            NwsbSpace.pageX,
            96, // clear of the bottom nav
          ),
          children: [
            const _TopRow(),
            const SizedBox(height: 18),
            _Greeting(name: name),
            const SizedBox(height: NwsbSpace.gap),
            const _SearchBar(),
            const SizedBox(height: NwsbSpace.gap),
            const NwsbDayDashboard(fashion: false),
            const SizedBox(height: NwsbSpace.gap),

            // Shipped order of #home-nm, matching app/js/part062.js REG.nm.
            // Every clip goes through NwsbVideo. On-screen films play.
            const HeroSection(),
            const SizedBox(height: NwsbSpace.gap),
            TvSection(
              eyebrow: 'Today, on film',
              title: 'Streak Video',
              onTap: () => Dest.open(context, Dest.practice),
              icon: Icons.local_fire_department_outlined,
              asset: 'assets/video/tv-screen.mp4',
            ),
            const SizedBox(height: NwsbSpace.gap),
            const _StreakSection(),
            const SizedBox(height: NwsbSpace.gap),
            PromoDisc(
              asset: 'assets/video/store-trigger.mp4',
              title: 'NowssB Store',
              sub: 'Words, meanings, the origins behind them',
              onTap: () => Dest.open(context, Dest.store),
            ),
            const SizedBox(height: NwsbSpace.gap),
            const _PracticeCard(),
            const SizedBox(height: NwsbSpace.gap),
            const _Tiles(),
            const SizedBox(height: NwsbSpace.gap),
            TvSection(
              eyebrow: 'The shelf',
              title: 'NowssB Store',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.storefront_outlined,
              asset: 'assets/video/store-section.mp4',
              frame: DeviceFrame.tabletPortrait,
              bannerTitle: 'Everything the practice needs',
              bannerSub: 'Open the store',
            ),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Today words meaning',
              title: 'Reader',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.auto_stories_outlined,
              asset: 'assets/video/store-banner.mp4',
              overlay: 'Every word,\nexplained',
              bannerTitle: 'Meanings and eBooks, in one place',
              bannerSub: 'Open the store',
            ),
            const SizedBox(height: NwsbSpace.gap),
            TvSection(
              eyebrow: "Today's trending",
              title: 'The Signature',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.workspace_premium_outlined,
              asset: 'assets/video/signature-banner.mp4',
              bannerTitle: 'One word, made only for you',
              bannerSub: 'See the Signature',
            ),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Your daily recommended words',
              title: 'AI Prescription',
              onTap: () => Dest.open(context, Dest.practice),
              icon: Icons.auto_awesome_outlined,
              asset: 'assets/video/rx-banner.mp4',
              overlay: 'A word\nfor today',
              bannerTitle: 'Open today’s practice',
              bannerSub: 'Matched to the hour',
            ),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Daily practice system',
              title: 'My Routines',
              onTap: () => Dest.open(context, Dest.routines),
              icon: Icons.repeat_rounded,
              asset: 'assets/video/player-liquid-splash.mp4',
              aspect: 16 / 10,
              bannerTitle: 'Five slots, one day',
              bannerSub: 'Open routines',
            ),
            const SizedBox(height: NwsbSpace.gap),
            const FeedCarousel(),
            const SizedBox(height: NwsbSpace.gap),
            const _QuickRow(),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Shop the moment',
              title: 'Trending Shop',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.local_mall_outlined,
              asset: 'assets/video/store-banner-fash.mp4',
              aspect: 16 / 10,
              bannerTitle: 'Shop now',
              bannerSub: 'Open the store',
            ),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Own the sounds that heal',
              title: 'Store Banner',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.shopping_bag_outlined,
              asset: 'assets/video/store-banner.mp4',
              aspect: 16 / 10,
              bannerTitle: 'Shop the Library',
              bannerSub: 'Words, meanings and the origins behind them',
            ),
            const SizedBox(height: NwsbSpace.gap),
            BannerSection(
              eyebrow: 'Deep-dive guides',
              title: 'eBooks',
              onTap: () => Dest.open(context, Dest.store),
              icon: Icons.menu_book_outlined,
              asset: 'assets/video/word-acts.mp4',
              bannerTitle: 'Word science and sound healing',
              bannerSub: 'Browse the library',
            ),
            const SizedBox(height: NwsbSpace.gap),
            const HealingGrid(),
            const SizedBox(height: NwsbSpace.gap),
            const GenderPath(),
            const SizedBox(height: NwsbSpace.gap),
            WordSearchBlock(
              title: 'Word Search',
              sub: 'Discover the origin of any word',
              asset: 'assets/video/fp-word-science.mp4',
            ),
            const SizedBox(height: NwsbSpace.gap),
            WordSearchBlock(
              title: 'Meaning Search',
              sub: 'Earth · Water · God · your name',
              asset: 'assets/video/store-verify-banner.mp4',
            ),
            const SizedBox(height: NwsbSpace.gap),
            NeuCard(
              padding: const EdgeInsets.all(16),
              onTap: () => Settings.instance.setFashionHome(true),
              child: Row(
                children: const [
                  Icon(Icons.dark_mode_outlined, color: NwsbColors.ink),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fashion Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: NwsbColors.ink,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Switch to the dark home with the film behind it',
                          style: TextStyle(
                            fontSize: 12,
                            color: NwsbColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: NwsbColors.ink),
                ],
              ),
            ),
            const FooterMark(),
          ],
        ),
      ),
    );
  }
}

/// .nmh-toprow — the logo, the wordmark, and the three embossed buttons.
class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The app's own mark, out of assets/icons. This was an empty
        // neumorphic disc — the logo has been in the repository all along.
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: NwsbColors.surface,
            shape: BoxShape.circle,
            boxShadow: NwsbShadows.raisedXs,
          ),
          clipBehavior: Clip.antiAlias,
          child: NwsbImage(
            'assets/icons/logo-disc.webp',
            fit: BoxFit.cover,
            error: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 12),
        // Flexible, not a bare Column: 'NOWSBANSIU EDITION' at 2pt of letter
        // spacing is wider than it looks, and on a 412pt screen it pushed
        // the three header buttons clean off the right edge.
        Flexible(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NowssB',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            Text(
              'NOWSBANSIU EDITION',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
        ),
        const Spacer(),
        const _HeaderButton(icon: Icons.notifications_none, badge: 0),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WidgetsPage()),
          ),
        ),
        const SizedBox(width: 8),
        // The home button switches which home you are on. There are three
        // ways to reach the Fashion home now — this, the pill above the nav,
        // and Settings — because one that nobody finds is one that is not
        // built.
        _HeaderButton(
          icon: Icons.dark_mode_outlined,
          onTap: () => Settings.instance.setFashionHome(true),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.badge, this.onTap});
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NwsbColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: NwsbShadows.raisedXs,
          ),
          child: Icon(icon, size: 21, color: NwsbColors.ink),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0342B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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

/// .nmh-greet-block — the orb, the hello, the name, the line under it.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: NwsbColors.surface,
            shape: BoxShape.circle,
            boxShadow: NwsbShadows.raisedXs,
          ),
          child: const Icon(Icons.wb_sunny_outlined,
              size: 26, color: NwsbColors.gold),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nwsbGreeting(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0x8C000000),
                ),
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              const Text(
                "Ready for today's healing practice?",
                style: TextStyle(fontSize: 13, color: NwsbColors.inkFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// .nmh-search — one bar for words and meanings. A pressed well, not a
/// raised card, which is why the shadows are inset on the web; here the
/// same read comes from a dimmer fill inside the raised page.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF4),
        borderRadius: BorderRadius.circular(31),
        boxShadow: NwsbShadows.raisedXs,
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 22, color: Color(0x59000000)),
          const SizedBox(width: 10),
          const Expanded(
            child: _HomeSearchField(),
          ),
          GestureDetector(
            onTap: () => Dest.open(context, Dest.searchWords),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: NwsbColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: (_) => Dest.open(context, Dest.searchWords),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        hintText: 'Search any word or meaning…',
        hintStyle: TextStyle(fontSize: 15, color: Color(0x59000000)),
      ),
    );
  }
}

/// .nmh-streak-section
class _StreakSection extends StatelessWidget {
  const _StreakSection();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Building Your Streak Today',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Practice daily to keep it alive — and unlock exclusive offers',
            style: TextStyle(fontSize: 13, color: NwsbColors.inkFaint),
          ),
          const SizedBox(height: 18),
          NeuCard(
            elevation: NwsbElevation.xs,
            radius: NwsbRadius.bar,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: NwsbColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: NwsbShadows.raisedXs,
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      color: NwsbColors.gold),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: NwsbColors.gold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'day streak',
                      style: TextStyle(
                        fontSize: 11,
                        color: NwsbColors.inkFaint,
                      ),
                    ),
                  ],
                ),
                ),
                const Text(
                  'KEEP GOING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0x66000000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NwsbBanner(
            title: 'Daily Streak',
            sub: 'Practice daily to keep your healing streak alive',
            icon: Icons.local_fire_department_outlined,
            onTap: () => Dest.open(context, Dest.practice),
          ),
        ],
      ),
    );
  }
}

/// .nmh-practice — Today's Practice. The eyebrow, the embossed icon tile,
/// the word, the meaning, then Enter and its arrow, in that order.
class _PracticeCard extends StatelessWidget {
  const _PracticeCard();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      onTap: () => Dest.open(context, Dest.player),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S PRACTICE",
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 14),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: NwsbColors.surface,
              borderRadius: BorderRadius.circular(NwsbRadius.pill),
              boxShadow: NwsbShadows.raisedXs,
            ),
            child: const Icon(Icons.psychology_outlined,
                size: 30, color: NwsbColors.ink),
          ),
          const SizedBox(height: 18),
          Text(
            nwsbSlotTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontSize: 26,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to My Routines to add words to this session.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: NwsbColors.inkSoft),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NwsbColors.ink,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: NwsbColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 16, color: NwsbColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// .nmh-grid — the four tiles, two across.
class _Tiles extends StatelessWidget {
  const _Tiles();

  static const _items = [
    ('Sound Library', 'Root frequencies', Icons.graphic_eq, Dest.sound),
    ('My Progress', 'Your practice', Icons.insights_outlined, Dest.profile),
    ('Word Atelier', 'Origins of words', Icons.auto_stories_outlined, Dest.store),
    ('Routines', 'Daily system', Icons.repeat_rounded, Dest.routines),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // 1.05 was a tile 12pt shorter than its own contents once the disc,
      // the title and the caption were laid out at the system text size.
      // Taller, and the text is allowed to ellipsize rather than overflow —
      // a tile has to survive a reader who has turned their font up.
      childAspectRatio: 0.92,
      children: [
        for (final (title, sub, icon, dest) in _items)
          NeuCard(
            radius: NwsbRadius.tile,
            elevation: NwsbElevation.sm,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            onTap: () => Dest.open(context, dest),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: NwsbColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: NwsbShadows.raisedXs,
                  ),
                  child: Icon(icon, size: 24, color: NwsbColors.ink),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: NwsbColors.inkFaint),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// .nmh-quick-row — Cart, Wishlist, Order. Plain, no frame.
class _QuickRow extends StatelessWidget {
  const _QuickRow();

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
            child: NeuCard(
              radius: NwsbRadius.bar,
              elevation: NwsbElevation.xs,
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              onTap: () => Dest.open(context, _items[i].$3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_items[i].$2, size: 26, color: NwsbColors.gold),
                  const SizedBox(height: 7),
                  Text(
                    _items[i].$1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0x8C000000),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
