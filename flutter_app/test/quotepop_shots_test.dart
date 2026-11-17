// 390- and 360-wide shots of the reinvented Today's Quote pop-up over the
// Zen home, with real fonts. The wave shows its first-frame poster (there is
// no video texture in a widget test), which is also what a phone shows for
// the first frames before the film fades in over it.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/quote_film.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/quotes_live.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/quotepop';
const _key = ValueKey('quotepop-shot');

Future<void> _write(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(_key));
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _noop(int _) {}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(() async {
    VideoPool.instance.debugDropAll();
    await QuoteFilm.debugReset();
  });

  Future<void> shoot(WidgetTester t, double w, String name) async {
    const h = 844.0;
    t.view.physicalSize = Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await Settings.instance.load();
    });
    late BuildContext ctx;
    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(w, h),
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: RepaintBoundary(
          key: _key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'DM Sans',
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
            ),
            home: Builder(builder: (c) {
              ctx = c;
              return const NavScope(go: _noop, child: HomeFashion());
            }),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    showTodayQuote(ctx, now: DateTime(2026, 11, 17, 9));
    for (var i = 0; i < 16; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('daily-quote-popup')), findsOneWidget);
    await _write(t, name);
    await t.tap(find.byKey(const ValueKey('daily-quote-close')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('pop-up at 390', (t) => shoot(t, 390, 'after-390'));
  testWidgets('pop-up at 360', (t) => shoot(t, 360, 'after-360'));
}
