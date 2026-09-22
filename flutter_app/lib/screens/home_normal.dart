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
/// My Routines remains `defOff`; Personalized Healing is visible so its
/// Explore action opens the native Healing Path gender selector.
///
/// Nine of the sections here are the SAME widgets the Fashion home uses, out
/// of lib/screens/shared_sections.dart. index.html writes each of them once
/// and shows it on both homes; only the pane and the head differ, and
/// [HomeSkinScope] is what tells them which home they are on.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../data/settings.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import '../widgets/home_skin.dart';
import 'normal/neomorphic_action_bar.dart';
import 'normal/neomorphic_dashboard.dart';
import 'personal_coach.dart';
import 'healing_path.dart';
import '../media/video_pool.dart';
import 'normal/glassmorphism_theme.dart';
import 'normal/header_actions_sheet.dart';
import 'fashion/header.dart';
import '../widgets/nwsb_icon.dart';
import 'normal/neomorphic_essentials.dart';
import '../widgets/colored_split_promo_banner.dart';
import 'normal/horizontal_routine_cards.dart';
import 'normal/sections_bottom.dart';
import 'normal/sections_top.dart';
import 'normal/rotating_promo_rail.dart';
import 'shared_sections.dart';
import 'fashion/sections_mid.dart';
import 'sound_library.dart';
import 'notifications_sheet.dart';
import 'quick_access.dart';
import 'widgets_page.dart';
import '../widgets/home_menu_drawer.dart';
import '../widgets/hero_curve_stage.dart';
import 'practice_player.dart';
import 'progress/progress_screen.dart';
import 'reader/reader_hub.dart';
import 'subscription.dart';
import 'store/ebooks_store.dart';

