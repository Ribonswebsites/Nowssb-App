// Zen home · Your day card (Ribon, Nov 17): Quick and Today moved here, the
// real numbers from EconomyMirror, and every tile opening its real page.
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
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/fashion/today_earn_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('TODAY_EARN_SHOTS');
final _shotKey = GlobalKey();

Future<void> _mount(WidgetTester t, Widget body, {double w = 412, double h = 915}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        key: _shotKey,
        child: DecoratedBox(
          // Stand-in for the Zen home's backdrop film (no decoder in tests).
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.3, colors: [Color(0xFF3A1D78), Color(0xFF0E061E), Color(0xFF000000)], stops: [0, .55, 1]),
          ),
          child: SafeArea(child: SingleChildScrollView(child: body)),
        ),
      ),
    ),
  ));
  await t.pump();
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

void _signedIn({int coins = 0, int cents = 0, int lifetime = 0, int sold = 0, int target = 100, String tier = 'Seller', int team = 0}) {
  final m = EconomyMirror.instance;
  m.live = true;
  m.uid = 'test-user';
  m.coins = coins;
  m.cash = cents;
  m.lifetimeCents = lifetime;
  m.wordsSold = sold;
  m.nextSellerTarget = target;
  m.sellerTier = tier;
  m.teamCount = team;
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

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  tearDown(_signedOut);

  testWidgets('greeting and Begin banner no longer carry Quick or Today', (t) async {
    await _mount(t, const Column(children: [HeroGreeting(name: 'Healer'), FashGreeting()]));
    expect(find.byKey(const Key('greeting-quick-access')), findsNothing);
    expect(find.byType(TodayProgressButton), findsNothing);
    expect(find.text('Begin Your\nHealing Path'), findsOneWidget, reason: 'the banner itself stays');
  });

  testWidgets('Your day card: Quick and Today once each, real numbers, no overflow', (t) async {
    _signedIn(coins: 140, cents: 2500, lifetime: 12000, sold: 7, target: 25, tier: 'Officer', team: 3);
    var quick = 0;
    await _mount(t, TodayEarnSection(onQuick: () => quick++));
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('today-earn-quick')), findsOneWidget);
    expect(find.byType(TodayProgressButton), findsOneWidget);
    expect(find.text('140'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('7 / 25'), findsOneWidget);
    expect(find.text('Officer'), findsOneWidget);
    expect(find.textContaining('3 people under you'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('today-earn-quick')));
    expect(quick, 1);
  });

  testWidgets('signed out shows honest empty states', (t) async {
    _signedOut();
    await _mount(t, TodayEarnSection(onQuick: () {}));
    expect(t.takeException(), isNull);
    expect(find.text('No sales yet'), findsOneWidget);
    expect(find.text('Sign in to see your rank'), findsOneWidget);
    expect(find.text('Sign in to see your target'), findsOneWidget);
  });

  testWidgets('fits at 320 wide', (t) async {
    _signedIn(coins: 123456, lifetime: 98765432, sold: 1234, target: 5000, tier: 'Senior Officer', team: 42);
    await _mount(t, TodayEarnSection(onQuick: () {}), w: 320, h: 700);
    expect(t.takeException(), isNull);
  });

  for (final c in [
    ('today-earn-coins', CoinsScreen),
    ('today-earn-cash', EarningsScreen),
    ('today-earn-sold', EarnTabsPage),
    ('today-earn-target', EarnTabsPage),
    ('today-earn-position', EarnTabsPage),
  ]) {
    testWidgets('${c.$1} opens ${c.$2}', (t) async {
      final routes = <Route<dynamic>>[];
      t.view.physicalSize = const Size(412, 915);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [_Spy(routes)],
        home: Scaffold(body: SingleChildScrollView(child: TodayEarnSection(onQuick: () {}))),
      ));
      await t.pump();
      routes.clear();
      await t.tap(find.byKey(ValueKey(c.$1)));
      await t.pump();
      final r = routes.whereType<MaterialPageRoute<void>>().single;
      final page = r.builder(t.element(find.byType(TodayEarnSection)));
      expect(page.runtimeType, c.$2);
      if (page is EarnTabsPage) {
        expect(page.initialTab, switch (c.$1) { 'today-earn-sold' => 'sales', 'today-earn-target' => 'targets', _ => 'team' });
      }
      // Drop the pushed page and let its load timers run out.
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('shots 412x915', (t) async {
    if (_out.isEmpty) return;
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _mount(t, Column(children: [const HeroGreeting(name: 'Healer'), TodayEarnSection(onQuick: () {}), const FashGreeting()]));
    await _shot(t, '00_warm');
    FlutterError.onError = warm;
    _signedIn(coins: 140, cents: 2500, lifetime: 12000, sold: 7, target: 25, tier: 'Officer', team: 3);
    await _mount(t, Column(children: [const HeroGreeting(name: 'Healer'), TodayEarnSection(onQuick: () {}), const FashGreeting()]));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _shot(t, '01_your_day_signed_in_sample_values');
    _signedOut();
    await _mount(t, Column(children: [const HeroGreeting(name: 'Healer'), TodayEarnSection(onQuick: () {}), const FashGreeting()]));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _shot(t, '02_your_day_signed_out_empty');
  });
}

class _Spy extends NavigatorObserver {
  _Spy(this.routes);
  final List<Route<dynamic>> routes;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}
