/// NORMAL HOME v5 — the sections below the ritual card, wired to real data.
///
/// Each widget here only reads live stores and passes the values into the
/// v5 section widgets (lib/widgets/concept/normal). Nothing is invented: a
/// value that has no real source is left out of the section.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/billing_config.dart';
import '../../data/cart_bag.dart';
import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/models.dart';
import '../../data/play_subscriptions.dart';
import '../../data/store_catalog.dart';
import '../../data/trending_chart.dart';
import '../../features/economy/economy_api.dart';
import '../../widgets/concept/normal/ebooks.dart';
import '../../widgets/concept/normal/edition.dart';
import '../../widgets/concept/normal/own.dart';
import '../../widgets/concept/normal/trending.dart';

Map<String, dynamic> _map(Object? o) => o is Map ? Map<String, dynamic>.from(o) : const {};
int? _int(Object? o) => o is num ? o.toInt() : int.tryParse('${o ?? ''}');

/// The day's library pick (same rule as the old Trending row).
/// The first three of the shared Trending ranking (same as TrendingScreen).
List<String> v5TrendingPick(List<Word> words, DateTime now) => [for (final i in trendingChart(words, now, max: 3)) words[i].word];

class V5Trending extends StatelessWidget {
  const V5Trending({super.key, required this.onWord, required this.onLibrary, required this.onSeeAll, this.now});
  final void Function(Word word) onWord;
  final VoidCallback onLibrary;
  /// Opens the poster TrendingScreen.
  final VoidCallback onSeeAll;
  /// Ranking day (tests); defaults to today.
  final DateTime? now;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ContentStore.instance,
        builder: (context, _) {
          final lib = ContentStore.instance.library;
          return NTrending(
            key: const ValueKey('v5-trending'),
            words: v5TrendingPick(lib, now ?? DateTime.now()),
            onWord: (s) {
              for (final w in lib) {
                if (w.word == s) return onWord(w);
              }
            },
            onLibrary: onLibrary,
            onSeeAll: onSeeAll,
          );
        },
      );
}

ImageProvider? v5Thumb(String src) {
  if (src.startsWith('assets/')) return AssetImage(src);
  if (src.startsWith('http://') || src.startsWith('https://')) return CachedNetworkImageProvider(src);
  return null;
}

/// One bay picture per shelf: the NowssB Store box, standing alone (no
/// stack, no person art). An empty bay keeps its dashed outline.
List<ImageProvider> _thumbs(Iterable<BagItem> items) =>
    items.isEmpty ? const [] : const [AssetImage('assets/home/nowssb-store.webp')];

/// Cart, wishlist and orders from CartBag (counts and item images).
class V5Own extends StatelessWidget {
  const V5Own({super.key, required this.onCart, required this.onWishlist, required this.onOrders});
  final VoidCallback onCart, onWishlist, onOrders;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: CartBag.instance,
        builder: (context, _) {
          final b = CartBag.instance;
          return NOwn(
            key: const ValueKey('v5-own'),
            onCart: onCart,
            onWishlist: onWishlist,
            onOrders: onOrders,
            cartCount: b.cartCount,
            wishlistCount: b.wishCount,
            orderCount: b.orders.length,
            cartThumbs: _thumbs(b.cart),
            wishlistThumbs: _thumbs(b.wishlist),
            orderThumbs: _thumbs(b.orders.expand((o) => o.items)),
          );
        },
      );
}

/// Edition (Play prices, availability, active tier) + Partner (points and
/// the server's `config.partner.levels`).
class V5EditionPartner extends StatelessWidget {
  const V5EditionPartner({super.key, required this.onJoin});
  final void Function(String tier) onJoin;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([PlaySubscriptions.instance, EconomyMirror.instance]),
        builder: (context, _) {
          final ps = PlaySubscriptions.instance;
          final w = EconomyMirror.instance;
          return Column(key: const ValueKey('v5-edition-partner'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            NEdition(
              onJoin: onJoin,
              prices: {
                for (final p in NEdition.plans)
                  p.$1: switch (playPlanFor(p.$1, yearly: false)) { final plan? => ps.priceFor(plan.productId), null => null },
              },
              playAvailable: ps.available,
              currentTier: ps.activeTier,
            ),
          ]);
        },
      );
}

/// eBooks from the store catalogue (kEbBooks).
class V5Ebooks extends StatelessWidget {
  const V5Ebooks({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => NEbooks(
        key: const ValueKey('v5-ebooks'),
        onBrowse: onBrowse,
        books: [for (final b in kEbBooks) (b.key, b.title)],
      );
}
