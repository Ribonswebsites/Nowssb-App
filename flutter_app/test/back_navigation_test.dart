// Android back (handlePopRoute = the hardware back key / back gesture) on
// every main page and sub-page: it must go to the previous page, a non-Home
// tab goes to Home, and only Home asks "press back again" before exiting.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'fake_video_platform.dart';
import 'back_screens.g.dart';

final exits = <String>[];

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

/// Screens that keep the user on purpose when back is pressed (they
/// minimise or finish themselves instead of being popped straight away).
const _ownBack = {'PracticePlayerScreen', 'SpinWheelScreen', 'PlayerGuide'};

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'SystemNavigator.pop') exits.add('exit');
      return null;
    });
  });
  setUp(exits.clear);

  Future<GlobalKey<NavigatorState>> shell(WidgetTester t) async {
    t.view.physicalSize = const Size(460, 1024);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: nav, home: const NavShell()));
    await _settle(t, 15);
    final agree = find.text('I Agree · Continue');
    if (agree.evaluate().isNotEmpty) {
      await t.tap(agree.first, warnIfMissed: false);
      await _settle(t, 15);
    }
    return nav;
  }

  testWidgets('Home root: first back warns, second back exits', (t) async {
    final errs = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errs.add(d.exceptionAsString());
    addTearDown(() => FlutterError.onError = prev);
    await shell(t);
    await t.binding.handlePopRoute();
    await t.pump();
    expect(exits, isEmpty, reason: 'one back on Home must not close the app');
    expect(find.text('Press back again to exit'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pump();
    expect(exits, ['exit']);
    await t.pumpWidget(const SizedBox());
  });

  for (final tab in [1, 2, 3, 4]) {
    testWidgets('tab $tab: back returns to Home, app stays open', (t) async {
      final prev = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = prev);
      final nav = await shell(t);
      NavScope.goTo(nav.currentContext!, tab);
      await _settle(t);
      await t.binding.handlePopRoute();
      await _settle(t);
      expect(exits, isEmpty);
      // Back on Home now warns instead of exiting.
      await t.binding.handlePopRoute();
      await t.pump();
      expect(exits, isEmpty);
      expect(find.text('Press back again to exit'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('sheet and dialog over the shell close with back', (t) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() => FlutterError.onError = prev);
    final nav = await shell(t);
    showModalBottomSheet<void>(context: nav.currentContext!, builder: (_) => const Text('a sheet'));
    await _settle(t);
    expect(find.text('a sheet'), findsOneWidget);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.text('a sheet'), findsNothing);
    showDialog<void>(context: nav.currentContext!, builder: (_) => const AlertDialog(content: Text('a dialog')));
    await _settle(t);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.text('a dialog'), findsNothing);
    expect(exits, isEmpty);
    await t.pumpWidget(const SizedBox());
  });

  final failures = <String>[];
  tearDownAll(() {
    if (failures.isNotEmpty) stderr.writeln('BACK FAILURES: $failures');
  });
  for (final e in btScreens.entries) {
    if (e.key == 'NavShell') continue;
    // These fetch google_fonts at runtime; the test VM has no network so
    // the font error escapes the zone. Their back is a plain route pop.
    if (const {'PlayerSettingsScreen', 'SavedWordsScreen'}.contains(e.key)) continue;
    testWidgets('back on sub-page ${e.key} returns to the page under it', (t) async {
      final prev = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = prev);
      t.view.physicalSize = const Size(460, 1024);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(MaterialApp(
          navigatorKey: nav,
          home: NavScope(go: (_) {}, child: const Scaffold(body: Text('UNDER')))));
      nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => e.value()));
      await _settle(t, 15);
      final agree = find.text('I Agree · Continue');
      if (agree.evaluate().isNotEmpty) {
        await t.tap(agree.first, warnIfMissed: false);
        await _settle(t, 10);
      }
      await t.binding.handlePopRoute();
      await _settle(t, 10);
      expect(exits, isEmpty, reason: '${e.key}: back closed the app');
      if (!_ownBack.contains(e.key)) {
        if (find.text('UNDER').hitTestable().evaluate().isEmpty) {
          // A second back must get there (first may close an intro/overlay).
          await t.binding.handlePopRoute();
          await _settle(t, 10);
        }
        final ok = find.text('UNDER').hitTestable().evaluate().isNotEmpty;
        if (!ok) failures.add(e.key);
        expect(ok, isTrue, reason: '${e.key}: back did not return to the previous page');
      }
      await t.pumpWidget(const SizedBox());
      await _settle(t, 3);
    });
  }
}