/// `REG.norm.items` — app/js/part062.js:41-100, key for key and in order.
const kNormalSectionOrder = <String>[
  'greet',
  'search',
  'heroCurve',
  'promoRail',
  'dashboard',
  'essentials',
  'routineCards',
  // Streak+Store video carousel (shared 2-card), then the streak text block.
  'herovid',
  'streak',
  'practice',
  // Not on the website's registry. Six doors on one panel so the app can
  // be used without knowing where anything is — see MainOptionsSection.
  'mainops',
  'actionbar',
  'tiles',
  'store',
  'reader',
  'trendwd',
  'custom',
  'rx',
  'routines',
  'condisc',
  'feed',
  'quickrow',
  'trendshop',
  'subvid',
  'edition',
  'ebooks',
  'connectban',
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
const kNormalDefOff = <String>{'routines'};

class HomeNormal extends StatefulWidget {
  const HomeNormal({super.key, this.name = 'Healer'});

  final String name;

  @override
  State<HomeNormal> createState() => _HomeNormalState();
}

class _HomeNormalState extends State<HomeNormal> {
  bool _glassMode = false;

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
    PracticeProgress.instance.addListener(_onContent);
    unawaited(PracticeProgress.instance.start());
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    PracticeProgress.instance.removeListener(_onContent);
    VideoPool.instance.setGlassHomeMode(false);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  void _go(int tab) => NavScope.goTo(context, tab);

  void _push(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  void _openDashboardSession(List<Word> words, String title) {
    _push(PracticePlayerScreen(words: words, title: title));
  }

  void _openDashboardProgress() {
    _push(PracticeProgressScreen(words: ContentStore.instance.library));
  }

  void _openHomeMenu(BuildContext context) {
    showHomeMenuDrawer(context, goTab: _go);
  }

  void _openMainOption(String label, int tab) {
    switch (label) {
      case 'Sound Library':
        _push(const SoundLibraryScreen());
      case 'My Progress':
        _openDashboardProgress();
      default:
        _go(tab);
    }
  }

  void _openEnter(String id) {
    switch (id) {
      case 'player':
        _go(1);
      case 'library':
        _push(const SoundLibraryScreen());
      case 'store':
        _go(3);
      case 'reader':
        _push(const ReaderHubScreen());
      case 'ebook':
        _push(const EbooksStoreScreen());
      case 'healing':
        _push(const HealingPathScreen());
    }
  }

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
  /// Quick action hero chip → HeaderActionsSheet destinations.
  /// QuickAccessScreen (nav customize) stays on settings/hamburger only.
  void _openQuickAction() {
    showHeaderActionsSheet(
      context,
      glassMode: _glassMode,
      onGlassToggle: () => setState(() {
        _glassMode = !_glassMode;
        VideoPool.instance.setGlassHomeMode(_glassMode);
      }),
      onNotifications: () => showNotificationsSheet(context),
      onFashionHome: () => Settings.instance.setFashionHome(true),
      onStore: () => NavScope.goTo(context, 3),
      onPlayer: () {
        final words = ContentStore.instance.library;
        if (words.isEmpty) {
          NavScope.goTo(context, 1);
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PracticePlayerScreen(
              words: words,
              title: 'Practice',
            ),
          ),
        );
      },
    );
  }

  List<(String, Widget?)> _sections() => [
        ('greet', NmGreeting(name: widget.name)),
        ('search', NmSearch(onSearch: (_) => _go(2))),
        ('heroCurve', HeroCurveStage(
          compact: true,
          onSearch: () => showDestinationSearchSheet(context),
          // Quick action chip → HeaderActionsSheet (destinations), NOT QuickAccessScreen.
          onQuickAccess: _openQuickAction,
        )),
        (
          'promoRail',
          NormalPromoRail(
            onStore: () => _go(3),
            onPlayer: () => _go(1),
            onEarn: () => _go(4),
          ),
        ),
        (
          'dashboard',
          NmSuppliedDashboard(
              onStart: _openDashboardSession,
              onProgress: _openDashboardProgress)
        ),
        (
          'essentials',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: ColoredSplitPromoBanner.forSurface(
                  SplitPromoSurface.normalHome,
                  onTap: () => _go(2),
                ),
              ),
              const NmSuppliedEssentials(),
            ],
          ),
        ),
        ('routineCards', const NmHorizontalRoutineCards()),
        (
          'herovid',
          NmStreakVideo(
            onTap: () => _go(1),
            onStoreTap: () => _go(3),
          ),
        ),
        ('streak', NmStreak(onTap: () => _go(1))),
        ('practice', NmPractice(onTap: () => _go(1))),
        ('mainops', MainOptionsSection(onGo: _go, onAction: _openMainOption)),
        (
          'actionbar',
          NmSuppliedActionBar(
              onSupport: () => _go(4),
              onCoach: () => _push(const PersonalCoachScreen()))
        ),
        // H-scroll: Flip glass brand showcase (card 0) + existing feature cards.
        (
          'tiles',
          FashTiles(onTile: _go, onOpen: _openEnter),
        ),
        ('store', NmStore(onTap: () => _go(3))),
        ('reader', NmReader(onTap: () => _push(const ReaderHubScreen()))),
        ('trendwd', NmTrending(onTap: () => _go(2))),
        ('custom', NmCustomize(onTap: () => _push(const WidgetsPage()))),
        ('rx', null),
        ('routines', RoutinesSection(onTap: () => _go(1))),
        (
          'condisc',
          NmPromoDisc(
            gradient: NmPromoDisc.blue,
            slides: NmPromoDisc.connectSlides,
            onTap: () => _go(0),
          )
        ),
        ('feed', NmFeed(onTap: () => _go(0))),
        (
          'quickrow',
          QuickAccessSection(
            onCart: () => _go(3),
            onWishlist: () => _go(3),
            onOrders: () => _go(4),
          )
        ),
        ('trendshop', NmTrendShop(onTap: () => _go(3))),
        ('subvid', const SizedBox.shrink()),
        (
          'edition',
          EditionSection(onTap: () => _push(const SubscriptionScreen()))
        ),
        ('ebooks', EbooksSection(onTap: () => _go(2))),
        ('connectban', ConnectBannerSection(onTap: () => _go(0))),
        (
          'healing',
          HealingSection(
            onTap: () => _push(const HealingPathScreen()),
            onFemale: () => _push(
                const HealingPathScreen(initialGender: HealingGender.female)),
            onMale: () => _push(
                const HealingPathScreen(initialGender: HealingGender.male)),
          ),
        ),
        // Choose Your Path is slide 2 of HealingSection — do not inject a
        // second banner/section (that caused stacked banners + blank pages).
        ('genderpath', const SizedBox.shrink()),
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
        if (w != null && !kNormalDefOff.contains(k)) (k, w),
    ];

    final page = SafeArea(
      child: Column(
        children: [
          // `.nmh-toprow` — pinned to the top, never scrolls.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: _TopRow(
              onMenu: () => _openHomeMenu(context),
              onNotifications: () => showNotificationsSheet(context),
              glassMode: _glassMode,
              onGlassToggle: () => setState(() {
                _glassMode = !_glassMode;
                // Keep on-screen clips decoding while glass film is up.
                VideoPool.instance.setGlassHomeMode(_glassMode);
              }),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _go(1),
              child: const Text('Play session'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              // Modest look-ahead: enough for smooth scroll, not enough to
              // mount every video on the home at once (N+1 decoder churn).
              cacheExtent: 480,
              // Footer paints solid black through nav clearance.
              padding: EdgeInsets.zero,
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final (k, w) = shown[i];
                return KeyedSubtree(key: ValueKey('nm-$k'), child: w);
              },
            ),
          ),
        ],
      ),
    );

    return NormalGlassMode(
      enabled: _glassMode,
      child: HomeSkinScope(
        skin: HomeSkin.normal,
        child: Scaffold(
          backgroundColor:
              _glassMode ? const Color(0xFFF7FAFF) : NwsbColors.surface,
          body: _glassMode ? NormalGlassBackground(child: page) : page,
        ),
      ),
    );
  }
}

