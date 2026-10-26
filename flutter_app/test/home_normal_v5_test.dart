// Normal home v5 sections: every action reaches its callback, nothing is
// invented when a real source is missing, and no section overflows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/widgets/concept/normal/ebooks.dart';
import 'package:nowssb/widgets/concept/normal/edition.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/concept/normal/footer.dart';
import 'package:nowssb/widgets/concept/normal/invite.dart';
import 'package:nowssb/widgets/concept/normal/own.dart';
import 'package:nowssb/widgets/concept/normal/partner.dart';
import 'package:nowssb/widgets/concept/normal/rewards.dart';
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
      NRewards(coins: 120, streak: 3, signedIn: true, onOpenRewards: () => log.add('rewards'), onSignIn: () => log.add('signin')),
      NInvite(onInvite: () => log.add('invite'), wordPct: null, wordFirstN: null, subscriptionPct: null),
      NTrending(words: const ['Om', 'Shanti', 'Prana'], onWord: (w) => log.add('word:$w'), onLibrary: () => log.add('library')),
      NOwn(onCart: () => log.add('cart'), onWishlist: () => log.add('wish'), onOrders: () => log.add('orders'), cartCount: 2, wishlistCount: 0, orderCount: 1),
      NEdition(onJoin: (t) => log.add('join:$t'), prices: const {}, playAvailable: null),
      NPartner(points: 0, levels: null, onPartner: () => log.add('partner')),
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

    for (final l in ['Open rewards', 'Invite a friend', 'Open Om', 'Open Shanti', 'Everything you own',
        'Join Frequency', 'Open partner program', 'Browse eBooks', 'Enter Fashion Plus']) {
      if (_act(l).evaluate().isEmpty) continue;
      await tap(l);
    }
    await t.ensureVisible(find.text('Open the library  →'));
    await t.tap(find.text('Open the library  →'));
    for (final l in NFooter.links) {
      await tap(l.$1);
    }
    await t.pump(const Duration(seconds: 1));
    for (final want in ['rewards', 'invite', 'word:Om', 'word:Shanti', 'join:frequency', 'partner', 'ebooks', 'fashion', 'library',
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

  testWidgets('signed out rewards ask to sign in', (t) async {
    final log = <String>[];
    await _pump(t, NRewards(coins: 0, streak: 0, signedIn: false, onOpenRewards: () => log.add('r'), onSignIn: () => log.add('s')));
    expect(find.text('Sign in for rewards'), findsOneWidget);
    await t.tap(_act('Sign in').first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    expect(log, ['s']);
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
      const NInvite(onInvite: _no, wordPct: 15, wordFirstN: 3, subscriptionPct: 20),
      const NPartner(points: 120, levels: [('Bronze', 100), ('Silver', 500)], onPartner: _no),
      NEdition(onJoin: (_) {}, prices: const {'resonance': '₹99', 'frequency': '₹99', 'frequencyX': '₹99'}, playAvailable: true),
    ]));
    expect(find.text('Friends get 20% off a first plan and 15% off 3 words.'), findsOneWidget);
    expect(find.text('380 points to Silver'), findsOneWidget);
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
        NRewards(coins: 123456, streak: 7, signedIn: true, onOpenRewards: _no, onSignIn: _no),
        const NInvite(onInvite: _no, wordPct: 15, wordFirstN: 3, subscriptionPct: 20, code: 'ABCD1234'),
        const NPartner(points: 120, levels: [('Bronze', 100), ('Silver', 500), ('Gold', 2000)], onPartner: _no),
        NEdition(onJoin: (_) {}, prices: const {'resonance': '₹99', 'frequency': '₹199', 'frequencyX': '₹499'}, playAvailable: true),
        const NOwn(onCart: _no, onWishlist: _no, onOrders: _no, cartCount: 12, wishlistCount: 34, orderCount: 56),
      ]), w: w, ts: ts);
      FlutterError.onError = old;
      expect(errors, isEmpty);
    }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart
  }
}

void _no() {}
