// Full Sound Library page shots at 390.
// flutter test test/soundlib_shots_test.dart --dart-define=SL_SHOTS=/out
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/widgets/sound_glass.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('SL_SHOTS');

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
  });
  final key = GlobalKey();
  testWidgets('sound library page 390', (t) async {
    if (_out.isEmpty) return;
    t.view.physicalSize = const Size(390, 6200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // The box has no real fonts, so older sections overflow in the test font.
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    addTearDown(() => FlutterError.onError = prev);
    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (c, child) => RepaintBoundary(
          key: key,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            child ?? const SizedBox(),
          ])),
      home: const SoundLibraryScreen(embedded: true),
    ));
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
          '$_out/${const String.fromEnvironment('SL_NAME', defaultValue: 'page')}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(b!.buffer.asUint8List());
    });
    // Where each glass section sits, so the shots can be cropped per style.
    final rects = <String, List<double>>{};
    for (final e in find.byType(GlassSection).evaluate()) {
      final w = e.widget as GlassSection;
      final r = (e.renderObject! as RenderBox).localToGlobal(Offset.zero) &
          (e.renderObject! as RenderBox).size;
      rects[w.title] = [r.left, r.top, r.width, r.height];
    }
    File('$_out/rects.json').writeAsStringSync(jsonEncode(rects));
    debugPrint(
        'words=${ContentStore.instance.library.length} meanings=${ContentStore.instance.meanings.length}');
  });

  Future<void> shotHost(
      WidgetTester t, Widget child, String name, double h) async {
    t.view.physicalSize = Size(390, h);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (c, ch) => RepaintBoundary(
          key: key,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            ch ?? const SizedBox(),
          ])),
      home: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(child: child)),
    ));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
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

  testWidgets('A page two, B playing', (t) async {
    if (_out.isEmpty) return;
    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    final words = ContentStore.instance.library.take(12).toList();
    final ledger = SoundArtLedger();
    final picks = [
      for (final w in words) SlPick(word: w, art: ledger.pick('x:${w.word}'))
    ];
    final fake = _Playing(words[2]);
    await shotHost(
        t,
        GlassSection(
          title: 'Trending songs for you',
          subline: 'Pick up where you left off',
          trailing: GlassPill(label: 'Play all', onTap: () {}),
          child: GlassNowPlayingGrid(
              picks: picks,
              onPlay: (_) {},
              headerArt: (w) => ledger.pick('np:${w.word}'),
              player: fake),
        ),
        'style-B-now-playing-390',
        560);
    await t.pumpWidget(const SizedBox());
    await shotHost(
        t,
        GlassSection(
          title: 'Quick picks',
          subline: 'Tap to play · hold to open',
          trailing: GlassPill(label: 'Play all', onTap: () {}),
          child: GlassQuickGrid(
            picks: picks,
            onPlay: (_) {},
            chips: const ['All', 'Practised', 'New'],
            matches: (c, p) => true,
            player: _Playing(words[1]),
          ),
        ),
        'style-A-quick-grid-390',
        470);
    await t.drag(find.byType(PageView), const Offset(-380, 0));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/style-A-quick-grid-page2-390.png')
          .writeAsBytesSync(b!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
  });
}

class _Playing extends ChangeNotifier implements SlPlayer {
  _Playing(this.word);
  @override
  final Word? word;
  @override
  bool get active => true;
  @override
  bool get playing => true;
  @override
  Future<void> toggle() async {}
}
