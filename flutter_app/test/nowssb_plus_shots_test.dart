// 390- and 360-wide shots of the reinvented NowssB Plus intro, and the
// page underneath after Enter.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/nowssbplus';

Future<void> _writePng(ui.Image img, String name) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(_out)..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _write(WidgetTester t, Finder f, String name) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(f);
    final img = await b.toImage(pixelRatio: 2);
    await _writePng(img, name);
  });
}

void main() {
  SharedPreferences.setMockInitialValues({
    'nwsb_terms_hub': '1',
    'guide_seen_plus': true,
  });
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pumpIntro(
    WidgetTester t, {
    required double w,
    required double h,
  }) async {
    t.view.physicalSize = Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    await t.runAsync(() async {
      await Settings.instance.load();
      await Settings.instance.setFashionPlus(false);
    });

    const key = ValueKey('nowssbplus-shot');
    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(w, h),
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'DM Sans',
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
            ),
            home: const FashionPlusScreen(),
          ),
        ),
      ),
    );
    // Let the poster decode.
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/fashion/nowssb-plus-intro.webp'),
        t.element(find.byType(FashionPlusScreen)),
      );
    });
    await t.pump();
  }

  testWidgets('NowssB Plus intro and the page after Enter', (t) async {
    await pumpIntro(t, w: 390, h: 844);
    await _write(t, find.byKey(const ValueKey('nowssbplus-shot')), 'intro');

    expect(find.text('Enter NowssB Plus'), findsOneWidget);
    expect(find.textContaining('Fashion'), findsNothing);
    expect(
      find.textContaining('Switch it off anytime in Settings.'),
      findsOneWidget,
    );
    expect(find.textContaining('Settings > Zen Plus'), findsNothing);

    await t.tap(find.text('Enter NowssB Plus'));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await _write(t, find.byKey(const ValueKey('nowssbplus-shot')), 'inside');
  });

  testWidgets('NowssB Plus intro at 360 width keeps NOWSSB clear of the pane', (
    t,
  ) async {
    await pumpIntro(t, w: 360, h: 844);
    await _write(t, find.byKey(const ValueKey('nowssbplus-shot')), 'intro-360');
    expect(find.text('Enter NowssB Plus'), findsOneWidget);
    expect(
      find.textContaining('Switch it off anytime in Settings.'),
      findsOneWidget,
    );
  });
}
