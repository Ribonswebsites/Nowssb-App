// 390-wide shots of Settings choice rows, each picker sheet, and the
// confirmation after selecting an option.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = '/workspace/team-plan/shots/pickers';

final _key = GlobalKey();

Future<void> _shot(WidgetTester t, String name) async {
  await t.pump(const Duration(milliseconds: 80));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _pumpSettings(WidgetTester t) async {
  const size = Size(390, 844);
  t.view.physicalSize = Size(size.width * 2, size.height * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: size, disableAnimations: true),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        debugShowCheckedModeBanner: false,
        builder: (c, child) => RepaintBoundary(
          key: _key,
          child: child ?? const SizedBox(),
        ),
        home: const AppSettingsScreen(),
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _openRow(WidgetTester t, String title) async {
  final row = find.text(title);
  await t.ensureVisible(row);
  await t.tap(row);
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _clearToasts(WidgetTester t) async {
  final e = find.byType(AppSettingsScreen);
  if (e.evaluate().isEmpty) return;
  ScaffoldMessenger.of(t.element(e)).clearSnackBars();
  await t.pump();
  await t.pump(const Duration(milliseconds: 200));
}

Future<void> _scrollToTop(WidgetTester t) async {
  final f = find.byType(Scrollable);
  if (f.evaluate().isEmpty) return;
  final state = t.state<ScrollableState>(f.first);
  state.position.jumpTo(0);
  await t.pump();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setUpHomeRender();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.instance.setFashionHome(false);
    await Settings.instance.setFashionPlus(true);
    await Settings.instance.setNavConfig(color: 'black');
  });

  testWidgets('settings rows and picker sheets', (t) async {
    await _pumpSettings(t);
    await _shot(t, 'settings-look-and-sound');

    await t.ensureVisible(find.text('Nav Bar'));
    await t.pump();
    await _shot(t, 'settings-look-choices');

    await _openRow(t, 'Home');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await _shot(t, 'picker-home');
    await t.tap(find.byKey(const ValueKey('settings-choice-NowssB home')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Home set to NowssB home'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    await _shot(t, 'confirm-home-nowssb');

    await _openRow(t, 'Zen Plus');
    await _shot(t, 'picker-zenplus');
    await t.tap(find.byKey(const ValueKey('settings-choice-Still')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Zen Plus set to Still'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    await _shot(t, 'confirm-zenplus-still');

    await _openRow(t, 'Nav Bar');
    await _shot(t, 'picker-navbar');
    await t.tap(find.byKey(const ValueKey('settings-choice-Glass')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Nav Bar set to Glass'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    await _shot(t, 'confirm-navbar-glass');

    await _clearToasts(t);
    await _scrollToTop(t);
    await t.tap(find.text('This phone'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _shot(t, 'settings-this-phone');
    await _openRow(t, 'Keep Screen Awake');
    await _shot(t, 'picker-screen-awake');
    await t.tap(find.byKey(const ValueKey('settings-choice-Can sleep')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Keep Screen Awake set to Can sleep'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    await _shot(t, 'confirm-screen-can-sleep');

    await _clearToasts(t);
    await _scrollToTop(t);
    await t.tap(find.text('Account'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _shot(t, 'settings-account');
    await _openRow(t, 'Appear in Discover');
    await _shot(t, 'picker-discover');
  });
}
