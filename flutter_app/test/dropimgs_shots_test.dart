// Shots of Drop Studio door previews, the featured-hour card, and
// the How the drop flows section.
//
// dart-define DROPIMGS_SHOT_PREFIX=before|after (default after).
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _shots = Directory('/workspace/team-plan/shots/dropimgs')
  ..createSync(recursive: true);

const _prefix =
    String.fromEnvironment('DROPIMGS_SHOT_PREFIX', defaultValue: 'after');

final _fixed = DateTime(2026, 11, 17, 14, 0);

Future<void> _png(WidgetTester t, Finder finder, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(finder);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('${_shots.path}/$_prefix-$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });

  Future<void> bootPage(WidgetTester t, {int? debugFront}) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.noScaling,
        padding: EdgeInsets.only(top: 47, bottom: 34),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: RepaintBoundary(
          key: const ValueKey('shot'),
          child: DropStudioScreen(
            clock: () => _fixed,
            debugTilt: Offset.zero,
            debugFront: debugFront,
          ),
        ),
      ),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('featured drop card', (t) async {
    await bootPage(t);
    await _png(t, find.byKey(const ValueKey('shot')), 'featured');
    expect(find.textContaining('A featured drop'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('each door of the prism', (t) async {
    const names = ['background', 'start-art', 'access'];
    for (var i = 0; i < names.length; i++) {
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await bootPage(t, debugFront: i);
      final heading = find.byKey(const ValueKey('drop-prism-heading'));
      final scroll = find.byType(Scrollable).first;
      for (var n = 0; n < 40; n++) {
        if (heading.evaluate().isEmpty) {
          await t.drag(scroll, const Offset(0, -240));
          await t.pump(const Duration(milliseconds: 80));
          continue;
        }
        final top = t.getRect(heading).top;
        // Sit the heading just under the top bar so the whole door is on screen.
        if ((top - 120).abs() < 8) break;
        await t.drag(scroll, Offset(0, 120 - top));
        await t.pump(const Duration(milliseconds: 80));
      }
      await t.pump();
      await _png(t, find.byKey(const ValueKey('shot')), 'door-${names[i]}');
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('how the drop flows', (t) async {
    await bootPage(t);
    final flows = find.text('HOW THE DROP FLOWS');
    for (var i = 0; i < 40 && flows.hitTestable().evaluate().isEmpty; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -240));
      await t.pump(const Duration(milliseconds: 80));
    }
    await t.ensureVisible(flows);
    await t.pump();
    await _png(t, find.byKey(const ValueKey('shot')), 'flows');
    expect(flows, findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
