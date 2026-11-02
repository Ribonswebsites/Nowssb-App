// Older overflows: NowProgressCard (fashion/home_cards.dart) and
// BrandTopBanner (widgets/brand_top_banner.dart) overflowed on the Fashion
// home at 320@1.3. Scroll the whole home and require no RenderFlex overflow.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/home_cards.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/brand_top_banner.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = String.fromEnvironment('BUGFIX_SHOTS');

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });
  for (final c in const [(390.0, 1.0, '390'), (320.0, 1.3, '320')]) {
    testWidgets('Fashion home: no overflow at ${c.$1}@${c.$2}', (t) => _ignoringFontLoads(() async {
      t.view.physicalSize = Size(c.$1 * 3, 800 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      final hits = <String>[];
      final old = FlutterError.onError;
      addTearDown(() => FlutterError.onError = old);
      // Collect overflows; ignore offline font loads (google_fonts Oswald).
      FlutterError.onError = (d) {
        final s = d.exceptionAsString();
        if (s.contains('overflow')) hits.add(s.split('\n').first);
      };
      Future<void> shot(String id) async {
        if (_shots.isEmpty) return;
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate().toList()) {
            try { await precacheImage((e.widget as Image).image, e).timeout(const Duration(seconds: 3)); } catch (_) {}
          }
        });
        await t.pump(const Duration(milliseconds: 100));
        await t.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final png = await (await b.toImage(pixelRatio: 3)).toByteData(format: ui.ImageByteFormat.png);
          File('$_shots/$id-${c.$3}.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
      await t.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: Builder(builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(c.$2)),
              child: NavScope(go: (_) {}, child: const HomeFashion()))))));
      for (var i = 0; i < 6; i++) { await t.pump(const Duration(milliseconds: 200)); }
      final want = {'OLD-progresscard': find.byType(NowProgressCard), 'OLD-brandbanner': find.byType(BrandTopBanner)};
      for (var step = 0; step < 60; step++) {
        for (final id in want.keys.toList()) {
          final f = want[id]!;
          if (f.evaluate().isNotEmpty) {
            final r = t.getRect(f.first);
            if (r.top > 60 && r.bottom < 760) { await shot(id); want.remove(id); }
          }
        }
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 200));
      }
      FlutterError.onError = old;
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
      if (homeFontsReady) expect(hits, isEmpty);
    }), skip: !homeFontsReady);
  }
}

/// Runs [body] so offline google_fonts loads (e.g. Oswald, not in the font
/// cache) that fail in the background do not fail the test; any other error
/// still does.
Future<void> _ignoringFontLoads(Future<void> Function() body) {
  final done = Completer<void>();
  runZonedGuarded(() async {
    await body();
    if (!done.isCompleted) done.complete();
  }, (e, st) {
    final s = '$e';
    if (s.contains('Failed to load font') || s.contains('google_fonts')) return;
    if (!done.isCompleted) done.completeError(e, st);
  });
  return done.future;
}
