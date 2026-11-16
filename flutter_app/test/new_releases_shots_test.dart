// 390-wide shots of the New releases card, alone and on the Normal home.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/normal/new_releases.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/tokens.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _shots = Directory('/workspace/team-plan/shots/newrel')
  ..createSync(recursive: true);

Future<void> _png(WidgetTester t, Finder finder, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(finder);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('${_shots.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
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
        await (FontLoader(fam)
              ..addFont(Future.value(ByteData.sublistView(
                File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync(),
              ))))
            .load();
      }
    }
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('card crop at 390', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    expect(ContentStore.instance.library, isNotEmpty);

    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 900),
        devicePixelRatio: 3,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: const Scaffold(
          backgroundColor: NwsbColors.surface,
          body: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: ValueKey('shot'),
              child: ColoredBox(
                color: NwsbColors.surface,
                child: NewReleasesCard(
                  onWord: _noopWord,
                  onSeeAll: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.pump();
    await _png(t, find.byKey(const ValueKey('shot')), 'card');
    expect(find.text('New releases'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Normal home in context at 390', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });

    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(
        size: Size(390, 844),
        devicePixelRatio: 3,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: RepaintBoundary(
          key: ValueKey('home-shot'),
          child: NavScope(go: _noopGo, child: HomeNormal()),
        ),
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }

    final list = find.byType(ListView).first;
    final streak = find.byKey(const ValueKey('v4-streak'));
    final card = find.byKey(const ValueKey('new-releases'));
    for (var i = 0; i < 24 && streak.evaluate().isEmpty; i++) {
      await t.drag(list, const Offset(0, -450));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(streak, findsOneWidget);
    expect(card, findsOneWidget);
    // Pin the streak card just under the header so the New releases
    // row that sits under it is in the same frame.
    await t.ensureVisible(streak);
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    await _png(t, find.byKey(const ValueKey('home-shot')), 'home');
    expect(find.text('New releases'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

void _noop() {}
void _noopWord(Word word) {}

void _noopGo(int _) {}
