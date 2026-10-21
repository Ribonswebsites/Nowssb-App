import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';
import 'package:nowssb/features/ebooks_v2/ebooks_data.dart';
import 'package:nowssb/features/ebooks_v2/ebooks_pages.dart';

class FakeData implements EbooksData {
  FakeData({this.books = kEbBooks, this.fail = false, this.offline = false, Set<String>? owned, this.seen = true}) : owned = owned ?? {};
  final List<EbBook> books;
  final bool fail;
  @override
  final bool offline;
  final Set<String> owned;
  bool seen;
  final progress = <String, int>{};
  @override
  Future<List<EbBook>> load() async {
    if (fail) throw Exception('x');
    return books;
  }
  @override
  bool owns(EbBook b) => owned.contains(b.key);
  @override
  String priceLabel(EbBook b) => catalogPriceLabel(b.price);
  @override
  Future<bool> guideSeen() async => seen;
  @override
  Future<void> markGuideSeen() async => seen = true;
  @override
  int progressOf(EbBook b) => progress[b.key] ?? 0;
  @override
  void saveProgress(EbBook b, int c) => progress[b.key] = c;
}

final b0 = kEbBooks.first;

Future<void> _fonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final r = FontLoader('Roboto'), i = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) r.addFont(f.readAsBytes().then(ByteData.sublistView));
    if (n.startsWith('MaterialIcons')) i.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await r.load();
  await i.load();
}

Future<void> pumpPage(WidgetTester t, FakeData d, {EbooksActions a = const EbooksActions()}) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 2.75;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Roboto'),
    home: EbooksV2Page(key: UniqueKey(), data: d, actions: a, background: const ColoredBox(color: Color(0xFF1B1530))),
  ));
  await t.pump(const Duration(milliseconds: 5));
  await t.pump();
}

