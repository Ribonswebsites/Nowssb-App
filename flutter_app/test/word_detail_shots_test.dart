// Full-page Word detail shots for VATA and PRANA at 390 wide, real fonts.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = '/workspace/team-plan/shots/worddetail';

final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester t, String name) async {
  try {
    await precacheAll(t);
  } catch (_) {}
  await _settle(t, 4);
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
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
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('full-page VATA and PRANA', (t) async {
    const w = 390.0, h = 1800.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    final library = ContentStore.instance.library;
    expect(library, isNotEmpty);

    for (final name in ['VATA', 'PRANA']) {
      final word = library.firstWhere(
        (w) => w.word.toUpperCase() == name,
        orElse: () => throw StateError('$name missing from library'),
      );
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
            child: WordDetail(word: word),
          ),
        ),
      ));
      await _settle(t, 14);
      await precacheAll(t);
      await _settle(t, 4);
      expect(find.text(name), findsWidgets);
      expect(find.text('How to say it'), findsOneWidget);
      expect(find.text('Meaning and use'), findsOneWidget);
      await _shot(t, name.toLowerCase());
    }

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
