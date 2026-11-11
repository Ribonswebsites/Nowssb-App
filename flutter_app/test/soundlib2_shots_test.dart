// Currently Playing chip shots at 390.
// flutter test test/soundlib2_shots_test.dart --dart-define=SL2_SHOTS=/out
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/currently_playing_album.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'currently_playing_hero_test.dart' show FakeTransport;
import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('SL2_SHOTS');

void main() {
  SharedPreferences.setMockInitialValues(
      {'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
  });
  final key = GlobalKey();

  Future<void> snap(WidgetTester t, String name) async {
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(b!.buffer.asUint8List());
    });
  }

  Widget shell(Widget home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (c, ch) => RepaintBoundary(
            key: key,
            child: Stack(children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black)),
              const Positioned.fill(child: FaintFilm()),
              ch ?? const SizedBox(),
            ])),
        home: home,
      );

  testWidgets('currently playing chip, full page', (t) async {
    if (_out.isEmpty) return;
    t.view.physicalSize = const Size(390, 1500);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    addTearDown(() => FlutterError.onError = prev);
    await t.runAsync(() => ContentStore.instance
        .start()
        .timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pumpWidget(shell(const SoundLibraryScreen(embedded: true)));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.text('Currently Playing').first);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    }
    await snap(t, 'currently-playing-390');
    await t.pumpWidget(const SizedBox());
    VideoPool.instance.debugDropAll();
  });

  for (final playing in [false, true]) {
    testWidgets('hero ${playing ? 'playing' : 'paused'}', (t) async {
      if (_out.isEmpty) return;
      t.view.physicalSize = const Size(390, 330);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {};
      addTearDown(() => FlutterError.onError = prev);
      await t.runAsync(() => ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {}));
      final words = ContentStore.instance.library.take(6).toList();
      final p = FakeTransport(active: true, playing: playing, word: words[0]);
      await t.pumpWidget(shell(Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: CurrentlyPlayingHero(
            words: words,
            art: (_) => 'assets/icons/nwsb-coin.webp',
            onPlay: (_) {},
            onOpen: (_) {},
            onDownload: () {},
            player: p,
          ),
        ),
      )));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 400));
      }
      await snap(t, 'hero-${playing ? 'playing' : 'paused'}-390');
      await t.pumpWidget(const SizedBox());
    });
  }
}
