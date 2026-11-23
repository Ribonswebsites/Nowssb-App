// Your day (Ribon, Nov 18): Quick · Today · Your Earnings as three glass
// buttons on one black banner, below Begin Your Healing Path (Zen) and
// Where to Begin (Normal). Quick and Today open the SAME sheets as the
// greeting's Quick and the banner's Today; Your Earnings opens the glass
// Your Earnings tab (black hero), which expands to full screen and back.
// The originals stay. Shots: --dart-define=TRIO_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/earn/your_earnings_section.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/normal/header_actions_sheet.dart';
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('TRIO_SHOTS');
final _shotKey = GlobalKey();

/// The hosts' Quick: the header actions sheet, exactly as the homes call it.
void _quick(BuildContext c) => showHeaderActionsSheet(c, onNotifications: () {}, onStore: () {}, onPlayer: () {});

Future<void> _mount(WidgetTester t, Widget Function(BuildContext) body,
    {double w = 412, double h = 915, bool light = false, double scale = 1, bool still = false, List<NavigatorObserver> obs = const []}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    navigatorObservers: obs,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: still),
      child: RepaintBoundary(key: _shotKey, child: child!),
    ),
    home: Scaffold(
      backgroundColor: light ? NwsbColors.surface : Colors.black,
      body: DecoratedBox(
        // Stand-in for the Zen home's backdrop film (no decoder in tests).
        decoration: light
            ? const BoxDecoration(color: NwsbColors.surface)
            : const BoxDecoration(
                gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.3, colors: [Color(0xFF3A1D78), Color(0xFF0E061E), Color(0xFF000000)], stops: [0, .55, 1]),
              ),
        child: SafeArea(child: SingleChildScrollView(child: Builder(builder: body))),
      ),
    ),
  ));
  await t.pump();
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 14; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 5));
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _signedIn() {
  final m = EconomyMirror.instance;
  m.live = true;
  m.uid = 'test-user';
  m.coins = 140;
  m.cash = 2500;
  m.lifetimeCents = 12000;
  m.wordsSold = 7;
  m.nextSellerTarget = 25;
  m.sellerTier = 'Senior Officer';
  m.teamCount = 3;
}

/// A brand-new signed-in account exactly as the server starts it: no coins,
/// no sales, first rank. The shots use this, not made-up figures.
void _newAccount() {
  _signedOut();
  final m = EconomyMirror.instance;
  m.live = true;
  m.uid = 'new-user';
}

void _signedOut() {
  final m = EconomyMirror.instance;
  m.live = false;
  m.uid = null;
  m.coins = 0;
  m.cash = 0;
  m.lifetimeCents = 0;
  m.wordsSold = 0;
  m.nextSellerTarget = 100;
  m.sellerTier = 'Seller';
  m.teamCount = 0;
}

/// The Zen top: greeting (its Quick), Begin Your Healing Path (its Today)
/// and Your day right under it, as on the home.
Widget _zen(BuildContext c) => Column(children: [
      HeroGreeting(name: 'Healer', onQuickAccess: () => _quick(c)),
      FashGreeting(below: HomeTrioSection(light: false, padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), onQuick: () => _quick(c))),
    ]);

Widget _normal(BuildContext c) => Column(children: [
      const NmGreeting(name: 'Healer'),
      const SizedBox(height: 10),
      HomeTrioSection(onQuick: () => _quick(c)),
    ]);

Finder get _sheet => find.byKey(const ValueKey('your-earnings-sheet'));

