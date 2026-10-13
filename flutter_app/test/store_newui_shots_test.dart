import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';
import 'package:nowssb/screens/store/newui/store_feed.dart';
import 'package:nowssb/screens/store/newui/store_page.dart';

/// Writes phone-size PNGs of the rebuilt Store (flag-on page) when
/// STORE_SHOTS_DIR is set; otherwise just smoke-renders.
void main() {
  final dir = Platform.environment['STORE_SHOTS_DIR'];
  setUpAll(_loadFonts);
  Future<void> shot(WidgetTester t, String name, Widget Function(Widget bg) page, {double scroll = 0}) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'Roboto'), home: page(Image.asset(Settings.fashionImages.first, fit: BoxFit.cover))),
      ),
    ));
    await t.pump();
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
      final ctx = find.byType(Scaffold).evaluate().first;
      for (final c in NCircles.all) {
        await precacheImage(c, ctx);
      }
    });
    await t.pump();
    if (scroll > 0) {
      await t.drag(find.byType(ListView).first, Offset(0, -scroll));
      await t.pump();
    }
    if (dir == null) return;
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  testWidgets('store-1 hub top', (t) async => shot(t, 'store-1', (b) => NewStorePage(loader: bundledStoreRails, background: b)));
  testWidgets('store-2 hub list', (t) async => shot(t, 'store-2', (b) => NewStorePage(loader: bundledStoreRails, background: b), scroll: 420));
  testWidgets('store-3 empty', (t) async => shot(t, 'store-3', (b) => NewStorePage(loader: () async => [], background: b)));
  testWidgets('store-4 offline', (t) async => shot(t, 'store-4', (b) => NewStorePage(loader: () async => throw const SocketException('x'), background: b)));
  testWidgets('words-1', (t) async => shot(t, 'words-1', (b) => StoreDeptPage(dept: StoreDept.words, loader: bundledStoreRails, background: b)));
  testWidgets('words-2', (t) async => shot(t, 'words-2', (b) => StoreDeptPage(dept: StoreDept.words, loader: bundledStoreRails, background: b), scroll: 420));
  testWidgets('meanings-1', (t) async => shot(t, 'meanings-1', (b) => StoreDeptPage(dept: StoreDept.meanings, loader: bundledStoreRails, background: b)));
  testWidgets('meanings-2', (t) async => shot(t, 'meanings-2', (b) => StoreDeptPage(dept: StoreDept.meanings, loader: bundledStoreRails, background: b), scroll: 420));
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter';
  final d = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!d.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in d.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
    if (n.startsWith('MaterialIcons')) icons.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await roboto.load();
  await icons.load();
}
