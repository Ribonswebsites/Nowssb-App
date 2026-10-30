// Chip legibility + checkout currency (chip-inr).
// Set CHIPINR_SHOTS=<dir> to also write chipinr-*.png renders.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/nwsb_choice_chip.dart';
import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

/// The app's light theme (NwsbTheme.light) minus its google_fonts text
/// theme, which tests cannot fetch: same M3 colour scheme and surface.
final _appLight = ThemeData(
  useMaterial3: true,
  fontFamily: 'DM Sans',
  scaffoldBackgroundColor: NwsbColors.surface,
  colorScheme: const ColorScheme.light(primary: NwsbColors.gold, surface: NwsbColors.surface, onSurface: NwsbColors.ink),
);

const _ist = Duration(hours: 5, minutes: 30);

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  group('chip contrast', () {
    test('selected and unselected pairs are >= 4.5:1', () {
      for (final sel in [false, true]) {
        final r = contrastRatio(NwsbChoiceChip.text(sel), NwsbChoiceChip.fill(sel));
        expect(r, greaterThanOrEqualTo(4.5), reason: 'selected=$sel ratio=$r');
        expect(NwsbChoiceChip.fill(sel).a, 1.0, reason: 'fill must be opaque');
      }
    });

    testWidgets('renders its own fill under the app light theme', (t) async {
      final px = <bool, Color>{};
      for (final sel in [false, true]) {
        final key = GlobalKey();
        await t.pumpWidget(MaterialApp(
          theme: _appLight,
          home: Material(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: NwsbChoiceChip(label: const Text('Ember Silk'), selected: sel, onSelected: (_) {}, showCheckmark: false),
              ),
            ),
          ),
        ));
        await t.pumpAndSettle();
        final r = t.getRect(find.byType(ChoiceChip));
        ByteData? bd;
        late int w;
        await t.runAsync(() async {
          final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
          w = img.width;
          bd = await img.toByteData();
        });
        final o = ((r.center.dy.round()) * w + (r.left + 6).round()) * 4;
        px[sel] = Color.fromARGB(255, bd!.getUint8(o), bd!.getUint8(o + 1), bd!.getUint8(o + 2));
        expect(contrastRatio(NwsbChoiceChip.text(sel), px[sel]!), greaterThanOrEqualTo(4.5),
            reason: 'painted fill ${px[sel]} selected=$sel');
      }
    });
  });

  group('currency', () {
    final fx = FxBook.instance;
    setUp(() {
      fx.country = null;
      fx.playCurrency = null;
    });

    test('locale codes', () {
      expect(fx.codeFor('en_IN'), 'INR');
      expect(fx.codeFor('hi_IN'), 'INR');
      expect(fx.codeFor('en_US'), 'USD');
      // No region at all: the catalogue base (INR), never a guessed USD.
      expect(fx.codeFor('en'), 'INR');
    });

    test('prices', () {
      expect(fx.formatPrice(99, locale: 'en_IN'), contains('₹'));
      expect(fx.formatPrice(99, locale: 'en_IN'), '₹99.00');
      expect(fx.formatPrice(99, locale: 'hi_IN'), contains('₹'));
      expect(fx.formatPrice(99, locale: 'en'), contains('₹'));
      expect(fx.formatPrice(99, locale: 'en_US'), startsWith(r'$'));
    });

    test('an India phone set to English (US) resolves to IN', () {
      expect(FxBook.resolveCountry(locales: const [Locale('en', 'US')], tzOffset: _ist), 'IN');
      expect(FxBook.resolveCountry(locales: const [Locale('hi', 'IN')], tzOffset: Duration.zero), 'IN');
      expect(FxBook.resolveCountry(locales: const [Locale('en', 'US')], tzOffset: const Duration(hours: -5)), 'US');
      expect(FxBook.resolveCountry(locales: const [Locale('en')], tzOffset: const Duration(hours: -5)), isNull);
      expect(FxBook.resolveCountry(locales: const [Locale('si', 'LK')], tzOffset: _ist), 'LK');
      expect(FxBook.resolveCountry(locales: const [Locale('ar', 'AE')], tzOffset: const Duration(hours: 4)), 'AE');
      fx.country = FxBook.resolveCountry(locales: const [Locale('en', 'US')], tzOffset: _ist);
      expect(fx.codeFor(), 'INR');
      expect(fx.formatPrice(99), contains('₹'));
    });

    test('Android: bare en + Platform.localeName en_IN / region IN -> INR', () {
      String? r(String? pl) => FxBook.resolveCountry(
          locales: const [Locale('en')], tzOffset: const Duration(hours: -5), platformLocale: pl);
      expect(r('en_IN'), 'IN');
      expect(r('en-IN.UTF-8'), 'IN');
      expect(r('hi_IN'), 'IN');
      expect(r('en'), isNull);
      expect(FxBook.resolveCountry(locales: const [Locale('en', 'IN')], tzOffset: Duration.zero), 'IN');
      for (final pl in ['en_IN', 'hi_IN']) {
        fx.country = r(pl);
        expect(fx.codeFor(), 'INR', reason: pl);
        // The Drop Studio dock price path (localizedMoney -> formatPrice).
        expect(fx.formatPrice(99), '₹99.00', reason: pl);
        expect(fx.formatPrice(99), isNot(contains(r'$')));
      }
    });

    test("'Enter' (EnterPill) stays >= 4.5:1 on black even with a dark saved colour", () {
      const black = Color(0xFF0B0A12);
      expect(contrastRatio(Colors.white, black), greaterThan(4.5));
      expect(legibleOr(const Color(0xFF3A3A3A), black, Colors.white), Colors.white);
      expect(legibleOr(NwsbColors.goldLight, black, Colors.white), NwsbColors.goldLight);
    });

    test("Google Play's currency wins", () {
      fx.country = 'US';
      fx.notePlayCurrency('inr');
      expect(fx.codeFor(), 'INR');
    });
  });

  group('checkout', () {
    final shots = Platform.environment['CHIPINR_SHOTS'];
    BagItem word(String w, {num price = 99}) => BagItem(
        id: 'word:$w', title: w.toUpperCase(), subtitle: 'Word', image: 'assets/store/nowssb-bag-headphones.webp', price: price, kind: 'Word');

    Future<void> shot(WidgetTester t, GlobalKey key, String name) async {
      if (shots == null) return;
      await precacheAll(t);
      await t.pump(const Duration(milliseconds: 200));
      await t.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/chipinr-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    Future<GlobalKey> boot(WidgetTester t, Widget home, {double w = 390, double s = 1}) async {
      t.view.physicalSize = Size(w * 2, 844 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.runAsync(() async {
        await Settings.instance.load();
        await CartBag.instance.load();
      });
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: MediaQueryData(size: Size(w, 844), textScaler: TextScaler.linear(s)),
          child: MaterialApp(debugShowCheckedModeBanner: false, theme: _appLight, home: home),
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 120));
      }
      return key;
    }

    Future<void> fill(WidgetTester t, List<BagItem> items) async {
      await t.runAsync(() async {
        for (final it in List.of(CartBag.instance.cart)) {
          await CartBag.instance.removeCart(it.id);
        }
        for (final it in items) {
          await CartBag.instance.addCart(it);
        }
      });
    }

    for (final (w, s) in [(390.0, 1.0), (320.0, 1.3)]) {
      final tag = '${w.round()}${s == 1 ? '' : '@$s'}';

      testWidgets('paid $tag', (t) async {
        FxBook.instance.country = 'IN';
        FxBook.instance.playCurrency = null;
        Entitlements.instance.debugSet(uid: 'u1');
        await fill(t, [word('aarogya'), word('shakti')]);
        final key = await boot(t, const CheckoutPage(), w: w, s: s);
        expect(find.textContaining('₹'), findsWidgets);
        expect(find.textContaining(r'$'), findsNothing);
        expect(find.textContaining('2 items in your cart, 2 items to pay for'), findsOneWidget);
        expect(CartBag.instance.cartCount, 2);
        await shot(t, key, 'checkout-paid-$tag');
      });

      testWidgets('in plan $tag', (t) async {
        FxBook.instance.country = 'IN';
        Entitlements.instance.debugSet(uid: 'u1', tier: 'resonance', until: DateTime(2099));
        await fill(t, [word('aarogya'), word('shakti')]);
        final key = await boot(t, const CheckoutPage(), w: w, s: s);
        expect(find.text('In your plan'), findsNWidgets(2));
        expect(find.textContaining('₹'), findsNothing, reason: 'in-plan rows are not sold');
        expect(find.textContaining('Nothing to pay'), findsOneWidget);
        expect(find.textContaining('Pay on Google Play'), findsNothing);
        expect(CartBag.instance.cartCount, 2, reason: 'badge = rows shown');
        await shot(t, key, 'checkout-inplan-$tag');
      });

      testWidgets('B003 Done clears in-plan items $tag', (t) async {
        FxBook.instance.country = 'IN';
        Entitlements.instance.debugSet(uid: 'u1', tier: 'resonance', until: DateTime(2099));
        await fill(t, [word('aarogya'), word('shakti')]);
        await boot(t, const CheckoutPage(), w: w, s: s);
        expect(CartBag.instance.cartCount, 2);
        // Wider CI fonts can push Done below the lazily built list: scroll
        // the checkout list until it exists, then tap it wherever it sits.
        final done = find.text('Done');
        final list = find.byType(Scrollable).last;
        for (var i = 0; i < 30 && done.hitTestable().evaluate().isEmpty; i++) {
          await t.drag(list, const Offset(0, -160), warnIfMissed: false);
          await t.pump(const Duration(milliseconds: 60));
        }
        expect(done, findsOneWidget);
        await t.ensureVisible(done);
        await t.pump();
        await t.tap(done.hitTestable().evaluate().isEmpty ? done : done.hitTestable(), warnIfMissed: false);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await t.pump(const Duration(milliseconds: 300));
        expect(CartBag.instance.cartCount, 0, reason: 'badge drops to 0');
        expect(CartBag.instance.inCart('word:aarogya') || CartBag.instance.inCart('word:shakti'), isFalse);
      });

      testWidgets('empty $tag', (t) async {
        Entitlements.instance.debugSet(uid: 'u1');
        await fill(t, []);
        final key = await boot(t, const CheckoutPage(), w: w, s: s);
        expect(find.text('Your cart is empty.'), findsOneWidget);
        expect(CartBag.instance.cartCount, 0);
        await shot(t, key, 'checkout-empty-$tag');
      });

      for (final mode in [FashionPlusMode.background, FashionPlusMode.startArt]) {
        testWidgets('chips ${mode.name} $tag', (t) async {
          final key = await boot(t, FashionPlusScreen(mode: mode), w: w, s: s);
          final chips = find.byType(NwsbChoiceChip);
          expect(chips, findsWidgets);
          await t.ensureVisible(chips.first);
          await t.pump(const Duration(milliseconds: 300));
          await shot(t, key, '${mode.name}-$tag');
        });
      }
    }
  });
}
