// Shared pump + shot for R27 section/page fit tests (bugfix B029+).
// Real DM Sans / Anton / Material Icons from test_fonts; shots go to
// --dart-define=BUGFIX_SHOTS=<dir> as <name>.png at 3x.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';

import 'test_fonts.dart';

const bugfixShots = String.fromEnvironment('BUGFIX_SHOTS');

Future<void> loadR27Fonts() async {
  await loadDmSans();
  await loadAnton();
  await loadMaterialIcons();
  NormalMotion.freeze = .35;
}

/// Pumps [w] at [width] logical px and text [scale]; returns the boundary key.
Future<GlobalKey> pumpR27(WidgetTester t, Widget w, double width, double scale, Color bg, {double height = 2400}) async {
  final key = GlobalKey();
  t.view.physicalSize = Size(width * 3, height * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(
          builder: (ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                    backgroundColor: bg,
                    body: SingleChildScrollView(
                        child: RepaintBoundary(
                            key: key, child: Container(color: bg, padding: const EdgeInsets.symmetric(vertical: 14), child: w)))),
              ))));
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate().toList()) {
      try {
        await precacheImage((e.widget as Image).image, e).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await t.pump(const Duration(milliseconds: 100));
  return key;
}

/// Writes the boundary to $BUGFIX_SHOTS/[name].png when shots are on.
Future<void> shotR27(WidgetTester t, GlobalKey key, String name) async {
  if (bugfixShots.isEmpty) return;
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(bugfixShots).createSync(recursive: true);
    File('$bugfixShots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
