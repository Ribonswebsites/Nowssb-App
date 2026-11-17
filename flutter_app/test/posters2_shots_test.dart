// posters2 shots: New releases on two dates, Picked for you, and the
// Normal home showing both.
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
import 'package:nowssb/screens/normal/picked_for_you.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/tokens.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _shots = Directory('/workspace/team-plan/shots/posters2')
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


  Widget card(Widget child) => MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 900),
          devicePixelRatio: 3,
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: Scaffold(
            backgroundColor: NwsbColors.surface,
            body: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const ValueKey('shot'),
                child: ColoredBox(color: NwsbColors.surface, child: child),
              ),
            ),
          ),
        ),
      );

  Future<void> loadLib(WidgetTester t) async {
    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    expect(ContentStore.instance.library, isNotEmpty);
  }

  for (final (date, tag) in [
    (DateTime(2026, 11, 17, 10), 'newrel-2026-11-17'),
    (DateTime(2026, 11, 18, 10), 'newrel-2026-11-18'),
  ]) {
    testWidgets('New releases on $tag', (t) async {
      t.view.physicalSize = const Size(390 * 3, 900 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await loadLib(t);
      await t.pumpWidget(card(NewReleasesCard(
        today: date,
        onWord: _noopWord,
        onSeeAll: _noop,
      )));
      await t.pump();
      await _png(t, find.byKey(const ValueKey('shot')), tag);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Picked for you', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await loadLib(t);
    await t.pumpWidget(card(PickedForYouCard(
      today: DateTime(2026, 11, 17, 10),
      onWord: _noopWord,
      onSeeAll: _noop,
    )));
    await t.pump();
    await _png(t, find.byKey(const ValueKey('shot')), 'picked-2026-11-17');
    expect(t.takeException(), isNull);
  });

  for (final (key, name, h) in [
    ('new-releases', 'home-newrel', 844.0),
    ('picked-for-you', 'home-picked', 844.0),
    ('new-releases', 'home-both', 2200.0),
  ]) {
    testWidgets('Normal home $name', (t) async {
      t.view.physicalSize = Size(390 * 3, h * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await loadLib(t);
      await t.pumpWidget(MediaQuery(
        data: MediaQueryData(
          size: Size(390, h),
          devicePixelRatio: 3,
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
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
      final target = find.byKey(ValueKey(key));
      for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
        await t.drag(list, const Offset(0, -400));
        await t.pump();
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(target, findsOneWidget);
      if (name == 'home-both') {
        await t.ensureVisible(find.byKey(const ValueKey('v4-streak')));
        await t.pump();
        // Make sure the lower card is laid out in this frame too.
        expect(find.byKey(const ValueKey('picked-for-you')), findsOneWidget);
      } else {
        await t.ensureVisible(target);
        await t.pump();
        await t.drag(list, const Offset(0, 160));
        await t.pump();
      }
      await t.pump(const Duration(milliseconds: 80));
      await _png(t, find.byKey(const ValueKey('home-shot')), name);
      expect(t.takeException(), isNull);
    });
  }
}

void _noop() {}
void _noopWord(Word word) {}

void _noopGo(int _) {}
