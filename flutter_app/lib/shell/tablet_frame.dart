/// The tablet frame: a permanent sidebar (840+ wide) or a nav rail
/// (600 to 839) beside every page, built from the side menu's own
/// destinations and the mini player. It sits above the navigator, so it
/// stays put while pages push and pop in the centre pane.
///
/// Under 600 wide the frame is a no-op and the phone keeps its drawer and
/// bottom nav exactly as before.
///
/// The look is the restyle kit's: dark glass panes (HeroGlassRecipe), white
/// icon badges, small caps eyebrows, a white glass pane for the page you are on
/// (no gold or yellow fills).
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_haptics.dart';
import '../data/content.dart';
import '../data/firebase.dart';
import '../data/models.dart';
import '../data/playback_session.dart';
import '../data/settings.dart';
import '../data/word_art.dart';
import '../screens/practice.dart' show nwsbSlot;
import '../screens/practice_player.dart';
import '../screens/splash.dart';
import '../theme/tokens.dart';
import '../widgets/app_destinations.dart';
import '../widgets/hero_glass.dart';
import 'nav_shell.dart';
import 'tablet.dart';

export 'tablet.dart';

/// What the frame needs to know from the shell and the player.
class TabletShellGate {
  TabletShellGate._();

  /// True while the signed-in shell (NavShell) is on screen and the splash
  /// has gone. The sidebar only shows then: never over sign-in or splash.
  static final live = ValueNotifier<bool>(false);

  /// The shell's current tab (0 Home · 1 Practice · 2 Library · 3 Store ·
  /// 4 Profile), so the sidebar can mark it.
  static final tab = ValueNotifier<int>(0);

  /// The route the shell lives in.
  static Route<dynamic>? shellRoute;

  /// The open player pages, and what each one is playing, so the right
  /// panel can list the queue beside the player.
  static final player = ValueNotifier<TabletPlayerState?>(null);

  /// Tablet player: publish [route]'s queue. Called after a frame, never
  /// on a phone.
  static void publishPlayer(Route<dynamic>? route, List<Word> words, int index,
      bool playing, void Function(int index) jump, VoidCallback toggle, void Function(int dir) move,
      {bool upOpen = false}) {
    if (route == null) return;
    final cur = player.value;
    if (cur != null && cur.route == route && cur.index == index && cur.playing == playing &&
        cur.upOpen == upOpen && identical(cur.words, words)) {
      return;
    }
    player.value = TabletPlayerState(route, words, index, playing, jump, toggle, move, upOpen: upOpen);
  }

  static void dropPlayer(Route<dynamic>? route) {
    if (player.value?.route == route) player.value = null;
  }

  /// Tracks the top page (not pop-ups) so the frame knows when the right
  /// panel belongs on screen. Registered as a MaterialApp navigator observer.
  static final observer = TabletRouteObserver();
}

class TabletPlayerState {
  const TabletPlayerState(this.route, this.words, this.index, this.playing, this.jump, this.toggle, this.move,
      {this.upOpen = false});

  /// The swipe-up view is open. It has its own Up next list and now-playing
  /// card on a wide screen, so the frame drops its right column and gives the
  /// view the whole panel instead of showing the queue twice.
  final bool upOpen;
  final Route<dynamic> route;
  final List<Word> words;
  final int index;
  final bool playing;
  final void Function(int index) jump;
  final VoidCallback toggle;
  final void Function(int dir) move;
}

class TabletRouteObserver extends NavigatorObserver {
  final _pages = <Route<dynamic>>[];

  /// The top page route.
  final top = ValueNotifier<Route<dynamic>?>(null);

  void _emit() => top.value = _pages.isEmpty ? null : _pages.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _pages.add(route);
      _emit();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_pages.remove(route)) _emit();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_pages.remove(route)) _emit();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pages.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute is PageRoute) {
        _pages[i] = newRoute;
      } else {
        _pages.removeAt(i);
      }
    } else if (newRoute is PageRoute) {
      _pages.add(newRoute);
    }
    _emit();
  }
}

