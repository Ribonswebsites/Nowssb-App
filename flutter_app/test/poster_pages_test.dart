// Poster pages (Trending, Atelier, Meanings, Signature, eBooks): every action
// reaches a real route, owned / in-plan items show no price, en_IN prints ₹,
// and nothing overflows, ellipsizes or breaks mid-word at 320–412 and 320@1.3.
// Set POSTER_SHOTS=<dir> to also write poster-build-<page>-{390,320-1.3x}.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/billing_config.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/screens/poster/poster_pages.dart';
import 'package:nowssb/screens/store/meaning_store.dart';
import 'package:nowssb/screens/store/signature_store.dart';
import 'package:nowssb/screens/store/word_atelier.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/concept/stillwater.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = String.fromEnvironment('POSTER_SHOTS');
final _now = DateTime(2026, 10, 27, 9);

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  int pops = 0;
  @override
  void didPush(Route<dynamic> r, Route<dynamic>? p) => pushed.add(r);
  @override
  void didPop(Route<dynamic> r, Route<dynamic>? p) => pops++;
}

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

/// Pumps [page] on top of a base route (so Back has somewhere to go).
Future<_Obs> _pump(WidgetTester t, Widget page, {double width = 390, double height = 844, double scale = 1, GlobalKey? key}) async {
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
      home: Builder(builder: (c) => Scaffold(body: Center(child: TextButton(onPressed: () => posterPush(c, page), child: const Text('base'))))),
    ),
  ));
  await t.tap(find.text('base'));
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
  obs.pushed.clear();
  return obs;
}

/// No overflow (exceptions), no ellipsis, no single word wrapped mid-word.
void _expectCleanText(WidgetTester t, String label) {
  expect(t.takeException(), isNull, reason: 'exception/overflow: $label');
  for (final e in find.byType(RichText).evaluate()) {
    final rp = e.renderObject as RenderParagraph?;
    if (rp == null || !rp.attached || !rp.hasSize) continue;
    final s = rp.text.toPlainText().trim();
    if (s.isEmpty) continue;
    expect(rp.didExceedMaxLines, isFalse, reason: 'ellipsis/clip "$s" at $label');
    expect(s.contains('…') || s.contains('...'), isFalse, reason: 'ellipsis text "$s" at $label');
    final full = rp.text.toPlainText();
    for (final m in RegExp(r'[^\s\u00B7·—-]{2,}').allMatches(full)) {
      final tops = rp
          // Line-height boxes: a fallback glyph (₂, ē) has its own glyph box,
          // so only a real line change moves `top`.
          .getBoxesForSelection(TextSelection(baseOffset: m.start, extentOffset: m.end), boxHeightStyle: ui.BoxHeightStyle.max).map((b) => b.top.round()).toSet();
      expect(tops.length, 1, reason: 'mid-word break "${m[0]}" in "$s" at $label');
    }
  }
}

