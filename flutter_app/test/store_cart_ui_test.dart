import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/screens/store/store_cards.dart';

void main() {
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
      expect(cards, contains('height: 132'));
      expect(cards, contains('_CenteredPrice'));
      expect(cards, contains('static const double cardHeight = 228'));
      expect(cards, contains('kWordPriceInr'));
      expect(cards, contains('kWordSaleInr'));
      expect(cards, contains('RmBannerRail'));
      expect(cards, contains('RmRowHeader'));
      expect(cards, isNot(contains('.clamp(1, 999999)')));

      final atelier =
          File('lib/screens/store/word_atelier.dart').readAsStringSync();
      expect(atelier, contains('RmBannerRail'));
      expect(atelier, contains('RmRowHeader'));
      expect(atelier, contains('kWordSaleInr'));
      expect(atelier, contains('originalPrice'));

      final detail =
          File('lib/screens/store/product_detail.dart').readAsStringSync();
      expect(detail, contains("label: 'Add to Cart'"));
      expect(detail, contains('NwsbMarks.cart'));
      expect(detail, contains("label: 'Buy Now'"));
      expect(detail, contains('NwsbMarks.bag'));
      expect(detail, contains('NwsbMarks.wishlist'));
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