/// Wraps the app's navigator (MaterialApp.builder).
class TabletFrame extends StatefulWidget {
  const TabletFrame({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<TabletFrame> createState() => _TabletFrameState();
}

class _TabletFrameState extends State<TabletFrame> {
  /// Keeps the navigator's state when the frame switches between phone and
  /// tablet trees (a foldable opening, a window resize).
  final _host = GlobalKey(debugLabel: 'tablet-host');

  late final Listenable _deps = Listenable.merge([
    TabletShellGate.live,
    TabletShellGate.tab,
    TabletShellGate.player,
    TabletShellGate.observer.top,
    SplashGate.done,
  ]);

  @override
  void initState() {
    super.initState();
    _deps.addListener(_changed);
  }

  @override
  void dispose() {
    _deps.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    // The shell flips the gate from initState / dispose and the observer
    // fires mid-navigation, when the tree may be locked: rebuild on the
    // next frame then.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(() {});
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Which right panel the top page gets, if any.
  _Panel _panelFor() {
    final top = TabletShellGate.observer.top.value;
    if (top == null) return _Panel.none;
    final p = TabletShellGate.player.value;
    if (p != null && p.route == top) return p.upOpen ? _Panel.none : _Panel.player;
    if (top == TabletShellGate.shellRoute) {
      final tab = TabletShellGate.tab.value;
      if (tab == 0 || tab == 1 || tab == 2) return _Panel.home;
    }
    return _Panel.none;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final kind = tabletWidthFor(mq.size.width);
    final host = KeyedSubtree(key: _host, child: widget.child);
    if (kind == TabletWidth.phone) {
      return TabletScope(width: kind, framed: false, child: host);
    }
    final framed = TabletShellGate.live.value && SplashGate.done.value;
    if (!framed) {
      return TabletScope(width: kind, framed: false, child: host);
    }
    final w = mq.size.width;
    // Ribon's reference: sidebar about a fifth of the screen, then one big
    // rounded panel holding the page and (homes, Library, player) a right
    // column about a quarter wide.
    final side = kind == TabletWidth.wide
        ? (w * 0.2).clamp(232.0, 280.0)
        : TabletBp.railWidth;
    final panelW = (w * 0.25).clamp(TabletBp.panelWidth - 20, 340.0);
    const gap = 12.0;
    var panel = _panelFor();
    // Room for a right column: the page keeps at least 460 (a 1024 landscape
    // tablet gets one, like the reference).
    if (kind != TabletWidth.wide || w - side - gap - panelW < 460) panel = _Panel.none;
    final hasPanel = panel != _Panel.none;
    final top = mq.padding.top + gap;
    final bottom = mq.padding.bottom + gap;
    final big = w - side - gap - mq.padding.right;
    final centreW = big - (hasPanel ? panelW : 0);
    // Pages without a right column keep a reading width in the middle.
    // The swipe-up view lays out its own Up next and now-playing card side by
    // side, so it gets the whole panel.
    final pl = TabletShellGate.player.value;
    final upWide = pl != null && pl.upOpen && pl.route == TabletShellGate.observer.top.value;
    final pageW = hasPanel || upWide ? centreW : math.min(centreW, TabletBp.page);
    final inner = mq.copyWith(
      size: Size(pageW, mq.size.height - top - bottom),
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      viewInsets: mq.viewInsets.copyWith(bottom: (mq.viewInsets.bottom - bottom).clamp(0.0, double.infinity)),
    );
    const r = 28.0;
    return TabletScope(
      width: kind,
      framed: true,
      child: _FrameBackdrop(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          textDirection: TextDirection.ltr,
          children: [
            SizedBox(
              width: side,
              child: Material(
                type: MaterialType.transparency,
                child: kind == TabletWidth.wide
                    ? TabletSidebar(navigatorKey: widget.navigatorKey)
                    : TabletRail(navigatorKey: widget.navigatorKey),
              ),
            ),
            SizedBox(
              width: big,
              child: Padding(
                padding: EdgeInsets.only(top: top, bottom: bottom),
                // One big rounded glass panel: the page, then the right column.
                child: DecoratedBox(
                  key: const ValueKey('tablet-panel'),
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: HeroGlassRecipe.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF111A2E), Color(0xFF0A0F1C), Color(0xFF0C0E16)],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        textDirection: TextDirection.ltr,
                        children: [
                          SizedBox(
                            width: centreW,
                            child: Center(
                              child: SizedBox(
                                key: const ValueKey('tablet-centre'),
                                width: pageW,
                                child: MediaQuery(data: inner, child: host),
                              ),
                            ),
                          ),
                          if (hasPanel)
                            SizedBox(
                              width: panelW,
                              child: Material(
                                type: MaterialType.transparency,
                                child: panel == _Panel.player
                                    ? TabletPlayerPanel(state: TabletShellGate.player.value!)
                                    : TabletRightPanel(navigatorKey: widget.navigatorKey),
                              ),
                            ),
                        ],
                      ),
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

enum _Panel { none, home, player }

// ─────────────────────────────── actions ───────────────────────────────

/// One place in the sidebar: a tab, or a side-menu destination.
class _Item {
  const _Item(this.id, this.label, this.icon, {this.tab, this.dest});
  final String id;
  final String label;
  final IconData icon;
  final int? tab;
  final AppDest? dest;
}

const _tabs = <_Item>[
  _Item('home', 'Home', Icons.home_outlined, tab: 0),
  _Item('practice', 'Practice', Icons.self_improvement_rounded, tab: 1),
  _Item('library', 'Library', Icons.library_music_outlined, tab: 2),
  _Item('store', 'Store', Icons.shopping_bag_outlined, tab: 3),
  _Item('profile', 'Profile', Icons.person_outline_rounded, tab: 4),
];

/// The side menu's own pages (everything that is not a tab), in menu order.
List<_Item> _libraryItems() => [
      for (final d in menuDestinations)
        if (d.tab == null) _Item(d.id, d.title, d.icon, dest: d),
    ];

void _open(GlobalKey<NavigatorState> key, _Item item) {
  final nav = key.currentState;
  final ctx = nav?.overlay?.context ?? key.currentContext;
  if (nav == null || ctx == null) return;
  AppHaptics.selection();
  if (item.tab != null) {
    NavScope.goTo(ctx, item.tab!);
    return;
  }
  final d = item.dest!;
  if (d.action != null) {
    d.action!(ctx);
    return;
  }
  // Side-menu pages replace whatever side-menu page is open, so the stack
  // never grows ten pages deep from sidebar taps.
  nav.popUntil((r) => r.isFirst);
  nav.push(MaterialPageRoute<void>(builder: d.page!));
}

void _openPlayer(GlobalKey<NavigatorState> key) {
  final nav = key.currentState;
  if (nav == null) return;
  final session = PlaybackSession.instance;
  if (session.active && session.words.isNotEmpty) {
    session.expand();
    nav.push(MaterialPageRoute<void>(
      builder: (_) => PracticePlayerScreen(
        words: session.words,
        title: session.title.isEmpty ? 'NowssB' : session.title,
        showIntro: false,
      ),
    ));
    return;
  }
  final words = tabletSessionWords();
  if (words.isEmpty) return;
  nav.push(MaterialPageRoute<void>(
    builder: (_) => PracticePlayerScreen(words: words, title: _slotTitle()),
  ));
}

/// This hour's words, the same list the Practice tab leads with.
List<Word> tabletSessionWords() {
  final all = ContentStore.instance.library;
  final slot = nwsbSlot();
  final now = all.where((w) => w.time == slot || w.time == 'any').toList();
  return now.isEmpty ? all : now;
}

String _slotTitle() => switch (nwsbSlot()) {
      'morning' => 'Morning Ritual',
      'afternoon' => 'Afternoon Session',
      'evening' => 'Evening Practice',
      'night' => 'Night Restoration',
      _ => 'Practice',
    };

// ─────────────────────────────── art ───────────────────────────────

class TabletArt extends StatelessWidget {
  const TabletArt(this.path, {super.key, this.fit = BoxFit.cover});
  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget err(BuildContext _, Object __, StackTrace? ___) =>
        const ColoredBox(color: Color(0xFF141418));
    if (path.isEmpty) return const ColoredBox(color: Color(0xFF141418));
    if (path.startsWith('http')) {
      return Image.network(path, fit: fit, alignment: Alignment.topCenter, errorBuilder: err);
    }
    return Image.asset(path, fit: fit, alignment: Alignment.topCenter, errorBuilder: err);
  }
}

/// The kit's glass pane, sized for the frame.
class TabletPane extends StatelessWidget {
  const TabletPane({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 18});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: HeroGlassRecipe.blurSigma, sigmaY: HeroGlassRecipe.blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: HeroGlassRecipe.fill,
            borderRadius: r,
            border: Border.all(color: HeroGlassRecipe.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────── sidebar ───────────────────────────────

/// The frame's backdrop: NowssB deep with a faint navy wash.
class _FrameBackdrop extends StatelessWidget {
  const _FrameBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1424), NwsbColors.deep, Color(0xFF04060B)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: child,
      );
}

class _ProfileInfo extends ChangeNotifier {
  _ProfileInfo._() {
    unawaited(refresh());
  }
  static final instance = _ProfileInfo._();

  String name = 'Practitioner';
  String photo = '';

  Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('nowssb_name')?.trim() ?? '';
      final account = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '' : '';
      final n = saved.isNotEmpty ? saved : (account.isNotEmpty ? account : 'Practitioner');
      final p = prefs.getString('nwsb_local_photo') ?? '';
      if (n != name || p != photo) {
        name = n;
        photo = p;
        notifyListeners();
      }
    } catch (_) {}
  }
}

class TabletSidebar extends StatefulWidget {
  const TabletSidebar({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<TabletSidebar> createState() => _TabletSidebarState();
}

class _TabletSidebarState extends State<TabletSidebar> {
  @override
  void initState() {
    super.initState();
    TabletShellGate.tab.addListener(_refresh);
  }

  @override
  void dispose() {
    TabletShellGate.tab.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => unawaited(_ProfileInfo.instance.refresh());

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final key = widget.navigatorKey;
    return Padding(
      padding: EdgeInsets.fromLTRB(14 + pad.left, pad.top + 18, 12, pad.bottom + 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHead(onTap: () => _open(key, _tabs.last)),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              key: const ValueKey('tablet-sidebar-list'),
              padding: EdgeInsets.zero,
              children: [
                const _Eyebrow('Menu'),
                ValueListenableBuilder<int>(
                  valueListenable: TabletShellGate.tab,
                  builder: (_, tab, __) => Column(children: [
                    for (final t in _tabs)
                      _SideRow(
                        key: ValueKey('tablet-side-${t.id}'),
                        icon: t.icon,
                        label: t.label,
                        active: t.tab == tab,
                        onTap: () => _open(key, t),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
                const _Eyebrow('Library'),
                for (final t in _libraryItems().where((i) => const {'sound', 'science', 'settings'}.contains(i.id)))
                  _SideRow(
                    key: ValueKey('tablet-side-${t.id}'),
                    icon: t.icon,
                    label: t.label,
                    onTap: () => _open(key, t),
                  ),
                // Ribon has both homes: the Normal / NowssB switch stays.
                const _HomeModeSwitch(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SideMiniPlayer(navigatorKey: key),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Text(text,
            style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ProfileInfo.instance,
      builder: (context, _) {
        final info = _ProfileInfo.instance;
        final letter = info.name.isEmpty ? 'N' : info.name.characters.first.toUpperCase();
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: SizedBox(
            width: size,
            height: size,
            child: info.photo.startsWith('http')
                ? Image.network(info.photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _letter(letter))
                : _letter(letter),
          ),
        );
      },
    );
  }

  Widget _letter(String l) => ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text(l,
              style: TextStyle(color: const Color(0xFF0B0B10), fontSize: size * 0.44, fontWeight: FontWeight.w800)),
        ),
      );
}

/// Rounded-square avatar, "Hi!" and the name in bold.
class _ProfileHead extends StatelessWidget {
  const _ProfileHead({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('tablet-profile-head'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // The reference stacks them: avatar, then "Hi!", then the name.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListenableBuilder(
          listenable: _ProfileInfo.instance,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Avatar(size: 56),
              const SizedBox(height: 12),
              const Text('Hi!', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 13)),
              const SizedBox(height: 1),
              Text(_ProfileInfo.instance.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({super.key, required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: active ? Colors.white : const Color(0x99FFFFFF)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xB3FFFFFF),
                fontSize: 14,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              )),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          // The page you are on sits in a glass pane, like the reference's
          // highlighted "Explore".
          child: active ? TabletPane(radius: 14, padding: EdgeInsets.zero, child: row) : row,
        ),
      ),
    );
  }
}

/// The phone's Normal / NowssB home switch, as a row.
class _HomeModeSwitch extends StatelessWidget {
  const _HomeModeSwitch({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) {
        final zen = Settings.instance.fashionHome;
        void flip() {
          AppHaptics.selection();
          Settings.instance.setFashionHome(!zen);
        }

        if (compact) {
          return _RailButton(
            key: const ValueKey('tablet-home-mode'),
            icon: zen ? Icons.light_mode : Icons.dark_mode,
            label: zen ? 'Normal' : 'NowssB',
            onTap: flip,
          );
        }
        return _SideRow(
          key: const ValueKey('tablet-home-mode'),
          icon: zen ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          label: zen ? 'Normal home' : 'NowssB home',
          onTap: flip,
        );
      },
    );
  }
}

/// Repeat and shuffle for the now-playing card. Repeat is the playback
/// session's loop (the session repeats the word it is on, and a player opened
/// from the tablet starts with it); shuffle is the player's own saved switch.
class _Toggles extends ChangeNotifier {
  _Toggles._() {
    PlaybackSession.instance.addListener(notifyListeners);
    unawaited(_load());
  }
  static final instance = _Toggles._();

  bool shuffle = false;
  bool get repeat => PlaybackSession.instance.loop;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(kPlayerShuffleKey) ?? false;
      if (v != shuffle) {
        shuffle = v;
        notifyListeners();
      }
    } catch (_) {}
  }

  void toggleRepeat() => PlaybackSession.instance.setLoop(!repeat);

  Future<void> toggleShuffle() async {
    shuffle = !shuffle;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPlayerShuffleKey, shuffle);
  }
}

/// What the mini player and now-playing card show: the live session, or
/// this hour's words ready to start.
class _NowState {
  _NowState._(this.live, this.words, this.index, this.playing, this.title);
  factory _NowState.read() {
    final s = PlaybackSession.instance;
    final live = s.active && s.words.isNotEmpty;
    final words = live ? s.words : tabletSessionWords();
    final i = words.isEmpty ? 0 : (live ? s.index.clamp(0, words.length - 1) : 0);
    return _NowState._(live, words, i, live && s.playing, live ? (s.title.isEmpty ? 'NowssB' : s.title) : _slotTitle());
  }
  final bool live;
  final List<Word> words;
  final int index;
  final bool playing;
  final String title;
  Word? get word => words.isEmpty ? null : words[index];
}

final _nowDeps = Listenable.merge([PlaybackSession.instance, WordArt.instance, ContentStore.instance]);

/// Prev, a rounded-square play/pause, next.
class _Controls extends StatelessWidget {
  const _Controls({required this.playing, required this.onPrev, required this.onToggle, required this.onNext, this.big = false, this.tag});
  final String? tag;
  final bool playing;
  final VoidCallback onPrev;
  final VoidCallback onToggle;
  final VoidCallback onNext;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final s = big ? 52.0 : 34.0;
    final t = tag ?? (big ? 'tablet-np' : 'tablet-mini');
    Widget side(IconData i, VoidCallback f, String k) => GestureDetector(
          key: ValueKey(k),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            f();
          },
          child: Padding(
            padding: EdgeInsets.all(big ? 10 : 4),
            child: Icon(i, size: big ? 28 : 20, color: Colors.white),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      side(Icons.skip_previous_rounded, onPrev, '$t-prev'),
      SizedBox(width: big ? 10 : 2),
      GestureDetector(
        key: ValueKey('$t-toggle'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onToggle();
        },
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(s * 0.24)),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: s * 0.6, color: const Color(0xFF0B0B10)),
        ),
      ),
      SizedBox(width: big ? 10 : 2),
      side(Icons.skip_next_rounded, onNext, '$t-next'),
    ]);
  }
}

/// A waveform strip: rounded bars, the played part white, the rest dim.
class TabletWaveform extends StatelessWidget {
  const TabletWaveform({super.key, required this.seed, required this.progress, this.height = 28, this.bars = 36});
  final String seed;
  final double progress;
  final double height;
  final int bars;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WavePainter(seed, progress.clamp(0.0, 1.0), bars)),
      );
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.seed, this.progress, this.bars);
  final String seed;
  final double progress;
  final int bars;

  @override
  void paint(Canvas canvas, Size size) {
    var h = seed.hashCode & 0x7fffffff;
    final step = size.width / bars;
    final w = step * 0.55;
    final on = Paint()..color = Colors.white;
    final off = Paint()..color = const Color(0x40FFFFFF);
    for (var i = 0; i < bars; i++) {
      h = (h * 1103515245 + 12345) & 0x7fffffff;
      // A soft envelope so the strip swells in the middle like speech.
      final env = 0.35 + 0.65 * (1 - ((i / (bars - 1)) * 2 - 1).abs());
      final v = (0.25 + (h % 1000) / 1000 * 0.75) * env;
      final bh = (size.height * v).clamp(3.0, size.height);
      final x = i * step + (step - w) / 2;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - bh) / 2, w, bh), Radius.circular(w / 2));
      canvas.drawRRect(r, (i + 0.5) / bars <= progress ? on : off);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.seed != seed || old.progress != progress || old.bars != bars;
}

