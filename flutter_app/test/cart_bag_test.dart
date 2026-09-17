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

  test('adding to cart and wishlist sticks, checkout empties the bag', () async {
    final bag = CartBag.instance;
    await bag.addCart(item());
    await bag.addCart(item());
    expect(bag.cartCount, 2);
    expect(bag.cartTotal, 98);

    await bag.addWishlist(item());
    expect(bag.wishCount, 1);

    final order = await bag.checkout(
      name: 'Healer',
      phone: '9999999999',
      address: 'Nagpur',
      payMethod: 'UPI',
    );
    expect(order, isNotNull);
    expect(bag.cart, isEmpty);
    expect(bag.orders, isNotEmpty);
    expect(bag.orders.first.total, 98);
  });
}
