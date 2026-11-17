import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/concept/drop_v4_concepts.dart' show DoorKind;
import 'package:nowssb/screens/concept/drop_v5.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });

  test('dedicated door preview art exists and is bundled', () {
    for (final k in DoorKind.values) {
      final a = doorPreviewArt(k);
      expect(File(a).existsSync(), isTrue, reason: a);
    }
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/drop_studio/'));
  });

  test('Drop Studio page has no ripple rings or orb blobs', () {
    final src = File('lib/screens/fashion/drop_studio.dart').readAsStringSync();
    expect(src, isNot(contains('_RingsPainter')));
    expect(src, isNot(contains('gold ripple rings')));
    expect(src, isNot(contains('_LiquidPainter')));
    expect(src, isNot(contains('drawCircle')));
  });

  test('user-selectable backgrounds and start-art stills are unchanged', () {
    expect(Settings.fashionVideoNames, ['Falling Diamonds', 'Violet Silk', 'Ember Silk', 'Silver Thread']);
    expect(Settings.fashionVideos.first, 'assets/video/fashion-plus-bg-5.mp4');
    expect(Settings.fashionImages.first, 'assets/fashion/fp-intro.webp');
  });

  testWidgets('prism faces use door preview art, not the live selected stills', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await Settings.instance.load();
      await Settings.instance.setFashionPlus(true);
      await Settings.instance.setFashionVideo(0); // Falling Diamonds
      await Settings.instance.setFashionImage(null); // NowssB black
    });
    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(size: Size(390, 844), textScaler: TextScaler.noScaling),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(child: DoorsPrismV5()),
        ),
      ),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));

    expect(find.image(AssetImage(doorPreviewArt(DoorKind.background))), findsWidgets);
    expect(find.image(const AssetImage('assets/video/fashion-plus-bg-5-poster.webp')), findsNothing);
    expect(find.image(const AssetImage('assets/fashion/fp-intro.webp')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
