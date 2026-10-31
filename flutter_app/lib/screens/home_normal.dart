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
import '../widgets/black_glass_banner.dart';
import '../widgets/four_banners.dart';
import '../widgets/meditation_flip_banner.dart';
import 'normal/calm_v3.dart';
import 'normal/home_v4.dart';
import 'normal/home_v5.dart';
import '../widgets/concept/normal/fashion_plus_entry_live.dart';
import '../widgets/concept/normal/footer.dart';
import '../features/programs/partner_program.dart';
import '../features/programs/reference_program.dart';
import '../features/vault/vault_screen.dart';
import 'nwsb_sign_in_sheet.dart';
import 'word_detail.dart';
import '../widgets/program_shelf.dart';
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
import '../widgets/buddha_gyro_stage.dart';
import '../widgets/stories_find_you_banner.dart';
import '../widgets/earth_day_film.dart';
import '../widgets/promo_color_grid.dart';
import 'quotes_live.dart';
import '../features/earn/earn_home_sections.dart';
import '../widgets/sections/category_tiles_section.dart';
import '../widgets/sections/spotlight_section.dart';
import '../features/earn/earn_hub_screen.dart';
import 'app_settings.dart';
import 'player_settings.dart';
import 'practice_player.dart';
import 'progress/progress_screen.dart';
import 'reader/reader_hub.dart';
import 'subscription.dart';
import 'store/cart_pages.dart';
import 'store/ebooks_store.dart';
import 'store/meaning_store.dart';
import 'features_page.dart';
import '../shell/nwsb_links.dart';
import '../widgets/home_keep_alive.dart';
import '../admin/layout/layout_sections.dart';
import '../admin/template/editable.dart';
import 'poster/poster_pages.dart' show TrendingScreen;

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
  // MK-6 home mix (ref 5): category tiles + spotlight, high on the page.
  'catTiles',
  'spotlight',
  'tiles',
  'storiesFind',
  'buddhaGyro',
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
const kNormalNoMarkup = <String>{'custom', 'rx', 'wsearch', 'msearch'};

/// The two `defOff` entries that DO have markup. Built, not placed.
const kNormalDefOff = <String>{'routines'};

/// Plain-words names for the UI Editor.
const kNormalSectionTitles = <String, String>{
  'greet': 'Quote & greeting',
  'search': 'Search bar',
  'heroCurve': 'Hero curve',
  'promoRail': 'Promo rail',
  'dashboard': 'Practice dashboard',
  'essentials': 'Split banner & essentials',
  'routineCards': 'Routine cards, Earth Day film & colour grid',
  'herovid': 'Streak & store videos',
  'streak': 'Streak',
  'practice': 'Practice card',
  'mainops': 'Main options',
  'actionbar': 'Support & coach bar',
  'catTiles': 'Category tiles & filters',
  'spotlight': 'In the spotlight',
  'tiles': 'Feature tiles',
  'storiesFind': 'Stories find you',
  'buddhaGyro': 'Buddha quotes stage',
  'store': 'Offer, earn, rewards & gifts',
  'reader': 'Reader',
  'trendwd': 'Trending words',
  'routines': 'Routines (off by default)',
  'condisc': 'Connect disc',
  'feed': 'Feed',
  'quickrow': 'Quick access row',
  'trendshop': 'Trending in the shop',
  'edition': 'Edition',
  'ebooks': 'eBooks',
  'connectban': 'Connect banner',
  'healing': 'Healing path',
  'fashsw': 'Switch to Fashion home',
  'footer': 'Footer',
};

