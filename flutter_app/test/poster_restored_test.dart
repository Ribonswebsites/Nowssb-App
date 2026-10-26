// Poster pages: the restored store features (Signature place decks + Request a
// Signature, Meanings / Atelier search with their no-match notes and Request
// words, the cart hint), the Signature fixes (full-size stub line, no repeated
// title, 'NowssB' wordmark), legible Atelier price tags and the PIE ₂ glyph.
// POSTER_SHOTS=<dir> also writes the zoomed ₂ crop and restored-section shots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/billing_config.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/poster/poster_pages.dart';
import 'package:nowssb/screens/store/request_words.dart';
import 'package:nowssb/screens/store/store_shelf.dart' show kPlaceRows;
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/concept/stillwater.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = String.fromEnvironment('POSTER_SHOTS');

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> r, Route<dynamic>? p) => pushed.add(r);
}

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

Future<_Obs> _pump(WidgetTester t, Widget Function(BuildContext) page, {double width = 390, double height = 844, double scale = 1, GlobalKey? key}) async {
  t.view.physicalSize = Size(width * 2, height * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final obs = _Obs();
  await t.pumpWidget(RepaintBoundary(
    key: key,
    child: MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, fontFamily: 'DM Sans', scaffoldBackgroundColor: NwsbColors.ink),
      navigatorObservers: [obs],
      builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true), child: w!),
      home: Builder(builder: page),
    ),
  ));
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
  obs.pushed.clear();
  return obs;
}

/// A Semantics widget by its label (no semantics tree needed).
Finder _sem(Pattern label) => find.byWidgetPredicate((w) {
      final l = w is Semantics ? w.properties.label : null;
      return l != null && (label is RegExp ? label.hasMatch(l) : l == label);
    });

