// Full Profile before/after shots at 390 wide.
// flutter test test/profile3_shots_test.dart --dart-define=PROFILE3_SHOTS=<dir> --dart-define=PROFILE3_TAG=before
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = String.fromEnvironment('PROFILE3_SHOTS');
const _tag = String.fromEnvironment('PROFILE3_TAG', defaultValue: 'shot');

final _key = GlobalKey();

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void _seedWeek() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday =
      DateTime(today.year, today.month, today.day - (today.weekday + 6) % 7);
  final sessions = <String, Map<String, dynamic>>{};
  // Practiced Monday and today (when today is later in the week), so the
  // week row shows real done days plus the current day.
  for (final offset in {0, (today.weekday + 6) % 7}) {
    final d = DateTime(monday.year, monday.month, monday.day + offset);
    if (d.isAfter(today)) continue;
    final key = _day(d);
    sessions['${key}_SOMA'] = {
      'date': key,
      'word': 'SOMA',
      'completedAt': '${key}T12:00:00.000',
      'source': 'test',
    };
  }
  PracticeProgress.instance.debugSetSessionsForTest(sessions);
}

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

void _drain(WidgetTester t) {
  for (var i = 0; i < 20; i++) {
    final e = t.takeException();
    if (e == null) break;
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  try {
    await precacheAll(t);
  } catch (_) {}
  _drain(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/${_tag}-$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _crop(WidgetTester t, Finder finder, String name,
    {double pad = 16}) async {
  await precacheAll(t);
  final el = finder.evaluate().isEmpty ? null : finder.evaluate().first;
  if (el == null) return;
  final box = el.renderObject as RenderBox?;
  if (box == null || !box.hasSize) return;
  final origin = box.localToGlobal(Offset.zero);
  final page =
      _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await page.toImage(pixelRatio: 2);
    final scale = 2.0;
    final rect = Rect.fromLTWH(
      (origin.dx - pad).clamp(0, img.width / scale) * scale,
      (origin.dy - pad).clamp(0, img.height / scale) * scale,
      (box.size.width + pad * 2).clamp(1, img.width / scale) * scale,
      (box.size.height + pad * 2).clamp(1, img.height / scale) * scale,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      img,
      rect,
      Rect.fromLTWH(0, 0, rect.width, rect.height),
      Paint(),
    );
    final cropped = await recorder
        .endRecording()
        .toImage(rect.width.round(), rect.height.round());
    final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/${_tag}-$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _jump(WidgetTester t, double frac) async {
  for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    final p = s.position;
    if (p.maxScrollExtent > 0)
      p.jumpTo((p.maxScrollExtent * frac).clamp(0, p.maxScrollExtent));
    break;
  }
  await _settle(t, 4);
}

Future<void> _open(WidgetTester t, {required Size size}) async {
  t.view.physicalSize = Size(size.width * 2, size.height * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: RepaintBoundary(key: _key, child: const ProfileScreen()),
    ),
  ));
  await _settle(t, 16);
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
  await _settle(t, 6);
}

const _g = '/usr/share/fonts/truetype/sand-box/google';
const _faces = {
  '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf': [
    'SF Pro Display',
    'Roboto',
    'DM Sans'
  ],
  '$_g/Roboto Mono/RobotoMono-VariableFont_wght.ttf': ['Roboto Mono'],
};

Future<void> _loadProfileFonts() async {
  for (final e in _faces.entries) {
    final f = File(e.key);
    if (!f.existsSync()) continue;
    final b = ByteData.sublistView(f.readAsBytesSync());
    for (final family in e.value) {
      await (FontLoader(family)..addFont(Future.value(b))).load();
    }
  }
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await _loadProfileFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
    await Settings.instance.load();
    await Settings.instance.setFashionPlus(false);
    await PracticeProgress.instance.start();
    // Network avatars 400 in tests; don't fail the shot run over them.
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      if (s.contains('HttpException') ||
          s.contains('statusCode') ||
          s.contains('HTTP request')) {
        return;
      }
      prev?.call(d);
    };
  });

  testWidgets('full Profile shots at 390', (t) async {
    _seedWeek();
    // Tall frame so the whole page is in one image.
    await _open(t, size: const Size(390, 4800));
    await _shot(t, 'full');
    final week = find.byKey(const ValueKey('profile-week-tracker'));
    if (week.evaluate().isNotEmpty) {
      await _crop(t, week, 'week', pad: 20);
    } else {
      // Before the restyle the week row is the seven letter circles.
      final dots = find.ancestor(
        of: find.byWidgetPredicate((x) =>
            x is Text &&
            x.data != null &&
            x.data!.length == 1 &&
            'MTWFS'.contains(x.data!)),
        matching: find.byType(AnimatedContainer),
      );
      if (dots.evaluate().length >= 7) {
        await _crop(
            t,
            find.ancestor(of: dots.first, matching: find.byType(Row)).first,
            'week',
            pad: 24);
      }
    }
    final sign = find.text('Sign Out');
    if (sign.evaluate().isNotEmpty) {
      await _crop(t, sign, 'signout', pad: 36);
    }
    _drain(t);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 11));
  }, skip: _out.isEmpty);

  testWidgets('phone-frame Profile shots at 390x844', (t) async {
    _seedWeek();
    await _open(t, size: const Size(390, 844));
    await _shot(t, 'top');
    await _jump(t, 0.5);
    await _shot(t, 'mid');
    await _jump(t, 1);
    await _shot(t, 'end');
    _drain(t);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 11));
  }, skip: _out.isEmpty);
}
