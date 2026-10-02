/// Shared Add to Cart / Buy Now entry so every Store family uses the same
/// flight animation and the same Cart / bag marks.
library;

import 'package:flutter/material.dart';

import '../../data/cart_bag.dart';
import '../../data/store_prices.dart';
import '../../widgets/cart_add_animation.dart';
import 'cart_pages.dart';

BagItem wordBagItem({
  required String name,
  required String root,
  required String img,
  num price = 0,
  bool signature = false,
}) {
  final id = '${signature ? 'signature' : 'word'}:${name.toLowerCase()}';
  return BagItem(
    id: id,
    title: name,
    subtitle: root,
    image: img,
    price: StorePrices.instance.priceFor(id, shown: price),
    kind: signature ? 'Signature' : 'Word',
  );
}

BagItem meaningBagItem({
  required String word,
  required String root,
  required String img,
  required num price,
  bool signature = false,
}) {
  return BagItem(
    id: 'meaning:${word.toLowerCase()}',
    title: word,
    subtitle: root,
    image: img,
    price: StorePrices.instance.priceFor('meaning:${word.toLowerCase()}', shown: price),
    kind: signature ? 'Signature Meaning' : 'Meaning',
  );
}

BagItem ebookBagItem({
  required String title,
  required String sub,
  required String img,
  required num price,
}) {
  return BagItem(
    id: 'ebook:${title.toLowerCase()}',
    title: title,
    subtitle: sub,
    image: img,
    price: StorePrices.instance.priceFor('ebook:${title.toLowerCase()}', shown: price),
    kind: 'Ebook',
  );
}

Future<void> storeAddToCart(
  BuildContext context,
  BagItem item, {
  GlobalKey? origin,
  GlobalKey? cartTarget,
}) async {
  await CartBag.instance.addCart(item);
  if (!context.mounted) return;
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
  CartAddAnimation.play(
    context,
    fromKey: origin,
    fromContext: origin == null ? context : null,
    targetKey: cartTarget,
    item: item,
  );
}

Future<void> storeBuyNow(
  BuildContext context,
  BagItem item, {
  GlobalKey? origin,
  GlobalKey? cartTarget,
}) {
  return CartAddAnimation.playForContext(
    context,
    item: item,
    pressedKey: origin,
    pressedContext: origin == null ? context : null,
    cartTargetKey: cartTarget,
    openCartAfter: true,
    onComplete: () {
      if (!context.mounted) return;
      // Buy Now = this one item on Google Play (the rest of the cart waits).
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => CheckoutPage(items: [item])));
    },
  );
}