/// Sideways carousels wired to the Animation tab's transitions and
/// auto-rotate (carouselFxItem / CarouselAutoRotate inside them).
const kNormalCarousels = <String>{'herovid', 'tiles', 'healing'};

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
    // Progress-driven sections (dashboard, streak) listen on their own;
    // the whole Home no longer rebuilds on every practice tick.
    Settings.instance.addListener(_onSettings);
    unawaited(PracticeProgress.instance.start());
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    Settings.instance.removeListener(_onSettings);
    VideoPool.instance.setGlassHomeMode(false);
    super.dispose();
  }

  Object? _lib;
  int _libLen = -1;
  void _onContent() {
    final lib = ContentStore.instance.library;
    if (identical(lib, _lib) && lib.length == _libLen) return;
    _lib = lib;
    _libLen = lib.length;
    if (mounted) setState(() {});
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _go(int tab) => NavScope.goTo(context, tab);

  void _push(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  void _openDashboardSession(List<Word> words, String title) {
    if (words.isEmpty) {
      // A new user has no routine yet: send them where words are picked
      // instead of opening an empty player.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
        content: Text('Pick a few words for your routine first.'),
      ));
      _go(1);
      return;
    }
    _push(PracticePlayerScreen(words: words, title: title));
  }

  void _openDashboardProgress() {
    // Progress (sessions, streak, coins) is shown on the Profile tab.
    _go(4);
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

  void _openGrid(String id) {
    switch (id) {
      case 'practice':
        _go(1);
      case 'library':
        _go(2);
      case 'store':
        _go(3);
      case 'reader':
        _push(const ReaderHubScreen());
      case 'healing':
        _push(const HealingPathScreen());
      case 'subscription':
        _push(const SubscriptionScreen());
      case 'player':
        _push(const PlayerSettingsScreen());
      case 'progress':
        _push(PracticeProgressScreen(words: ContentStore.instance.library));
      case 'quotes':
        _push(const QuotesWeekScreen());
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
        _push(const AboutNowssbScreen());
      case 'word-science':
        _push(const AboutNowssbScreen(science: true));
      case 'sound-library':
        _push(const SoundLibraryScreen());
      case 'meaning-store':
        _push(const MeaningStoreScreen());
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
        ('promoRail', const SizedBox.shrink()),
        (
          'dashboard',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalmToday(
                onStart: _openDashboardSession,
                onProgress: _openDashboardProgress,
              ),
            ],
          ),
        ),
        (
          'essentials',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Same look as the 'Your essentials' heading right below.
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 20, 14),
                child: EditableLabel('home_normal.TrioRail', 'Your programmes',
                    key: ValueKey('nm-trio-heading'),
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2D33))),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TrioRail(),
              ),
              const NmSuppliedEssentials(),
            ],
          ),
        ),
        // v4: everything from here to the footer is lib/screens/normal/home_v4.dart,
        // apart from the flip banners and the Buddha quote card (kept as-is).
        ('routineCards', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            V4SoundLibrary(onTap: () => _go(2)),
            V4GetStarted(onPlay: () => _go(1)),
            V4EarthDay(onTap: () => _go(1)),
            V4Doors(onOpen: _openGrid),
          ],
        )),
        ('herovid', V4Streak(onPractice: () => _go(1), onOffers: () => _go(3))),
        ('streak', const SizedBox.shrink()),
        ('practice', const SizedBox.shrink()),
        ('mainops', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeditationFlipBanner(onTap: () => _go(1), leadingIcons: true),
            MainOptionsSection(onGo: _go, onAction: _openMainOption),
          ],
        )),
        (
          'actionbar',
          V4HelpCoach(
              onSupport: () => _go(4),
              onCoach: () => _push(const PersonalCoachScreen()))
        ),
        ('catTiles', const SizedBox.shrink()),
        ('spotlight', const SizedBox.shrink()),
        ('tiles', const SizedBox.shrink()),
        ('storiesFind', const SizedBox.shrink()),
        // Exactly as at bcb6baf.
        ('buddhaGyro', BuddhaGyroStage(
          neumorphic: true,
          onOpenQuotes: () => _push(const QuotesWeekScreen()),
        )),
        ('store', V4StoreEarn(onStore: () => _go(3))),
        (
          'reader',
          // v5: Rewards + Invite only (the old v4 'NOWSSB READER' card is not in the v5 mocks)
          V5RewardsInvite(
            onOpenRewards: () => _push(const VaultScreen()),
            onSignIn: () => NwsbSignInPage.open(context),
            onInvite: () => _push(const ReferenceProgramPage()),
          ),
        ),
        ('trendwd', V5Trending(onWord: (w) => _push(WordDetail(word: w)), onLibrary: () => _go(2),
            onSeeAll: () => _push(const TrendingScreen()))),
        ('custom', null),
        ('rx', null),
        ('routines', const SizedBox.shrink()),
        ('condisc', const SizedBox.shrink()),
        ('feed', V4Community(onTap: () => NwsbLinks.connect(context))),
        (
          'quickrow',
          V5Own(
            onCart: () => NwsbLinks.cart(context),
            onWishlist: () => NwsbLinks.wishlist(context),
            onOrders: () => _push(const CartPage()), // the bag + "Your purchases", as Profile > Orders
          )
        ),
        ('trendshop', const SizedBox.shrink()),
        ('subvid', const SizedBox.shrink()),
        (
          'edition',
          V5EditionPartner(
            onJoin: (t) => _push(SubscriptionScreen(initialTier: t)),
            onPartner: () => _push(const PartnerProgramPage()),
          )
        ),
        ('ebooks', V5Ebooks(onBrowse: () => _push(const EbooksStoreScreen()))),
        ('connectban', const SizedBox.shrink()),
        (
          'healing',
          V4Healing(
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
          const NFashionPlusEntryLive(),
        ),
        ('footer', NFooter(onLink: _footerLink)),
      ];

  @override
  Widget build(BuildContext context) {
    final built = _sections();
    // These are useful development diagnostics, but neither a stale generated
    // build nor a content-section patch should take down the entire home.
    assert(() {
      final keys = built.map((e) => e.$1).toList();
      if (keys.toString() != kNormalSectionOrder.toString()) {
        debugPrint('NowssB: Normal section registry drift: $keys');
      }
      final noMarkup =
          built.where((e) => e.$2 == null).map((e) => e.$1).toSet();
      if (noMarkup.toString() != kNormalNoMarkup.toString()) {
        debugPrint('NowssB: Normal no-markup drift: $noMarkup');
      }
      return true;
    }());

    const air = {
      'promoRail',
      'storiesFind',
      'herovid',
      'store',
      'trendwd',
      'connectban',
      'edition',
      'condisc',
    };
    // Server-driven order (Admin → UI Editor). Each row is a section with a
    // stable id; the two empty rows stay as glue so the spacing is exactly
    // what it was. With no saved layout this is the bundled order, as is.
    final shown = layoutChildren(
      context,
      'home.normal',
      [
        for (final (k, w) in built)
          if (w != null && (k != 'healing' || Settings.instance.showHealing))
            if (w is SizedBox && w.width == 0 && w.height == 0)
              // Retired rows keep their key for the admin but take no room.
              KeyedSubtree(key: ValueKey('nm-$k'), child: w)
            else
              LSection(
                k,
                kNormalSectionTitles[k] ?? k,
                Padding(
                  padding: EdgeInsets.only(bottom: air.contains(k) ? 26 : 8),
                  child: KeyedSubtree(key: ValueKey('nm-$k'), child: w),
                ),
                // No server-side duplicates of a Normal section.
                copyable: false,
                carousel: kNormalCarousels.contains(k),
              ),
      ],
      hiddenByDefault: kNormalDefOff,
    );

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
          Expanded(
            child: ListView.builder(
              // Modest look-ahead: enough for smooth scroll, not enough to
              // mount every video on the home at once (N+1 decoder churn).
              cacheExtent: 480,
              // Footer paints solid black through nav clearance.
              padding: EdgeInsets.zero,
              itemCount: shown.length + 1,
              itemBuilder: (context, i) => i == shown.length
                  // Last item: room to scroll the footer clear of the nav bar.
                  ? const NavClearanceSpacer()
                  : HomeKeepAlive(child: shown[i]),
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
            child: EditableImage.asset(
              'assets/icons/logo-disc.webp',
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFA21A),
                size: 24,
              ),
              slot: 'home_normal.TopRow',
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Shrinks (never grows) on the narrowest phones so the right
        // cluster keeps its room.
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: EditableLabel('home_normal.TopRow',
              'NowssB',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
        // B022: keep the word clear of the raised button's highlight.
        const SizedBox(width: 10),
        // Right cluster: Settings | Notifications | Hamburger
        // Quick access belongs in Fashion Hero — bell returns here.
        _HeaderButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AppSettingsScreen(),
            ),
          ),
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
