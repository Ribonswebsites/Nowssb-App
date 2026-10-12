/// The bottom nav — #ig-bottomnav. Five destinations, the active one gold.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../data/settings.dart';
import '../data/content.dart';
import '../data/home_widget_sync.dart';
import '../data/models.dart';
import '../screens/home_fashion.dart';
import '../screens/home_normal.dart';
import '../screens/sound_library.dart';
import '../screens/practice.dart';
import '../screens/practice_player.dart';
import '../screens/profile.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/store.dart';
import '../screens/quick_access.dart';
import '../screens/app_settings.dart';
import '../screens/store/cart_pages.dart';
import '../screens/store/meaning_store.dart';
import '../screens/shared_sections.dart';
import '../screens/fashion/header.dart';
import '../screens/personal_coach.dart';
import '../screens/features_page.dart';
import '../features/notifications/inbox_screen.dart';
import '../features/notifications/notif_router.dart';
import '../widgets/pool_hud.dart';
import '../widgets/mini_player_pill.dart';
import '../widgets/tablet_section_rail.dart';
import '../data/phone_notifications.dart';
import '../data/playback_session.dart';
import '../admin/template/editable.dart';
import '../features/economy/reward_fx.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

/// Lets any screen move the shell to another destination without knowing how
/// the shell is built. The home's sections use it: pressing "Enter the Store"
/// goes to the Store tab rather than nowhere.
class NavScope extends InheritedWidget {
  const NavScope({super.key, required this.go, required super.child});

  /// 0 Connect · 1 Practice · 2 Library · 3 Store · 4 Profile
  final void Function(int) go;

  /// Switch the bottom-nav tab from anywhere — including pages pushed on
  /// the root navigator (Progress, Settings → Profile, Library, Routines,
  /// admin preview), where there is no NavScope above: pop back to the
  /// shell first, then switch.
  static void goTo(BuildContext context, int i) {
    final local = context.getInheritedWidgetOfExactType<NavScope>();
    if (local != null) {
      local.go(i);
      return;
    }
    final go = _global;
    if (go == null) return;
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    final route = _shellRoute;
    if (nav != null) nav.popUntil((r) => r == route || r.isFirst);
    go(i);
  }

  static void Function(int)? _global;
  static Route<dynamic>? _shellRoute;

  @override
  bool updateShouldNotify(NavScope old) => false;
}

class _NavShellState extends State<NavShell> {
  int _i = Settings.instance.lastTab;

