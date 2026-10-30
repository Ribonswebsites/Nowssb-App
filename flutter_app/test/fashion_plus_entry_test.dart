import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/fashion_bg_dim.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry_live.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';

Widget _app(Widget child, {double scale = 1, bool reduced = false}) => MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: reduced),
            child: Scaffold(backgroundColor: const Color(0xFFEDEFF3), body: SingleChildScrollView(child: RepaintBoundary(key: const ValueKey('shot'), child: child))),
          )),
    );

Future<void> _size(WidgetTester t, double w) async {
  t.view.physicalSize = Size(w * 3, 900 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(setUpHomeRender);
  setUp(() => SharedPreferences.setMockInitialValues({FashionBgDim.prefKey: 0.7}));

  testWidgets('tap opens the Fashion Plus home (Settings.fashionHome)', (t) async {
    await _size(t, 390);
    await Settings.instance.setFashionHome(false);
    await t.pumpWidget(_app(const NFashionPlusEntryLive()));
    await t.tap(find.text('Fashion Plus'));
    await t.pump(const Duration(milliseconds: 700));
    expect(Settings.instance.fashionHome, isTrue);
    await Settings.instance.setFashionHome(false);
  });

  testWidgets('bgDim reflects the stored FashionBgDim and updates live', (t) async {
    await FashionBgDim.instance.load();
    await t.pumpWidget(_app(const NFashionPlusEntryLive()));
    double dim() => t.widget<NFashionPlusEntry>(find.byType(NFashionPlusEntry)).bgDim!;
    expect(dim(), closeTo(0.7, 1e-9));
    await FashionBgDim.instance.set(0.2, persist: false);
    await t.pump();
    expect(dim(), closeTo(0.2, 1e-9));
    await FashionBgDim.instance.set(FashionBgDim.defaultDim, persist: false);
  });

  for (final (w, s) in const [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('no overflow / ellipsis / mid-word break at $w@$s', (t) async {
      await _size(t, w);
      await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: .45), scale: s));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject! as RenderParagraph;
        expect(r.didExceedMaxLines, isFalse);
        expect(r.overflow, isNot(TextOverflow.ellipsis));
        if (!homeFontsReady) continue;
        final text = r.text.toPlainText();
        // every line break must fall on a space
        final tp = TextPainter(text: r.text, textDirection: TextDirection.ltr, textScaler: r.textScaler)
          ..layout(maxWidth: r.constraints.maxWidth);
        var off = 0;
        while (off < text.length) {
          final end = tp.getLineBoundary(TextPosition(offset: off)).end;
          if (end <= off) break;
          if (end < text.length) {
            final ok = text[end - 1] == ' ' || text[end] == ' ' || text[end - 1] == '\n';
            expect(ok, isTrue, reason: 'mid-word break in "$text" at $end');
          }
          off = end;
          while (off < text.length && text[off] == ' ') {
            off++;
          }
        }
        tp.dispose();
      }
    });
  }

  testWidgets('reduced motion: tap enters at once', (t) async {
    var hit = 0;
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () => hit++), reduced: true));
    await t.tap(find.text('Fashion Plus'));
    await t.pump();
    expect(hit, 1);
  });

  testWidgets('dim overlay sits below the ripples and the neon', (t) async {
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: .7)));
    final order = [
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String>).evaluate())
        (e.widget.key! as ValueKey<String>).value
    ].where((k) => k.startsWith('fp-entry-')).toList();
    expect(order, ['fp-entry-dim', 'fp-entry-rings', 'fp-entry-neon']);
  });

  Future<Uint8List> grab(WidgetTester t, double dim) async {
    await _size(t, 390);
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: dim)));
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 300));
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    late Uint8List out;
    await t.runAsync(() async {
      final img = await b.toImage(pixelRatio: 1);
      out = (await img.toByteData(format: ImageByteFormat.rawRgba))!.buffer.asUint8List();
    });
    return out;
  }

  // Mean brightness of the brightest pixels = the neon plus and its outline.
  double neon(Uint8List px) {
    final v = <int>[for (var i = 0; i < px.length; i += 4) if (px[i + 2] > px[i + 1] + 40) px[i] + px[i + 1] + px[i + 2]]..sort();
    final top = v.sublist(v.length - 300);
    return top.reduce((a, b) => a + b) / top.length;
  }

  testWidgets('neon plus is as bright at dim 0.7 as at dim 0', (t) async {
    final a = neon(await grab(t, 0)), b = neon(await grab(t, .7));
    expect(b, greaterThan(a * .95), reason: 'dim 0: $a, dim .7: $b');
  });

  for (final (name, w, s) in const [('390', 390.0, 1.0), ('320-1.3', 320.0, 1.3)]) {
    for (final d in const [45, 70]) {
      testWidgets('shot $name dim$d', (t) async {
      await _size(t, w);
      await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {}, bgDim: d / 100), scale: s));
      await precacheAll(t);
      await t.pump(const Duration(milliseconds: 300));
      final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      await t.runAsync(() async {
        final img = await b.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ImageByteFormat.png);
        // Screenshots are optional: only written where the shots folder exists.
        final dir = Directory('/workspace/team-plan/shots');
        if (dir.existsSync()) {
          File('${dir.path}/fpentry-build-$name-dim$d.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      });
    });
    }
  }
}
