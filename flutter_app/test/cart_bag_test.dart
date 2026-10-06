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

  test('the wishlist belongs to the account: cleared on sign-out and on account switch', () async {
    final bag = CartBag.instance;
    await bag.onAccount('alice');
    await bag.addWishlist(item());
    expect(bag.wishCount, 1);

    // Alice signs out: her list does not stay on the phone.
    await bag.onAccount(null);
    expect(bag.wishlist, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nwsb_store_wish'), '[]');

    // Alice again, then Bob without a signed-out step in between.
    await bag.onAccount('alice');
    await bag.addWishlist(item());
    await bag.onAccount('bob');
    expect(bag.wishlist, isEmpty, reason: "Alice's items must not reach Bob");
  });

  test("a guest's wishlist is kept for the account that signs in", () async {
    final bag = CartBag.instance;
    await bag.onAccount(null);
    await bag.addWishlist(item());
    await bag.onAccount('carol');
    expect(bag.wishCount, 1);
  });
}
