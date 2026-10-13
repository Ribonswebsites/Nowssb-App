import 'dart:async';

import '../../../data/content.dart';
import '../../../data/entitlements.dart';
import '../../../data/store_catalog.dart';
import '../../../data/store_prices.dart';
import '../../economy/money.dart';

/// Page-local data access for the E-books rebuild. Swap to Bug Hunter's
/// shared `CatalogRepository` once it lands on main (spec 22).
abstract class EbooksSource {
  Future<List<EbBook>> load();
  bool get offline;
  num priceOf(EbBook b);

  /// Price in USD cents, the base unit KitMoney.cents localizes.
  int priceCents(EbBook b);
  bool owns(EbBook b);
}

class LiveEbooksSource implements EbooksSource {
  const LiveEbooksSource();

  @override
  Future<List<EbBook>> load() async {
    final live = ContentStore.instance.books;
    if (live.isEmpty) return kEbBooks;
    final keys = {for (final b in kEbBooks) b.key};
    return [
      ...kEbBooks,
      for (final b in live)
        if (!keys.contains(b.key))
          EbBook(
            key: b.key,
            title: b.title,
            sub: b.sub,
            price: b.price,
            cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
            about: b.sub,
            contents: const ['Published from the NowssB studio'],
          ),
    ];
  }

  @override
  bool get offline => false;

  @override
  num priceOf(EbBook b) => StorePrices.instance
      .priceFor('ebook:${b.title.toLowerCase()}', shown: b.price);

  @override
  int priceCents(EbBook b) => ebookCatalogToCents(priceOf(b));

  @override
  bool owns(EbBook b) =>
      Entitlements.instance.canOpenEbook(b.title, price: priceOf(b));
}

/// The legacy catalog (kEbBooks / ContentStore / StorePrices) stores prices in
/// its original catalog unit (INR). Convert once here to USD cents with the
/// same live FxBook rates the app uses, so the page only ever formats
/// currency-neutral cents through KitMoney.cents. Drop this once the catalog
/// carries a minor-unit price (or Play's localized priceLabel is wired).
int ebookCatalogToCents(num catalogPrice) {
  final perUsd = FxBook.instance.rates['INR'] ?? 83.5;
  return ((catalogPrice / perUsd) * 100).round();
}
