// slimgs shots: New releases, Picked for you, the Practice tab, and Sound
// Library, so the same per-word art can be compared side by side.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/normal/new_releases.dart';
import 'package:nowssb/screens/normal/picked_for_you.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/faint_film.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

final _shots = Directory('/workspace/team-plan/shots/slimgs')
  ..createSync(recursive: true);

final _day = DateTime(2026, 11, 17, 10);

Future<void> _png(WidgetTester t, Finder finder, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(finder);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('${_shots.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  SharedPreferences.setMockInitialValues({
    'nwsb_terms_hub': '1',
    'nwsb_player_guide_seen': true,
  });

  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    await loadDmSans();
    await loadRoboto();
    await loadMaterialIcons();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)
              ..addFont(Future.value(ByteData.sublistView(
                File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync(),
              ))))
            .load();
      }
    }
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(() {
    VideoPool.instance.debugDropAll();
    DayClock.clock = null;
  });

  Future<void> loadLib(WidgetTester t) async {
    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    expect(ContentStore.instance.library, isNotEmpty);
  }

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

  testWidgets('New releases', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await loadLib(t);
    await t.pumpWidget(card(NewReleasesCard(
      today: _day,
      onWord: _noopWord,
      onSeeAll: _noop,
    )));
    await t.pump();
    await _png(t, find.byKey(const ValueKey('shot')), 'new-releases');
    expect(t.takeException(), isNull);
  });

  testWidgets('Picked for you', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await loadLib(t);
    await t.pumpWidget(card(PickedForYouCard(
      today: _day,
      onWord: _noopWord,
      onSeeAll: _noop,
    )));
    await t.pump();
    await _png(t, find.byKey(const ValueKey('shot')), 'picked-for-you');
    expect(t.takeException(), isNull);
  });

  testWidgets('Practice tab', (t) async {
    const w = 390.0, h = 844.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    DayClock.clock = () => DateTime(2026, 11, 16, 22, 0);
    await loadLib(t);
    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(
        size: Size(w, h),
        devicePixelRatio: 2,
        disableAnimations: true,
        padding: EdgeInsets.only(top: 44, bottom: 24),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NwsbTheme.light,
        home: RepaintBoundary(
          key: ValueKey('practice-shot'),
          child: PracticeScreen(),
        ),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 80));
    expect(find.text('Night Restoration'), findsOneWidget);
    await _png(t, find.byKey(const ValueKey('practice-shot')), 'practice-tab');
    expect(t.takeException(), isNull);
  });

  testWidgets('Sound Library', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    addTearDown(() => FlutterError.onError = prev);
    await loadLib(t);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        devicePixelRatio: 2,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (c, child) => RepaintBoundary(
          key: const ValueKey('library-shot'),
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            child ?? const SizedBox(),
          ]),
        ),
        home: const SoundLibraryScreen(embedded: true),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    await _png(t, find.byKey(const ValueKey('library-shot')), 'sound-library');
  });
}

void _noop() {}
void _noopWord(Word word) {}
