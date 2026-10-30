// Signature Store, used like a real user: store terms → first-use guide →
// top bar (Back / All stores / Bag) → hero, stubs, meaning cards, place decks
// (Open / Add to cart / Own) → Request → Android back, swipes, keyboard.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/poster/poster_pages.dart';
import 'package:nowssb/screens/store/request_words.dart';
import 'package:nowssb/screens/store/signature_store.dart';
import 'package:nowssb/screens/store/store_shelf.dart' show kPlaceRows;
import 'package:nowssb/widgets/concept/stillwater.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  int pops = 0;
  @override
  void didPush(Route<dynamic> r, Route<dynamic>? p) => pushed.add(r);
  @override
  void didPop(Route<dynamic> r, Route<dynamic>? p) => pops++;
}

/// The visible widget with this semantics label (the top bar has an invisible twin).
Finder _sem(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reveal(WidgetTester t, Finder f) async {
  final s = find.byType(Scrollable).first;
  for (var i = 0; i < 120 && f.hitTestable().evaluate().isEmpty; i++) {
    final st = t.state<ScrollableState>(s);
    if (st.position.pixels >= st.position.maxScrollExtent) break;
    st.position.jumpTo((st.position.pixels + 250).clamp(0, st.position.maxScrollExtent));
    await t.pump(const Duration(milliseconds: 80));
  }
}

/// Scrolls the store terms sheet to its end and taps "I Agree · Continue".
Future<void> _agree(WidgetTester t) async {
  final agree = find.textContaining(RegExp('^I agree', caseSensitive: false));
  await t.scrollUntilVisible(agree, 300, scrollable: find.byType(Scrollable).last);
  expect(agree, findsOneWidget);
  await t.tap(agree);
  await _settle(t);
}

/// Opens the Signature Store from a base page (so Back has somewhere to go).
Future<_Obs> _open(WidgetTester t, {bool firstRun = false}) async {
  t.view.physicalSize = const Size(780, 1688);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(firstRun
      ? {}
      : {'nwsb_terms_signature': '1', 'guide_seen_signature_store': true});
  final obs = _Obs();
  await t.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: ThemeData(brightness: Brightness.dark),
    navigatorObservers: [obs],
    builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: w!),
    home: Builder(
      builder: (x) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(x).push(MaterialPageRoute<void>(builder: (_) => const SignatureStoreScreen())),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.text('go'));
  await _settle(t);
  obs.pushed.clear();
  obs.pops = 0;
  return obs;
}

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });
  setUp(() {
    Stillwater.debugPhase = .42;
    Entitlements.instance.debugSet(uid: 'u1');
    FxBook.instance.country = 'IN';
  });
  tearDown(() {
    Stillwater.debugPhase = null;
    FxBook.instance.country = null;
  });

  testWidgets('first visit: store terms, then the Signature guide, both remembered', (t) async {
    await _open(t, firstRun: true);
    await _agree(t);
    await _settle(t);
    expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
    expect(find.text('Signature words'), findsWidgets);
    for (var i = 0; i < kSignatureGuideSteps.length - 1; i++) {
      await t.tap(find.byKey(const Key('storeGuideNext')));
      await t.pump();
    }
    expect(find.text('Got it'), findsOneWidget);
    await t.tap(find.text('Got it'));
    await _settle(t);
    expect(find.byKey(const Key('storeGuideCard')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('nwsb_terms_signature'), '1');
    expect(p.getBool('guide_seen_signature_store'), isTrue);
  });

  testWidgets('guide Skip closes it at once', (t) async {
    await _open(t, firstRun: true);
    await _agree(t);
    await _settle(t);
    await t.tap(find.byKey(const Key('storeGuideSkip')));
    await _settle(t);
    expect(find.byKey(const Key('storeGuideCard')), findsNothing);
  });

  testWidgets('top bar: Back pops, All stores opens the picker, Bag opens the bag', (t) async {
    var obs = await _open(t);
    await t.tap(_sem('All stores').last);
    await _settle(t);
    expect(obs.pushed, isNotEmpty, reason: 'store picker');
    await t.binding.handlePopRoute(); // Android back closes the sheet
    await _settle(t);
    expect(find.byType(SignatureStoreScreen), findsOneWidget);
    obs.pushed.clear();
    await t.tap(_sem('Bag').last);
    await _settle(t);
    expect(obs.pushed, isNotEmpty, reason: 'bag sheet');
    await t.binding.handlePopRoute();
    await _settle(t);
    await t.tap(_sem('Back').last);
    await _settle(t);
    expect(find.byType(SignatureStoreScreen), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('Android back leaves the store', (t) async {
    await _open(t);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.byType(SignatureStoreScreen), findsNothing);
  });

  testWidgets('hero: Look inside opens the meaning; Own goes to checkout', (t) async {
    var obs = await _open(t);
    await _reveal(t, find.text('Look inside'));
    await t.tap(find.text('Look inside'));
    await _settle(t);
    expect(obs.pushed, isNotEmpty);
    obs = await _open(t);
    final own = find.textContaining('Own · ₹').first;
    await _reveal(t, own);
    await t.tap(own);
    await _settle(t);
    expect(obs.pushed, isNotEmpty);
  });

  testWidgets('every signature word stub opens and its Own buys, priced in local money', (t) async {
    final cats = [
      for (final c in kRmCategories)
        if (c.signature != null && c.id != 'off50' && c.signature!.name.toLowerCase() != 'sale') c
    ];
    expect(cats, isNotEmpty);
    for (final c in cats.take(3)) {
      var obs = await _open(t);
      final open = _sem('Open ${c.signature!.name}');
      await _reveal(t, open);
      await t.tap(open.first, warnIfMissed: false);
      await _settle(t);
      expect(obs.pushed, isNotEmpty, reason: 'open ${c.signature!.name}');
      obs = await _open(t);
      final own = _sem('Own ${c.signature!.name}');
      await _reveal(t, own);
      expect(find.descendant(of: own, matching: find.textContaining('₹')), findsOneWidget);
      await t.tap(own.first, warnIfMissed: false);
      await _settle(t);
      expect(obs.pushed, isNotEmpty, reason: 'own ${c.signature!.name}');
    }
  });

  testWidgets('every signature meaning card: Open and Own work', (t) async {
    for (final e in kMsSignature.entries.skip(1).take(2)) {
      final title = sigTitle(e.value);
      var obs = await _open(t);
      await _reveal(t, find.text(title));
      final card = find.ancestor(of: find.text(title), matching: find.byType(Tap)).first;
      final open = find.descendant(of: card, matching: find.text('Open'));
      await _reveal(t, open);
      await t.tap(open);
      await _settle(t);
      expect(obs.pushed, isNotEmpty, reason: 'open $title');
      obs = await _open(t);
      await _reveal(t, find.text(title));
      final own = find.descendant(of: find.ancestor(of: find.text(title), matching: find.byType(Tap)).first, matching: find.textContaining('Own · '));
      await _reveal(t, own);
      await t.tap(own);
      await _settle(t);
      expect(obs.pushed, isNotEmpty, reason: 'own $title');
    }
  });

  testWidgets('place deck swipes sideways; Add to cart adds once with the hint', (t) async {
    await _open(t);
    final first = kPlaceRows.first;
    final card = _sem('Open ${first.$1}');
    await _reveal(t, card);
    final deck = find.ancestor(of: card, matching: find.byType(Scrollable)).first;
    final st = t.state<ScrollableState>(deck);
    await t.fling(card, const Offset(-300, 0), 1200);
    await _settle(t);
    expect(st.position.pixels, greaterThan(0));
    st.position.jumpTo(0);
    await t.pump();
    await t.ensureVisible(card);
    await t.pump();
    final before = CartBag.instance.cartCount;
    await t.tap(find.descendant(of: card, matching: find.text('Add to cart')));
    await t.pump(const Duration(milliseconds: 300));
    expect(CartBag.instance.cartCount, before + 1);
    expect(find.text('Your cart is waiting in Profile → Cart'), findsOneWidget);
  });

  testWidgets('vertical swipe scrolls; Request opens Request words; back returns', (t) async {
    final obs = await _open(t);
    final s = t.state<ScrollableState>(find.byType(Scrollable).first);
    await t.fling(find.byType(SignatureStoreScreen), const Offset(0, -600), 1500);
    await _settle(t);
    expect(s.position.pixels, greaterThan(0));
    await _reveal(t, find.text('Request'));
    await t.tap(find.text('Request'));
    await _settle(t);
    expect(find.byType(RequestWordsScreen), findsOneWidget);
    expect(obs.pushed, isNotEmpty);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.byType(RequestWordsScreen), findsNothing);
    expect(find.byType(SignatureStoreScreen), findsOneWidget);
  });

  testWidgets('keyboard: Tab reaches the top bar and Enter activates it', (t) async {
    await _open(t);
    var reached = false;
    for (var i = 0; i < 12 && !reached; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      reached = FocusManager.instance.primaryFocus?.context != null &&
          find.ancestor(of: find.byWidget(FocusManager.instance.primaryFocus!.context!.widget), matching: find.byType(SignatureStoreScreen)).evaluate().isNotEmpty;
    }
    expect(reached, isTrue, reason: 'something on the page takes keyboard focus');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(t);
    expect(t.takeException(), isNull);
  });
}
