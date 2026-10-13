import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:nowssb/features/ebooks/newui/ebooks_page.dart';
import 'package:nowssb/features/ebooks/newui/ebooks_source.dart';

class FakeSource implements EbooksSource {
  FakeSource({this.books = kEbBooks, this.fail = false, this.offline = false, this.owned = const {}, this.delay = Duration.zero});
  final List<EbBook> books;
  final bool fail;
  @override
  final bool offline;
  final Set<String> owned;
  final Duration delay;
  @override
  Future<List<EbBook>> load() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw Exception('boom');
    return books;
  }
  @override
  num priceOf(EbBook b) => b.price;
  @override
  int priceCents(EbBook b) => ebookCatalogToCents(b.price);
  @override
  bool owns(EbBook b) => owned.contains(b.key);
}

Widget _app(EbooksSource s, [EbooksActions a = const EbooksActions()]) =>
    MaterialApp(home: EbooksNewUiPage(source: s, actions: a, reduceEffects: true));

void main() {
  setUp(() {
    final b = TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    b.platformDispatcher.views.first.devicePixelRatio = 2.6;
  });
  testWidgets('loading then library', (t) async {
    await t.pumpWidget(_app(FakeSource(delay: const Duration(milliseconds: 50))));
    expect(find.byKey(const Key('eb-loading')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 60));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.text('Library'), findsOneWidget);
    expect(find.byKey(Key('eb-card-${kEbBooks.first.key}')), findsOneWidget);
  });

  testWidgets('empty state', (t) async {
    await t.pumpWidget(_app(FakeSource(books: const [])));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.byKey(const Key('eb-empty')), findsOneWidget);
  });

  testWidgets('error state with retry', (t) async {
    await t.pumpWidget(_app(FakeSource(fail: true)));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.byKey(const Key('eb-error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.byKey(const Key('eb-error')), findsOneWidget);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(FakeSource(fail: true, offline: true)));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.byKey(const Key('eb-offline')), findsOneWidget);
  });

  testWidgets('offline banner with cached library', (t) async {
    await t.pumpWidget(_app(FakeSource(offline: true)));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.byKey(const Key('eb-offline-banner')), findsOneWidget);
  });

  testWidgets('detail flow: buy, gift, coupon', (t) async {
    final calls = <String>[];
    await t.pumpWidget(_app(
        FakeSource(),
        EbooksActions(
          buy: (_, b) => calls.add('buy:${b.key}'),
          gift: (_, b) => calls.add('gift'),
          coupon: (_, b) => calls.add('coupon'),
        )));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    await t.tap(find.byKey(Key('eb-card-${kEbBooks.first.key}')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('eb-sample')), findsOneWidget);
    await t.scrollUntilVisible(find.text('Buy'), 100, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Buy'));
    await t.scrollUntilVisible(find.text('Gift'), 100, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Gift'));
    await t.tap(find.text('Add coupon'));
    expect(calls, ['buy:${kEbBooks.first.key}', 'gift', 'coupon']);
  });

  testWidgets('owned book opens reader', (t) async {
    var read = 0;
    await t.pumpWidget(_app(FakeSource(owned: {kEbBooks.first.key}), EbooksActions(read: (_, __) => read++)));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    await t.tap(find.byKey(Key('eb-card-${kEbBooks.first.key}')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Open in Reader'), 100, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Open in Reader'));
    expect(read, 1);
  });

  testWidgets('how it works carousel', (t) async {
    await t.pumpWidget(_app(FakeSource()));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    await t.tap(find.byTooltip('How it works'));
    await t.pumpAndSettle();
    expect(find.text('Browse'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    expect(find.text('Preview'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 5));
    await t.pump();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.text('Read anywhere'), findsNothing);
  });

  test('newui_ebooks: off for users, on for admins, remote switch wins', () {
    expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: null)), isFalse);
    expect(NewUi.decide(const NewUiInputs(isAdmin: true, remote: null)), isTrue);
    expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: true)), isTrue);
  });

  test('storeEbooks route uses the ebooks flag', () {
    expect(AppRoutes.byScreenId('store.ebooks')?.flag, 'ebooks');
  });

  test('catalog price converts to USD cents, never shown 1:1', () {
    expect(ebookCatalogToCents(835), 1000); // 835 at 83.5/USD = 10.00 USD
    expect(KitMoney.cents(ebookCatalogToCents(499), locale: 'en_US'), isNot(contains('499')));
  });
}
