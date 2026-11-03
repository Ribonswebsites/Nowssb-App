// Normal home v5 sections: every action reaches its callback, nothing is
// invented when a real source is missing, and no section overflows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/widgets/concept/normal/ebooks.dart';
import 'package:nowssb/widgets/concept/normal/edition.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/concept/normal/footer.dart';
import 'package:nowssb/widgets/concept/normal/own.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:nowssb/widgets/concept/normal/trending.dart';

import 'support/home_render.dart';

Finder _act(String l) => find.byWidgetPredicate(
    (w) => (w is NPress && w.label == l) || (w is Semantics && w.properties.button == true && w.properties.label == l));

Future<void> _pump(WidgetTester t, Widget child, {double w = 390, double ts = 1}) async {
  t.view.physicalSize = Size(w * 3, 3000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MediaQuery(
    data: MediaQueryData(size: Size(w, 3000), textScaler: TextScaler.linear(ts), disableAnimations: true),
    child: MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await t.pump(const Duration(milliseconds: 300));
}

final _books = [for (final b in kEbBooks) (b.key, b.title)];

List<Widget> _all(List<String> log) => [
      NTrending(words: const ['Om', 'Shanti', 'Prana'], onWord: (w) => log.add('word:$w'), onLibrary: () => log.add('library')),
      NOwn(onCart: () => log.add('cart'), onWishlist: () => log.add('wish'), onOrders: () => log.add('orders'), cartCount: 2, wishlistCount: 0, orderCount: 1),
      NEdition(onJoin: (t) => log.add('join:$t'), prices: const {}, playAvailable: null),
      NEbooks(onBrowse: () => log.add('ebooks'), books: _books),
      NFashionPlusEntry(onEnter: () => log.add('fashion')),
      NFooter(onLink: (k) => log.add('foot:$k')),
    ];

void main() {
  setUpAll(setUpHomeRender);
  testWidgets('every action reaches its callback', (t) async {
    final log = <String>[];
    await _pump(t, Column(children: _all(log)));
    Future<void> tap(String label) async {
      final f = _act(label);
      await t.ensureVisible(f.first);
      await t.tap(f.first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
    }

    for (final l in ['Open Om', 'Open Shanti', 'Everything you own',
        'Join Frequency', 'Browse eBooks', 'Enter Zen Plus']) {
      if (_act(l).evaluate().isEmpty) continue;
      await tap(l);
    }
    await t.ensureVisible(find.text('Open the library  →'));
    await t.tap(find.text('Open the library  →'));
    for (final l in NFooter.links) {
      await tap(l.$1);
    }
    await t.pump(const Duration(seconds: 1));
    for (final want in ['word:Om', 'word:Shanti', 'join:frequency', 'ebooks', 'fashion', 'library',
      for (final l in NFooter.links) 'foot:${l.$2}']) {
      expect(log, contains(want), reason: want);
    }
  });

  testWidgets('own bays call cart, wishlist and orders', (t) async {
    final log = <String>[];
    await _pump(t, NOwn(onCart: () => log.add('cart'), onWishlist: () => log.add('wish'), onOrders: () => log.add('orders')));
    for (final l in ['Cart', 'Wishlist', 'Orders']) {
      await t.tap(_act(l).first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
    }
    expect(log, ['cart', 'wish', 'orders']);
  });

  testWidgets('no fabricated values when sources are missing', (t) async {
    await _pump(t, Column(children: _all([])));
    expect(find.textContaining('40'), findsNothing); // the old invented chest rule
    expect(find.textContaining('to the next chest'), findsNothing);
    expect(find.textContaining('Friends get'), findsNothing); // no referral config
    expect(find.textContaining('points to'), findsNothing); // no partner levels
    expect(find.textContaining('₹'), findsNothing); // no Play price
    expect(find.text('Price on Google Play'.replaceAll(' ', '\u00A0')), findsNothing);
  });

  testWidgets('real config values are shown as given', (t) async {
    await _pump(t, Column(children: [
      NEdition(onJoin: (_) {}, prices: const {'resonance': '₹99', 'frequency': '₹99', 'frequencyX': '₹99'}, playAvailable: true),
    ]));
    expect(find.textContaining('₹99'), findsOneWidget);
  });

  testWidgets('ebooks hide when no catalogue book has bundled art', (t) async {
    await _pump(t, NEbooks(onBrowse: _no, books: const [('not-a-book', 'X')]));
    expect(find.text('NowssB eBooks'), findsNothing);
  });

  for (final (w, ts) in [(320.0, 1.3), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0)]) {
    testWidgets('no overflow at ${w.toInt()} x$ts', (t) async {
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d.exceptionAsString());
        FlutterError.dumpErrorToConsole(d);
      };
      await _pump(t, Column(children: _all([])), w: w, ts: ts);
      await _pump(t, Column(children: [
        NEdition(onJoin: (_) {}, prices: const {'resonance': '₹99', 'frequency': '₹199', 'frequencyX': '₹499'}, playAvailable: true),
        const NOwn(onCart: _no, onWishlist: _no, onOrders: _no, cartCount: 12, wishlistCount: 34, orderCount: 56),
      ]), w: w, ts: ts);
      FlutterError.onError = old;
      expect(errors, isEmpty);
    }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart
  }
}

void _no() {}