/// .nmh-toprow — logo + title on the left; Settings | Quick | Menu on the
/// right. The expanding SVG control opens the glass 3D actions carousel.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.onMenu,
    required this.onNotifications,
    required this.glassMode,
    required this.onGlassToggle,
  });

  final VoidCallback onMenu;
  final VoidCallback onNotifications;
  final bool glassMode;
  final VoidCallback onGlassToggle;

  void _openActions(BuildContext context) {
    showHeaderActionsSheet(
      context,
      glassMode: glassMode,
      onGlassToggle: onGlassToggle,
      onNotifications: () => showNotificationsSheet(context),
      onFashionHome: () => Settings.instance.setFashionHome(true),
      onStore: () => NavScope.goTo(context, 3),
      onPlayer: () {
        final words = ContentStore.instance.library;
        if (words.isEmpty) {
          NavScope.goTo(context, 1);
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PracticePlayerScreen(
              words: words,
              title: 'Practice',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Row(
      children: [
        // Normal home only: the static mark sits in a raised neumorphic disc.
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glass ? const Color(0xAFFFFFFF) : NwsbColors.surface,
            border: glass ? Border.all(color: const Color(0xDFFFFFFF)) : null,
            boxShadow: glass
                ? null
                : const [
                    BoxShadow(
                        color: Color(0xFFFFFFFF),
                        blurRadius: 8,
                        offset: Offset(-4, -4)),
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(4, 4)),
                  ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/logo-disc.webp',
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFA21A),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Flexible, not a bare Column: 'NOWSBANSIU EDITION' at 2pt of letter
        // spacing is wider than it looks, and on a 412pt screen it pushed
        // the header buttons clean off the right edge.
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
        // Right cluster: Settings | Notifications | Hamburger
        // Quick access belongs in Fashion Hero — bell returns here.
        _HeaderButton(
          icon: Icons.settings_outlined,
          onTap: () => _openActions(context),
        ),
        const _HeaderDivider(),
        _HeaderButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
        ),
        const _HeaderDivider(),
        _HamburgerButton(onTap: onMenu),
      ],
    );
  }
}

/// Hairline between right-cluster header controls (Settings | Quick | Menu).
class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 1,
        height: 22,
        decoration: BoxDecoration(
          color: glass ? const Color(0x66FFFFFF) : const Color(0x33244766),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Rounded header control — four-square [NwsbMarks.features] mark that
/// expands into the glass cover-flow sheet.
class _HeaderActionsSvgButton extends StatelessWidget {
  const _HeaderActionsSvgButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: glass ? const Color(0xAFFFFFFF) : NwsbColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: glass ? Border.all(color: const Color(0xDFFFFFFF)) : null,
          boxShadow: glass ? null : NwsbShadows.raisedXs,
        ),
        child: const Center(
          child: NwsbIcon(
            NwsbMarks.features,
            size: 20,
            color: NwsbColors.ink,
            strokeWidth: 1.7,
          ),
        ),
      ),
    );
  }
}

class _HamburgerButton extends StatelessWidget {
  const _HamburgerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: glass ? const Color(0xBFFFFFFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: glass ? Border.all(color: const Color(0xDFFFFFFF)) : null,
          boxShadow: glass ? null : NwsbShadows.raisedXs,
        ),
        child: const Icon(Icons.menu_rounded, size: 23, color: NwsbColors.ink),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    this.badge,
    this.badgeLabel,
    this.onTap,
  });
  final IconData icon;
  final int? badge;
  final String? badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
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
              color: glass ? const Color(0xAFFFFFFF) : NwsbColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: glass ? Border.all(color: const Color(0xDFFFFFFF)) : null,
              boxShadow: glass ? null : NwsbShadows.raisedXs,
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
                  badgeLabel ?? '$badge',
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
