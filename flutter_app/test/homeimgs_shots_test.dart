// 390-wide shots of the three Normal home image cards (offers, Sound
// Library, eBooks) and a full-home scroll pass that must raise no overflow.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/screens/normal/home_v5.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/tokens.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _tag = Platform.environment['SHOT_TAG'] ?? 'after';
final _shots = Directory(Platform.environment['SHOT_DIR'] ?? '/workspace/team-plan/shots/homeimgs')..createSync(recursive: true);

Future<void> _png(WidgetTester t, Finder finder, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(finder);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('${_shots.path}/$_tag-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _card(WidgetTester t, String name, Widget child) async {
  t.view.physicalSize = const Size(390 * 3, 1000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.runAsync(() async {
    await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
  });
  await t.pumpWidget(MediaQuery(
    data: const MediaQueryData(size: Size(390, 1000), devicePixelRatio: 3, textScaler: TextScaler.noScaling, disableAnimations: true),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Scaffold(
        backgroundColor: NwsbColors.surface,
        body: Align(
          alignment: Alignment.topCenter,
          child: RepaintBoundary(key: const ValueKey('shot'), child: ColoredBox(color: NwsbColors.surface, child: SizedBox(width: 390, child: child))),
        ),
      ),
    ),
  ));
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
  await _png(t, find.byKey(const ValueKey('shot')), name);
  expect(t.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync())))).load();
      }
    }
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('offers card', (t) => _card(t, 'offers', V4StoreEarn(onStore: () {})));
  testWidgets('sound library card', (t) => _card(t, 'sound', V4SoundLibrary(onTap: () {})));
  testWidgets('ebooks shelf', (t) => _card(t, 'ebooks', V5Ebooks(onBrowse: () {})));

  testWidgets('full Normal home scroll raises no overflow', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), devicePixelRatio: 3, textScaler: TextScaler.noScaling, disableAnimations: true),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: NavScope(go: (_) {}, child: const HomeNormal()),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    final list = find.byType(ListView).first;
    for (var i = 0; i < 30; i++) {
      await t.drag(list, const Offset(0, -400));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(t.takeException(), isNull);
    }
  });
}