/// Home's Reader film rotates its line every 2 s and keeps painting, so the
/// page never "settles"; advance 1.2 s (longer than every transition here).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> shot(String n) => expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ebooks_v2/ebooks-v3-$n.png'));

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await _fonts();
  });
  tearDown(VideoPool.instance.debugDropAll);
  // Pin FX so prices render converted and deterministic (main shows
  // FxBook.pricePending until config/fx loads).
  setUp(() => FxBook.instance.rates = const {'USD': 1, 'INR': 83.5});

  testWidgets('library: discover carousel + rows', (t) async {
    await pumpPage(t, FakeData());
    expect(find.byKey(Key('eb-card-${b0.key}')), findsOneWidget);
    expect(find.byKey(const Key('eb-home-reader')), findsOneWidget);
    expect(find.text('Meanings and eBooks, in one place'), findsWidgets);
    expect(find.text('Every eBook'), findsWidgets);
    expect(find.text('Reader'), findsOneWidget);
    await shot('1');
    await t.scrollUntilVisible(find.byKey(Key('eb-row-${b0.key}')), 200, scrollable: find.byType(Scrollable).at(1));
    expect(find.byKey(Key('eb-row-${b0.key}')), findsOneWidget);
  });

  testWidgets('empty / error / offline states', (t) async {
    await pumpPage(t, FakeData(books: const []));
    expect(find.byKey(const Key('eb-empty')), findsOneWidget);
    await pumpPage(t, FakeData(fail: true));
    expect(find.byKey(const Key('eb-error')), findsOneWidget);
    await shot('5');
    await t.tap(find.text('Try again'));
    await t.pump();
    await pumpPage(t, FakeData(fail: true, offline: true));
    expect(find.byKey(const Key('eb-offline')), findsOneWidget);
  });

  testWidgets('first-use guide shows once and steps through', (t) async {
    final d = FakeData(seen: false);
    await pumpPage(t, d);
    await settle(t);
    expect(find.byKey(const Key('eb-guide')), findsOneWidget);
    await shot('6');
    await t.tap(find.text('Next'));
    await t.pump();
    await t.tap(find.text('Next'));
    await t.pump();
    await t.tap(find.text('Done'));
    await settle(t);
    expect(find.byKey(const Key('eb-guide')), findsNothing);
    expect(d.seen, isTrue);
  });

  testWidgets('tabs: My books and Saved', (t) async {
    await pumpPage(t, FakeData());
    await t.tap(find.text('My books'));
    await settle(t);
    expect(find.byKey(const Key('eb-mine-empty')), findsOneWidget);
    await t.tap(find.text('Discover'));
    await settle(t);
    await t.tap(find.byTooltip('Save').first);
    await t.pump();
    await t.tap(find.text('Saved'));
    await settle(t);
    expect(find.byKey(Key('eb-row-${b0.key}')), findsOneWidget);
  });

  testWidgets('search filters and opens a book', (t) async {
    await pumpPage(t, FakeData());
    await t.tap(find.byTooltip('Search'));
    await settle(t);
    await t.enterText(find.byKey(const Key('eb-search')), 'zzzz');
    await t.pump();
    expect(find.text('No books match. Try another word.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('eb-search')), b0.title.split(' ').last);
    await t.pump();
    await t.tap(find.widgetWithText(ListTile, b0.title));
    await settle(t);
    expect(find.byKey(const Key('eb-chapters')), findsOneWidget);
  });

  testWidgets('detail: buy, gift, coupon, info pop-up', (t) async {
    final calls = <String>[];
    await pumpPage(t, FakeData(), a: EbooksActions(buy: (_, __) => calls.add('buy'), gift: (_, __) => calls.add('gift'), coupon: (_, __) => calls.add('coupon')));
    await t.tap(find.byKey(Key('eb-card-${b0.key}')));
    await settle(t);
    await shot('2');
    await t.tap(find.text('Buy'));
    await t.tap(find.byTooltip('What is the price?'));
    await settle(t);
    await t.tap(find.text('Got it'));
    await settle(t);
    await t.scrollUntilVisible(find.text('Gift'), 100, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Gift'));
    await t.tap(find.text('Add coupon'));
    expect(calls, ['buy', 'gift', 'coupon']);
  });

  testWidgets('reader: sample free, later chapters locked, size + chapters', (t) async {
    final calls = <String>[];
    await pumpPage(t, FakeData(), a: EbooksActions(buy: (_, __) => calls.add('buy')));
    await t.tap(find.byKey(Key('eb-card-${b0.key}')));
    await settle(t);
    await t.tap(find.text('Read a sample'));
    await settle(t);
    expect(find.byKey(const Key('eb-reader')), findsOneWidget);
    expect(find.byKey(const Key('eb-locked')), findsNothing);
    await shot('4');
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.byKey(const Key('eb-locked')), findsOneWidget);
    await t.tap(find.text('Buy to keep reading'));
    expect(calls, ['buy']);
    await t.tap(find.byTooltip('Text size'));
    await settle(t);
    expect(find.byKey(const Key('eb-size')), findsOneWidget);
    await t.tap(find.text('Done'));
    await settle(t);
    await t.tap(find.byTooltip('Chapters'));
    await settle(t);
    await t.tap(find.textContaining('1. '));
    await settle(t);
    expect(find.byKey(const Key('eb-locked')), findsNothing);
  });

  testWidgets('owned book: My books, continue reading saves progress', (t) async {
    final d = FakeData(owned: {b0.key});
    await pumpPage(t, d);
    await t.tap(find.text('My books'));
    await settle(t);
    await t.tap(find.byKey(Key('eb-row-${b0.key}')));
    await settle(t);
    await shot('3');
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.byKey(const Key('eb-locked')), findsNothing);
    expect(d.progress[b0.key], 1);
  });

  test('price uses FxBook: converted when rates load, never relabelled', () {
    expect(catalogPriceLabel(499), isNot(contains('499')));
    expect(catalogPriceLabel(835), contains('10'));
  });

  test('price waits for FX instead of guessing', () {
    FxBook.instance.rates = const {'USD': 1};
    expect(catalogPriceLabel(499), isNot(contains(r'$499')));
  });

  testWidgets('library shows converted local prices, not a placeholder', (t) async {
    await pumpPage(t, FakeData());
    expect(find.text(FxBook.pricePending), findsNothing);
    expect(find.text(catalogPriceLabel(b0.price)), findsWidgets);
  });
}
