// Phone-size screenshots of every tab (top and scrolled to the very end) for
// the Oct 31 sweep. Only runs with --dart-define=SWEEP_SHOTS=<out dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = String.fromEnvironment('SWEEP_SHOTS');

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

final _key = GlobalKey();

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
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
    GoogleFonts.config.allowRuntimeFetching = false;
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });

  for (final w in [360.0, 320.0]) {
    testWidgets('sweep shots ${w.toInt()}', (t) async {
      t.view.physicalSize = Size(w, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final prev = FlutterError.onError;
      final errs = <String>[];
      FlutterError.onError = (d) => errs.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = prev);
      await t.pumpWidget(MaterialApp(
          home: RepaintBoundary(key: _key, child: const NavShell())));
      await _settle(t, 15);
      final agree = find.text('I Agree · Continue');
      if (agree.evaluate().isNotEmpty) {
        await t.tap(agree.first, warnIfMissed: false);
        await _settle(t, 15);
      }
      final tag = '${w.toInt()}';
      for (final skin in ['normal', 'fashion']) {
        for (final tab in ['Home', 'Practice', 'Library', 'Store', 'Profile']) {
          if (tab != 'Home') {
            final f = find.text(tab).hitTestable();
            if (f.evaluate().isEmpty) continue;
            await t.tap(f.last, warnIfMissed: false);
            await _settle(t, 10);
          }
          await _shot(t, '${tag}_${skin}_${tab}_top');
          await _toEnd(t);
          await _shot(t, '${tag}_${skin}_${tab}_end');
          if (tab == 'Home') {
            // back to top for the next tab
          }
        }
        // Back to Home, flip the skin.
        final home = find.text('Connect').hitTestable();
        if (home.evaluate().isNotEmpty) {
          await t.tap(home.last, warnIfMissed: false);
          await _settle(t, 10);
        }
        final chip = find.textContaining(skin == 'normal' ? 'Normal home' : 'Fashion home').hitTestable();
        if (chip.evaluate().isNotEmpty) {
          await t.tap(chip.first, warnIfMissed: false);
          await _settle(t, 15);
        }
      }
      File('$_out/errors_$tag.txt').writeAsStringSync(errs.toSet().join('\n'));
      await t.pumpWidget(const SizedBox());
    }, skip: _out.isEmpty);
  }
}
