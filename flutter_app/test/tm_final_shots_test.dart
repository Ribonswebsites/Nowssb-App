/// tm-final: full Normal + Zen homes at 390, and every normal hero card at
/// 320 and 390. Run with --dart-define=RITUAL_OUT=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/normal/calm_hero.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = String.fromEnvironment('RITUAL_OUT', defaultValue: '');

Future<void> _pumpHome(WidgetTester t, Widget home, double w, double h, GlobalKey key) async {
  t.view.physicalSize = Size(w * 2, h * 2);
  t.view.devicePixelRatio = 2;
  await t.pumpWidget(MediaQuery(
    data: MediaQueryData(size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'DM Sans'),
        home: RepaintBoundary(key: key, child: NavScope(go: (_) {}, child: home))),
  ));
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
    final ex = t.takeException(); if (ex != null) debugPrint('TKEX $ex');
  }
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 300));
  final ex2 = t.takeException(); if (ex2 != null) debugPrint('TKEX $ex2');
}

Future<ui.Image> _grab(WidgetTester t, GlobalKey key) async =>
    (await t.runAsync(() => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 1)))!;

Future<void> _save(WidgetTester t, ui.Image img, Rect r, String name) async {
  await t.runAsync(() async {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawImageRect(img, r, Rect.fromLTWH(0, 0, r.width, r.height), Paint());
    final part = await rec.endRecording().toImage(r.width.ceil(), r.height.ceil());
    final png = await part.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')..createSync(recursive: true)..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _full(WidgetTester t, Widget home, String prefix) async {
  const w = 390.0, h = 26000.0;
  final key = GlobalKey();
  await _pumpHome(t, home, w, h, key);
  final img = await _grab(t, key);
  final raw = (await t.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  final bg = raw.getUint32(((h - 2).toInt() * w.toInt() + 5) * 4);
  var end = h.toInt() - 1;
  while (end > 0) {
    var same = true;
    for (var x = 0; x < w.toInt(); x += 7) {
      if (raw.getUint32((end * w.toInt() + x) * 4) != bg) { same = false; break; }
    }
    if (!same) break;
    end--;
  }
  const slice = 1400;
  for (var i = 0, y = 0; y < end; i++, y += slice) {
    await _save(t, img, Rect.fromLTWH(0, y.toDouble(), w, (end - y + 1).clamp(1, slice).toDouble()), '$prefix-${i.toString().padLeft(2, '0')}');
  }
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(minutes: 2));
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    ByteData f(String p) => ByteData.sublistView(File(p).readAsBytesSync());
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'monospace', 'Roboto']) {
        await (FontLoader(fam)..addFont(Future.value(f('assets/fonts/NotoSans-PIE.ttf')))).load();
      }
    }
  });
  tearDown(() {});

  testWidgets('normal full', (t) async { await _full(t, const HomeNormal(), 'normal'); addTearDown(t.view.reset); }, skip: _out.isEmpty);
  testWidgets('zen full', (t) async { await _full(t, const HomeFashion(), 'zen'); addTearDown(t.view.reset); }, skip: _out.isEmpty);

  for (final w in [320.0, 390.0]) {
    testWidgets('hero cards @$w', (t) async {
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await _pumpHome(t, const HomeNormal(), w, 3000, key);
      final hero = find.byKey(const ValueKey('hero-mixed'));
      final cs = t.state<HeroCarouselState>(hero);
      final r = t.getRect(hero);
      for (var i = 0; i < 7; i++) {
        cs.jumpTo(i);
        for (var k = 0; k < 6; k++) { await t.pump(const Duration(milliseconds: 100)); }
        await precacheAll(t);
        await t.pump(const Duration(milliseconds: 100));
        await _save(t, await _grab(t, key), r, 'hero-${w.toInt()}-$i');
        if (i == 1 && find.byKey(const ValueKey('hero-depth')).evaluate().isNotEmpty) {
          for (var d = 1; d < 3; d++) {
            await t.drag(find.byKey(const ValueKey('hero-depth')), const Offset(0, -80));
            for (var k = 0; k < 10; k++) { await t.pump(const Duration(milliseconds: 100)); }
            await precacheAll(t);
            await t.pump(const Duration(milliseconds: 100));
            await _save(t, await _grab(t, key), r, 'hero-${w.toInt()}-1-depth$d');
          }
        }
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
    }, skip: _out.isEmpty);
  }
}
