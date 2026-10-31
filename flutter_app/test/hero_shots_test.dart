// Phone-size screenshots of every tab (top and scrolled to the very end) for
// the Oct 31 sweep. Only runs with --dart-define=SWEEP_SHOTS=<out dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'fake_video_platform.dart';
import 'support/test_fonts.dart';
import 'support/home_render.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/screens/normal/calm_hero.dart';

const _out = String.fromEnvironment('SWEEP_SHOTS');

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

final _key = GlobalKey();

const _midKeys = <String, List<String>>{
  'Home': ['cv3-ez-hero'],
  'Profile': ['profile-mind'],
};

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: double.parse(const String.fromEnvironment('SHOT_PR', defaultValue: '1')));
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Scrolls every onstage vertical scrollable to its very end.
Future<void> _toEnd(WidgetTester t) async {
  for (var pass = 0; pass < 4; pass++) {
    for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
      final s = (e as StatefulElement).state as ScrollableState;
      if (s.axisDirection != AxisDirection.down) continue;
      final p = s.position;
      if (p.maxScrollExtent > 0) p.jumpTo(p.maxScrollExtent);
    }
    await _settle(t, 4);
  }
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    final dir = sdkMaterialFonts;
    if (dir != null) {
      for (final fam in ['SF Pro Display', 'Roboto Mono', 'monospace', 'Georgia']) {
        final l = FontLoader(fam);
        for (final f in Directory(dir).listSync().whereType<File>()) {
          final n = f.uri.pathSegments.last;
          if (n.startsWith('Roboto-') && n.endsWith('.ttf')) {
            l.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
          }
        }
        await l.load();
      }
    }
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });


  {
    const tag = 'M';
    testWidgets('hero concept $tag', (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(() => ContentStore.instance.start());
      final errs = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errs.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = prev);
      await t.pumpWidget(MaterialApp(
          theme: NwsbTheme.light,
          debugShowCheckedModeBanner: false,
          builder: (c, child) => RepaintBoundary(
              key: _key,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: Colors.black)),
                const Positioned.fill(child: FaintFilm()),
                child ?? const SizedBox(),
              ])),
          home: const NavShell()));
      await _settle(t, 15);
      final agree = find.text('I Agree · Continue');
      if (agree.evaluate().isNotEmpty) {
        await t.tap(agree.first, warnIfMissed: false);
        await _settle(t, 15);
      }
      final f = find.byKey(const ValueKey('cv3-ez-hero'));
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).hitTestable().first, maxScrolls: 80);
      }
      await t.ensureVisible(f.first);
      // Leave a little of the page above the hero for context.
      final sc = find.byType(Scrollable).hitTestable().first;
      final pos = (t.state(sc) as ScrollableState).position;
      pos.jumpTo((pos.pixels - 90).clamp(0, pos.maxScrollExtent));
      await _settle(t, 8);
      final r = t.getRect(f.first);
      File('$_out/${tag}_rect.txt')..createSync(recursive: true)..writeAsStringSync('${r.left} ${r.top} ${r.width} ${r.height}');
      await _shot(t, tag);
      final cs = t.state<HeroCarouselState>(find.byKey(const ValueKey('hero-mixed')));
      for (final (i, n) in [(0, 'hero_A2'), (1, 'hero_B2'), (2, 'hero_C2'), (3, 'hero_A2b'), (4, 'hero_C2b')]) {
        cs.jumpTo(i);
        await _settle(t, 6);
        await _shot(t, n);
      }
      cs.jumpTo(0);
      await _settle(t, 4);
      // Motion: 5 frames, 1.6s apart (A/C breath), with a drag on frame 3 for B.
      for (var i = 0; i < 5; i++) {
        if (i == 2) {
          final g = await t.startGesture(t.getCenter(f.first));
          await g.moveBy(const Offset(-40, 0));
          await t.pump(const Duration(milliseconds: 16));
          await g.moveBy(const Offset(-50, 0));
          await t.pump(const Duration(milliseconds: 16));
          await _shot(t, '${tag}_f$i');
          await g.moveBy(const Offset(-30, 0));
          await g.up();
          await t.pump(const Duration(milliseconds: 250));
          continue;
        }
        await _shot(t, '${tag}_f$i');
        for (var k = 0; k < 4; k++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      File('$_out/errors_$tag.txt').writeAsStringSync(errs.toSet().join('\n'));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    }, skip: _out.isEmpty);
  }
}
