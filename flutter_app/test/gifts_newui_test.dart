import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/features/gifts/newui/gifts_flag.dart';
import 'package:nowssb/features/gifts/newui/gifts_hub_page.dart';

const _catalog = [GiftItem('word', 'Word card', 99), GiftItem('basic7', '7-day Basic', 79)];

Widget _app(GiftsSnapshot s, {VoidCallback? retry, void Function(String)? buy, GiftsRedeem? redeem, String? tab, VoidCallback? coins}) => MaterialApp(
      home: GiftsHubView(
        snapshot: s,
        animate: false,
        onRetry: retry ?? () {},
        onBuy: buy ?? (_) {},
        onRedeem: redeem ?? (c) async => 'Word card',
        initialTab: tab,
        onCoins: coins,
      ),
    );

void main() {
  test('flag: override wins, default on for everyone', () {
    expect(newUiGiftsEnabled(override: true), isTrue);
    expect(newUiGiftsEnabled(), isTrue);
  });

  testWidgets('loading state', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot()));
    expect(find.byKey(const Key('gifts.loading')), findsOneWidget);
  });

  testWidgets('error state retries', (t) async {
    var n = 0;
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.error), retry: () => n++));
    expect(find.byKey(const Key('gifts.error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    expect(n, 1);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.offline)));
    expect(find.byKey(const Key('gifts.offline')), findsOneWidget);
  });

  testWidgets('empty state shows hub and empty card', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog)));
    expect(find.text('Send a calm moment'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('gifts.empty')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('gifts.empty')), findsOneWidget);
  });

  testWidgets('free gifts progress', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog, minutesToday: 5, minutesTarget: 15)));
    expect(find.text('10 more minutes for today\'s free gift.'), findsOneWidget);
  });

  testWidgets('buy flow picks a card', (t) async {
    String? picked;
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog), buy: (id) => picked = id));
    await t.tap(find.byKey(const Key('gifts.send')));
    await t.pumpAndSettle();
    await t.tap(find.text('7-day Basic').last);
    await t.pumpAndSettle();
    expect(picked, 'basic7');
  });

  testWidgets('redeem flow', (t) async {
    String? code;
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog), redeem: (c) async {
      code = c;
      return 'Word card';
    }));
    await t.tap(find.text('Redeem'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('gifts.code')), 'ABC123');
    await t.tap(find.byKey(const Key('gifts.redeem')));
    await t.pumpAndSettle();
    expect(code, 'ABC123');
    expect(find.text('Opened: Word card'), findsOneWidget);
  });

  testWidgets('my gifts tabs with expired', (t) async {
    const entries = [
      GiftsEntry(title: 'Word card', note: 'From Asha', direction: 'received', status: 'active'),
      GiftsEntry(title: 'Basic', note: '', direction: 'sent', status: 'active'),
      GiftsEntry(title: 'Old', note: '', direction: 'received', status: 'expired'),
    ];
    await t.pumpWidget(const MaterialApp(home: GiftsMineView(entries: entries, animate: false)));
    expect(find.text('From Asha'), findsOneWidget);
    await t.tap(find.text('Expired'));
    await t.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
  });

  testWidgets('coin chip shows balance and opens coins', (t) async {
    var n = 0;
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog, coins: 120), coins: () => n++));
    expect(find.text('120'), findsOneWidget);
    await t.tap(find.byKey(const Key('gifts.coins')));
    expect(n, 1);
  });

  testWidgets('redeem deep link opens the redeem sheet', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog), tab: 'redeem'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('gifts.code')), findsOneWidget);
  });

  testWidgets('how-it-works card: Next walks the steps, Skip jumps to the end', (t) async {
    await t.pumpWidget(_app(const GiftsSnapshot(load: GiftsLoad.ready, catalog: _catalog)));
    expect(find.text('Send a calm moment'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.text('Add a message'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pump();
    expect(find.text('They open it'), findsOneWidget);
    expect(find.text('Start again'), findsOneWidget);
  });
}
