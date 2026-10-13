// Renders phone-size PNGs of the newui_earnings page to /workspace/screens
// when EARNINGS_SHOTS=1. Skipped in CI.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/earnings/earnings_models.dart';
import 'package:nowssb/pages/earnings/earnings_page.dart';

import 'earnings_newui_test.dart' show FakeProvider, ready;

/// Poster frame of the app's original background video.
const _poster = AssetImage('assets/video/fashion-plus-bg-6-poster.webp');
const _fonts = '/workspace/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  final loader = FontLoader('Roboto');
  for (final f in Directory(_fonts).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  await (FontLoader('MaterialIcons')
        ..addFont(File('$_fonts/MaterialIcons-Regular.otf').readAsBytes().then(ByteData.sublistView)))
      .load();
}

String _usd(int c, {String? locale}) => '\$${(c / 100).toStringAsFixed(2)}';

void main() {
  final on = Platform.environment['EARNINGS_SHOTS'] == '1';

  Future<void> render(WidgetTester t, EarningsData d, String name, {double scrollTo = 0, bool sheet = false}) async {
    await t.runAsync(_loadFonts);
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(RepaintBoundary(key: const ValueKey('shot'), child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844), disableAnimations: true, padding: EdgeInsets.only(top: 47)),
        child: EarningsNewUiPage(data: d, provider: FakeProvider(), money: _usd,
            background: const Image(image: _poster, fit: BoxFit.cover)),
      ),
    )));
    await t.runAsync(() async {
      for (final e in t.allElements.toList()) {
        final w = e.widget;
        if (w is Image) await precacheImage(w.image, e);
        if (w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).image != null) {
          await precacheImage((w.decoration as BoxDecoration).image!.image, e);
        }
      }
    });
    await t.pump(const Duration(milliseconds: 500));
    if (scrollTo > 0) {
      await t.drag(find.byKey(const ValueKey('earnings-ready')), Offset(0, -scrollTo));
      await t.pump(const Duration(milliseconds: 500));
    }
    if (sheet) {
      await t.drag(find.byType(PageView), const Offset(-300, 0));
      await t.pump(const Duration(milliseconds: 600));
      await t.tap(find.text('Next').hitTestable().first);
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.byKey(const ValueKey('country-DE')));
      await t.pump(const Duration(milliseconds: 300));
    }
    final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/workspace/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('1 hub', (t) => render(t, ready, 'earnings-1'), skip: !on);
  testWidgets('2 list', (t) => render(t, ready, 'earnings-2', scrollTo: 300), skip: !on);
  testWidgets('3 payout setup', (t) => render(t, ready, 'earnings-3', sheet: true), skip: !on);
  testWidgets('4 empty', (t) => render(t, const EarningsData(status: EarningsStatus.empty), 'earnings-4'), skip: !on);
  testWidgets('5 offline', (t) => render(t, const EarningsData(status: EarningsStatus.offline), 'earnings-5'), skip: !on);
}
