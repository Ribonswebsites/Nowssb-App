// 390-wide shots of the Practice tab with each session word selected,
// plus the This session / Also today lists.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/theme/theme.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = '/workspace/team-plan/shots/practiceimg';

const _words = ['SOMA', 'PITTA', 'KAPHA', 'CHANDRA'];

final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _writePng(ui.Image img, String name) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(_out)..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<ui.Image> _crop(ui.Image src, int top, int height) async {
  if (top < 0) top = 0;
  if (top + height > src.height) height = src.height - top;
  if (height <= 0) height = src.height;
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

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(_key));
    final img = await b.toImage(pixelRatio: 2);
    await _writePng(img, name);
  });
}

Finder _pill(String word) => find.byKey(ValueKey('practice-chip-$word'), skipOffstage: false);

void _jumpPageTo(WidgetTester t, double offset) {
  for (final e in find.byType(Scrollable).evaluate()) {
    final w = e.widget as Scrollable;
    if (w.axis == Axis.vertical) {
      t.state<ScrollableState>(find.byWidget(w)).position.jumpTo(offset);
      return;
    }
  }
}

Future<void> _selectChip(WidgetTester t, String word) async {
  final chip = _pill(word);
  final row = find.byKey(const ValueKey('practice-chips'));
  for (var i = 0; i < 6; i++) {
    final box = t.getRect(chip);
    if (box.left >= 8 && box.right <= 390 - 8) break;
    await t.drag(row, Offset(box.left < 8 ? 90 : -90, 0));
    await t.pump();
  }
  await t.tap(chip);
}

void main() {
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
  });

  setUp(() {
    DayClock.clock = () => DateTime(2026, 11, 16, 22, 0);
  });
  tearDown(() {
    DayClock.clock = null;
    VideoPool.instance.debugDropAll();
  });

  testWidgets('Practice tab covers for each selected word, plus the lists',
      (t) async {
    const w = 390.0, h = 844.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    expect(ContentStore.instance.library, isNotEmpty);

    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(w, h),
        devicePixelRatio: 2,
        disableAnimations: true,
        padding: EdgeInsets.only(top: 44, bottom: 24),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NwsbTheme.light,
        home: RepaintBoundary(
          key: _key,
          child: const PracticeScreen(),
        ),
      ),
    ));
    await _settle(t, 12);
    await precacheAll(t);
    await _settle(t, 6);

    expect(find.text('Night Restoration'), findsOneWidget);
    expect(find.text("Today's session"), findsOneWidget);

    for (final word in _words) {
      _jumpPageTo(t, 0);
      await t.pump();
      await _selectChip(t, word);
      _jumpPageTo(t, 0);
      await _settle(t, 4);
      await precacheAll(t);
      await _settle(t, 3);
      expect(t.getRect(find.text('Night Restoration')).top, lessThan(80));
      expect(find.text('Start Player'), findsOneWidget);
      await _shot(t, 'practice-${word.toLowerCase()}');
    }

    // This session list, pulled up under the title so every row is in frame.
    final pane = find.byKey(const ValueKey('practice-session-pane'));
    await t.ensureVisible(pane);
    await _settle(t, 4);
    await precacheAll(t);
    await _settle(t, 3);
    await _shot(t, 'practice-session-list');

    // A taller full-page render so Also today rows are in the same frame.
    const tall = 1600.0;
    t.view.physicalSize = const Size(w * 2, tall * 2);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(w, tall),
        devicePixelRatio: 2,
        disableAnimations: true,
        padding: EdgeInsets.only(top: 44, bottom: 24),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NwsbTheme.light,
        home: RepaintBoundary(
          key: _key,
          child: PracticeScreen(key: UniqueKey()),
        ),
      ),
    ));
    await _settle(t, 12);
    _jumpPageTo(t, 0);
    await t.pump();
    await precacheAll(t);
    await _settle(t, 6);
    expect(t.getRect(find.text('Night Restoration')).top, lessThan(80));
    await t.runAsync(() async {
      final b = t.renderObject<RenderRepaintBoundary>(find.byKey(_key));
      final img = await b.toImage(pixelRatio: 2);
      await _writePng(img, 'practice-full');
      // Crop just the This session + Also today block if present.
      final session = t.getRect(pane);
      final also = find.byKey(const ValueKey('practice-also-pane'));
      final bottom = also.evaluate().isEmpty
          ? session.bottom
          : t.getRect(also).bottom;
      final topPx = (session.top * 2).floor() - 16;
      final heightPx = ((bottom - session.top) * 2).ceil() + 32;
      await _writePng(await _crop(img, topPx, heightPx), 'practice-lists');
    });
  });
}
