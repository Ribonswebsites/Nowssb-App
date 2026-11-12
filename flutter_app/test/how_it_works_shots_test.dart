// 390-wide shots of the normal home without the Zen Plus card, and of
// each How it works pop-up step.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/concept/normal/footer.dart';
import 'package:nowssb/screens/normal/header_actions_sheet.dart';
import 'package:nowssb/widgets/how_it_works_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/howitworks';

Future<void> _writePng(ui.Image img, String name) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(_out)..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<ui.Image> _crop(ui.Image src, int top, int height) async {
  if (top < 0) top = 0;
  if (top + height > src.height) height = src.height - top;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.drawImageRect(
    src,
    ui.Rect.fromLTWH(
        0, top.toDouble(), src.width.toDouble(), height.toDouble()),
    ui.Rect.fromLTWH(0, 0, src.width.toDouble(), height.toDouble()),
    ui.Paint(),
  );
  return rec.endRecording().toImage(src.width, height);
}

int _yellowRows(ByteData pixels, int width, int height, {int minPerRow = 40}) {
  var rows = 0;
  for (var y = 0; y < height; y++) {
    var n = 0;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final r = pixels.getUint8(i);
      final g = pixels.getUint8(i + 1);
      final b = pixels.getUint8(i + 2);
      final a = pixels.getUint8(i + 3);
      if (a > 200 && r > 200 && g > 180 && b < 80) n++;
    }
    if (n >= minPerRow) rows++;
  }
  return rows;
}

Future<void> _write(WidgetTester t, Finder f, String name,
    {bool checkYellow = false}) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(f);
    final img = await b.toImage(pixelRatio: 2);
    if (checkYellow) {
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rows = _yellowRows(bd!, img.width, img.height);
      expect(rows, 0, reason: '$name has $rows rows of yellow underlines');
    }
    await _writePng(img, name);
  });
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  tearDown(() {
    HowItWorksCard.debugFrame = null;
  });

  testWidgets('home top and bottom without the Zen Plus card', (t) async {
    const w = 390.0, h = 20000.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const key = ValueKey('howitworks-home-shot');
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: const RepaintBoundary(
          key: key,
          child: NavScope(go: _noop, child: HomeNormal()),
        ),
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      t.takeException();
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(NFashionPlusEntry, skipOffstage: false), findsNothing);
    expect(find.text('Enter Zen Plus', skipOffstage: false), findsNothing);
    expect(find.text('Zen Plus', skipOffstage: false), findsNothing);
    expect(find.text('Enter now', skipOffstage: false), findsNothing);
    expect(find.text('HOW IT WORKS', skipOffstage: false), findsNothing);
    expect(find.byType(NFooter, skipOffstage: false), findsOneWidget);
    await t.runAsync(() async {
      final b = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final img = await b.toImage(pixelRatio: 2);
      const slice = 1688; // 844 logical px at pixelRatio 2
      await _writePng(await _crop(img, 0, slice), 'home_top');
      final footer = t.getRect(find.byType(NFooter).last);
      var bottom = (footer.bottom * 2).round();
      if (bottom < slice) bottom = slice;
      if (bottom > img.height) bottom = img.height;
      await _writePng(await _crop(img, bottom - slice, slice), 'home_bottom');
    });
  });

  for (var i = 0; i < 5; i++) {
    testWidgets('pop-up step ${i + 1}', (t) async {
      const w = 390.0, h = 844.0;
      t.view.physicalSize = const Size(w * 2, h * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      HowItWorksCard.debugFrame =
          (clip) => AssetImage(clip.replaceAll('.mp4', '-poster.webp'));
      const key = ValueKey('howitworks-step-shot');
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(
            size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Align(
                  alignment: Alignment.center,
                  child: HowItWorksCard(
                    startAt: i,
                    autoRotate: false,
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await t.pump();
      await precacheAll(t);
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      await _write(t, find.byKey(key), 'step_${i + 1}', checkYellow: true);
    });
  }

  testWidgets('header actions sheet without a Zen home switch', (t) async {
    const w = 390.0, h = 844.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const key = ValueKey('howitworks-header-shot');
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: const ColoredBox(
          color: Color(0xFF1A1A1A),
          child: RepaintBoundary(
            key: key,
            child: HeaderActionsSheet(
              glassMode: false,
              onGlassToggle: _noop2,
              onNotifications: _noop2,
            ),
          ),
        ),
      ),
    ));
    await t.pump();
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
    expect(find.text('Zen home'), findsNothing);
    expect(find.text('Zen'), findsNothing);
    await _write(t, find.byKey(key), 'header_actions');
  });
}

void _noop(int _) {}
void _noop2() {}
