/// Normal home v2: every section once, nothing scaled up, nothing spilling
/// at the phone sizes people actually hold, and the programmes rail sits
/// under its own heading.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/four_banners.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

/// Rows that render nothing on purpose in v2 (kept for the registry/admin).
const _quiet = {
  'heroCurve', 'promoRail',
  'streak',
  'practice',
  'catTiles',
  'spotlight',
  'tiles',
  'storiesFind',
  'condisc',
  'trendshop',
  'connectban',
  'routines',
  'custom',
  'rx',
  'subvid',
  'genderpath',
  'wsearch',
  'msearch',
  'healing', // behind Settings.showHealing
};

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<List<String>> pumpAt(WidgetTester t, double w, double dpr,
      {double h = 22000}) async {
    t.view.physicalSize = Size(w * dpr, h * dpr);
    t.view.devicePixelRatio = dpr;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: NavScope(go: (_) {}, child: const HomeNormal())));
    final errors = <String>[];
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      final e = t.takeException();
      if (e != null) errors.add('$e');
    }
    return errors;
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  }

  List<RenderParagraph> paragraphs() => [
        for (final e in find.byType(RichText).evaluate())
          if (e.renderObject is RenderParagraph)
            e.renderObject! as RenderParagraph
      ];

  test('the registry still holds 37 keys', () {
    expect(kNormalSectionOrder, hasLength(37));
  });

  testWidgets('each section and each heading appears once', (t) async {
    await pumpAt(t, 390, 1);
    for (final k in kNormalSectionOrder) {
      final n = find.byKey(ValueKey('nm-$k')).evaluate().length;
      expect(n, lessThanOrEqualTo(1), reason: '$k placed $n times');
    }
    for (final w in [TrioRail]) {
      expect(find.byType(w), findsOneWidget);
    }
    // Section headings: a single-line paragraph of 18px+ text is a heading.
    final seen = <String, int>{};
    for (final r in paragraphs()) {
      final txt = r.text.toPlainText().trim();
      final style = (r.text as TextSpan).style;
      final size = style?.fontSize ?? 14;
      if (!RegExp('[A-Za-z]').hasMatch(txt) || txt.contains('\n') || size < 18)
        continue;
      seen[txt] = (seen[txt] ?? 0) + 1;
    }
    final dupes =
        seen.entries.where((e) => e.value > 1).map((e) => e.key).toList();
    // Carousels repeat a face while looping; only fixed headings count.
    const looped = {'NOWSSB'};
    expect(dupes.where((d) => !looped.contains(d)), isEmpty, reason: '$dupes');
    for (final k in kNormalSectionOrder.where((k) => !_quiet.contains(k))) {
      expect(find.byKey(ValueKey('nm-$k')), findsOneWidget, reason: k);
    }
    await finish(t);
  }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart

  testWidgets('the programmes rail has its heading right above it', (t) async {
    await pumpAt(t, 390, 1);
    final head = find.byKey(const ValueKey('nm-trio-heading'));
    expect(head, findsOneWidget);
    expect(find.text('Your programmes'), findsOneWidget);
    final rail = find.byType(TrioRail);
    expect(rail, findsOneWidget);
    expect(t.getTopLeft(head).dy, lessThan(t.getTopLeft(rail).dy));
    expect(t.getTopLeft(rail).dy,
        lessThan(t.getTopLeft(find.text('Your essentials')).dy));
    await finish(t);
  }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart

  testWidgets('signed out, rewards ask to sign in', (t) async {
    await pumpAt(t, 390, 1);
    expect(find.text('Sign in to see your rewards'), findsOneWidget);
    await finish(t);
  }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart

  for (final (w, dpr) in [
    (360.0, 2.0),
    (390.0, 3.0),
    (412.0, 2.625),
    (320.0, 1.3)
  ]) {
    testWidgets('no overflow, no oversized text at ${w.toInt()}@$dpr',
        (t) async {
      final errors = await pumpAt(t, w, dpr, h: 22000);
      if (homeFontsReady)
        expect(errors.where((e) => e.contains('overflow')), isEmpty);
      for (final r in paragraphs()) {
        var max = 0.0;
        r.text.visitChildren((s) {
          final f = (s is TextSpan ? s.style?.fontSize : null) ?? 0;
          if (f > max) max = f;
          return true;
        });
        final top = (r.text as TextSpan).style?.fontSize ?? 0;
        if (top > max) max = top;
        expect(max * r.textScaler.scale(1), lessThanOrEqualTo(28.0),
            reason: '"${r.text.toPlainText()}" is ${max}px');
      }
      for (final e in find.byType(FittedBox).evaluate()) {
        final box = e.renderObject! as RenderFittedBox;
        final child = box.child;
        if (child == null || !child.hasSize || child.size.isEmpty) continue;
        if (find
            .descendant(
                of: find.byWidget(e.widget), matching: find.byType(RichText))
            .evaluate()
            .isEmpty) continue;
        final sx = box.size.width / child.size.width;
        final sy = box.size.height / child.size.height;
        expect(sx < sy ? sx : sy, lessThanOrEqualTo(1.01),
            reason: 'a FittedBox blows its child up');
      }
      await finish(t);
    }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart
  }
}
