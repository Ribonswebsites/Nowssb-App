// Ribon, Nov 18: the Store loses the SHABDAPATHY · LIBRARY single-card
// section and the MEANING STORE / Today carousel; the login button's busy
// state is only the centred "Loading please wait" (no orb); the dark home
// loses the EXPERIENCE · Zen Plus banner, while the Zen Plus page stays
// reachable from Settings, the hamburger and the Quick shortcuts.
// Shots: --dart-define=CLEANUP_SHOTS=<dir> --dart-define=CLEANUP_TAG=before|after
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/screens/fashion/sections_mid.dart' show FashPlusMini;
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/normal/header_actions_sheet.dart';
import 'package:nowssb/screens/store/store_drift_banners.dart';
import 'package:nowssb/widgets/app_destinations.dart';
import 'package:nowssb/widgets/app_thinking_loader.dart';
import 'package:nowssb/widgets/home_menu_drawer.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart' show DropStudioEntry;
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/login_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('CLEANUP_SHOTS');
const _tag = String.fromEnvironment('CLEANUP_TAG', defaultValue: 'after');
final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester t, String name, {double ratio = 1}) async {
  if (_out.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: ratio);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/${_tag}_$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _app(WidgetTester t, Widget home, {double w = 412, double h = 915}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (c, child) => RepaintBoundary(key: _shotKey, child: child!),
    home: NavScope(go: (_) {}, child: home),
  ));
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Widget _login({required bool busy, bool create = false}) => Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: LoginStage(
          id: TextEditingController(text: 'ribon@nowssb.com'),
          secret: TextEditingController(text: 'secret'),
          busy: busy,
          obscure: true,
          remember: false,
          createAccount: create,
          codeSent: false,
          onSubmit: () {},
          onGoogle: () {},
          onApple: () {},
          onForgot: () {},
          onToggleCreate: () {},
          onToggleObscure: () {},
          onToggleRemember: () {},
        ),
      ),
    );

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'guide_seen_plus': true});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);


  Finder down() => find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

  testWidgets('Store: Library single card and Meaning Store Today are gone; the rest stays', (t) async {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await _app(t, const StoreScreen(), h: 7000);
    expect(find.text('SHABDAPATHY · LIBRARY'), findsNothing);
    expect(find.text('MEANING STORE'), findsNothing);
    expect(find.byType(StoreDriftBanner), findsNothing);
    expect(find.byType(StoreSlashBanner), findsNothing);
    for (final kept in ['WORD ATELIER', 'Build Your Personal Library', 'Meanings beneath every word', 'NOWSSB CONNECT', 'Open NowssB Connect', 'Get Verified', 'NowssB Ebooks', 'SUBSCRIPTION PLANS']) {
      expect(find.text(kept), findsWidgets, reason: kept);
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  test('Store: the editor cannot bring the two sections back', () {
    final src = File('lib/screens/store.dart').readAsStringSync();
    expect(src, isNot(contains("LSection('today'")));
    expect(src, isNot(contains("LSection('sit'")));
    expect(src, isNot(contains('StoreDriftBanner(')));
    expect(src, isNot(contains('StoreSlashBanner(')));
  });

  for (final create in [false, true]) {
    testWidgets('${create ? 'Sign up' : 'Log in'} busy: centred words, no orb', (t) async {
      await _app(t, _login(busy: true, create: create));
      expect(find.byType(AppThinkingLoader), findsNothing);
      final label = find.byKey(const ValueKey('login-busy-label'));
      expect(label, findsOneWidget);
      final button = find.ancestor(of: label, matching: find.byType(InkWell)).first;
      expect(t.getCenter(label).dx, closeTo(t.getCenter(button).dx, 1));
      expect(t.getCenter(label).dy, closeTo(t.getCenter(button).dy, 1));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('dark home: no Zen Plus banner', (t) async {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await _app(t, const HomeFashion());
    await t.scrollUntilVisible(find.byType(DropStudioEntry), 400, scrollable: down());
    await t.drag(down(), const Offset(0, -600));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(FashPlusMini), findsNothing);
    expect(find.text('Zen Plus'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Zen Plus page from the hamburger menu', (t) async {
    expect(menuDestinations.any((d) => d.id == 'zenplus'), isTrue);
    await _app(t, Builder(builder: (c) => Scaffold(body: Center(child: TextButton(onPressed: () => showHomeMenuDrawer(c, goTab: (_) {}), child: const Text('menu'))))));
    await t.tap(find.text('menu'));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final entry = find.text('Zen Plus');
    await t.scrollUntilVisible(entry, 200, scrollable: down());
    await t.drag(down(), const Offset(0, -200));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(entry);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FashionPlusScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Zen Plus page from Settings search', (t) async {
    await _app(t, const AppSettingsScreen());
    await t.enterText(find.byType(TextField).first, 'zen plus');
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final open = find.text('Open Zen Plus');
    expect(open, findsOneWidget);
    await t.ensureVisible(open);
    await t.tap(open);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FashionPlusScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Zen Plus page from the Quick shortcuts', (t) async {
    expect(Settings.defaultQuickActions, contains('zenplus'));
    expect(Settings.availableQuickActions, contains('zenplus'));
    await _app(t, Builder(builder: (c) => Scaffold(body: Center(child: TextButton(
        onPressed: () => showHeaderActionsSheet(c, glassMode: false, onGlassToggle: () {}, onNotifications: () {}),
        child: const Text('quick'))))));
    await t.tap(find.text('quick'));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // Tap once to centre the Zen Plus tile, again to open it.
    final tile = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.endsWith('-Zen Plus'));
    expect(tile, findsOneWidget);
    await t.tap(tile, warnIfMissed: false);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.endsWith('-Zen Plus')), warnIfMissed: false);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FashionPlusScreen), findsOneWidget);
    expect(find.byType(HeaderActionsSheet), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('shots: store, login busy, dark home', (t) async {
    if (_out.isEmpty) return;
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await _app(t, const StoreScreen(), h: 7000);
    await _shot(t, 'store_full', ratio: .6);
    await t.pumpWidget(const SizedBox());
    await _app(t, _login(busy: true));
    await _shot(t, 'login_busy');
    await t.pumpWidget(const SizedBox());
    await _app(t, _login(busy: true, create: true));
    await _shot(t, 'signup_busy');
    await t.pumpWidget(const SizedBox());
    await _app(t, const HomeFashion());
    // The Zen Plus banner sat right under the Drop Studio card.
    await t.scrollUntilVisible(find.byType(DropStudioEntry), 400, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await t.ensureVisible(find.byType(DropStudioEntry));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _shot(t, 'zen_home_around_drop_studio');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
