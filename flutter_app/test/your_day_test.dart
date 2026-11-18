// Your day (Ribon, Nov 18): an ADDITIVE row of Quick · Today · Your Earnings
// under the greeting; each opens its own tab of one glass sheet. The
// greeting's Quick and the Begin banner's Today stay where they were.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/your_day/your_day.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('YOUR_DAY_SHOTS');
final _shotKey = GlobalKey();

var _store = 0, _player = 0, _alerts = 0, _glass = 0;
var _glassOn = false;
YourDayActions _actions({bool glass = false}) => YourDayActions(
      onNotifications: () => _alerts++,
      onStore: () => _store++,
      onPlayer: () => _player++,
      onGlassToggle: glass
          ? () {
              _glass++;
              _glassOn = !_glassOn;
            }
          : null,
      glassOn: glass ? () => _glassOn : null,
    );

Future<void> _mount(WidgetTester t, Widget body, {double w = 412, double h = 915, bool light = false, double scale = 1, bool still = false}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
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
        child: SafeArea(child: SingleChildScrollView(child: body)),
      ),
    ),
  ));
  await t.pump();
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
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
  m.sellerTier = 'Officer';
  m.teamCount = 3;
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

Widget _zen() => Column(children: [
      HeroGreeting(name: 'Healer', onQuickAccess: () {}),
      YourDaySection(actions: _actions()),
      const FashGreeting(),
    ]);

Future<void> _openTab(WidgetTester t, String button) async {
  await t.tap(find.byKey(ValueKey(button)));
  await _settle(t);
  expect(find.byKey(const ValueKey('your-day-sheet')), findsOneWidget);
}

