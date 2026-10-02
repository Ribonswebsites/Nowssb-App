import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CartBag.instance.load();
    for (final e in List<BagItem>.from(CartBag.instance.cart)) {
      await CartBag.instance.removeCart(e.id);
    }
    for (final e in List<BagItem>.from(CartBag.instance.wishlist)) {
      await CartBag.instance.removeWishlist(e.id);
    }
  });

  BagItem item() => BagItem(
        id: 'word:agni',
        title: 'Agni',
        subtitle: 'Fire',
        image: 'assets/store/nowssb-bag-headphones.webp',
        price: 49,
        kind: 'Word',
      );

  test('digital items stay one per cart; wishlist sticks; no phone-only orders', () async {
    final bag = CartBag.instance;
    await bag.addCart(item());
    await bag.addCart(item());
    expect(bag.cartCount, 1);
    expect(bag.cartTotal, 49);

    await bag.addWishlist(item());
    expect(bag.wishCount, 1);

    await bag.removeCart('word:agni');
    expect(bag.cart, isEmpty);
    expect(bag.orders, isEmpty);
  });
}
