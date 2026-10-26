// B026: the white 'Active' pill on the Profile course card has readable text.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nowssb/widgets/course_face.dart';
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
    testWidgets('Active pill readable at ${w.toInt()} x$scale', (t) async {
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
      final f = find.descendant(of: find.byType(CourseFace), matching: find.text('Active'));
      expect(f, findsWidgets);
      for (final e in f.evaluate()) {
        final c = (e.renderObject! as RenderParagraph).text.style!.color!;
        final ratio = _contrast(c, Colors.white);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Active text $c is $ratio:1 on white');
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}

double _contrast(Color fg, Color bg) {
  // Blend a translucent colour onto the background, then WCAG luminance.
  final a = fg.a;
  final l1 = Color.from(alpha: 1, red: fg.r * a + bg.r * (1 - a), green: fg.g * a + bg.g * (1 - a), blue: fg.b * a + bg.b * (1 - a)).computeLuminance();
  final l2 = bg.computeLuminance();
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}
