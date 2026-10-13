import 'dart:async';

import '../../../data/content.dart';
import '../../../data/entitlements.dart';
import '../../../data/store_catalog.dart';
import '../../../data/store_prices.dart';

/// Page-local data access for the E-books rebuild. Swap to Bug Hunter's
/// shared `CatalogRepository` once it lands on main (spec 22).
abstract class EbooksSource {
  Future<List<EbBook>> load();
  bool get offline;
  num priceOf(EbBook b);
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
  bool owns(EbBook b) =>
      Entitlements.instance.canOpenEbook(b.title, price: priceOf(b));
}
