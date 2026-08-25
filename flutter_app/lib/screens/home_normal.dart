/// The Normal home — `#home-nm`, the pale one.
///
/// The Fashion home is a dark page with the film running behind it and every
/// block sitting on it as a pane of glass. This one is the opposite: the
/// page's own colour everywhere, and every section RAISED out of it by a
/// pair of shadows — a dark one down-right and a white one up-left. Drop
/// either and the surface stops reading as raised, which is the whole
/// language of this home.
///
/// WHAT THIS PAGE IS, EXACTLY
///
/// `REG.norm.items` in app/js/part062.js:40-101 is the list of sections this
/// home is made of — twenty-nine of them, in that order. This file is that
/// list, in that order.
///
/// Four of the twenty-nine have a registry row and no markup behind it, and
/// that is the website's state rather than an omission here:
///
///   rx        "AI Prescription removed from this home" (index.html:1329) —
///             the one search bar at the head replaced it
///   wsearch   "removed from this home — the one search bar above covers it"
///   msearch   the same
///
/// `storeban` USED TO BE ON THAT LIST — "points at .fash-storeban-wrap,
/// which is Fashion markup". It is not any more. app/js/part062.js:82
/// registers it on this home too, against that same selector, and there was
/// simply no element for it to match: this home dropped a bare clip above
/// its store card with no heading, no device and no bar under it, while the
/// Fashion home carried the same thing as a proper block. Both build it now.
///
/// Two more are `defOff` — My Routines and Personalised Healing. So a fresh
/// install shows twenty-three sections.
///
/// Nine of the sections here are the SAME widgets the Fashion home uses, out
/// of lib/screens/shared_sections.dart. index.html writes each of them once
/// and shows it on both homes; only the pane and the head differ, and
/// [HomeSkinScope] is what tells them which home they are on.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../media/nwsb_image.dart';
import '../data/settings.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import '../widgets/home_skin.dart';
import 'normal/sections_bottom.dart';
import 'normal/sections_top.dart';
import 'shared_sections.dart';
import '../widgets/day_dashboard.dart';
import '../widgets/motion.dart';
import 'sound_library.dart';
import 'widgets_page.dart';

