// Profile 'You' tab at 412x915 inside the real shell (bottom nav on top).
// flutter test test/profile_fix_shots_test.dart --dart-define=PF_SHOTS=<dir> --dart-define=PF_TAG=before
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

const _out = String.fromEnvironment('PF_SHOTS');
const _tag = String.fromEnvironment('PF_TAG', defaultValue: 'shot');
final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester t, String name) async {
  try { await precacheAll(t); } catch (_) {}
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$_tag-$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

ScrollPosition? _main() {
  for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    if (s.position.maxScrollExtent > 0) return s.position;
  }
  return null;
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

  testWidgets('profile 412x915', (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final prev = FlutterError.onError;
    final errs = <String>[];
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
    final f = find.text('Profile').hitTestable();
    await t.tap(f.last, warnIfMissed: false);
    await _settle(t, 20);
    await _shot(t, '01_top');
    // Each tab in the row under the hero, with the page scrolled so the
    // tabs, the tab card and the Earn wrapper are all in view.
    final p = _main();
    if (p != null) { p.jumpTo(260.0.clamp(0, p.maxScrollExtent)); await _settle(t, 6); }
    for (final (i, label) in ['NowssB coins', 'Cart', 'Wishlist', 'Order history'].indexed) {
      final c = find.descendant(
          of: find.byKey(const ValueKey('course-chips-fade')),
          matching: find.textContaining(label, findRichText: true));
      if (c.evaluate().isNotEmpty) {
        await t.tap(c.first, warnIfMissed: false);
        await _settle(t, 8);
      }
      await _shot(t, '0${i + 2}_tab_${label.replaceAll(' ', '_')}');
    }
    var k = 6;
    while (p != null && p.pixels < p.maxScrollExtent - 1 && k < 16) {
      p.jumpTo((p.pixels + 620).clamp(0, p.maxScrollExtent));
      await _settle(t, 6);
      await _shot(t, '${k.toString().padLeft(2, '0')}_scroll');
      k++;
    }
    File('$_out/$_tag-errors.txt').writeAsStringSync(errs.toSet().join('\n'));
    await t.pumpWidget(const SizedBox());
    await _settle(t, 20);
  }, skip: _out.isEmpty);
}
