/// The bottom nav — #ig-bottomnav. Five destinations, the active one gold.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/hero_glass.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tokens.dart';
import 'shell_back.dart';
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
import '../screens/quotes_live.dart';
import '../screens/splash.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/store.dart';
import '../screens/quick_access.dart';
import '../screens/app_settings.dart';
import '../screens/store/cart_pages.dart';
import '../screens/store/meaning_store.dart';
import '../features/notifications/inbox_screen.dart';
import '../features/notifications/notif_router.dart';
import '../widgets/pool_hud.dart';
import '../widgets/mini_player_pill.dart';
import '../widgets/nwsb_icon.dart';
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

/// How much of the bottom of a tab the floating nav bar (and the mode pill /
/// mini player row above it) covers, safe area included. A tab's main scroll
/// view ends with [NavClearanceSpacer] so its last item (the footer) can be
/// scrolled fully above the nav. Zero on pages pushed above the shell.
class NavClearance extends InheritedWidget {
  const NavClearance({super.key, required this.height, required super.child});

  final double height;

  /// Nav bar: 14 from the bottom + 58 tall, plus 12 breathing room.
  static const double navOnly = 14 + 58 + 12;

  /// Nav bar plus the Normal/Fashion pill or mini-player row (bottom 88, ~40 tall).
  static const double navAndPill = 88 + 40 + 8;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavClearance>()?.height ?? 0;

  @override
  bool updateShouldNotify(NavClearance old) => old.height != height;
}

/// Empty space at the end of a tab's scroll view, as tall as [NavClearance].
class NavClearanceSpacer extends StatelessWidget {
  const NavClearanceSpacer({super.key, this.extra = 0});
  final double extra;
  @override
  Widget build(BuildContext context) =>
      SizedBox(key: const ValueKey('nav-clearance'), height: NavClearance.of(context) + extra);
}

class _NavShellState extends State<NavShell> {
  int _i = Settings.instance.lastTab;

