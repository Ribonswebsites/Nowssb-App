// B027: the Profile tab strip reads as scrollable when a tab is cut off.
import 'dart:io';

import 'package:flutter/material.dart';
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
    testWidgets('tab strip shows it scrolls at ${w.toInt()} x$scale', (t) async {
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
      final cart = find.descendant(of: find.byType(CourseFace), matching: find.textContaining('Cart', findRichText: true));
      expect(cart, findsWidgets);
      final strip = find.ancestor(of: cart.first, matching: find.byType(Scrollable)).first;
      final pos = t.state<ScrollableState>(strip).position;
      if (pos.maxScrollExtent > 0) {
        // Cut off: the strip must fade at its edge to show it scrolls.
        expect(find.ancestor(of: strip, matching: find.byType(ShaderMask)), findsWidgets, reason: 'cut-off tabs with no edge fade');
        // And the last tab can be scrolled fully clear of the fade.
        pos.jumpTo(pos.maxScrollExtent);
        await t.pump();
        final view = t.getRect(strip);
        final last = t.getRect(find.descendant(of: strip, matching: find.textContaining('Order history', findRichText: true)).first);
        expect(last.right, lessThanOrEqualTo(view.right - 31.5), reason: 'last tab $last under the fade of $view');
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}

