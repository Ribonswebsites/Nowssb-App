// Your Earnings (Ribon, Nov 17): one black banner below Begin Your Healing
// Path (Zen) / Where to Begin (Normal) with a Cash earned hero and a row of
// square tiles; See all opens the black Your Earnings sheet. Quick and Today
// are NOT repeated: the greeting's Quick and the banner's Today stay.
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
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('EARN_SHOTS');
final _shotKey = GlobalKey();

Future<void> _mount(WidgetTester t, Widget body, {double w = 412, double h = 915, bool light = false, double scale = 1, bool still = false, List<NavigatorObserver> obs = const []}) async {
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
        child: SafeArea(child: SingleChildScrollView(child: body)),
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

/// The Zen top: greeting (with its Quick), then Begin Your Healing Path
/// (with its Today) carrying Your Earnings right under it, as on the home.
Widget _zen() => Column(children: [
      HeroGreeting(name: 'Healer', onQuickAccess: () {}),
      const FashGreeting(below: YourEarningsSection(light: false, padding: EdgeInsets.fromLTRB(16, 16, 16, 4))),
    ]);

Widget _normal() => const Column(children: [NmGreeting(name: 'Healer'), SizedBox(height: 10), YourEarningsSection()]);

Future<void> _openSheet(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('earn-see-all')));
  await _settle(t);
  expect(find.byKey(const ValueKey('your-earnings-sheet')), findsOneWidget);
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

  testWidgets('Zen: Earnings sits under Begin Your Healing Path; Quick and Today untouched, not repeated', (t) async {
    await _mount(t, _zen());
    expect(find.byKey(const Key('greeting-quick-access')), findsOneWidget);
    expect(find.byType(TodayProgressButton), findsOneWidget);
    final begin = t.getRect(find.text('Begin Your\nHealing Path'));
    final earn = t.getRect(find.byKey(const ValueKey('your-earnings-section')));
    expect(earn.top, greaterThan(begin.bottom));
    expect(find.text('Quick'), findsOneWidget, reason: 'only the greeting one');
    expect(t.takeException(), isNull);
    await _done(t);
  });

  testWidgets('Normal: greeting keeps its Today; Earnings banner renders', (t) async {
    await _mount(t, _normal(), light: true);
    expect(find.byType(TodayProgressButton), findsOneWidget);
    expect(find.byKey(const ValueKey('your-earnings-section')), findsOneWidget);
    expect(t.takeException(), isNull);
    await _done(t);
  });

  testWidgets('real mirror values on the banner', (t) async {
    _signedIn();
    await _mount(t, _normal(), light: true);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('140'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('/ 25'), findsOneWidget);
    expect(find.text('SO'), findsOneWidget, reason: 'Senior Officer');
    expect(find.text('3 people'), findsOneWidget);
    expect(find.text('Not on board'), findsOneWidget);
    expect(find.textContaining('Senior Officer'), findsWidgets);
    await _done(t);
  });

  testWidgets('signed out: honest empty states', (t) async {
    await _mount(t, _normal(), light: true);
    expect(find.text('Sign in to start earning'), findsOneWidget);
    expect(find.text('No sales yet'), findsOneWidget);
    await _done(t);
  });

  testWidgets('reduced motion: figures land at once', (t) async {
    _signedIn();
    await _mount(t, _normal(), light: true, still: true);
    expect(find.text('140'), findsOneWidget);
    await _done(t);
  });

  testWidgets('See all opens the black sheet (no tab bar); close closes', (t) async {
    _signedIn();
    await _mount(t, _zen());
    await _openSheet(t);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    expect(find.byKey(const ValueKey('earn-position-card')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('earn-sheet-close')));
    await _settle(t);
    expect(find.byKey(const ValueKey('your-earnings-sheet')), findsNothing);
    await _done(t);
  });

  final dests = [
    ('earn-hero-cash', EarningsScreen, ''),
    ('earn-tile-coins', CoinsScreen, ''),
    ('earn-tile-sold', EarnTabsPage, 'sales'),
    ('earn-tile-target', EarnTabsPage, 'targets'),
    ('earn-tile-position', EarnTabsPage, 'team'),
    ('earn-tile-under', EarnTabsPage, 'team'),
    ('earn-tile-month', EarnTabsPage, 'sales'),
  ];
  for (final inSheet in [false, true]) {
    for (final c in [
      ...dests,
      if (inSheet) ...[
        ('earn-position-card', EarnTabsPage, 'team'),
        ('earn-target-card', EarnTabsPage, 'targets'),
        ('earn-open-earnings', EarningsScreen, ''),
        ('earn-open-sales', EarnTabsPage, 'sales'),
      ],
    ]) {
      testWidgets('${inSheet ? 'sheet' : 'home'}: ${c.$1} opens ${c.$2} ${c.$3}', (t) async {
        final routes = <Route<dynamic>>[];
        await _mount(t, _normal(), light: true, obs: [_Spy(routes)]);
        if (inSheet) await _openSheet(t);
        final scope = inSheet ? find.byKey(const ValueKey('your-earnings-sheet')) : find.byKey(const ValueKey('your-earnings-section'));
        final target = find.descendant(of: scope, matching: find.byKey(ValueKey(c.$1)));
        if (inSheet) {
          // The sheet's list builds lazily; scroll its own column.
          await t.scrollUntilVisible(target, 200, scrollable: find.descendant(of: scope, matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)).first);
        }
        await t.ensureVisible(target);
        await t.pump();
        routes.clear();
        await t.tap(target);
        await t.pump();
        final r = routes.whereType<MaterialPageRoute<void>>().single;
        final page = r.builder(t.element(scope));
        expect(page.runtimeType, c.$2);
        if (page is EarnTabsPage) expect(page.initialTab, c.$3);
        await _done(t);
      });
    }
  }

  for (final w in [360.0, 390.0, 412.0]) {
    for (final s in [1.0, 1.3]) {
      testWidgets('no overflow at ${w.toInt()}@$s: both homes and the sheet', (t) async {
        _signedIn();
        await _mount(t, _zen(), w: w, h: 900, scale: s);
        expect(t.takeException(), isNull);
        await _openSheet(t);
        expect(t.takeException(), isNull);
        await t.drag(find.byType(ListView).last, const Offset(0, -900));
        await _settle(t);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await _mount(t, _normal(), w: w, h: 900, scale: s, light: true);
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
    await _mount(t, _zen());
    await _shot(t, '00_warm');
    FlutterError.onError = warm;
    _signedIn();
    final shots = [
      ('01_zen_home_earnings_below_begin', _zen(), false, false),
      ('02_zen_earnings_sheet_open', _zen(), false, true),
      ('03_normal_home_earnings_banner', _normal(), true, false),
      ('04_normal_earnings_sheet_open', _normal(), true, true),
    ];
    for (final (name, body, light, sheet) in shots) {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await _mount(t, body, light: light);
      await _settle(t);
      if (sheet) {
        await _openSheet(t);
        await t.pump(const Duration(seconds: 1));
      }
      await _shot(t, name);
    }
    await _mount(t, _zen());
    await _done(t);
  });
}

class _Spy extends NavigatorObserver {
  _Spy(this.routes);
  final List<Route<dynamic>> routes;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => routes.add(route);
}
