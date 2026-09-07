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
import '../media/video_pool.dart';
import 'normal/glassmorphism_theme.dart';
import 'normal/header_actions_sheet.dart';
import '../widgets/nwsb_icon.dart';
import 'normal/neomorphic_essentials.dart';
import 'normal/sections_bottom.dart';
import 'normal/sections_top.dart';
import 'shared_sections.dart';
import 'sound_library.dart';
import 'notifications_sheet.dart';
import 'widgets_page.dart';
import 'practice_player.dart';

/// `REG.norm.items` — app/js/part062.js:41-100, key for key and in order.
const kNormalSectionOrder = <String>[
  'greet',
  'search',
  'dashboard',
  'essentials',
  'streak',
  'storedisc',
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
  'connect',
  'feed',
  'quickrow',
  // MOVED. It used to open the page directly above the streak card,
  // which put a heading, a film and a second heading in a row all saying
  // Streak. It sits with the other video banners now.
  'herovid',
  'trendshop',
  'storeban',
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
const kNormalDefOff = <String>{'routines', 'healing'};

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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (sheetContext) => _NormalHomeMenu(
        onSelect: (tab) {
          Navigator.of(sheetContext).pop();
          _go(tab);
        },
      ),
    );
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
          NmSuppliedDashboard(
              onStart: _openDashboardSession,
              onProgress: _openDashboardProgress)
        ),
        ('essentials', const NmSuppliedEssentials()),
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
        ('mainops', MainOptionsSection(onGo: _go, onAction: _openMainOption)),
        (
          'actionbar',
          NmSuppliedActionBar(
              onSupport: () => _go(4),
              onCoach: () => _push(const PersonalCoachScreen()))
        ),
        ('tiles', NmTiles(onTile: _go)),
        ('store', NmStore(onTap: () => _go(3))),
        ('reader', NmReader(onTap: () => _go(2))),
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
        ('connect', NmConnect(onTap: () => _go(0))),
        ('feed', NmFeed(onTap: () => _go(0))),
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
        ('subvid', SubscriptionSection(onTap: () => _go(3))),
        ('edition', EditionSection(onTap: () => _go(3))),
        ('ebooks', EbooksSection(onTap: () => _go(2))),
        ('connectban', ConnectBannerSection(onTap: () => _go(0))),
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
    final bottomNavigationClearance =
        MediaQuery.paddingOf(context).bottom + 112;
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

    final page = SafeArea(
      child: Column(
        children: [
          // `.nmh-toprow` — pinned to the top, never scrolls.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: _TopRow(
              onMenu: () => _openHomeMenu(context),
              glassMode: _glassMode,
              onGlassToggle: () => setState(() {
                _glassMode = !_glassMode;
                // Keep on-screen clips decoding while glass film is up.
                VideoPool.instance.setGlassHomeMode(_glassMode);
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: bottomNavigationClearance),
              itemCount: shown.length,
              itemBuilder: (context, i) => shown[i],
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

/// .nmh-toprow — essentials only: menu, logo, title, Settings, and one
/// expanding SVG control that opens the glass 3D actions carousel.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.onMenu,
    required this.glassMode,
    required this.onGlassToggle,
  });

  final VoidCallback onMenu;
  final bool glassMode;
  final VoidCallback onGlassToggle;

  void _openActions(BuildContext context) {
    showHeaderActionsSheet(
      context,
      glassMode: glassMode,
      onGlassToggle: onGlassToggle,
      onNotifications: () => showNotificationsSheet(context),
      onFashionHome: () => Settings.instance.setFashionHome(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Row(
      children: [
        _HamburgerButton(onTap: onMenu),
        const SizedBox(width: 12),
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
        _HeaderButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WidgetsPage()),
          ),
        ),
        const SizedBox(width: 8),
        _HeaderActionsSvgButton(onTap: () => _openActions(context)),
      ],
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: glass ? const Color(0xBFFFFFFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: glass ? Border.all(color: const Color(0xDFFFFFFF)) : null,
          boxShadow: glass ? null : NwsbShadows.raisedSm,
        ),
        child: const Icon(Icons.menu_rounded, size: 25, color: NwsbColors.ink),
      ),
    );
  }
}

class _NormalHomeMenu extends StatelessWidget {
  const _NormalHomeMenu({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = <(String, IconData, int)>[
      ('Home', Icons.home_outlined, 0),
      ('Practice', Icons.record_voice_over_outlined, 1),
      ('Library', Icons.menu_book_outlined, 2),
      ('Store', Icons.storefront_outlined, 3),
      ('Profile', Icons.person_outline, 4),
    ];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: NwsbShadows.raised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: NwsbColors.surfaceDim,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            for (final (label, icon, tab) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: NwsbColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(tab),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(icon, color: NwsbColors.ink, size: 22),
                          const SizedBox(width: 14),
                          Text(label,
                              style: const TextStyle(
                                  color: NwsbColors.ink,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              color: NwsbColors.inkSoft),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
