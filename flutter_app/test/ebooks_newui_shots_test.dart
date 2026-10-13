// Phone-size renders of the rebuilt E-books pages (flag on).
// Regenerate: flutter test test/ebooks_newui_shots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/features/ebooks/newui/ebooks_page.dart';
import 'package:nowssb/features/ebooks/newui/ebooks_source.dart';

class _Src implements EbooksSource {
  _Src({this.books = kEbBooks, this.fail = false, this.owned = const {}});
  final List<EbBook> books;
  final bool fail;
  final Set<String> owned;
  @override
  Future<List<EbBook>> load() async {
    if (fail) throw Exception('x');
    return books;
  }
  @override
  bool get offline => false;
  @override
  num priceOf(EbBook b) => b.price;
  @override
  bool owns(EbBook b) => owned.contains(b.key);
}

Future<void> _fonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto'), icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    if (n.startsWith('MaterialIcons')) icons.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await roboto.load();
  await icons.load();
}

void main() {
  setUpAll(_fonts);
  Future<void> shot(WidgetTester t, EbooksSource s, String name, {bool openFirst = false}) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'Roboto'),
        home: EbooksNewUiPage(source: s, reduceEffects: true)));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    if (openFirst) {
      await t.tap(find.byKey(Key('eb-card-${kEbBooks.first.key}')));
      await t.pumpAndSettle();
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ebooks_newui/$name.png'));
  }

  testWidgets('1 library', (t) => shot(t, _Src(), 'ebooks-1'));
  testWidgets('2 detail', (t) => shot(t, _Src(), 'ebooks-2', openFirst: true));
  testWidgets('3 owned', (t) => shot(t, _Src(owned: {kEbBooks.first.key}), 'ebooks-3', openFirst: true));
  testWidgets('4 empty', (t) => shot(t, _Src(books: const []), 'ebooks-4'));
  testWidgets('5 error', (t) => shot(t, _Src(fail: true), 'ebooks-5'));
}