Future<void> _shot(GlobalKey key, String name) async {
  final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await ro.toImage(pixelRatio: 2);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File('$_shots/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}

/// Scroll the whole page, checking text at every screen.
Future<void> _sweep(WidgetTester t, String label) async {
  _expectCleanText(t, label);
  final s = find.byType(Scrollable);
  if (s.evaluate().isEmpty) return;
  for (var i = 0; i < 30; i++) {
    final st = t.state<ScrollableState>(s.first);
    if (st.position.pixels >= st.position.maxScrollExtent) break;
    st.position.jumpTo((st.position.pixels + 600).clamp(0, st.position.maxScrollExtent));
    await t.pump(const Duration(milliseconds: 100));
    _expectCleanText(t, '$label @${st.position.pixels.round()}');
  }
}

class PosterSpec {
  const PosterSpec(this.name, this.build, this.ownedIds, this.priced, this.open);
  final String name;
  final Widget Function() build;

  /// Item ids on the first screen, for the owned / in-plan check.
  final Set<String> Function() ownedIds;

  /// A visible price-bearing pill label prefix.
  final String priced;

  /// Text of a control that opens an item page.
  final String open;
}

final specs = <PosterSpec>[
  PosterSpec('trending', () => TrendingScreen(now: _now), () {
    final lib = ContentStore.instance.library;
    return {for (final i in PosterTrending.chart(lib, _now)) 'word:${lib[i].word.toLowerCase()}'};
  }, 'Own · ', 'Hear it'),
  PosterSpec('atelier', () => WordAtelierScreen(now: _now), () => {
        for (final c in kRmCategories)
          for (final w in c.words) 'word:${w.word.toLowerCase()}',
      }, 'Own · ', 'Open'),
  PosterSpec('meaning', () => MeaningStoreScreen(now: _now), () => {for (final m in kMsBaseMeanings) 'meaning:${m.word.toLowerCase()}'}, 'Own · ',
      PosterMeaning.pick(_now).word),
  PosterSpec('signature', () => const SignatureStoreScreen(), () => {
        for (final c in kRmCategories)
          if (c.signature != null) 'signature:${c.signature!.name.toLowerCase()}',
        for (final e in kMsSignature.values) 'meaning:${e.word.toLowerCase()}',
      }, 'Own · ', 'Look inside'),
];

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
    // Ribon's region: India (the located country the IP lookup sets).
    FxBook.instance.country = 'IN';
    // The store research sheet is agreed (it asks once per store).
    SharedPreferences.setMockInitialValues({
      for (final w in ['word', 'meaning', 'signature', 'ebook', 'ebooks']) 'nwsb_terms_$w': '1',
      // The first-use guide has been seen (it shows once per store).
      for (final g in ['meaning_store', 'signature_store', 'ebook_store', 'ebooks_store']) 'guide_seen_$g': true,
    });
  });
  tearDown(() {
    Stillwater.debugPhase = null;
    FxBook.instance.country = null;
  });

  Future<void> load(WidgetTester t) => t.runAsync(() async {
        await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      });

  for (final p in specs) {
    group('poster ${p.name}', () {
      testWidgets('back, bag and every price pill reach a real route', (t) async {
        await load(t);
        var obs = await _pump(t, p.build());
        // Bag
        await t.tap(find.byIcon(Icons.shopping_bag_outlined).first);
        await t.pump(const Duration(milliseconds: 400));
        expect(obs.pushed, isNotEmpty, reason: 'bag opens a sheet');
        // Back
        obs = await _pump(t, p.build());
        await t.tap(find.byIcon(Icons.arrow_back_rounded).first);
        await t.pump(const Duration(milliseconds: 400));
        expect(obs.pops, greaterThan(0), reason: 'back pops');
        // Buy pills (first screen) and every Open
        obs = await _pump(t, p.build());
        final buys = find.textContaining(p.priced, findRichText: true).hitTestable();
        expect(buys, findsWidgets, reason: 'a price pill is visible');
        final before = CartBag.instance.cartCount;
        await t.tap(buys.first);
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 250));
        }
        final after = CartBag.instance.cartCount;
        expect(obs.pushed.isNotEmpty || after > before, isTrue, reason: 'buy reaches checkout or bag');
        obs = await _pump(t, p.build());
        final open = find.textContaining(p.open, findRichText: true).hitTestable();
        expect(open, findsWidgets, reason: '${p.open} is visible');
        await t.tap(open.first);
        await t.pump(const Duration(milliseconds: 400));
        expect(obs.pushed, isNotEmpty, reason: '${p.open} opens the item page');
      });

      testWidgets('owned and in-plan items show no price', (t) async {
        await load(t);
        Entitlements.instance.debugSet(uid: 'u1', owned: {for (final id in p.ownedIds()) ownedDocId(id)});
        await _pump(t, p.build());
        expect(find.textContaining('Owned', findRichText: true), findsWidgets);
        Entitlements.instance.debugSet(uid: 'u1', tier: 'frequencyX', until: DateTime(2099));
        await _pump(t, p.build());
        expect(find.textContaining('₹', findRichText: true).hitTestable(), findsNothing, reason: 'in-plan hides every price');
        expect(find.textContaining('In your plan', findRichText: true), findsWidgets);
      });

      testWidgets('en_IN prints ₹', (t) async {
        t.platformDispatcher.localesTestValue = const [Locale('en', 'IN')];
        t.platformDispatcher.localeTestValue = const Locale('en', 'IN');
        addTearDown(t.platformDispatcher.clearAllTestValues);
        // The region path: located country IN (IP lookup / +05:30 zone).
        FxBook.instance.country = 'IN';
        addTearDown(() => FxBook.instance.country = null);
        await load(t);
        await _pump(t, p.build());
        final prices = find.textContaining(RegExp(r'Own · '), findRichText: true);
        expect(prices, findsWidgets);
        for (final e in prices.evaluate()) {
          final s = (e.widget as RichText).text.toPlainText();
          expect(s, contains('₹'), reason: s);
          expect(s, isNot(contains(r'$')), reason: s);
        }
      });

      testWidgets('overflow sweep 320/360/390/412/320@1.3', (t) async {
        if (!homeFontsReady) return markTestSkipped('real fonts needed (HOME_FONT_CACHE)');
        await load(t);
        for (final plan in [false, true]) {
          Entitlements.instance.debugSet(uid: 'u1', tier: plan ? 'frequencyX' : null, until: plan ? DateTime(2099) : null);
          for (final (w, sc) in [(320.0, 1.3), (412.0, 1.0)]) {
            await _pump(t, p.build(), width: w, scale: sc);
            await _sweep(t, '${p.name} $w@$sc plan=$plan');
          }
        }
        Entitlements.instance.debugSet(uid: 'u1');
        for (final (w, sc) in [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
          final key = GlobalKey();
          await _pump(t, p.build(), width: w, scale: sc, key: key);
          await _sweep(t, '${p.name} $w@$sc');
          if (_shots.isNotEmpty && (w == 390 && sc == 1 || w == 320 && sc == 1.3)) {
            final tall = GlobalKey();
            await _pump(t, p.build(), width: w, height: 2400, scale: sc, key: tall);
            await precacheAll(t);
            await t.pump(const Duration(milliseconds: 300));
            await t.runAsync(() => _shot(tall, 'poster-build-${p.name}-${w == 390 ? '390' : '320-1.3x'}'));
          }
        }
      });
    });
  }
}
