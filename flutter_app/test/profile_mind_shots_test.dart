// Section shots for "Your practice mind" at 390 wide, three palettes.
// Run with --dart-define=MIND_SHOTS=<dir>.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:nowssb/widgets/editeaze.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('MIND_SHOTS');
final _key = GlobalKey();

Map<String, dynamic> _seed() {
  final now = DateTime.now();
  final out = <String, dynamic>{};
  final hours = [7, 8, 19, 21, 13, 7, 20, 22, 8];
  for (var i = 0; i < hours.length; i++) {
    final d = DateTime(now.year, now.month, now.day - (i ~/ 2), hours[i]);
    final ymd =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_w$i'] = {
      'date': ymd,
      'word': 'w$i',
      'completedAt': d.toIso8601String(),
      'durationSec': 300,
    };
  }
  return out;
}

Future<void> _shoot(WidgetTester t, Widget child, String name) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: _key,
        child: const ColoredBox(color: Colors.black, child: SizedBox.shrink()),
      ),
    ),
  );
  // Rebuild with the child; the key must stay on the same RepaintBoundary.
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: _key,
        child: ColoredBox(
          color: Colors.black,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final focus = find.byKey(const ValueKey('mind-focus'));
  if (focus.evaluate().isNotEmpty) {
    final box = t.renderObject<RenderBox>(focus);
    final o = box.localToGlobal(Offset.zero, ancestor: ro);
    File('$_out/$name.focus.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'x': o.dx,
          'y': o.dy,
          'w': box.size.width,
          'h': box.size.height,
        }),
      );
  }
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
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
  });

  testWidgets(
    'seeded cards use a forced palette of different shades, no header fade',
    (t) async {
      t.view.physicalSize = const Size(390, 980);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({
        'nwsb_native_sessions': jsonEncode(_seed()),
      });
      await t.runAsync(() => PracticeProgress.instance.start());
      const idx = 4; // lavender
      final pal = kMindPalettes[idx];
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: SingleChildScrollView(child: ProfileMind(paletteIndex: idx)),
          ),
        ),
      );
      await t.pumpAndSettle();
      final focus = t.widget<EzOrangeCard>(
        find.byKey(const ValueKey('mind-focus')),
      );
      final rhythm = t.widget<EzOrangeCard>(
        find.byKey(const ValueKey('mind-rhythm')),
      );
      final week = t.widget<EzOrangeCard>(
        find.byKey(const ValueKey('mind-week')),
      );
      expect(focus.color, pal.focus);
      expect(rhythm.color, pal.rhythm);
      expect(week.color, pal.week);
      expect({focus.color, rhythm.color, week.color}.length, 3);
      expect(focus.headerFade, isFalse);
      expect(rhythm.headerFade, isFalse);
      expect(week.headerFade, isFalse);
      expect(find.byType(Image), findsWidgets);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('practice mind shots 390, every palette with its portrait', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 980);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'nwsb_native_sessions': jsonEncode(_seed()),
    });
    await t.runAsync(() => PracticeProgress.instance.start());
    for (var idx = 0; idx < kMindPalettes.length; idx++) {
      await _shoot(
        t,
        ProfileMind(paletteIndex: idx),
        'palette-${idx.toString().padLeft(2, '0')}-${kMindPalettes[idx].id}',
      );
    }
    await t.pumpWidget(const SizedBox());
  }, skip: _out.isEmpty);
}
