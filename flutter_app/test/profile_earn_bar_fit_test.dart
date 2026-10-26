// B025: the Profile 'Open NowssB Earn' bar stays inside the deck.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

// Profile sets SF Pro Display and Roboto Mono. The test font (Ahem) draws
// every glyph as a full square, so load real faces where the box has them.
const _g = '/usr/share/fonts/truetype/sand-box/google';
const _faces = {
  '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf': ['SF Pro Display', 'Roboto'],
  '$_g/Roboto Mono/RobotoMono-VariableFont_wght.ttf': ['Roboto Mono'],
};

void main() {
  final haveFonts = _faces.keys.every((f) => File(f).existsSync());
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    if (!haveFonts) return;
    for (final e in _faces.entries) {
      final b = ByteData.sublistView(File(e.key).readAsBytesSync());
      for (final f in e.value) {
        await (FontLoader(f)..addFont(Future.value(b))).load();
      }
    }
  });

  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('earn bar fits at ${w.toInt()} x$scale', (t) async {
      if (!haveFonts) return markTestSkipped('Profile fonts not installed');
      FakeVideoPlatform();
      VideoPool.debugDeadlines = false;
      t.view.physicalSize = Size(w * 3, 3600 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString());
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(w, 3600), textScaler: TextScaler.linear(scale)),
          child: const ProfileScreen(),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      FlutterError.onError = prev;
      expect(errors.where((e) => e.contains('overflowed')), isEmpty);
      final f = find.text('Open NowssB Earn');
      expect(f, findsOneWidget);
      final deck = t.getRect(find.ancestor(of: f, matching: find.byType(ListView)).first);
      final bar = t.getRect(find.ancestor(of: f, matching: find.byType(Row)).first);
      expect(bar.right, lessThanOrEqualTo(deck.right + 0.5), reason: 'bar $bar past deck $deck');
      expect(bar.left, greaterThanOrEqualTo(deck.left - 0.5));
      expect(bar.right, lessThanOrEqualTo(w + 0.5));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}
