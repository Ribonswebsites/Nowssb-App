// Shots of every Learn-guide slide on the Zen home, for the left-aligned
// title copy. Writes to /workspace/team-plan/shots/gsleft/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/follow_steps.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/gsleft';

Future<void> _write(WidgetTester t, Finder f, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(f);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> revealHero(WidgetTester t) async {
  final nav = find.byType(FstNav);
  if (nav.evaluate().isEmpty) return;
  // Keep the television and the Start/steps row fully on screen, below
  // the sticky header, the way the home looks on a phone.
  const wantTop = 420.0;
  for (final e in find.byType(Scrollable).evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    final r = t.getRect(nav.first);
    final next = (s.position.pixels + r.top - wantTop)
        .clamp(0.0, s.position.maxScrollExtent);
    s.position.jumpTo(next);
    await t.pump();
    break;
  }
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pumpHome(
    WidgetTester t, {
    required double w,
    required double scale,
  }) async {
    const h = 844.0;
    t.view.physicalSize = Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('gsleft-shot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'DM Sans',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
          ),
          home: Builder(
            builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: NavScope(go: (_) {}, child: const HomeFashion()),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 16; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await precacheAll(t);
    await t.pump();
  }

  Future<void> openGuide(WidgetTester t) async {
    final disc = find.bySemanticsLabel('How this app works — follow the steps');
    await t.ensureVisible(disc);
    await t.pump();
    await t.tap(disc);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Follow the steps'), findsOneWidget);
    await revealHero(t);
  }

  String slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  testWidgets('every guide slide at 390@1.0 plus intro at other sizes',
      (t) async {
    const key = ValueKey('gsleft-shot');

    await pumpHome(t, w: 390, scale: 1.0);
    await openGuide(t);
    await _write(t, find.byKey(key), 'slide-00-intro');

    for (var i = 1; i <= kFstSteps.length; i++) {
      await t.tap(find.bySemanticsLabel('Next step').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 420));
      final name =
          'slide-${i.toString().padLeft(2, '0')}-${slug(kFstSteps[i - 1].title)}';
      await _write(t, find.byKey(key), name);
    }

    for (final c in const [(360.0, 1.0), (360.0, 1.3), (390.0, 1.3)]) {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 50));
      await pumpHome(t, w: c.$1, scale: c.$2);
      await openGuide(t);
      final tag = '${c.$1.toInt()}-${c.$2.toString().replaceAll('.', '')}';
      await _write(t, find.byKey(key), 'intro-$tag');
    }
  });
}
