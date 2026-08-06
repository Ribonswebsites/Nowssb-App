/// The Normal home — #home-nm, in real widgets.
///
/// Section for section, in the order app/js/part062.js ships them:
/// greeting, search, hero, streak, practice, tiles, quick row. Nothing here
/// is a WebView and nothing here is HTML.
library;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/neumorphic.dart';

/// The website derives this from the hour in app/js/part026.js and the same
/// three windows are used here, so the two never disagree.
///
/// Top-level, not a getter on HomeNormal. It was a getter, and _Greeting
/// reached it by building its own `const HomeNormal()` — which also meant
/// it read that throwaway's default name rather than the one passed in, so
/// the greeting always said "Healer" no matter who was signed in.
String nwsbGreeting([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
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
            const _StreakSection(),
            const SizedBox(height: NwsbSpace.gap),
            const _PracticeCard(),
            const SizedBox(height: NwsbSpace.gap),
            const _Tiles(),
            const SizedBox(height: NwsbSpace.gap),
            const _QuickRow(),
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
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: NwsbColors.surface,
            shape: BoxShape.circle,
            boxShadow: NwsbShadows.raisedXs,
          ),
        ),
        const SizedBox(width: 12),
        Column(
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
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
        const Spacer(),
        const _HeaderButton(icon: Icons.notifications_none, badge: 0),
        const SizedBox(width: 8),
        const _HeaderButton(icon: Icons.settings_outlined),
        const SizedBox(width: 8),
        const _HeaderButton(icon: Icons.home_outlined),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.badge});
  final IconData icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Search any word or meaning…',
                hintStyle:
                    TextStyle(fontSize: 15, color: Color(0x59000000)),
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: NwsbColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, size: 20, color: Colors.white),
          ),
        ],
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
                const Column(
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
                const Spacer(),
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
          const NwsbBanner(
            title: 'Daily Streak',
            sub: 'Practice daily to keep your healing streak alive',
            icon: Icons.local_fire_department_outlined,
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
            'Afternoon Word Ritual',
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
    ('Sound Library', 'Root frequencies', Icons.graphic_eq),
    ('My Progress', 'Your practice', Icons.insights_outlined),
    ('Word Atelier', 'Origins of words', Icons.auto_stories_outlined),
    ('Routines', 'Daily system', Icons.repeat_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final (title, sub, icon) in _items)
          NeuCard(
            radius: NwsbRadius.tile,
            elevation: NwsbElevation.sm,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  sub,
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
    ('Cart', Icons.shopping_cart_outlined),
    ('Wishlist', Icons.favorite_border),
    ('Order', Icons.shopping_bag_outlined),
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
