// Hunter's home-text blockers: B008 (the Anton drop word, e.g. SOMA, shows
// whole inside its card) and the Fashion Plus subline wraps fully (no
// ellipsis, no mid-word break) at 320/360/390/412 and 320@1.3.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';
import 'package:nowssb/screens/fashion/sections_mid.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = '/workspace/team-plan/shots';
final _shoot = Directory(_shots).existsSync() && homeFontsReady;

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  const sizes = [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)];
  final key = GlobalKey();

  Future<List<String>> boot(WidgetTester t, Widget child, double w, double s) async {
    t.view.physicalSize = Size(w * 2, 900 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(size: Size(w, 900), textScaler: TextScaler.linear(s)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: NavScope(
            go: (_) {},
            child: Scaffold(
                backgroundColor: Colors.black,
                body: RepaintBoundary(key: key, child: ColoredBox(color: Colors.black, child: ListView(children: [child]))))),
      ),
    ));
    final errs = <String>[];
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
      final e = t.takeException();
      if (e != null) errs.add('$e');
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 100));
    return errs;
  }

  Future<void> shot(WidgetTester t, String name) async {
    if (!_shoot) return;
    final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 2);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_shots/home-text-fix-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  void noEllipsis(WidgetTester t) {
    for (final e in find.byType(RichText).evaluate()) {
      final p = e.renderObject as RenderParagraph;
      expect(p.overflow == TextOverflow.ellipsis && p.didExceedMaxLines, isFalse,
          reason: 'ellipsis on "${p.text.toPlainText()}"');
      expect(p.didExceedMaxLines && p.maxLines != 1, isFalse,
          reason: 'cut text "${p.text.toPlainText()}"');
    }
  }

  // Find the hour whose drop word is SOMA (real library data); fall back to
  // checking the word at every hour.
  for (final (w, s) in sizes) {
    final tag = s == 1.0 ? '${w.toInt()}' : '${w.toInt()}x$s';
    testWidgets('B008: drop word glyphs inside the card, every hour, at $tag', (t) async {
      DateTime now = DateTime(2026, 10, 27, 0, 10);
      DayClock.clock = () => now;
      addTearDown(() => DayClock.clock = null);
      var shotDone = false;
      for (var h = 0; h < 24; h++) {
        now = DateTime(2026, 10, 27, h, 10);
        final errs = await boot(t, DropStudioEntry(onTap: () {}), w, s);
        expect(errs, isEmpty, reason: 'h$h: $errs');
        final wf = find.byKey(const ValueKey('drop-studio-entry-word'));
        if (wf.evaluate().isEmpty) continue;
        final card = t.getRect(find.byKey(const ValueKey('drop-studio-entry')));
        final para = t.renderObject<RenderParagraph>(find.descendant(of: wf, matching: find.byType(RichText)));
        final word = para.text.toPlainText();
        expect((para.text as TextSpan).style!.fontFamily, 'Anton');
        final n = word.length;
        for (var i = 0; i < n; i++) {
          for (final b in para.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))) {
            final g = MatrixUtils.transformRect(para.getTransformTo(null), b.toRect());
            expect(g.top >= card.top - .5 && g.bottom <= card.bottom + .5 && g.left >= card.left - .5 && g.right <= card.right + .5,
                isTrue, reason: '$word glyph $i $g outside card $card at h$h');
          }
        }
        if (word.toUpperCase() == 'SOMA' && !shotDone) {
          await shot(t, 'soma-$tag');
          shotDone = true;
        }
        await t.pumpWidget(const SizedBox());
      }
      if (!shotDone) {
        now = DateTime(2026, 10, 27, 1, 10);
        await boot(t, DropStudioEntry(onTap: () {}), w, s);
        await shot(t, 'dropword-$tag');
        await t.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Fashion Plus subline wraps whole at $tag', (t) async {
      final errs = await boot(t, const FashPlusMini(), w, s);
      expect(errs, isEmpty);
      final sub = find.textContaining(Settings.instance.fashionPlus ? 'On —' : 'Off —');
      expect(sub, findsOneWidget);
      final p = t.renderObject<RenderParagraph>(find.descendant(of: sub, matching: find.byType(RichText)));
      expect(p.overflow, isNot(TextOverflow.ellipsis));
      expect(p.didExceedMaxLines, isFalse);
      // No mid-word break: every line ends at a space or the text end.
      final text = p.text.toPlainText();
      final lines = (TextPainter(text: p.text, textDirection: TextDirection.ltr, textScaler: p.textScaler)
            ..layout(maxWidth: p.size.width))
          .computeLineMetrics();
      var off = 0;
      for (final lm in lines.take(lines.length - 1)) {
        final pos = p.getPositionForOffset(Offset(p.size.width, lm.baseline - lm.ascent / 2)).offset;
        off = pos;
        expect(off >= text.length || text[off - 1] == ' ' || text[off] == ' ', isTrue,
            reason: 'mid-word break at $off in "$text"');
      }
      noEllipsis(t);
      await shot(t, 'fashplus-$tag');
      await t.pumpWidget(const SizedBox());
    });
  }
}