  /// Which home. The website keeps both in the DOM and switches a class;
  /// here it is two different screens rather than two skins — see
  /// lib/screens/home_fashion.dart. The answer is remembered between
  /// launches, and Settings is the other place it can be changed, so this
  /// reads the setting rather than keeping a copy that could disagree.
  bool get _fashion => Settings.instance.fashionHome;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
    PlaybackSession.instance.addListener(_onSettings);
    NotificationBanner.setOnHome(_i == 0);
    unawaited(PlaybackSession.instance.ensureLoaded());
    // Home-screen widget taps (Android): nowssb://widget/practice?word=…
    _widgetTaps = HomeWidgetSync.instance.clicks.listen(_onWidgetTap);
    // Daily 'open the app' activity (server caps it at once a day).
    reportEarn('open');
    NotifRouter.instance
        .attach(context, goTab: _goToTab, popToRoot: _popShellOverlays);
  }

  StreamSubscription<Uri>? _widgetTaps;

  void _onWidgetTap(Uri uri) {
    if (!mounted || uri.host != 'widget') return;
    final what = uri.pathSegments.isEmpty ? 'home' : uri.pathSegments.first;
    if (what == 'practice') {
      final name = (uri.queryParameters['word'] ?? '').toLowerCase();
      final lib = ContentStore.instance.library;
      Word? w;
      for (final x in lib) {
        if (x.word.toLowerCase() == name) {
          w = x;
          break;
        }
      }
      w ??= HomeWidgetSync.wordFor(DateTime.now(), lib);
      if (w == null) return;
      _popShellOverlays();
      reportEarn('word_of_day');
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticePlayerScreen(
            words: [w!], title: 'Word of the day', showIntro: false),
      ));
    } else if (what == 'streak') {
      _popShellOverlays();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PracticeProgressScreen(words: ContentStore.instance.library),
      ));
    }
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    PlaybackSession.instance.removeListener(_onSettings);
    unawaited(_widgetTaps?.cancel());
    if (NavScope._global == _goToTab) {
      NavScope._global = null;
      NavScope._shellRoute = null;
    }
    NotifRouter.instance.detach(context);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _openMiniPlayer() {
    final session = PlaybackSession.instance;
    if (!session.active || session.words.isEmpty) return;
    session.expand();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePlayerScreen(
          words: session.words,
          title: session.title.isEmpty ? 'NowssB' : session.title,
          showIntro: false,
        ),
      ),
    );
  }

  Widget _fashionHomeChip() {
    return GestureDetector(
      onTap: () => Settings.instance.setFashionHome(!_fashion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _fashion ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _fashion ? Icons.light_mode : Icons.dark_mode,
              size: 14,
              color: _fashion ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              _fashion ? 'Normal home' : 'Fashion home',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _fashion ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Progress (and other sub-screens) are pushed on the shell navigator, so
  /// they cover every tab. Without popping them, tapping Profile after opening
  /// Progress still shows My Progress / orb / YOUR NUMBERS — the two feel like
  /// the same screen. Always clear overlays when selecting a primary tab
  /// (including re-tapping the current one).
  void _popShellOverlays() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  void _goToTab(int tab) {
    _popShellOverlays();
    NotificationBanner.setOnHome(tab == 0);
    if (tab == _i) return;
    Settings.instance.fadeBackgroundForNavigation();
    setState(() => _i = tab);
    Settings.instance.setLastTab(tab);
  }

  static const _navFeatures = <String, Map<String, String>>{
    'connect': {
      'label': 'Connect',
      'img':
          'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png'
    },
    'practice': {
      'label': 'Practice',
      'img':
          'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png'
    },
    'library': {
      'label': 'Library',
      'img':
          'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png'
    },
    'store': {
      'label': 'Store',
      'img':
          'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'
    },
    'profile': {
      'label': 'Profile',
      'img':
          'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png'
    },
    'progress': {
      'label': 'Progress',
      'img':
          'https://media.nowssb.com/migrated-images/0480c10b8a8d79dd_file_00000000ae607208aa51504989648920_ml2czc.png'
    },
    'wordscience': {
      'label': 'Word Sci',
      'img':
          'https://media.nowssb.com/migrated-images/dd44cf9fc35b783c_file_0000000086d872089ce376674620d5f3_mtfftb.png'
    },
    'meaningstore': {
      'label': 'Meaning',
      'img':
          'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png'
    },
    'search': {
      'label': 'Search',
      'img':
          'https://media.nowssb.com/migrated-images/8d85320f63c3e176_file_00000000029c7208b5e915d9af2c480c_tuccwo.png'
    },
    'cart': {
      'label': 'Cart',
      'img':
          'https://media.nowssb.com/migrated-images/311c26afee2bc52c_file_00000000f02c72088cd128f3f4b08af5_vskoom.png'
    },
    'wishlist': {
      'label': 'Wishlist',
      'img':
          'https://media.nowssb.com/migrated-images/a74a9935fb237eb8_file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png'
    },
    'routines': {
      'label': 'Routines',
      'img':
          'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png'
    },
    'chat': {
      'label': 'Chat',
      'img':
          'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png'
    },
    'ai': {
      'label': 'AI Rx',
      'img':
          'https://media.nowssb.com/migrated-images/41c9ed21b2822c90_file_0000000062a882089abd27eb90ea3945_ngqyu6.png'
    },
    'streak': {
      'label': 'Streak',
      'img':
          'https://media.nowssb.com/migrated-images/f82047a0e727766b_file_0000000010fc820891f9e15a38316d2b_ffffhq.png'
    },
    'journal': {'label': 'Journal', 'img': 'asset:assets/icons/qa-journal.png'},
    'settings': {
      'label': 'Settings',
      'img':
          'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png'
    },
    'everything': {
      'label': 'Everything',
      'img':
          'https://media.nowssb.com/migrated-images/47f9e2c9fad5a78f_file_00000000be547207aaa56f43cfef4f67_nxhvw0.png'
    },
  };
  int? _primaryTab(String id) => const {
        'connect': 0,
        'practice': 1,
        'library': 2,
        'store': 3,
        'profile': 4
      }[id];
  void _goToSlot(String id) {
    final tab = _primaryTab(id);
    if (tab != null) {
      // Profile / Connect / Practice / Library / Store — never Progress.
      _goToTab(tab);
      return;
    }
    if (id == 'progress' || id == 'streak') {
      // Progress / Streak are NOT tab roots — push the dedicated screen only.
      _popShellOverlays();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PracticeProgressScreen(words: ContentStore.instance.library),
      ));
      return;
    }
    // Shortcuts with their own page open it. "Everything" stays the Quick
    // access customiser. Journal stays the Activity inbox (no journal page).
    if (id == 'search') {
      _popShellOverlays();
      unawaited(showDestinationSearchSheet(context));
      return;
    }
    final Widget? page = switch (id) {
      'journal' => const InboxScreen(),
      'cart' => const CartPage(),
      'wishlist' => const WishlistPage(),
      'settings' => const AppSettingsScreen(),
      'meaningstore' => const MeaningStoreScreen(),
      'wordscience' => const AboutNowssbScreen(science: true),
      'routines' => const _NavRoutinesPage(),
      'chat' || 'ai' => const PersonalCoachScreen(),
      'everything' => const QuickAccessScreen(),
      _ => null,
    };
    _popShellOverlays();
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page ?? const QuickAccessScreen()));
  }

  /// Keep inactive tabs mounted (IndexedStack) but off-stage so their videos
  /// do not claim VideoPool decoders. NwsbVideo already respects Offstage.
  Widget _tabAlive(int index, Widget child) {
    final on = _i == index;
    return TickerMode(
      enabled: on,
      child: Offstage(
        offstage: !on,
        child: child,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NavScope._global = _goToTab;
    NavScope._shellRoute = ModalRoute.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return NavScope(
      go: _goToTab,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    if (nwsbTablet(context)) return _buildTablet(context);
    final lightHome = _i == 0 && !_fashion;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: lightHome ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            lightHome ? NwsbColors.surface : NwsbColors.deep,
        systemNavigationBarIconBrightness:
            lightHome ? Brightness.dark : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        // Match the visible tab so the home-indicator strip is never a black
        // chin on Normal home, and never a white line on dark tabs.
        backgroundColor: lightHome ? NwsbColors.surface : NwsbColors.deep,
        body: Stack(
          children: [
            // IndexedStack rather than swapping the child: it keeps each tab's
            // scroll position and state alive, which is what the website does
            // (its screens are all in the DOM at once, one of them .active).
            _tabs(),
            // Fashion-home switch + mini player share one row above the nav.
            if (_i == 0 || PlaybackSession.instance.showPill)
              Positioned(
                // Inset mode pill from screen/card edge (Normal/Fashion toggle).
                left: 20,
                right: 20,
                bottom: 112,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (_i == 0) _fashionHomeChip(),
                      if (_i == 0 && PlaybackSession.instance.showPill) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 22,
                          color: const Color(0x66FFFFFF),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (PlaybackSession.instance.showPill)
                        Expanded(
                          child: MiniPlayerPill(onOpen: _openMiniPlayer),
                        ),
                    ],
                  ),
                ),
              ),

            // Debug only, and compiled out of a release build: the decoder
            // count, live, so the ceiling is something you can watch rather
            // than something you have to take on trust.
            const Positioned(
                top: 4, right: 8, child: SafeArea(child: PoolHud())),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Builder(builder: (context) {
                        final settings = Settings.instance;
                        final radius = settings.navShape == 'pill'
                            ? 40.0
                            : settings.navShape == 'rect'
                                ? (settings.navCorner == 'rounded' ? 20.0 : 2.0)
                                : 33.0;
                        final background = settings.navColor == 'black'
                            ? const Color(0xF5000000)
                            : const Color(0xF5182033);
                        final slots = settings.navSlots;
                        // BD-8: Nykaa-style raised centre button. The middle
                        // slot (same destination, same order) sticks up above
                        // the bar as a calm black circle (brief B).
                        final centre =
                            slots.length.isOdd ? slots.length ~/ 2 : -1;
                        Widget navIcon(String slot, double iconSize) =>
                            (_navFeatures[slot]?['img'] ?? '')
                                    .startsWith('asset:')
                                ? EditableImage.asset(
                                    (_navFeatures[slot]?['img'] ?? '')
                                        .substring(6),
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.circle_outlined,
                                      size: 22,
                                      color: slot == 'connect' ||
                                              _primaryTab(slot) == _i
                                          ? NwsbColors.goldLight
                                          : const Color(0x99FFFFFF),
                                    ),
                                    slot: 'nav_shell.NavShell',
                                  )
                                : Image.network(
                                    _navFeatures[slot]?['img'] ?? '',
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.circle_outlined,
                                      size: 22,
                                      color: slot == 'connect' ||
                                              _primaryTab(slot) == _i
                                          ? NwsbColors.goldLight
                                          : const Color(0x99FFFFFF),
                                    ),
                                  );
                        final bar = Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Row(children: [
                            for (var i = 0; i < slots.length; i++) ...[
                              if (i > 0 && i != centre && i != centre + 1)
                                Container(
                                  width: 1,
                                  height: 18,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  color: const Color(0x33FFFFFF),
                                ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _goToSlot(slots[i]),
                                  child: Column(
                                    mainAxisAlignment: i == centre
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.center,
                                    children: [
                                      if (i != centre) navIcon(slots[i], 28),
                                      if (i != centre)
                                        const SizedBox(height: 3),
                                      Text(
                                        _navFeatures[slots[i]]?['label'] ??
                                            slots[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textScaler: TextScaler.linear(
                                            MediaQuery.textScalerOf(context)
                                                .scale(1)
                                                .clamp(1.0, 1.3)),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight:
                                              _primaryTab(slots[i]) == _i
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                          color: _primaryTab(slots[i]) == _i
                                              ? NwsbColors.goldLight
                                              : const Color(0x99FFFFFF),
                                        ),
                                      ),
                                      if (i == centre)
                                        const SizedBox(height: 7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        );
                        if (centre < 0) return bar;
                        final active = _primaryTab(slots[centre]) == _i;
                        return SizedBox(
                          height: 58 + 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                  left: 0, right: 0, bottom: 0, child: bar),
                              Positioned(
                                top: 0,
                                child: GestureDetector(
                                  key: const ValueKey('nav-raised-centre'),
                                  onTap: () => _goToSlot(slots[centre]),
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0B0C0F),
                                      border: Border.all(
                                          color: active
                                              ? NwsbColors.goldLight
                                              : const Color(0x33FFFFFF),
                                          width: 1.2),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x80000000),
                                            blurRadius: 14,
                                            offset: Offset(0, 6)),
                                      ],
                                    ),
                                    child: navIcon(slots[centre], 30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  /// IndexedStack rather than swapping the child: it keeps each tab's
  /// scroll position and state alive. Inactive tabs stay off-stage so their
  /// videos do not claim VideoPool seats.
  Widget _tabs() {
    return IndexedStack(
      index: _i,
      children: [
        _tabAlive(0, _fashion ? const HomeFashion() : const HomeNormal()),
        _tabAlive(1, const PracticeScreen()),
        _tabAlive(2, const SoundLibraryScreen(embedded: true)),
        _tabAlive(3, const StoreScreen()),
        _tabAlive(4, const ProfileScreen()),
      ],
    );
  }

  Widget _buildTablet(BuildContext context) {
    final lightHome = _i == 0 && !_fashion;
    final rail = lightHome ? NwsbColors.surface : const Color(0xFF07090E);
    final ink = lightHome ? const Color(0xFF16181E) : Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: lightHome ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: rail,
        systemNavigationBarIconBrightness:
            lightHome ? Brightness.dark : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: lightHome ? NwsbColors.surface : NwsbColors.deep,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TabletRail(
              light: lightHome,
              background: rail,
              ink: ink,
              index: _i,
              fashion: _fashion,
              homeTab: _i == 0,
              slots: Settings.instance.navSlots,
              features: _navFeatures,
              showPlayer: PlaybackSession.instance.showPill,
              primaryTab: _primaryTab,
              onSlot: _goToSlot,
              onToggleHome: () => Settings.instance.setFashionHome(!_fashion),
              onOpenPlayer: _openMiniPlayer,
            ),
            Expanded(
              child: Stack(
                children: [
                  _tabs(),
                  const Positioned(
                    top: 4,
                    right: 8,
                    child: SafeArea(child: PoolHud()),
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

/// Side navigation for a tablet. The phone keeps the bottom bar.
class _TabletRail extends StatelessWidget {
  const _TabletRail({
    required this.light,
    required this.background,
    required this.ink,
    required this.index,
    required this.fashion,
    required this.homeTab,
    required this.slots,
    required this.features,
    required this.showPlayer,
    required this.primaryTab,
    required this.onSlot,
    required this.onToggleHome,
    required this.onOpenPlayer,
  });

  final bool light;
  final Color background;
  final Color ink;
  final int index;
  final bool fashion;
  final bool homeTab;
  final List<String> slots;
  final Map<String, Map<String, String>> features;
  final bool showPlayer;
  final int? Function(String id) primaryTab;
  final void Function(String id) onSlot;
  final VoidCallback onToggleHome;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final line = light ? const Color(0x14000000) : const Color(0x22FFFFFF);
    return Container(
      width: 84,
      decoration: BoxDecoration(
        color: background,
        border: Border(right: BorderSide(color: line)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'N',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ink,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 28, height: 1, color: line),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final id in slots) _item(id),
                ],
              ),
            ),
            if (homeTab)
              _iconButton(
                icon: fashion ? Icons.light_mode : Icons.dark_mode,
                label: fashion ? 'Normal' : 'Fashion',
                onTap: onToggleHome,
              ),
            if (showPlayer)
              _iconButton(
                icon: Icons.play_arrow_rounded,
                label: 'Playing',
                onTap: onOpenPlayer,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(String id) {
    final active = primaryTab(id) == index;
    final label = features[id]?['label'] ?? id;
    final img = features[id]?['img'] ?? '';
    final tile = active
        ? (light ? const Color(0xFF16181E) : Colors.white)
        : Colors.transparent;
    final fg = active ? (light ? Colors.white : const Color(0xFF16181E)) : ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSlot(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _mark(img, fg),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mark(String img, Color fallback) {
    if (img.startsWith('asset:')) {
      return EditableImage.asset(
        img.substring(6),
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.circle_outlined, size: 22, color: fallback),
        slot: 'nav_shell.TabletRail',
      );
    }
    if (img.isEmpty) {
      return Icon(Icons.circle_outlined, size: 22, color: fallback);
    }
    return Image.network(
      img,
      width: 26,
      height: 26,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.circle_outlined, size: 22, color: fallback),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600, color: ink)),
          ],
        ),
      ),
    );
  }
}

/// Bottom-nav Routines slot — same destinations as the drawer Routines page.
class _NavRoutinesPage extends StatelessWidget {
  const _NavRoutinesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060C18),
        foregroundColor: Colors.white,
        title: const Text('My Routines'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          RoutinesSection(
            fashion: true,
            onTap: () {
              Navigator.of(context).pop();
              NavScope.goTo(context, 1);
            },
          ),
        ],
      ),
    );
  }
}
