// Store word pages (Nov 23, 2026): every catalogue word has its own photo,
// the removed words (Fire, countries, cities, languages, currencies) are
// gone everywhere, old carts drop them, and the word page keeps its working
// Wishlist / Add to Cart / Buy actions and a wishlist star.
// WORDS_SHOTS=<dir> also writes shots at 390x844.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/data/word_photos.dart';
import 'package:nowssb/screens/store/daily_deals.dart';
import 'package:nowssb/screens/store/store_word_page.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store/product_detail.dart';
import 'package:nowssb/screens/store/store_art.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = String.fromEnvironment('WORDS_SHOTS');

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      await (FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())))).load();
    }
  });

  test('fantasy filler words, warrior titles and ancient peoples are gone', () {
    const gone = ['dragon', 'zeus', 'phoenix', 'kitsune', 'oni', 'samurai', 'ninja', 'viking', 'aztec', 'sigil', 'griffon', 'titan'];
    final atelier = {for (final c in kRmCategories) for (final w in c.words) w.word.toLowerCase()};
    for (final w in gone) {
      expect(isRemovedWord(w), isTrue, reason: w);
      expect(atelier.contains(w), isFalse, reason: w);
      expect(wordPhotoFor(w), isNull, reason: w);
    }
    expect(kRmCategories.any((c) => c.id == 'mythical' || c.id == 'ancient'), isFalse);
    for (final c in kRmCategories) {
      expect(c.words, isNotEmpty, reason: c.id);
    }
    // Real words in the same rows stay.
    expect(atelier, containsAll(['warrior', 'shield', 'archer', 'oracle', 'rune']));
  });

  test('removed words are out of every catalogue list', () {
    final atelier = {for (final c in kRmCategories) for (final w in c.words) w.word.toLowerCase()};
    final meanings = {for (final m in kMsBaseMeanings) m.key};
    final deals = {for (final l in dealPool().values) for (final w in l) w.$1.toLowerCase()};
    for (final k in kRemovedWordKeys) {
      expect(atelier.contains(k), isFalse, reason: k);
      expect(meanings.contains(k), isFalse, reason: k);
      expect(deals.contains(k), isFalse, reason: k);
      expect(kMsWordBlurb.containsKey(k), isFalse, reason: k);
    }
    for (var d = 0; d < 60; d++) {
      for (final e in dailyDeals(day: DateTime(2026, 11, 1).add(Duration(days: d)))) {
        expect(isRemovedWord(e.word), isFalse, reason: e.word);
      }
    }
    expect(isRemovedItemId('word:fire'), isTrue);
    expect(isRemovedItemId('meaning:India'), isTrue);
    expect(isRemovedItemId('word:water'), isFalse);
    expect(isRemovedItemId('ebook:fire'), isFalse);
  });

  test('every catalogue word has its own photo, none repeated', () {
    final words = {
      for (final c in kRmCategories) for (final w in c.words) w.word.toLowerCase(),
      for (final m in kMsBaseMeanings) m.word.toLowerCase(),
    };
    // Ribon turned these photos down (Nov 23): they show the default art.
    const noPhoto = {'shield', 'honor', 'clan', 'sovereign', 'space'};
    for (final w in noPhoto) {
      expect(wordPhotoFor(w), isNull, reason: w);
      expect(File('assets/word_photos/$w.webp').existsSync(), isFalse, reason: w);
      expect(storeWordPicture(w, kNowssbWordFallback), isNotEmpty, reason: w);
    }
    final seen = <String>{};
    for (final w in words.difference(noPhoto)) {
      final p = wordPhotoFor(w);
      expect(p, isNotNull, reason: w);
      expect(File(p!).existsSync(), isTrue, reason: p);
      expect(seen.add(p), isTrue, reason: 'repeated: $p');
    }
    expect(kWordPhotos.values.toSet(), hasLength(kWordPhotos.length));
    expect(plainOrigin('Proto-Indo-European'), 'Ancient roots');
    expect(plainOrigin('Old French'), 'Old French');
    expect(drawableRoot('péh₂wr̥'), 'péh2wr');
  });

  test('an old cart or wishlist drops removed words', () async {
    SharedPreferences.setMockInitialValues({
      'nwsb_store_cart': '[{"id":"word:fire","title":"Fire","subtitle":"","image":"","price":49,"kind":"Word","qty":1},'
          '{"id":"word:water","title":"Water","subtitle":"","image":"","price":49,"kind":"Word","qty":1}]',
      'nwsb_store_wish': '[{"id":"meaning:india","title":"India","subtitle":"","image":"","price":49,"kind":"Meaning","qty":1}]',
    });
    await CartBag.instance.load();
    expect(CartBag.instance.cart.map((e) => e.id), isNot(contains('word:fire')));
    expect(CartBag.instance.wishlist.map((e) => e.id), isNot(contains('meaning:india')));
  });

  final key = GlobalKey();
  Future<void> shot(WidgetTester t, String name) async {
    if (_out.isEmpty) return;
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final im = await b.toImage(pixelRatio: 2);
      final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
      Directory(_out).createSync(recursive: true);
      File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester t, [int n = 14]) async {
    for (var i = 0; i < n; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester t, void Function(BuildContext) go, {double width = 390}) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = Size(width * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await CartBag.instance.load();
    });
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: NavScope(
          go: (_) {},
          child: Builder(builder: (c) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: TextButton(key: const ValueKey('go'), onPressed: () => go(c), child: const Text('go')),
              ),
            );
          }),
        ),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('go')));
    await settle(t);
  }

  MsMeaning meaning(String k) => kMsBaseMeanings.firstWhere((m) => m.key == k,
      orElse: () => MsMeaning(word: '${k[0].toUpperCase()}${k.substring(1)}', key: k, root: 'Proto-Indo-European', category: 'Elements', price: 49, img: 'assets/meanings/meanings-clean.jpg'));

  final pages = <String, void Function(BuildContext)>{
    'meaning-water': (c) => openMeaningDetail(c, meaning('water')),
    'meaning-moon': (c) => openMeaningDetail(c, meaning('moon')),
    'word-shield': (c) => openAtelierWord(c, word: 'shield', root: 'Proto-Germanic', img: kNowssbStoreMark),
    'word-ocean': (c) => openAtelierWord(c, word: 'ocean', root: 'Old French', img: kNowssbStoreMark),
    'word-serenity': (c) => openAtelierWord(c, word: 'serenity', root: 'Latin', img: kNowssbStoreMark),
    'word-peace': (c) => openAtelierWord(c, word: 'peace', root: 'Old French', img: kNowssbStoreMark),
  };
  if (const bool.fromEnvironment('WORDS_BEFORE')) {
    pages['meaning-fire'] = (c) => openMeaningDetail(c, meaning('fire'));
    pages['word-fire'] = (c) => openAtelierWord(c, word: 'fire', root: 'Proto-Indo-European', img: kNowssbStoreMark);
  }

  for (final e in pages.entries) {
    testWidgets('word page ${e.key}', (t) async {
      await open(t, e.value);
      await shot(t, '${e.key}-top');
      final s = find.byKey(const ValueKey('store-word-list'));
      expect(s, findsOneWidget);
      await t.drag(s, const Offset(0, -640));
      await settle(t, 8);
      await shot(t, '${e.key}-scrolled');
      await t.drag(s, const Offset(0, -760));
      await settle(t, 8);
      await shot(t, '${e.key}-more');
      expect(t.takeException(), isNull);
    });
    testWidgets('word page ${e.key} fits at 360', (t) async {
      await open(t, e.value, width: 360);
      expect(t.takeException(), isNull);
      final s = find.byKey(const ValueKey('store-word-list'));
      for (var i = 0; i < 4; i++) {
        await t.drag(s, const Offset(0, -600));
        await settle(t, 3);
        expect(t.takeException(), isNull);
      }
    });
  }

  testWidgets('the chips switch what the photo says, the tall pill is the wishlist', (t) async {
    await open(t, (c) => openAtelierWord(c, word: 'ocean', root: 'Old French', img: kNowssbStoreMark));
    expect(find.text('Hi there 👋'), findsOneWidget);
    expect(find.text('Ocean\nNature'), findsOneWidget);
    expect(find.text('OLD FRENCH'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('word-mode-listen')));
    await settle(t, 2);
    expect(find.text('Hear Ocean said right'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('word-mode-practice')));
    await settle(t, 2);
    expect(find.text('Practise Ocean daily'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('word-wish')));
    await settle(t, 3);
    expect(CartBag.instance.inWish('word:ocean'), isTrue);
    await t.tap(find.byKey(const ValueKey('word-wish')));
    await settle(t, 3);
    expect(CartBag.instance.inWish('word:ocean'), isFalse);
    // No jargon labels on the page.
    expect(find.textContaining('Hellenic'), findsNothing);
    expect(find.textContaining('Romance'), findsNothing);
    expect(find.textContaining('Proto-'), findsNothing);
  });

  testWidgets('the word page keeps its actions and the star saves to the wishlist', (t) async {
    await open(t, (c) => openAtelierWord(c, word: 'ocean', root: 'Old French', img: kNowssbStoreMark));
    expect(find.byKey(const ValueKey('word-wish')), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('Buy on Google Play'), findsOneWidget);
    expect(find.text('Ocean'), findsWidgets);
    expect(find.text('Nature'), findsWidgets);
    final star = find.byType(StoreWordStar).first;
    await t.tap(star);
    await settle(t, 3);
    expect(CartBag.instance.inWish('word:ocean'), isTrue);
    await t.tap(star);
    await settle(t, 3);
    expect(CartBag.instance.inWish('word:ocean'), isFalse);
  });
}
