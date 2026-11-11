// Normal home: the bottom nav is a plain black bar inside one glass wrapper.
// Zen home and the other tabs keep their own bar. Shots with
// --dart-define=NAV_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('NAV_SHOTS');
final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(b!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() => ContentStore.instance
        .start()
        .timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pumpWidget(MaterialApp(
        theme: NwsbTheme.light,
        debugShowCheckedModeBanner: false,
        builder: (c, child) => RepaintBoundary(
            key: _key,
            child: Stack(children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black)),
              const Positioned.fill(child: FaintFilm()),
              child ?? const SizedBox(),
            ])),
        home: const NavShell()));
    await _settle(t, 12);
    final agree = find.text('I Agree · Continue');
    if (agree.evaluate().isNotEmpty) {
      await t.tap(agree.first, warnIfMissed: false);
      await _settle(t, 8);
    }
  }

  Color? barColor(WidgetTester t) {
    final d = t.widget<Container>(find.byKey(const ValueKey('nav-glass-bar')))
        .decoration as BoxDecoration;
    return d.color;
  }

  testWidgets('normal home: black bar inside a glass wrapper; Zen untouched',
      (t) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    try {
      await t.runAsync(() => Settings.instance.setFashionHome(false));
      await boot(t);
      expect(find.byKey(const ValueKey('nav-glass')), findsOneWidget);
      expect(barColor(t), const Color(0xF5000000), reason: 'plain black');
      // The glass wrapper is a real blur over the page.
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('nav-glass')),
              matching: find.byType(BackdropFilter)),
          findsOneWidget);
      // Icons, labels, all five rooms are still there.
      for (final l in ['Connect', 'Practice', 'Library', 'Store', 'Profile']) {
        expect(
            find.descendant(
                of: find.byKey(const ValueKey('nav-glass')),
                matching: find.text(l)),
            findsOneWidget,
            reason: l);
      }
      await _shot(t, 'nav-normal-home-390');

      // Selected state follows the tab, and tabs still switch.
      await t.tap(find.descendant(
          of: find.byKey(const ValueKey('nav-glass')),
          matching: find.text('Library')));
      await _settle(t, 4);
      // Off the home the bar is the shared black bar, as before.
      expect(find.byKey(const ValueKey('nav-glass')), findsNothing);
      expect(find.text('Library'), findsWidgets);
      await _shot(t, 'nav-library-390');

      // Zen home keeps its own bar: no glass wrapper.
      await t.runAsync(() => Settings.instance.setFashionHome(true));
      await t.tap(find.text('Connect').last);
      await _settle(t, 8);
      expect(find.byKey(const ValueKey('nav-glass')), findsNothing);
      await _shot(t, 'nav-zen-home-390');
      await t.runAsync(() => Settings.instance.setFashionHome(false));
    } finally {
      FlutterError.onError = prev;
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 30));
      VideoPool.instance.debugDropAll();
    }
  });
}