Future<void> _openEarnings(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('trio-earnings')));
  await _settle(t);
  expect(_sheet, findsOneWidget);
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(() {
    _signedOut();
    VideoPool.instance.debugDropAll();
  });

  testWidgets('Zen: three buttons under Begin Your Healing Path; originals untouched', (t) async {
    await _mount(t, _zen);
    expect(find.byKey(const Key('greeting-quick-access')), findsOneWidget);
    expect(find.byType(TodayProgressButton), findsOneWidget);
    for (final k in ['trio-quick', 'trio-today', 'trio-earnings']) {
      expect(find.byKey(ValueKey(k)), findsOneWidget);
    }
    final begin = t.getRect(find.text('Begin Your\nHealing Path'));
    expect(t.getRect(find.byKey(const ValueKey('home-trio-section'))).top, greaterThan(begin.bottom));
    // The big earnings content is not on home any more.
    expect(find.byKey(const ValueKey('earn-hero-cash')), findsNothing);
    expect(find.byKey(const ValueKey('earn-tile-coins')), findsNothing);
    expect(t.takeException(), isNull);
    await _done(t);
  });

  testWidgets('Quick opens the same sheet as the greeting Quick', (t) async {
    await _mount(t, _zen);
    await t.tap(find.byKey(const Key('greeting-quick-access')));
    await _settle(t);
    expect(find.byType(HeaderActionsSheet), findsOneWidget);
    Navigator.of(t.element(find.byType(HeaderActionsSheet))).pop();
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('trio-quick')));
    await _settle(t);
    expect(find.byType(HeaderActionsSheet), findsOneWidget);
    expect(_sheet, findsNothing);
    await _done(t);
  });

  testWidgets('Today opens the same panel as the banner Today', (t) async {
    await _mount(t, _zen);
    await t.tap(find.byKey(const ValueKey('today-progress-button')));
    await _settle(t);
    expect(find.byType(ProgressPanel), findsOneWidget);
    Navigator.of(t.element(find.byType(ProgressPanel))).pop();
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('trio-today')));
    await _settle(t);
    expect(find.byType(ProgressPanel), findsOneWidget);
    await _done(t);
  });

  testWidgets('real Normal home: Quick opens the header sheet, Today the panel, Earnings the tab', (t) async {
    t.view.physicalSize = const Size(412 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: const HomeNormal())));
    await t.pump(const Duration(milliseconds: 50));
    final quick = find.byKey(const ValueKey('trio-quick'));
    await t.scrollUntilVisible(quick, 300, scrollable: find.byType(Scrollable).first);
    await t.pump();
    await t.tap(quick);
    await _settle(t);
    expect(find.byType(HeaderActionsSheet), findsOneWidget);
    Navigator.of(t.element(find.byType(HeaderActionsSheet))).pop();
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('trio-today')));
    await _settle(t);
    expect(find.byType(ProgressPanel), findsOneWidget);
    Navigator.of(t.element(find.byType(ProgressPanel))).pop();
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('trio-earnings')));
    await _settle(t);
    expect(_sheet, findsOneWidget);
    await _done(t);
  });

  testWidgets('real Zen home: Quick opens the header sheet, Today the panel', (t) async {
    t.view.physicalSize = const Size(412 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await t.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: const HomeFashion())));
    await t.pump(const Duration(milliseconds: 50));
    final quick = find.byKey(const ValueKey('trio-quick'));
    await t.ensureVisible(quick);
    await t.pump();
    await t.tap(quick, warnIfMissed: false);
    await _settle(t);
    expect(find.byType(HeaderActionsSheet), findsOneWidget);
    Navigator.of(t.element(find.byType(HeaderActionsSheet))).pop();
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('trio-today')), warnIfMissed: false);
    await _settle(t);
    expect(find.byType(ProgressPanel), findsOneWidget);
    await _done(t);
  });

  testWidgets('buttons show real lines', (t) async {
    _signedIn();
    await _mount(t, _normal, light: true);
    expect(find.text('Your shortcuts'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('trio-today')), matching: find.textContaining(' done')), findsOneWidget);
    expect(find.text('\$120.00 earned'), findsOneWidget);
    await _done(t);
    _signedOut();
    await _mount(t, _normal, light: true);
    expect(find.text('Sign in to earn'), findsOneWidget);
    await _done(t);
  });

  testWidgets('earnings tab: glass, black hero, real values, expand and collapse', (t) async {
    _signedIn();
    await _mount(t, _zen);
    await _openEarnings(t);
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(find.byType(TabBar), findsNothing);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('140'), findsOneWidget);
    expect(find.textContaining(' / 25'), findsOneWidget);
    expect(find.text('Senior Officer'), findsOneWidget);
    final part = t.getSize(_sheet).height;
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await _settle(t);
    final full = t.getSize(_sheet).height;
    expect(full, greaterThan(part + 100));
    expect(find.bySemanticsLabel('Collapse'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await _settle(t);
    expect(t.getSize(_sheet).height, closeTo(part, 1));
    // Drag the handle up: expands. Drag down: collapses, then closes.
    await t.drag(find.byKey(const ValueKey('earn-sheet-handle')), const Offset(0, -200));
    await _settle(t);
    expect(t.getSize(_sheet).height, closeTo(full, 1));
    await t.drag(find.byKey(const ValueKey('earn-sheet-handle')), const Offset(0, 200));
    await _settle(t);
    expect(t.getSize(_sheet).height, closeTo(part, 1));
    await t.drag(find.byKey(const ValueKey('earn-sheet-handle')), const Offset(0, 200));
    await _settle(t);
    expect(_sheet, findsNothing);
    await _done(t);
  });

  testWidgets('earnings tab: every figure once, no repeated rows', (t) async {
    _signedIn();
    await _mount(t, _zen);
    await _openEarnings(t);
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await _settle(t);
    await t.pump(const Duration(seconds: 2));
    // Rank, place and team live only in the Your position card.
    expect(find.text('Senior Officer'), findsOneWidget);
    expect(find.textContaining('this month\u2019s board'), findsNothing);
    expect(find.text('3 people'), findsOneWidget);
    expect(find.text('At a glance'), findsNothing);
    for (final k in ['earn-tile-target', 'earn-tile-position', 'earn-tile-under', 'earn-tile-month', 'earn-open-earnings', 'earn-open-sales']) {
      expect(find.byKey(ValueKey(k)), findsNothing, reason: k);
    }
    expect(find.text('Earnings and payouts'), findsNothing);
    expect(find.text('Sales and leaderboard'), findsNothing);
    await _done(t);
  });

  testWidgets('Your day: no filler line under the title', (t) async {
    await _mount(t, _zen);
    expect(find.text('Your day'), findsOneWidget);
    expect(find.textContaining('Shortcuts, today'), findsNothing);
    await _done(t);
  });

  testWidgets('Quick sheet: four shortcuts, no glass toggle, no add tile, one tap opens', (t) async {
    await _mount(t, _zen);
    await t.tap(find.byKey(const ValueKey('trio-quick')));
    await _settle(t);
    final sheet = find.byType(HeaderActionsSheet);
    expect(sheet, findsOneWidget);
    for (final l in ['Notifications', 'Store', 'Player', 'Zen Plus']) {
      expect(find.descendant(of: sheet, matching: find.text(l)), findsOneWidget, reason: l);
    }
    for (final l in ['Glassmorphism on', 'Glassmorphism off', 'Glass on', 'Glass off', 'Add shortcut', 'Add', 'Swipe \u00b7 centre to open', 'Customize shortcuts']) {
      expect(find.text(l), findsNothing, reason: l);
    }
    await _done(t);
  });

  testWidgets('earnings tab close button closes', (t) async {
    await _mount(t, _normal, light: true);
    await _openEarnings(t);
    await t.tap(find.byKey(const ValueKey('earn-sheet-close')));
    await _settle(t);
    expect(_sheet, findsNothing);
    await _done(t);
  });

  testWidgets('reduced motion: the tab expands at once, figures land at once', (t) async {
    _signedIn();
    await _mount(t, _normal, light: true, still: true);
    await _openEarnings(t);
    expect(find.text('140'), findsOneWidget);
    final part = t.getSize(_sheet).height;
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await t.pump();
    await t.pump();
    expect(t.getSize(_sheet).height, greaterThan(part + 100));
    await _done(t);
  });

  for (final c in [
    ('earn-hero-cash', EarningsScreen, ''),
    ('earn-tile-coins', CoinsScreen, ''),
    ('earn-tile-sold', EarnTabsPage, 'sales'),
    ('earn-position-card', EarnTabsPage, 'team'),
    ('earn-target-card', EarnTabsPage, 'targets'),
  ]) {
    testWidgets('tab: ${c.$1} opens ${c.$2} ${c.$3}', (t) async {
      final routes = <Route<dynamic>>[];
      await _mount(t, _normal, light: true, obs: [_Spy(routes)]);
      await _openEarnings(t);
      final target = find.descendant(of: _sheet, matching: find.byKey(ValueKey(c.$1)));
      await t.scrollUntilVisible(target, 200,
          scrollable: find.descendant(of: _sheet, matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)).first);
      await t.ensureVisible(target);
      await t.pump();
      routes.clear();
      await t.tap(target);
      await t.pump();
      final r = routes.whereType<MaterialPageRoute<void>>().single;
      final page = r.builder(t.element(_sheet));
      expect(page.runtimeType, c.$2);
      if (page is EarnTabsPage) expect(page.initialTab, c.$3);
      await _done(t);
    });
  }

  for (final w in [360.0, 390.0, 412.0]) {
    for (final s in [1.0, 1.3]) {
      testWidgets('no overflow at ${w.toInt()}@$s: both homes and the tab, collapsed and expanded', (t) async {
        _signedIn();
        await _mount(t, _zen, w: w, h: 900, scale: s);
        expect(t.takeException(), isNull);
        await _openEarnings(t);
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
        await _settle(t);
        await t.drag(find.descendant(of: _sheet, matching: find.byType(ListView)), const Offset(0, -900));
        await _settle(t);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await _mount(t, _normal, w: w, h: 900, scale: s, light: true);
        expect(t.takeException(), isNull);
        await _done(t);
      });
    }
  }

  testWidgets('shots 412x915', (t) async {
    if (_out.isEmpty) return;
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _mount(t, _zen);
    await _shot(t, '00_warm');
    FlutterError.onError = warm;
    _newAccount();
    final shots = <(String, Widget Function(BuildContext), bool, String?)>[
      ('01_zen_home_three_buttons', _zen, false, null),
      ('02_normal_home_three_buttons', _normal, true, null),
      ('03_zen_earnings_tab_collapsed', _zen, false, 'earn'),
      ('04_zen_earnings_tab_expanded', _zen, false, 'expand'),
      ('05_normal_earnings_tab_collapsed', _normal, true, 'earn'),
      ('06_normal_earnings_tab_expanded', _normal, true, 'expand'),
      ('07_zen_quick_opens_existing_quick_sheet', _zen, false, 'trio-quick'),
      ('08_zen_today_opens_existing_today_panel', _zen, false, 'trio-today'),
      ('09_normal_quick_opens_existing_quick_sheet', _normal, true, 'trio-quick'),
      ('10_normal_today_opens_existing_today_panel', _normal, true, 'trio-today'),
    ];
    for (final (name, body, light, act) in shots) {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await _mount(t, body, light: light);
      await _settle(t);
      if (act == 'earn' || act == 'expand') {
        await _openEarnings(t);
        if (act == 'expand') {
          await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
          await _settle(t);
        }
        await t.pump(const Duration(seconds: 1));
      } else if (act != null) {
        await t.tap(find.byKey(ValueKey(act)));
        await _settle(t);
        await t.pump(const Duration(seconds: 1));
      }
      await _shot(t, name);
    }
    await _done(t);
  });
}

class _Spy extends NavigatorObserver {
  _Spy(this.routes);
  final List<Route<dynamic>> routes;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}
