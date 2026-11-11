import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/fashion_bg_dim.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/golden_breath.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry_live.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Widget _app(Widget child, {double scale = 1, bool reduced = false}) => MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: reduced),
            child: Scaffold(backgroundColor: const Color(0xFFEDEFF3), body: SingleChildScrollView(child: RepaintBoundary(key: const ValueKey('shot'), child: child))),
          )),
    );

Future<void> _size(WidgetTester t, double w) async {
  t.view.physicalSize = Size(w * 3, 900 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() => SharedPreferences.setMockInitialValues({FashionBgDim.prefKey: 0.7}));

  testWidgets('tap opens the Fashion Plus home (Settings.fashionHome)', (t) async {
    await _size(t, 390);
    await Settings.instance.setFashionHome(false);
    await t.pumpWidget(_app(const NFashionPlusEntryLive()));
    await t.tap(find.text('Zen Plus'));
    await t.pump(const Duration(milliseconds: 700));
    expect(Settings.instance.fashionHome, isTrue);
    await Settings.instance.setFashionHome(false);
  });

  testWidgets('bgDim reflects the stored ZenBgDim and updates live', (t) async {
    await FashionBgDim.instance.load();
    await t.pumpWidget(_app(const NFashionPlusEntryLive()));
    double dim() => t.widget<NFashionPlusEntry>(find.byType(NFashionPlusEntry)).bgDim!;
    expect(dim(), closeTo(0.7, 1e-9));
    await FashionBgDim.instance.set(0.2, persist: false);
    await t.pump();
    expect(dim(), closeTo(0.2, 1e-9));
    await FashionBgDim.instance.set(FashionBgDim.defaultDim, persist: false);
  });

  for (final (w, s) in const [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('no overflow / ellipsis / mid-word break at $w@$s', (t) async {
      await _size(t, w);
      await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: .45), scale: s));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject! as RenderParagraph;
        expect(r.didExceedMaxLines, isFalse);
        expect(r.overflow, isNot(TextOverflow.ellipsis));
        if (!homeFontsReady) continue;
        final text = r.text.toPlainText();
        // every line break must fall on a space
        final tp = TextPainter(text: r.text, textDirection: TextDirection.ltr, textScaler: r.textScaler)
          ..layout(maxWidth: r.constraints.maxWidth);
        var off = 0;
        while (off < text.length) {
          final end = tp.getLineBoundary(TextPosition(offset: off)).end;
          if (end <= off) break;
          if (end < text.length) {
            final ok = text[end - 1] == ' ' || text[end] == ' ' || text[end - 1] == '\n';
            expect(ok, isTrue, reason: 'mid-word break in "$text" at $end');
          }
          off = end;
          while (off < text.length && text[off] == ' ') {
            off++;
          }
        }
        tp.dispose();
      }
    });
  }

  testWidgets('reduced motion: tap enters at once', (t) async {
    var hit = 0;
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () => hit++), reduced: true));
    await t.tap(find.text('Zen Plus'));
    await t.pump();
    expect(hit, 1);
  });

  testWidgets('Zen Plus is a black reel of five people: no terrace photo, no old clip', (t) async {
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: .7), reduced: true));
    expect(find.byKey(const ValueKey('zen-plus-reel')), findsOneWidget);
    expect(find.byType(GoldenBreathClip), findsNothing);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('zen-thumb-$i')), findsOneWidget);
    }
    expect(File('assets/home/hx/zenplus-terrace.webp').existsSync(), isFalse);
    for (final k in ['man-black', 'man-asian', 'woman-indian', 'woman-silver', 'man-latino']) {
      expect(File('assets/video/zp-$k.mp4').existsSync(), isTrue, reason: k);
      expect(File('assets/video/zp-$k-poster.webp').existsSync(), isTrue, reason: k);
    }
  });

  testWidgets('reel moves on every 5 s, holds under a finger, resumes 5 s after it lifts', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {})));
    expect(find.text('01 / 05'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(find.text('01 / 05'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('02 / 05'), findsOneWidget);
    // a finger holds it
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('zen-plus-well'))));
    await t.pump(const Duration(seconds: 8));
    expect(find.text('02 / 05'), findsOneWidget);
    await g.up();
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(const Duration(seconds: 4));
    expect(find.text('02 / 05'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('03 / 05'), findsOneWidget);
    // a thumbnail jumps to its person
    await t.tap(find.byKey(const ValueKey('zen-thumb-0')));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('01 / 05'), findsOneWidget);
  });

  for (final (name, w, s) in const [('390', 390.0, 1.0), ('320-1.3', 320.0, 1.3)]) {
    for (final d in const [45, 70]) {
      testWidgets('shot $name dim$d', (t) async {
      await _size(t, w);
      await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: d / 100), scale: s));
      await precacheAll(t);
      await t.pump(const Duration(milliseconds: 300));
      final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      await t.runAsync(() async {
        final img = await b.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ImageByteFormat.png);
        // Screenshots are optional: only written where the shots folder exists.
        final dir = Directory('/workspace/team-plan/shots');
        if (dir.existsSync()) {
          File('${dir.path}/fpentry-build-$name-dim$d.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      });
    });
    }
  }
}
