// B028: the Fashion hero's foot labels keep at least 80% of their size and
// hold 4.5:1 against the pixels behind them — on the real film art and on a
// bright flat-grey fallback alike.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/hero.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _labels = ['EXPLORE', 'APP GUIDE', 'LEARN'];

double _lum(int r, int g, int b) {
  double c(int v) {
    final s = v / 255;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }
  return 0.2126 * c(r) + 0.7152 * c(g) + 0.0722 * c(b);
}

/// White text against the BRIGHTEST pixel in a 2–5px ring around the label.
double _contrast(ui.Image img, ByteData px, Rect r) {
  var worst = 0.0;
  final outer = r.inflate(5), inner = r.inflate(2);
  for (var y = (outer.top * 3).floor(); y < outer.bottom * 3; y++) {
    for (var x = (outer.left * 3).floor(); x < outer.right * 3; x++) {
      if (inner.contains(Offset(x / 3, y / 3))) continue;
      final i = (y * img.width + x) * 4;
      worst = math.max(worst, _lum(px.getUint8(i), px.getUint8(i + 1), px.getUint8(i + 2)));
    }
  }
  return 1.05 / (worst + 0.05);
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  // fallback: the hero on a flat grey brighter than any the film gives.
  for (final art in [false, true]) {
    for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
      final what = art ? 'on the film art' : 'on flat grey';
      testWidgets('foot labels fit and hold 4.5:1 $what at ${w.toInt()} x$scale', (t) async {
        t.view.physicalSize = Size(w * 3, 1000 * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final root = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
          key: root,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'DM Sans'),
            home: MediaQuery(
              data: MediaQueryData(size: Size(w, 1000), textScaler: TextScaler.linear(scale)),
              child: art
                  ? NavScope(go: (_) {}, child: const HomeFashion())
                  : const Scaffold(
                      backgroundColor: Color(0xFF999999),
                      body: SingleChildScrollView(child: FashionHero()),
                    ),
            ),
          ),
        ));
        final errors = <String>[];
        // Pump until every image on screen (TV bezel, posters, film still) decodes.
        for (var k = 0; k < 4; k++) {
          await t.pump(const Duration(milliseconds: 200));
          await t.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
        }
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 200));
          final e = t.takeException();
          if (e != null) errors.add('$e');
        }
        if (homeFontsReady) expect(errors.where((e) => e.contains('overflowed')), isEmpty);
        for (final label in ['APP GUIDE', 'EXPLORE']) {
          final f = find.text(label).first;
          final ratio = t.getRect(f).width / t.getSize(f).width;
          expect(ratio, greaterThanOrEqualTo(0.8), reason: '$label drawn at ${(ratio * 100).round()}%');
        }
        final img = (await t.runAsync(() =>
            (root.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 3)))!;
        final px = (await t.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
        for (final l in _labels) {
          final c = _contrast(img, px, t.getRect(find.text(l).first));
          // ignore: avoid_print
          print('B028 contrast $what ${w.toInt()} $l ${c.toStringAsFixed(2)}:1');
          expect(c, greaterThanOrEqualTo(4.5), reason: '$l $what at ${c.toStringAsFixed(2)}:1');
        }
        final name = Platform.environment['SHOT'];
        if (art && name != null) {
          final hero = t.getRect(find.byType(FashionHero));
          await t.runAsync(() async {
            final rec = ui.PictureRecorder();
            final src = Rect.fromLTRB(0, hero.top * 3, w * 3, hero.bottom * 3);
            Canvas(rec).drawImageRect(img, src, Offset.zero & src.size, Paint());
            final out = await rec.endRecording().toImage(src.width.round(), src.height.round());
            final png = await out.toByteData(format: ui.ImageByteFormat.png);
            File('/workspace/bugfix-shots/$name-${w.toInt()}.png').writeAsBytesSync(png!.buffer.asUint8List());
          });
        }
      }, skip: !homeFontsReady);
    }
  }
}
