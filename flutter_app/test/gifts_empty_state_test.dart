// B034: with no gift cards the Gifts section/page show an empty state, not a
// blank card row or "0 gift cards from ₹0 · 0 sent · 0 received".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:nowssb/widgets/concept/r27/data.dart';
import 'package:nowssb/widgets/concept/r27/kit.dart';
import 'package:nowssb/widgets/concept/r27/pages.dart';
import 'package:nowssb/widgets/concept/r27/sections.dart';

import 'support/r27_fit.dart';

const empty = R27Gifts(cards: [], sent: 0, received: 0);

void main() {
  setUpAll(loadR27Fonts);
  void g(String id) {}
  Widget all() => ColoredBox(
      color: r27Black,
      child: Column(children: [
        ColoredBox(color: nBase, child: R27GiftsSection(data: empty, onGift: g, onRedeem: () {}, onOpen: () {})),
        R27GiftsSection(fashion: true, data: empty, onGift: g, onRedeem: () {}, onOpen: () {}),
        R27GiftsPage(data: empty, onBack: () {}, onGift: g, onRedeem: () {}, onHistory: () {}),
      ]));

  for (final (w, sc) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('gifts empty state at ${w.toInt()}@$sc', (t) async {
      final key = await pumpR27(t, all(), w, sc, r27Black, height: 3000);
      expect(t.takeException(), isNull);
      expect(find.textContaining('0 gift cards'), findsNothing);
      expect(find.textContaining('₹0'), findsNothing);
      expect(find.textContaining('0 sent'), findsNothing);
      expect(find.byType(R27GiftPoster), findsNothing);
      expect(find.text('No gift cards right now'), findsNWidgets(3));
      expect(find.textContaining('Redeem a gift code'), findsWidgets);
      // Text only: no icon in the empty card; no big SENT 0 / RECEIVED 0.
      for (final e in find.byKey(const ValueKey('gifts-empty')).evaluate()) {
        expect(find.descendant(of: find.byWidget(e.widget), matching: find.byType(Icon)), findsNothing);
      }
      expect(find.byKey(const ValueKey('gifts-counts-empty')), findsOneWidget);
      expect(find.text('SENT'), findsNothing);
      expect(find.text('RECEIVED'), findsNothing);
      await shotR27(t, key, 'B034-${w.toInt()}');
    });
  }

  test('gifts line keeps only real, non-zero parts', () {
    expect(r27GiftsLine(empty, 0), isNull);
    expect(r27GiftsLine(const R27Gifts(cards: [R27Gift('word', 'Word card', 99)], sent: 0, received: 2), 99), '1 gift cards from ₹99 · 2 received');
  });
}