/// Let the hero photos decode before a shot.
Future<void> _photos(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _settleRoute(WidgetTester t) async {
  await t.pump();
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reveal(WidgetTester t, Finder f) async {
  final s = find.byType(Scrollable).first;
  for (var i = 0; i < 80 && f.hitTestable().evaluate().isEmpty; i++) {
    final st = t.state<ScrollableState>(s);
    if (st.position.pixels >= st.position.maxScrollExtent) break;
    st.position.jumpTo((st.position.pixels + 250).clamp(0, st.position.maxScrollExtent));
    await t.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shotOf(GlobalKey key, String name, {Rect? crop, double zoom = 1}) async {
  final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await ro.toImage(pixelRatio: 2 * zoom);
  ui.Image out = img;
  if (crop != null) {
    final rec = ui.PictureRecorder();
    final r = Rect.fromLTWH(crop.left * 2 * zoom, crop.top * 2 * zoom, crop.width * 2 * zoom, crop.height * 2 * zoom);
    Canvas(rec).drawImageRect(img, r, Offset.zero & r.size, Paint()..filterQuality = FilterQuality.none);
    out = await rec.endRecording().toImage(r.width.round(), r.height.round());
  }
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  File('$_shots/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await _font('NotoSansPIE', 'assets/fonts/NotoSans-PIE.ttf');
    await _font('Anton', 'assets/fonts/Anton-Regular.ttf');
    if (_shots.isNotEmpty) Directory(_shots).createSync(recursive: true);
  });
  setUp(() {
    Stillwater.debugPhase = .42;
    Entitlements.instance.debugSet(uid: 'u1');
    FxBook.instance.country = 'IN';
    SharedPreferences.setMockInitialValues({
      for (final w in ['word', 'meaning', 'signature', 'ebook', 'ebooks']) 'nwsb_terms_$w': '1',
      for (final g in ['meaning_store', 'signature_store', 'ebook_store', 'ebooks_store']) 'guide_seen_$g': true,
    });
  });
  tearDown(() {
    Stillwater.debugPhase = null;
    FxBook.instance.country = null;
  });

  group('signature', () {
    testWidgets('header wordmark is NowssB with no dot', (t) async {
      await _pump(t, (x) => posterSignaturePage(x));
      expect(find.text('NowssB'), findsWidgets);
      expect(find.text('NowssB.'), findsNothing);
    });

    testWidgets('four place decks: every Countries/Capitals/Currency/Language row, Open + Add to cart (hint) + Own', (t) async {
      final key = GlobalKey();
      var obs = await _pump(t, (x) => posterSignaturePage(x), key: key);
      for (final g in kSigPlaceGroups) {
        await _reveal(t, find.text('Signature $g'));
        expect(find.text('Signature $g'), findsOneWidget, reason: g);
      }
      expect(kPlaceRows.where((r) => kSigPlaceGroups.contains(r.$3)), hasLength(kPlaceRows.length));
      // First Countries card
      obs = await _pump(t, (x) => posterSignaturePage(x), key: key);
      final first = kPlaceRows.first;
      final add = find.descendant(of: _sem('Open ${first.$1}'), matching: find.text('Add to cart'));
      await _reveal(t, add);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-restored-signature-places-390'));
      final before = CartBag.instance.cartCount;
      await t.tap(add.first);
      await t.pump(const Duration(milliseconds: 300));
      expect(CartBag.instance.cartCount, before + 1);
      expect(find.text('Your cart is waiting in Profile → Cart'), findsOneWidget);
      final own = find.descendant(of: _sem('Open ${first.$1}'), matching: find.textContaining('Own · ₹'));
      expect(own, findsOneWidget);
      expect((t.widget<Text>(own)).data, matches(RegExp(r'^Own · ₹[0-9,]+$')), reason: 'whole-rupee Play signature price');
      await t.tap(own);
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty, reason: 'Own → checkout');
      obs = await _pump(t, (x) => posterSignaturePage(x));
      final open = find.descendant(of: _sem('Open ${first.$1}'), matching: find.text('Open'));
      await _reveal(t, open);
      await t.tap(open);
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty, reason: 'Open → word page');
    });

    testWidgets('owned / in-plan place cards show no price and no Add to cart', (t) async {
      final r = kPlaceRows.first;
      Entitlements.instance.debugSet(uid: 'u1', owned: {ownedDocId('signature:${r.$1.toLowerCase()}')});
      await _pump(t, (x) => posterSignaturePage(x));
      final card = _sem('Open ${r.$1}');
      await _reveal(t, card);
      expect(find.descendant(of: card, matching: find.text('Owned')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining('₹')), findsNothing);
      expect(find.descendant(of: card, matching: find.text('Add to cart')), findsNothing);
    });

    testWidgets('Request a Signature opens Request words', (t) async {
      final key = GlobalKey();
      final obs = await _pump(t, (x) => posterSignaturePage(x), key: key);
      await _reveal(t, find.text('Request'));
      expect(find.text('REQUEST A SIGNATURE'), findsOneWidget);
      expect(find.text('Personally crafted & delivered within 48 hours.'), findsOneWidget);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-restored-signature-request-390'));
      await t.tap(find.text('Request'));
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty);
      expect(find.byType(RequestWordsScreen), findsOneWidget);
    });

    testWidgets('stub line stays ≥80% size at 320@1.3; no "Elements / Elements"', (t) async {
      await _pump(t, (x) => posterSignaturePage(x), width: 320, scale: 1.3);
      final stub = find.textContaining('words inside');
      await _reveal(t, stub);
      expect(stub, findsWidgets);
      for (final e in stub.evaluate()) {
        final rb = e.renderObject! as RenderBox;
        final s = rb.getTransformTo(null).getMaxScaleOnAxis();
        expect(s, greaterThanOrEqualTo(.8), reason: 'stub line scaled to $s');
      }
      for (final m in kMsSignature.entries) {
        expect(sigKicker(m.key, m.value).toLowerCase() == sigTitle(m.value).toLowerCase(), isFalse, reason: m.key);
      }
      expect(sigKicker('Elements', kMsSignature['Elements']!), 'Most Exclusive');
      expect(sigKicker('Nations & People', kMsSignature['Nations & People']!), 'Nations & People');
    });
  });

  group('meanings', () {
    testWidgets('search filters; no match shows "No meanings match." and Request words', (t) async {
      final key = GlobalKey();
      final obs = await _pump(t, (x) => posterMeaningPage(x, now: DateTime(2026, 10, 27, 9)), key: key);
      await _reveal(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), 'mother');
      await t.pump();
      expect(find.text('No meanings match.'), findsNothing);
      expect(kMsBaseMeanings.where((m) => meaningMatches(m, 'mother')), isNotEmpty);
      await t.enterText(find.byType(TextField), 'qqzzxx');
      await t.pump();
      expect(find.text('No meanings match.'), findsOneWidget);
      await _photos(t);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-restored-meaning-nomatch-390'));
      await _reveal(t, find.text('Request this word'));
      await t.tap(find.text('Request this word').hitTestable());
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty);
      expect(t.widget(find.byType(RequestWordsScreen)), isA<RequestWordsScreen>());
    });

    testWidgets('search go with no match / promo open Request words', (t) async {
      final obs = await _pump(t, (x) => posterMeaningPage(x));
      await _reveal(t, find.text('Request a word'));
      await t.tap(find.text('Request a word'));
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty);
      expect(find.byType(RequestWordsScreen), findsOneWidget);
    });

    testWidgets('PIE root méh₂tēr: ₂ comes from NotoSansPIE (no tofu) at 320', (t) async {
      final key = GlobalKey();
      await _pump(t, (x) => posterMeaningPage(x), width: 320, key: key);
      await _reveal(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), 'mother');
      await t.pump(const Duration(milliseconds: 200));
      final f = find.textContaining('méh₂tēr', findRichText: true);
      await _reveal(t, f.last);
      expect(f.hitTestable(), findsWidgets);
      final rp = t.renderObject<RenderParagraph>(f.hitTestable().last);
      final plain = rp.text.toPlainText();
      final i = plain.indexOf('₂');
      final box = rp.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1)).single;
      expect(box.right - box.left, greaterThan(2), reason: '₂ has a real advance');
      final style = rp.text.style ?? (rp.text as TextSpan).children!.first.style!;
      expect(style.fontFamilyFallback, contains('NotoSansPIE'));
      // The DM Sans line falls back to NotoSansPIE for ₂: same pixels as ₂ set in NotoSansPIE directly, unlike a tofu box.
      Future<Uint8List> ink(String s, TextStyle st) async {
        final pb = ui.ParagraphBuilder(ui.ParagraphStyle())..pushStyle(st.getTextStyle())..addText(s);
        final p = pb.build()..layout(const ui.ParagraphConstraints(width: 200));
        final rec = ui.PictureRecorder();
        Canvas(rec).drawParagraph(p, Offset.zero);
        final img = await rec.endRecording().toImage(60, 60);
        return (await img.toByteData())!.buffer.asUint8List();
      }

      const base = TextStyle(fontSize: 40, color: Colors.black);
      final viaFallback = await t.runAsync(() => ink('₂', base.copyWith(fontFamily: 'DM Sans', fontFamilyFallback: const ['NotoSansPIE'])));
      final direct = await t.runAsync(() => ink('₂', base.copyWith(fontFamily: 'NotoSansPIE')));
      final tofu = await t.runAsync(() => ink('\u{E000}', base.copyWith(fontFamily: 'DM Sans', fontFamilyFallback: const ['NotoSansPIE'])));
      expect(viaFallback, direct, reason: '₂ rendered by NotoSansPIE');
      expect(viaFallback, isNot(tofu), reason: '₂ is not the missing-glyph box');
      if (_shots.isNotEmpty) {
        final origin = rp.localToGlobal(Offset.zero);
        final c = Rect.fromLTRB(origin.dx + box.left - 18, origin.dy + box.top - 8, origin.dx + box.right + 18, origin.dy + box.bottom + 8);
        await t.runAsync(() => _shotOf(key, 'poster-meaning-pie-sub2-crop-320', crop: c, zoom: 4));
      }
    });
  });

  group('atelier', () {
    testWidgets('search no match: note + Request; go with empty query → Request words', (t) async {
      final key = GlobalKey();
      var obs = await _pump(t, (x) => posterAtelierPage(x, now: DateTime(2026, 10, 27, 9)), key: key);
      await _reveal(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), 'qqzzxx');
      await t.pump();
      expect(find.text('No words match this search in this collection.'), findsOneWidget);
      await _photos(t);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-restored-atelier-nomatch-390'));
      await t.tap(find.text('Request this word'));
      await _settleRoute(t);
      expect(find.byType(RequestWordsScreen), findsOneWidget);
      obs = await _pump(t, (x) => posterAtelierPage(x, now: DateTime(2026, 10, 27, 9)));
      await _reveal(t, find.byType(TextField));
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.search);
      await _settleRoute(t);
      expect(obs.pushed, isNotEmpty);
      expect(find.byType(RequestWordsScreen), findsOneWidget);
    });

    testWidgets('a real query keeps matching swatches; "+" adds and shows the cart hint', (t) async {
      await _pump(t, (x) => posterAtelierPage(x, now: DateTime(2026, 10, 27, 9)));
      final w = kRmCategories.firstWhere((c) => c.id != 'off50').words.first;
      await _reveal(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), w.word);
      await t.pump();
      expect(find.text('No words match this search in this collection.'), findsNothing);
      final plus = _sem(RegExp(r'^Add .* to bag$'));
      await _reveal(t, plus);
      final before = CartBag.instance.cartCount;
      await t.tap(plus.first);
      await t.pump(const Duration(milliseconds: 300));
      expect(CartBag.instance.cartCount, before + 1);
      expect(find.text('Your cart is waiting in Profile → Cart'), findsOneWidget);
    });

    testWidgets('swatch price tags are full size at 320 and 320@1.3', (t) async {
      for (final sc in [1.0, 1.3]) {
        final key = GlobalKey();
        await _pump(t, (x) => posterAtelierPage(x, now: DateTime(2026, 10, 27, 9)), width: 320, scale: sc, key: key);
        final tag = _sem(RegExp(r'^Add .* to bag$'));
        await _reveal(t, tag);
        final prices = find.textContaining(RegExp(r'^₹[0-9,]+$'));
        expect(prices, findsWidgets);
        for (final e in prices.evaluate()) {
          final rb = e.renderObject! as RenderBox;
          final s = rb.getTransformTo(null).getMaxScaleOnAxis();
          expect(s, closeTo(1, .01), reason: 'price tag scaled to $s at 320@$sc');
          expect((e.widget as Text).style?.fontSize, greaterThanOrEqualTo(14));
        }
        if (_shots.isNotEmpty && homeFontsReady) {
          await t.runAsync(() => _shotOf(key, 'poster-atelier-swatches-320${sc == 1 ? '' : '-1.3x'}'));
        }
      }
    });
  });

  group('poster search field', () {
    testWidgets('320@1.3: hint wraps unclipped; typed text is one line, centred with the icon', (t) async {
      final key = GlobalKey();
      await _pump(t, (x) => posterAtelierPage(x, now: DateTime(2026, 10, 27, 9)), width: 320, scale: 1.3, key: key);
      final field = find.byKey(const ValueKey('poster-search-field'));
      await _reveal(t, field);
      final box = find.ancestor(of: field, matching: find.byType(Container)).first;
      final icon = find.descendant(of: box, matching: find.byIcon(Icons.search_rounded));
      final hint = find.descendant(of: box, matching: find.text('Search words or roots'));
      expect(hint, findsOneWidget);
      final hp = t.renderObject<RenderParagraph>(hint);
      expect(hp.didExceedMaxLines, isFalse, reason: 'hint never ellipsized');
      final emptyH = t.getSize(box).height;
      expect((t.getCenter(hint).dy - t.getCenter(icon).dy).abs(), lessThan(2), reason: 'hint centred with icon');
      await _photos(t);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-search-empty-320-1.3x'));

      await t.enterText(field, 'qqzzxx');
      await t.pump();
      expect(hint, findsNothing);
      final typedH = t.getSize(box).height;
      expect(typedH, lessThan(emptyH), reason: 'drops to one line once typed');
      final editable = find.descendant(of: field, matching: find.byType(EditableText));
      final ep = t.state<EditableTextState>(editable).renderEditable;
      final line = ep.preferredLineHeight;
      expect(t.getSize(editable).height, lessThan(line * 1.5), reason: 'one line tall');
      expect((t.getCenter(editable).dy - t.getCenter(icon).dy).abs(), lessThan(2), reason: 'typed text centred with icon');
      expect(t.takeException(), isNull);
      if (_shots.isNotEmpty) await t.runAsync(() => _shotOf(key, 'poster-search-typed-320-1.3x'));
    });
  });
}