TabController _tabs(WidgetTester t) => t.widget<TabBarView>(find.byType(TabBarView)).controller!;

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    _store = _player = _alerts = _glass = 0;
    _glassOn = false;
  });
  tearDown(_signedOut);

  testWidgets('additive: greeting Quick and Begin banner Today are still there', (t) async {
    await _mount(t, _zen());
    expect(find.byKey(const Key('greeting-quick-access')), findsOneWidget);
    expect(find.byType(TodayProgressButton), findsOneWidget, reason: 'the Begin Your Healing Path Today button');
    expect(find.byKey(const ValueKey('your-day-section')), findsOneWidget);
    for (final k in ['your-day-quick', 'your-day-today', 'your-day-earnings']) {
      expect(find.byKey(ValueKey(k)), findsOneWidget);
    }
    // Home shows only the buttons, not the earnings grid.
    expect(find.byKey(const ValueKey('your-day-coins')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('light Normal home keeps its own Today and gets the row', (t) async {
    await _mount(t, Column(children: [const NmGreeting(name: 'Healer'), YourDaySection(light: true, actions: _actions(glass: true))]), light: true);
    expect(find.byType(TodayProgressButton), findsOneWidget);
    expect(find.byKey(const ValueKey('your-day-section')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final c in [('your-day-quick', 0), ('your-day-today', 1), ('your-day-earnings', 2)]) {
    testWidgets('${c.$1} opens the sheet on its own tab', (t) async {
      await _mount(t, _zen());
      await _openTab(t, c.$1);
      expect(_tabs(t).index, c.$2);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('tabs switch by tap and by swipe; close button closes', (t) async {
    await _mount(t, _zen());
    await _openTab(t, 'your-day-quick');
    await t.tap(find.byKey(const ValueKey('your-day-tab-2')));
    await _settle(t);
    expect(_tabs(t).index, 2);
    await t.fling(find.byType(TabBarView), const Offset(300, 0), 1200);
    await _settle(t);
    expect(_tabs(t).index, 1);
    expect(find.byType(ProgressPanel), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('your-day-close')));
    await _settle(t);
    expect(find.byKey(const ValueKey('your-day-sheet')), findsNothing);
  });

  testWidgets('Quick tab runs the real shortcuts; no Glass switch where there is no glass mode', (t) async {
    await _mount(t, _zen());
    await _openTab(t, 'your-day-quick');
    expect(find.byKey(const ValueKey('your-day-qa-glass')), findsNothing);
    expect(find.byKey(const ValueKey('your-day-qa-customize')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('your-day-qa-store')));
    await _settle(t);
    expect(_store, 1);
    expect(find.byKey(const ValueKey('your-day-sheet')), findsNothing, reason: 'sheet closes first');
    await _openTab(t, 'your-day-quick');
    await t.tap(find.byKey(const ValueKey('your-day-qa-player')));
    await _settle(t);
    expect(_player, 1);
    await _openTab(t, 'your-day-quick');
    await t.tap(find.byKey(const ValueKey('your-day-qa-notifications')));
    await _settle(t);
    expect(_alerts, 1);
  });

  testWidgets('Normal home Quick tab toggles the real glass mode', (t) async {
    await _mount(t, YourDaySection(light: true, actions: _actions(glass: true)), light: true);
    await _openTab(t, 'your-day-quick');
    expect(find.text('Off · tap to turn on'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('your-day-qa-glass')));
    await t.pump();
    expect(_glass, 1);
    expect(find.text('On · tap to turn off'), findsOneWidget);
  });

  testWidgets('Your Earnings shows the real mirror values', (t) async {
    _signedIn();
    await _mount(t, _zen());
    await _openTab(t, 'your-day-earnings');
    await t.pump(const Duration(seconds: 1));
    expect(find.text('140'), findsOneWidget);
    expect(find.text('7 / 25'), findsOneWidget);
    expect(find.text('Officer'), findsOneWidget);
    expect(find.text('3 people'), findsOneWidget);
    expect(find.text('Not on board'), findsOneWidget);
  });

  testWidgets('signed out: honest empty states', (t) async {
    await _mount(t, _zen());
    await _openTab(t, 'your-day-earnings');
    expect(find.text('No sales yet'), findsOneWidget);
    expect(find.text('Not ranked yet'), findsOneWidget);
    expect(find.text('Sign in to see your target'), findsOneWidget);
  });

  testWidgets('reduced motion: numbers land at once', (t) async {
    _signedIn();
    await _mount(t, _zen(), still: true);
    await _openTab(t, 'your-day-earnings');
    expect(find.text('140'), findsOneWidget);
  });

  for (final c in [
    ('your-day-coins', CoinsScreen),
    ('your-day-cash', EarningsScreen),
    ('your-day-sold', EarnTabsPage),
    ('your-day-target', EarnTabsPage),
    ('your-day-position', EarnTabsPage),
  ]) {
    testWidgets('${c.$1} opens ${c.$2}', (t) async {
      final routes = <Route<dynamic>>[];
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [_Spy(routes)],
        home: Scaffold(body: YourDaySection(actions: _actions())),
      ));
      await _openTab(t, 'your-day-earnings');
      routes.clear();
      await t.ensureVisible(find.byKey(ValueKey(c.$1)));
      await t.tap(find.byKey(ValueKey(c.$1)));
      await t.pump();
      final r = routes.whereType<MaterialPageRoute<void>>().single;
      final page = r.builder(t.element(find.byKey(const ValueKey('your-day-sheet'))));
      expect(page.runtimeType, c.$2);
      if (page is EarnTabsPage) {
        expect(page.initialTab, switch (c.$1) { 'your-day-sold' => 'sales', 'your-day-target' => 'targets', _ => 'team' });
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    });
  }

  for (final w in [360.0, 390.0, 412.0]) {
    for (final s in [1.0, 1.3]) {
      testWidgets('no overflow at ${w.toInt()}@$s: row and every tab', (t) async {
        _signedIn();
        await _mount(t, _zen(), w: w, h: 800, scale: s);
        expect(t.takeException(), isNull);
        await _openTab(t, 'your-day-quick');
        expect(t.takeException(), isNull);
        for (final i in [1, 2]) {
          await t.tap(find.byKey(ValueKey('your-day-tab-$i')));
          await _settle(t);
          expect(t.takeException(), isNull, reason: 'tab $i');
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 2));
      });
    }
  }

  testWidgets('shots 412x915', (t) async {
    if (_out.isEmpty) return;
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _mount(t, _zen());
    await _shot(t, '00_warm');
    FlutterError.onError = warm;
    _signedIn();
    await _mount(t, _zen());
    await _settle(t);
    await _shot(t, '01_zen_home_restored_buttons_and_your_day');
    for (final (k, name) in [('your-day-quick', '03_sheet_quick_tab'), ('your-day-today', '04_sheet_today_tab'), ('your-day-earnings', '05_sheet_your_earnings_tab')]) {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await _mount(t, _zen());
      await _openTab(t, k);
      await t.pump(const Duration(seconds: 1));
      await _shot(t, name);
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await _mount(t, Column(children: [const NmGreeting(name: 'Healer'), YourDaySection(light: true, actions: _actions(glass: true))]), light: true);
    await _settle(t);
    await _shot(t, '02_normal_home_today_kept_and_your_day');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}

class _Spy extends NavigatorObserver {
  _Spy(this.routes);
  final List<Route<dynamic>> routes;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}
