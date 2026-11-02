/// The full Normal home, top to bottom, at 390px: white neumorphism only.
/// Run: flutter test test/normal_home_white_shots_test.dart --dart-define=RITUAL_OUT=/workspace/team-plan/shots/tm-white
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = String.fromEnvironment('RITUAL_OUT', defaultValue: '');

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

  testWidgets('normal home renders top to bottom (white neumorphism)', (t) async {
    const w = 390.0, h = 26000.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'DM Sans'),
          home: RepaintBoundary(key: key, child: NavScope(go: (_) {}, child: const HomeNormal()))),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      t.takeException();
    }
    await precacheAll(t);
    // Image audit: every asset once, none mirrored.
    final uses = <String, int>{};
    final mirrored = <String>[];
    String? nameOf(ImageProvider p) => switch (p) {
          AssetImage(:final assetName) => assetName,
          ExactAssetImage(:final assetName) => assetName,
          ResizeImage(:final imageProvider) => nameOf(imageProvider),
          _ => null,
        };
    final imgs = <(Element, ImageProvider)>[
      for (final e in find.byType(Image, skipOffstage: false).evaluate()) (e, (e.widget as Image).image),
      for (final e in find.byType(DecoratedBox, skipOffstage: false).evaluate())
        if ((e.widget as DecoratedBox).decoration case BoxDecoration(image: DecorationImage(image: final p))) (e, p),
    ];
    for (final (e, p) in imgs) {
      final n = nameOf(p);
      if (n == null || n.endsWith('hc-grain.webp')) continue;
      uses[n] = (uses[n] ?? 0) + 1;
      var flipped = false;
      e.visitAncestorElements((a) {
        final w = a.widget;
        if (w is Transform) {
          final m = w.transform;
          if (m.storage[0] < 0 || m.storage[5] < 0) flipped = true;
        }
        return a.widget is! HomeNormal;
      });
      if (flipped) mirrored.add(n);
    }
    final dupes = {for (final MapEntry(:key, :value) in uses.entries) if (value > 1) key: value};
    // ignore: avoid_print
    print('IMAGES ${uses.keys.toList()..sort()}');
    // ignore: avoid_print
    print('DUPES $dupes MIRRORED $mirrored');
    expect(mirrored, isEmpty, reason: 'mirrored images on the normal home');
    expect(dupes, isEmpty, reason: 'repeated images on the normal home');
    await t.pump(const Duration(milliseconds: 300));
    t.takeException();
    if (_out.isNotEmpty) {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final raw = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        // find the end of content: last row that is not the page colour
        final bg = raw.getUint32(((h - 2).toInt() * w.toInt() + 5) * 4);
        var end = h.toInt() - 1;
        while (end > 0) {
          var same = true;
          for (var x = 0; x < w.toInt(); x += 7) {
            if (raw.getUint32((end * w.toInt() + x) * 4) != bg) {
              same = false;
              break;
            }
          }
          if (!same) break;
          end--;
        }
        Directory(_out).createSync(recursive: true);
        const slice = 1400;
        for (var i = 0, y = 0; y < end; i++, y += slice) {
          final rec = ui.PictureRecorder();
          final c = Canvas(rec);
          final hh = (end - y + 1).clamp(1, slice).toDouble();
          c.drawImageRect(img, Rect.fromLTWH(0, y.toDouble(), w, hh), Rect.fromLTWH(0, 0, w, hh), Paint());
          final part = await rec.endRecording().toImage(w.toInt(), hh.toInt());
          final png = await part.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/home-${i.toString().padLeft(2, '0')}.png').writeAsBytesSync(png!.buffer.asUint8List());
        }
      });
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  });
}
