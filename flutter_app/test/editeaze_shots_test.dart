// Section shots for the Editeaze styles (run with --dart-define=EZ_SHOTS=<dir>).
// The Profile mind "with data" shot uses a seeded practice record so the
// cards can be seen filled in; the app itself only reads real sessions.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('EZ_SHOTS');
final _key = GlobalKey();

Map<String, dynamic> _seed() {
  final now = DateTime.now();
  final out = <String, dynamic>{};
  final hours = [7, 8, 19, 21, 13, 7, 20, 22, 8];
  for (var i = 0; i < hours.length; i++) {
    final d = DateTime(now.year, now.month, now.day - (i ~/ 2), hours[i]);
    final ymd = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_w$i'] = {'date': ymd, 'word': 'w$i', 'completedAt': d.toIso8601String(), 'durationSec': 300};
  }
  return out;
}

Future<void> _shoot(WidgetTester t, Widget child, Color bg, String name) async {
  await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
          key: _key,
          child: ColoredBox(
              color: bg,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 30), child: Material(type: MaterialType.transparency, child: child)))))));
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
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

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    FakeVideoPlatform();
  });

  testWidgets('editeaze section shots 360', (t) async {
    t.view.physicalSize = const Size(360, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await _shoot(t, const ProfileMind(), Colors.black, '360_section_profile_mind_empty');
    SharedPreferences.setMockInitialValues({'nwsb_native_sessions': jsonEncode(_seed())});
    await t.runAsync(() => PracticeProgress.instance.start());
    await _shoot(t, const ProfileMind(), Colors.black, '360_section_profile_mind_seeded');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  }, skip: _out.isEmpty);
}