  /// `welcome`, or a tab index as text, while a one-time guide is up.
  String? _coach;
  var _dayLock = false;

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
    NotifRouter.instance.attach(context, goTab: _goToTab, popToRoot: _popShellOverlays);
    if (SplashGate.done.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_openDay()));
    } else {
      SplashGate.done.addListener(_onSplashDone);
    }
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
        builder: (_) => PracticePlayerScreen(words: [w!], title: 'Word of the day', showIntro: false),
      ));
    } else if (what == 'streak') {
      _popShellOverlays();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeProgressScreen(words: ContentStore.instance.library),
      ));
    }
  }

  @override
  void dispose() {
    SplashGate.done.removeListener(_onSplashDone);
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

  void _onSplashDone() {
    if (!SplashGate.done.value) return;
    SplashGate.done.removeListener(_onSplashDone);
    unawaited(_openDay());
  }

  Future<void> _openDay() async {
    if (_dayLock || !mounted) return;
    _dayLock = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      await showDailyQuoteIfNeeded(context);
    } finally {
      _dayLock = false;
      DailyQuoteGate.done.value = true;
    }
  }

  Future<void> _offerGuide() async {
    if (!mounted || _coach != null) return;
    final prefs = await SharedPreferences.getInstance();
    final welcome = prefs.getBool('nwsb_guide_welcome_v1') ?? false;
    if (!mounted) return;
    if (!welcome) {
      setState(() => _coach = 'welcome');
      return;
    }
    final seen = prefs.getStringList('nwsb_tab_guide_v1') ?? const <String>[];
    final id = '$_i';
    if (seen.contains(id)) return;
    setState(() => _coach = id);
  }

  Future<void> _dismissCoach() async {
    final id = _coach;
    if (id == null || !mounted) return;
    setState(() => _coach = null);
    final prefs = await SharedPreferences.getInstance();
    if (id == 'welcome') {
      await prefs.setBool('nwsb_guide_welcome_v1', true);
    } else {
      final seen = List<String>.from(prefs.getStringList('nwsb_tab_guide_v1') ?? const <String>[]);
      if (!seen.contains(id)) {
        seen.add(id);
        await prefs.setStringList('nwsb_tab_guide_v1', seen);
      }
    }
    if (!mounted) return;
    await _offerGuide();
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
    // Same glass as the hero header (HeroGlass). Ink on the light Normal
    // home, white over the Fashion film.
    final ink = _fashion ? Colors.white : NwsbColors.ink;
    return GestureDetector(
      key: const ValueKey('home-mode-pill'),
      onTap: () => Settings.instance.setFashionHome(!_fashion),
      child: HeroGlass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _fashion ? Icons.light_mode : Icons.dark_mode,
              size: 14,
              color: ink,
            ),
            const SizedBox(width: 6),
            Text(
              _fashion ? 'Normal home' : 'Fashion home',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ink,
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
    setState(() {
      _i = tab;
      if (_coach != null && _coach != 'welcome') _coach = null;
    });
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
    if (id == 'progress') {
      // Progress is NOT a tab root — push the dedicated screen only.
      _popShellOverlays();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PracticeProgressScreen(words: ContentStore.instance.library),
      ));
      return;
    }
    // Shortcuts with their own page open it; the rest keep opening Quick
    // access (the customiser) as before.
    final Widget? page = switch (id) {
      'journal' => const InboxScreen(),
      'cart' => const CartPage(),
      'wishlist' => const WishlistPage(),
      'settings' => const AppSettingsScreen(),
      'meaningstore' => const MeaningStoreScreen(),
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
    final pill = index == 0 || PlaybackSession.instance.showPill;
    final clearance = (pill ? NavClearance.navAndPill : NavClearance.navOnly) +
        MediaQuery.viewPaddingOf(context).bottom;
    return TickerMode(
      enabled: on,
      child: Offstage(
        offstage: !on,
        child: NavClearance(height: clearance, child: child),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NavScope._global = _goToTab;
    NavScope._shellRoute = ModalRoute.of(context);
  }

  DateTime? _backAt;

  /// Android back on the shell itself (no page pushed on top): a non-Home
  /// tab goes to Home; on Home, the first press warns and a second press
  /// within 2 s exits. Before this the shell had no back handling at all,
  /// so the root route popped and Android closed the app from any tab.
  void _onShellBack() {
    if (ShellBack.handle()) return; // an in-page guide closes first
    if (_coach != null) {
      unawaited(_dismissCoach()); // back closes the tab guide first
      return;
    }
    if (_i != 0) {
      _goToTab(0);
      return;
    }
    final now = DateTime.now();
    if (_backAt != null && now.difference(_backAt!) < const Duration(seconds: 2)) {
      _backAt = null;
      SystemNavigator.pop();
      return;
    }
    _backAt = now;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(const SnackBar(
      key: ValueKey('press-back-again'),
      content: Text('Press back again to exit'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onShellBack();
      },
      child: NavScope(
        go: _goToTab,
        child: _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
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
            IndexedStack(
              index: _i,
              children: [
                // Offstage + TickerMode: inactive IndexedStack tabs still layout,
                // so without this their NwsbVideos keep claiming VideoPool seats
                // and the visible tab (and player overlays) starve — "playing 1".
                _tabAlive(
                    0, _fashion ? const HomeFashion() : const HomeNormal()),
                _tabAlive(1, const PracticeScreen()),
                // Bottom-nav Library must be the media-rich Sound Library (website
                // SLM), NOT the old plain letter list in library.dart.
                _tabAlive(2, const SoundLibraryScreen(embedded: true)),
                _tabAlive(3, const StoreScreen()),
                // Tab 4 is always account Profile — never PracticeProgressScreen.
                _tabAlive(4, const ProfileScreen()),
              ],
            ),
            // Fashion-home switch + mini player share one row above the nav.
            if (_i == 0 || PlaybackSession.instance.showPill)
              Positioned(
                // Inset mode pill from screen/card edge (Normal/Fashion toggle).
                left: 20,
                right: 20,
                bottom: 88,
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
                        final found = slots.indexWhere((s) => _primaryTab(s) == 0);
                        final homeSlot = found >= 0 ? found : 0;
                        return Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Row(children: [
                            for (var i = 0; i < slots.length; i++) ...[
                              if (i > 0)
                                Container(
                                  width: 1,
                                  height: 18,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  color: const Color(0x33FFFFFF),
                                ),
                              Expanded(
                                child: _NavSlot(
                                  active: _primaryTab(slots[i]) == _i,
                                  asHome: _i != 0 && i == homeSlot,
                                  image: _navFeatures[slots[i]]?['img'] ?? '',
                                  label: _navFeatures[slots[i]]?['label'] ?? slots[i],
                                  onTap: () => _i != 0 && i == homeSlot
                                      ? _goToTab(0)
                                      : _goToSlot(slots[i]),
                                ),
                              ),
                            ],
                          ]),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            if (_coach != null)
              Positioned.fill(
                child: _RoomGuide(
                  coach: _coach!,
                  tab: _i,
                  onDone: () => unawaited(_dismissCoach()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.active,
    required this.asHome,
    required this.image,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final bool asHome;
  final String image;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? NwsbColors.goldLight : const Color(0x99FFFFFF);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (asHome)
            const NwsbIcon(NwsbMarks.house, size: 26, color: Color(0xF2FFFFFF), strokeWidth: 1.9)
          else if (image.startsWith('asset:'))
            EditableImage.asset(
              image.substring(6),
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: 22, color: color),
              slot: 'nav_shell.NavShell',
            )
          else
            Image.network(
              image,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: 22, color: color),
            ),
          const SizedBox(height: 3),
          Text(
            asHome ? 'Home' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomGuide extends StatelessWidget {
  const _RoomGuide({required this.coach, required this.tab, required this.onDone});

  final String coach;
  final int tab;
  final VoidCallback onDone;

  static const _rooms = <(String, String)>[
    ('Home', 'This is the day. The session sits up here. The other rooms are on the bar.'),
    ('Practice', 'These are today\'s words. Tap one and the player opens on it.'),
    ('Library', 'Everything you can hear. The chips filter it. Now playing is the card under them.'),
    ('Store', 'Ebooks, words, and plans. The black card under each film is the way in.'),
    ('Profile', 'Streak, account, and settings. The gear on this page opens the rest.'),
  ];

  @override
  Widget build(BuildContext context) {
    final welcome = coach == 'welcome';
    final room = _rooms[tab.clamp(0, _rooms.length - 1)];
    final title = welcome ? 'Five rooms' : room.$1;
    final body = welcome
        ? 'Home, Practice, Library, Store, and Profile. Each one gets a short mark the first time you open it.'
        : room.$2;
    final x = ((tab.clamp(0, 4) + 0.5) / 5) * 2 - 1;
    return Material(
      color: const Color(0x66000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: onDone, behavior: HitTestBehavior.opaque),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 84),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xF0141418),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0x33E8D5A3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GUIDE',
                              style: TextStyle(
                                color: Color(0xFFE8D5A3),
                                fontSize: 11,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: onDone,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8D5A3),
                                  foregroundColor: const Color(0xFF14110A),
                                  minimumSize: const Size(96, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(x, 0),
                      child: CustomPaint(
                        size: const Size(16, 9),
                        painter: const _GuideTail(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTail extends CustomPainter {
  const _GuideTail();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xF0141418));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