void _sessionPrev(GlobalKey<NavigatorState> key, _NowState n) {
  if (n.live) {
    unawaited(PlaybackSession.instance.previous());
  } else {
    _openPlayer(key);
  }
}

void _sessionNext(GlobalKey<NavigatorState> key, _NowState n) {
  if (n.live) {
    unawaited(PlaybackSession.instance.next());
  } else {
    _openPlayer(key);
  }
}

void _sessionToggle(GlobalKey<NavigatorState> key, _NowState n) {
  if (n.live) {
    unawaited(PlaybackSession.instance.togglePlay());
  } else {
    _openPlayer(key);
  }
}

/// The mini player at the foot of the sidebar: waveform strip, cover,
/// title and line, prev / pause / next.
class _SideMiniPlayer extends StatelessWidget {
  const _SideMiniPlayer({required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final key = navigatorKey;
    void onOpen() => _openPlayer(key);
    return ListenableBuilder(
      listenable: _nowDeps,
      builder: (context, _) {
        final n = _NowState.read();
        final w = n.word;
        if (w == null) return const SizedBox.shrink();
        return GestureDetector(
          key: const ValueKey('tablet-mini-player'),
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: TabletPane(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TabletWaveform(seed: w.word, progress: (n.index + 1) / n.words.length, height: 22, bars: 30),
              const SizedBox(height: 10),
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 42, height: 42, child: TabletArt(playerCoverArtFor(w, n.index))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(w.word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 1),
                      Text(n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11.5)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              _Controls(
                playing: n.playing,
                onPrev: () => _sessionPrev(key, n),
                onToggle: () => _sessionToggle(key, n),
                onNext: () => _sessionNext(key, n),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────── rail ───────────────────────────────

class TabletRail extends StatelessWidget {
  const TabletRail({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final key = navigatorKey;
    final lib = _libraryItems().where((i) => const {'sound', 'settings'}.contains(i.id));
    return Padding(
      padding: EdgeInsets.fromLTRB(6 + pad.left, pad.top + 16, 6, pad.bottom + 12),
      child: Column(children: [
        GestureDetector(
          key: const ValueKey('tablet-profile-head'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(key, _tabs.last),
          child: const _Avatar(size: 44),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            key: const ValueKey('tablet-rail-list'),
            padding: EdgeInsets.zero,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: TabletShellGate.tab,
                builder: (_, tab, __) => Column(children: [
                  for (final t in _tabs)
                    _RailButton(
                      key: ValueKey('tablet-side-${t.id}'),
                      icon: t.icon,
                      label: t.label,
                      active: t.tab == tab,
                      onTap: () => _open(key, t),
                    ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Divider(height: 1, color: Color(0x22FFFFFF)),
              ),
              for (final t in lib)
                _RailButton(
                  key: ValueKey('tablet-side-${t.id}'),
                  icon: t.icon,
                  label: t.id == 'sound' ? 'Sounds' : 'Settings',
                  onTap: () => _open(key, t),
                ),
              const _HomeModeSwitch(compact: true),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _RailMiniPlayer(onOpen: () => _openPlayer(key)),
      ]),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({super.key, required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final glyph = SizedBox(
      width: 48,
      height: 34,
      child: Icon(icon, size: 20, color: active ? Colors.white : const Color(0x99FFFFFF)),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          active ? TabletPane(radius: 12, padding: EdgeInsets.zero, child: glyph) : glyph,
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xB3FFFFFF),
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              )),
        ]),
      ),
    );
  }
}

class _RailMiniPlayer extends StatelessWidget {
  const _RailMiniPlayer({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _nowDeps,
      builder: (context, _) {
        final n = _NowState.read();
        final w = n.word;
        if (w == null) return const SizedBox.shrink();
        return GestureDetector(
          key: const ValueKey('tablet-mini-player'),
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: TabletPane(
            radius: 14,
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 52, height: 52, child: TabletArt(playerCoverArtFor(w, n.index))),
              ),
              const SizedBox(height: 5),
              Text(w.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────── right panel ───────────────────────────────

class _PanelHead extends StatelessWidget {
  const _PanelHead(this.title, {this.onMore});
  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (onMore != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMore,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('See more',
                    style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      );
}

/// The words the "Top words" list ranks: free words first (everyone can
/// play them), then the rest, in library order.
List<Word> _topWords() {
  final all = ContentStore.instance.library;
  return [...all.where((w) => w.price <= 0), ...all.where((w) => w.price > 0)];
}

/// The right column beside the homes and the Library: "Top words", then a
/// tall now-playing card (cover, title, waveform seek bar, controls).
class TabletRightPanel extends StatelessWidget {
  const TabletRightPanel({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  void _playWord(Word w) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    AppHaptics.selection();
    nav.push(MaterialPageRoute<void>(
      builder: (_) => PracticePlayerScreen(words: [w], title: w.word, showIntro: false),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final key = navigatorKey;
    return ListenableBuilder(
      listenable: _nowDeps,
      builder: (context, _) {
        final n = _NowState.read();
        final lead = n.word;
        final top = _topWords().take(3).toList();
        return LayoutBuilder(builder: (context, c) {
          return ListView(
            key: const ValueKey('tablet-right-panel'),
            padding: EdgeInsets.fromLTRB(4, pad.top + 20, 18 + pad.right, pad.bottom + 18),
            children: [
              if (top.isNotEmpty) ...[
                const _PanelHead('Top words'),
                for (var i = 0; i < top.length; i++)
                  _TopRow(
                    key: ValueKey('tablet-top-${top[i].key}'),
                    word: top[i],
                    art: playerCoverArtFor(top[i], i),
                    stat: '',
                    stats: _topStats(top[i]),
                    onTap: () => _playWord(top[i]),
                  ),
                // The reference's "See More" sits under the list.
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    key: const ValueKey('tablet-top-more'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final ctx = key.currentState?.overlay?.context;
                      if (ctx != null) NavScope.goTo(ctx, 1);
                    },
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(6, 2, 6, 4),
                      child: Text('See more',
                          style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (lead != null)
                _NowPlayingCard(
                  key: const ValueKey('tablet-now-playing'),
                  word: lead,
                  art: playerCoverArtFor(lead, n.index),
                  line: n.title,
                  index: n.index,
                  count: n.words.length,
                  playing: n.playing,
                  onOpen: () => _openPlayer(key),
                  onPrev: () => _sessionPrev(key, n),
                  onToggle: () => _sessionToggle(key, n),
                  onNext: () => _sessionNext(key, n),
                ),
            ],
          );
        });
      },
    );
  }
}

/// The reference's two stats under each name, from the word itself.
List<(IconData, String)> _topStats(Word w) {
  final parts = w.parts.length;
  final organ = w.organ.trim();
  return [
    if (organ.isNotEmpty) (Icons.favorite_border_rounded, organ),
    if (parts > 0) (Icons.graphic_eq_rounded, '$parts ${parts == 1 ? 'part' : 'parts'}'),
  ];
}

String _wordStat(Word w) {
  final parts = w.parts.length;
  final organ = w.organ.trim();
  final p = parts > 0 ? '$parts ${parts == 1 ? 'part' : 'parts'}' : '';
  return [if (organ.isNotEmpty) organ, if (p.isNotEmpty) p].join(' · ');
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    super.key,
    required this.word,
    required this.art,
    required this.line,
    required this.index,
    required this.count,
    required this.playing,
    required this.onOpen,
    required this.onPrev,
    required this.onToggle,
    required this.onNext,
  });
  final Word word;
  final String art;
  final String line;
  final int index;
  final int count;
  final bool playing;
  final VoidCallback onOpen;
  final VoidCallback onPrev;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const dim = Color(0x8CFFFFFF);
    // Repeat and shuffle really switch: white on a glass square when on.
    Widget small(IconData i, String k, bool on, VoidCallback f) => Semantics(
          button: true,
          toggled: on,
          child: GestureDetector(
            key: ValueKey(k),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              f();
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: on ? const Color(0x24FFFFFF) : null,
                borderRadius: BorderRadius.circular(9),
                border: on ? Border.all(color: HeroGlassRecipe.line) : null,
              ),
              child: Icon(i, size: 18, color: on ? Colors.white : dim),
            ),
          ),
        );
    final t = _Toggles.instance;
    // The reference's tall dark card: big cover, title and line, a waveform
    // seek bar between two labels, then the controls.
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF161E33), Color(0xFF05070D)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: HeroGlassRecipe.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: AspectRatio(
              aspectRatio: 1.12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TabletArt(art),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(word.word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: dim, fontSize: 11.5)),
          const SizedBox(height: 12),
          Row(children: [
            Text('${index + 1}', style: const TextStyle(color: dim, fontSize: 10.5, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(
              child: TabletWaveform(seed: word.word, progress: count == 0 ? 0 : (index + 1) / count, height: 26, bars: 34),
            ),
            const SizedBox(width: 8),
            Text('of $count', style: const TextStyle(color: dim, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: t,
            builder: (context, _) => Row(children: [
            small(Icons.repeat_one_rounded, 'tablet-np-repeat', t.repeat, t.toggleRepeat),
            Expanded(
              child: Center(
                child: _Controls(tag: 'tablet-np', playing: playing, onPrev: onPrev, onToggle: onToggle, onNext: onNext),
              ),
            ),
            small(Icons.shuffle_rounded, 'tablet-np-shuffle', t.shuffle, () => unawaited(t.toggleShuffle())),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({super.key, required this.word, required this.art, required this.stat, required this.onTap, this.rank, this.current = false, this.stats});
  final List<(IconData, String)>? stats;
  final Word word;
  final String art;
  final String stat;
  final VoidCallback onTap;
  final int? rank;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(children: [
        if (rank != null)
          SizedBox(
            width: 22,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        if (rank != null) const SizedBox(width: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 48, height: 48, child: TabletArt(art)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(word.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
              if (stats != null && stats!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  for (var k = 0; k < stats!.length; k++) ...[
                    if (k > 0) const SizedBox(width: 10),
                    Icon(stats![k].$1, size: 12, color: const Color(0x8CFFFFFF)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(stats![k].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11)),
                    ),
                  ],
                ]),
              ],
              if (stat.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(stat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11.5)),
              ],
            ],
          ),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: current ? TabletPane(radius: 14, padding: EdgeInsets.zero, child: row) : row,
      ),
    );
  }
}

/// The right column beside the player: the queue, with the playing word
/// marked. Tapping a word plays it.
class TabletPlayerPanel extends StatelessWidget {
  const TabletPlayerPanel({super.key, required this.state});
  final TabletPlayerState state;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final words = state.words;
    return ListView(
      key: const ValueKey('tablet-player-panel'),
      padding: EdgeInsets.fromLTRB(4, pad.top + 20, 18 + pad.right, pad.bottom + 18),
      children: [
        _PanelHead('Up next'),
        for (var k = 0; k < words.length; k++)
          _TopRow(
            key: ValueKey('tablet-queue-${words[k].key}-$k'),
            rank: k + 1,
            current: k == state.index,
            word: words[k],
            art: playerCoverArtFor(words[k], k),
            stat: _wordStat(words[k]),
            onTap: () {
              AppHaptics.selection();
              state.jump(k);
            },
          ),
      ],
    );
  }
}