/// The same local-time greeting used by both homes.
String nwsbGreeting([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h >= 5 && h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  if (h < 21) return 'Good Evening';
  return 'Good Night';
}

/// `REG.norm.items` — app/js/part062.js:41-100, key for key and in order.
const kNormalSectionOrder = <String>[
  'greet',
  'search',
  'dashboard',
  'streak',
  'storedisc',
  'practice',
  // Not on the website's registry. Six doors on one panel so the app can
  // be used without knowing where anything is — see MainOptionsSection.
  'mainops',
  'tiles',
  'store',
  'reader',
  'trendwd',
  'rx',
  'routines',
  'quickrow',
  // MOVED. It used to open the page directly above the streak card,
  // which put a heading, a film and a second heading in a row all saying
  // Streak. It sits with the other video banners now.
  'herovid',
  'trendshop',
  'storeban',
  'ebooks',
  'healing',
  'genderpath',
  'wsearch',
  'msearch',
  'fashsw',
  'footer',
];

/// Registered, and with nothing behind them on this home. See the note at
/// the head of this file — each one was taken out of `#home-nm` deliberately
/// and its registry row was left standing.
const kNormalNoMarkup = <String>{'rx', 'wsearch', 'msearch'};

/// The two `defOff` entries that DO have markup. Built, not placed.
const kNormalDefOff = <String>{'routines', 'healing'};

class HomeNormal extends StatefulWidget {
  const HomeNormal({super.key, this.name = 'Healer'});

  final String name;

  @override
  State<HomeNormal> createState() => _HomeNormalState();
}

class _HomeNormalState extends State<HomeNormal> {
  bool _scrollingDown = false;
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

  void _go(int tab) => NavScope.goTo(context, tab);

  void _push(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  void _footerLink(String key) {
    switch (key) {
      case 'about':
      case 'word-science':
        _go(2);
      case 'sound-library':
        _push(const SoundLibraryScreen());
      case 'meaning-store':
        _go(3);
      case 'practice':
        _go(1);
      case 'profile':
        _go(4);
    }
  }

  /// The twenty-nine, in `REG.norm.items` order. A null widget is a row with
  /// no markup on this home; it keeps its place in the list so the two can
  /// be diffed by eye against part062.js.
  List<(String, Widget?)> _sections() => [
        ('greet', NmGreeting(name: widget.name)),
        ('search', NmSearch(onSearch: (_) => _go(2))),
        (
          'dashboard',
          const HomeGutter(
            horizontal: 20,
            child: NwsbDayDashboard(fashion: false),
          ),
        ),
        ('streak', NmStreak(onTap: () => _go(1))),
        (
          'storedisc',
          NmPromoDisc(
            gradient: NmPromoDisc.purple,
            slides: NmPromoDisc.storeSlides,
            onTap: () => _go(3),
          )
        ),
        ('practice', NmPractice(onTap: () => _go(1))),
        ('mainops', MainOptionsSection(onGo: _go)),
        ('tiles', NmTiles(onTile: _go)),
        ('store', NmStore(onTap: () => _go(3))),
        ('reader', NmReader(onTap: () => _go(2))),
        ('trendwd', NmTrending(onTap: () => _go(2))),
        ('rx', null),
        ('routines', RoutinesSection(onTap: () => _go(1))),
        (
          'quickrow',
          QuickAccessSection(
            onCart: () => _go(3),
            onWishlist: () => _go(3),
            onOrders: () => _go(4),
          )
        ),
        ('herovid', NmStreakVideo(onTap: () => _go(1))),
        ('trendshop', NmTrendShop(onTap: () => _go(3))),
        ('storeban', StoreBannerSection(onTap: () => _go(3), framed: true)),
        ('ebooks', EbooksSection(onTap: () => _go(2))),
        ('healing', HealingSection(onTap: () => _go(2))),
        (
          'genderpath',
          GenderPathSection(
            onFemale: () => _go(2),
            onMale: () => _go(2),
            onTap: () => _go(2),
          )
        ),
        ('wsearch', null),
        ('msearch', null),
        (
          'fashsw',
          NmFashionSwitch(onTap: () => Settings.instance.setFashionHome(true))
        ),
        ('footer', HomeFooterSection(onLink: _footerLink)),
      ];

  @override
  Widget build(BuildContext context) {
    final built = _sections();
    assert(
      built.map((e) => e.$1).toList().toString() ==
          kNormalSectionOrder.toString(),
      'the page and the registry have drifted apart',
    );
    assert(
      built.where((e) => e.$2 == null).map((e) => e.$1).toSet().toString() ==
          kNormalNoMarkup.toString(),
      'a section lost its markup without the note at the head of this file '
      'being updated',
    );

    final shown = [
      for (final (k, w) in built)
        if (w != null && !kNormalDefOff.contains(k)) w,
    ];

    return HomeSkinScope(
      skin: HomeSkin.normal,
      child: Scaffold(
        backgroundColor: NwsbColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // `.nmh-toprow` — pinned to the top, never scrolls. It is
              // outside the list rather than its first row, which is what
              // "never scrolls" means.
              AnimatedSlide(
                offset: _scrollingDown ? const Offset(0, -.04) : Offset.zero,
                duration: NwsbMotion.pageDuration,
                curve: NwsbMotion.softCurve,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _TopRow(),
                ),
              ),
              Expanded(
                // No horizontal padding: the sections carry their own
                // `margin: 16px 0` inside `.nmh-wrap`'s 20px, and a raised
                // card needs room around it for its own shadow.
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    final direction = notification.direction;
                    if (direction == ScrollDirection.reverse ||
                        direction == ScrollDirection.forward) {
                      final next = direction == ScrollDirection.reverse;
                      if (_scrollingDown != next) setState(() => _scrollingDown = next);
                    } else if (direction == ScrollDirection.idle && _scrollingDown) {
                      setState(() => _scrollingDown = false);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const NwsbSmoothScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => NwsbMotionReveal(
                      delay: Duration(milliseconds: (i.clamp(0, 8) as num).toInt() * 24),
                      child: shown[i],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          child: const NwsbImage(
            asset: 'assets/icons/logo-disc.webp',
            fit: BoxFit.cover,
            error: SizedBox.shrink(),
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
