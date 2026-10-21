import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/widgets/colored_split_promo_banner.dart';

final _key = GlobalKey();
final _out = Platform.environment['GIFT_SHOTS'];

Future<void> _fonts() async {
  const d = '/workspace/flutter/bin/cache/artifacts/material_fonts';
  final l = FontLoader('Roboto');
  for (final f in Directory(d).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) l.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await l.load();
}

Future<void> _shot(WidgetTester t, String name) async {
  final ctx = t.element(find.byType(Scaffold).first);
  await t.runAsync(() async {
    for (final a in SplitPromoArts.all + [for (var i = 1; i <= 10; i++) 'assets/banners/promo/pose-${i.toString().padLeft(2, '0')}.png']) {
      try { await precacheImage(AssetImage(a), ctx); } catch (_) {}
    }
  });
  await t.pump(const Duration(milliseconds: 600));
  if (_out == null) return;
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _app(List<Widget> kids) => RepaintBoundary(
    key: _key,
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(backgroundColor: const Color(0xFF07070C), body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: kids)))));

void main() {
  testWidgets('gifts split cards render', (t) async {
    if (_out != null) await t.runAsync(_fonts);
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    var tapped = '';
    await t.pumpWidget(_app([
      GiftSplitCard(index: 1, title: 'Send a gift\nsomeone keeps.', cta: 'Send a gift', onTap: () => tapped = 'send'),
      const GiftSplitCard(index: 3, title: 'Got a code?\nOpen it here.', cta: 'Redeem'),
      const GiftSplitCard(index: 2, title: 'Free gifts for\nyour time today.', cta: 'Open free gifts'),
    ]));
    await _shot(t, 'gifts-1.png');
    await t.tap(find.text('Send a gift'));
    expect(tapped, 'send');
    await t.pumpWidget(_app([
      for (final (i, c) in kGiftCatalog.take(5).indexed)
        GiftSplitCard(index: i, title: '${c.label}\n${i == 0 ? 'Selected' : 'Price on Google Play'}', cta: i == 0 ? 'Write the card' : 'Choose'),
    ]));
    await _shot(t, 'gifts-2.png');
    expect(find.text('Write the card'), findsOneWidget);
    await t.pumpWidget(_app([Builder(builder: (c) => TextButton(onPressed: () => showGiftsGuide(c), child: const Text('go')))]));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await _shot(t, 'gifts-3.png');
  });
}
