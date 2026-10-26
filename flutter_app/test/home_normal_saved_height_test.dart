// A height saved in the UI Editor for an older design must not scale a
// rebuilt Normal home section (it blew 'reader' up ~3x and clipped its
// sides). Set HOME_SHOTS=<dir> to write home-overflow-fix-<w>.png there.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  for (final (w, dpr, ts) in [
    (360.0, 3.0, 1.0),
    (390.0, 3.0, 1.0),
    (412.0, 2.625, 1.0),
    (320.0, 2.0, 1.3),
  ]) {
    testWidgets('saved reader height does not scale it at ${w.toInt()} x$ts', (t) async {
      const h = 22000.0;
      t.view.physicalSize = Size(w * dpr, h * dpr);
      t.view.devicePixelRatio = dpr;
      t.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 16 * dpr);
      addTearDown(t.view.reset);
      UiLayouts.instance.applyLocal(const PageLayout(page: 'home.normal', sections: [
        SectionEntry(id: 'reader', props: {'height': 1500}),
      ]));
      addTearDown(() => UiLayouts.instance.removeLocal('home.normal'));
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(w, h),
            devicePixelRatio: dpr,
            textScaler: TextScaler.linear(ts),
            padding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'DM Sans'),
            home: NavScope(go: (_) {}, child: const HomeNormal()),
          ),
        ),
      ));
      final errors = <String>[];
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 150));
        final e = t.takeException();
        if (e != null) errors.add('$e');
      }
      expect(errors, isEmpty);
      await precacheAll(t);
      await t.pump();

      final reader = t.getRect(find.byKey(const ValueKey('nm-reader')));
      expect(reader.left, 0);
      expect(reader.right, w);
      for (final label in ['Sign in for rewards', 'They save. You earn.', 'Share your link  →']) {
        final f = find.text(label);
        expect(f, findsOneWidget, reason: label);
        final p = t.renderObject<RenderParagraph>(f);
        expect(p.getTransformTo(null).getMaxScaleOnAxis(), closeTo(1, 1e-6), reason: label);
        final r = t.getRect(f);
        expect(r.left, greaterThanOrEqualTo(0), reason: label);
        expect(r.right, lessThanOrEqualTo(w), reason: label);
        expect(p.didExceedMaxLines, isFalse, reason: label);
      }
      for (final e in find.descendant(of: find.byKey(const ValueKey('nm-reader')), matching: find.byType(RichText)).evaluate()) {
        final p = e.renderObject! as RenderParagraph;
        final r = t.getRect(find.byWidget(e.widget));
        expect(r.left >= 0 && r.right <= w && !p.didExceedMaxLines, isTrue,
            reason: p.text.toPlainText());
      }

      final dir = Platform.environment['HOME_SHOTS'];
      if (dir != null) {
        await t.runAsync(() async {
          final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await ro.toImage(pixelRatio: 2);
          final top = reader.top - 10, ht = reader.height + 20;
          final rec = ui.PictureRecorder();
          Canvas(rec).drawImageRect(img, Rect.fromLTWH(0, top * 2, w * 2, ht * 2),
              Rect.fromLTWH(0, 0, w * 2, ht * 2), Paint());
          final out = await rec.endRecording().toImage((w * 2).toInt(), (ht * 2).toInt());
          final png = await out.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/home-overflow-fix-${w.toInt()}.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
    }, skip: !homeFontsReady);
  }
}
