// B024: the Profile stat tile labels stay whole words (no STRE/AK).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    testWidgets('stat labels whole at ${w.toInt()} x$scale', (t) async {
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
      for (final label in ['COINS', 'STREAK', 'SESSIONS', 'WORDS']) {
        final f = find.text(label);
        expect(f, findsWidgets, reason: label);
        for (final e in f.evaluate()) {
          final r = e.renderObject! as RenderParagraph;
          expect(r.size.width + 0.5, greaterThanOrEqualTo(r.getMaxIntrinsicWidth(double.infinity)),
              reason: '$label breaks mid-word');
          // Whichever layout is used, a label renders at >= 80% of full size.
          final k = t.getRect(find.byWidget(e.widget)).width / r.size.width;
          expect(k, greaterThanOrEqualTo(0.8), reason: '$label scaled to $k');
          expect(r.didExceedMaxLines, isFalse, reason: '$label is cut');
        }
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}
