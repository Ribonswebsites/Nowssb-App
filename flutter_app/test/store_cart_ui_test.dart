import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/screens/store/store_cards.dart';

void main() {
  // These cover the legacy Store screens; the rebuilt ones have store_newui_test.
  setUpAll(() => NewUi.setDebugOverride('store', false));
  tearDownAll(NewUi.resetForTest);

  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Word cards and product detail use cart SVG for add and bag SVG for buy',
    () {
      final cards =
          File('lib/screens/store/store_cards.dart').readAsStringSync();
      expect(cards, contains("label: 'Add to Cart'"));
      expect(cards, contains('NwsbMarks.cart'));
      expect(cards, contains('NwsbMarks.bag'));
      expect(cards, contains('storeAddToCart'));
      expect(cards, contains('storeBuyNow'));
      expect(cards, isNot(contains('Icons.shopping_cart_outlined')));
      expect(cards, isNot(contains('Icons.graphic_eq')));
      expect(cards, contains('ribbon-plain.png'));
      expect(cards, contains('ribbon-metal.png'));
      expect(cards, contains('ribbon-silk.png'));
      expect(cards, contains('_CenteredPrice'));
      expect(cards, contains('static const double cardHeight = 308'));
      expect(cards, contains('kWordPriceInr'));
      expect(cards, contains('kWordSaleInr'));
      expect(cards, contains('RmBannerRail'));
      expect(cards, contains('RmRowHeader'));
      expect(cards, isNot(contains('.clamp(1, 999999)')));
      expect(cards, contains('TextDecoration.lineThrough'));
      expect(cards, contains('shape: BoxShape.circle'));
      expect(cards, contains('NwsbMarks.wishlist'));
      expect(cards, contains('StoreViewMoreTap'));
      expect(cards, contains('fontSize: 24'));

      final atelier =
          File('lib/screens/store/word_atelier.dart').readAsStringSync();
      // Rebuild C (8:22 PM): original media + glass, Myntra layout; real
      // prices with a sale strike only when real, no fake 50% OFF row.
      expect(atelier, contains('StorePrices'));
      expect(atelier, contains('originalPrice'));
      expect(atelier, contains('storeAddToCart'));
      expect(atelier, contains('kRmHeroVidFile'));
      expect(atelier, contains("c.id != 'off50'"));
      expect(atelier, isNot(contains('storeMidRailBannerAt')));
      expect(atelier, isNot(contains('IntroGate')));
      expect(atelier, isNot(contains('Enter The Word Atelier')));

      for (final path in [
        'lib/screens/store/word_atelier.dart',
        'lib/screens/store/meaning_store.dart',
        'lib/screens/store/signature_store.dart',
        'lib/screens/store/ebooks_store.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('IntroGate')), reason: path);
        // Rebuild C: the Meaning Store has its own light CLiQ-style shell.
        if (true) {
          expect(src, contains('PageShell('), reason: path);
        }
      }

      final storeHome = File('lib/screens/store.dart').readAsStringSync();
      expect(storeHome, contains('16 / 6.4'));
      expect(storeHome, contains('ClipPriority.feature'));
      expect(storeHome, contains('HeavyGlassPanel'));
      // The quick mosaic moved into the shared sections (Word Atelier).
      final sections =
          File('lib/screens/store/store_home_sections.dart').readAsStringSync();
      expect(sections, contains('class StoreQuickMosaic'));
      expect(sections, contains('assets/video/store-orb-box.mp4'));
      expect(sections, contains('clamp(120.0, 180.0)'));
      // Rebuild C: the mosaic (links to other stores) left Word Atelier.
      expect(atelier, isNot(contains('StoreQuickMosaic(')));

      final catalog = File('lib/data/store_catalog.dart').readAsStringSync();
      expect(catalog, contains("return 'assets/video/hero-word-store.mp4'"));
      expect(catalog, isNot(contains("=> '\$kNowssbVideoOrigin\$fileName'")));

      final detail =
          File('lib/screens/store/product_detail.dart').readAsStringSync();
      // Rebuild C (Myntra item ref): Add to Bag + Buy Now via the real
      // cart / Play checkout actions, wishlist via CartBag.
      expect(detail, contains("Text('Add to Bag')"));
      expect(detail, contains('storeAddToCart('));
      expect(detail, contains('storeBuyNow('));
      expect(detail, contains('addWishlist('));
      expect(detail, isNot(contains('Icons.shopping_cart_outlined')));
      expect(detail, isNot(contains('Icons.flash_on_outlined')));

      final flight =
          File('lib/widgets/cart_add_animation.dart').readAsStringSync();
      expect(flight, contains('NwsbMarks.cart'));
      expect(flight, isNot(contains('Icons.shopping_cart_outlined')));
    },
  );

  testWidgets('tapping Add to Cart on a word card increments the bag once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await CartBag.instance.load();
    for (final e in List<BagItem>.from(CartBag.instance.cart)) {
      await CartBag.instance.removeCart(e.id);
    }

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: Center(
            child: RmWordCard(
              name: 'Fire',
              root: 'Proto-Indo-European',
              imgUrl: 'assets/store/nowssb-bag-headphones.webp',
              price: 25,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Add to Cart'), findsOneWidget);
    expect(find.bySemanticsLabel('Buy Now'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add to Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(CartBag.instance.cartCount, 1);
    expect(CartBag.instance.cart.first.title, 'Fire');
  });
}
