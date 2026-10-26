/// POSTER PAGES — the store's poster-language pages, wired to the app's real
/// routes: item pages, add-to-bag / buy-now (StorePrices, ₹ region money),
/// the bag sheet, the store picker and the library. No tap is dead.
library;

import 'package:flutter/material.dart';

import '../library.dart';
import '../store/bag_ui.dart';
import '../store/product_detail.dart';
import '../store/store_actions.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../store/store_cards.dart';
import '../store/store_home_sections.dart';
import '../store/store_routes.dart';
import '../store/store_select_sheet.dart';
import 'poster_atelier.dart';
import 'poster_kit.dart';
import 'poster_trending.dart';

export 'poster_atelier.dart';
export 'poster_kit.dart';
export 'poster_orbit.dart';
export 'poster_trending.dart';

typedef PosterBuild = Widget Function(ScrollController? c, DateTime? now);

void posterBack(BuildContext x) => Navigator.of(x).maybePop();
void posterBag(BuildContext x) => showBagSheet(x, BagKind.cart);
void posterPush(BuildContext x, Widget page) => Navigator.of(x).push(MaterialPageRoute<void>(builder: (_) => page));

/// The store picker sheet (the same one every store page opens).
void posterStores(BuildContext x, String current) => showStoreSelectSheet(
      x,
      current: current,
      onSelect: (id) => openStoreFromPicker(x, id, current: current),
    );

/// The Word Atelier poster (WordAtelierScreen's page).
Widget posterAtelierPage(BuildContext x, {ScrollController? controller, DateTime? now}) => PosterAtelier(
      controller: controller,
      now: now,
      onBack: () => posterBack(x),
      onOpenStores: () => posterStores(x, 'word'),
      onOpenBag: () => posterBag(x),
      onOpenWord: (e, p) => openAtelierWord(x, word: e.word, root: e.root, img: kRmWordImg, price: p),
      onAddToCart: (e, p) => storeAddToCart(x, wordBagItem(name: e.word, root: e.root, img: kRmWordImg, price: p)),
      onBuy: (e, p) => storeBuyNow(x, wordBagItem(name: e.word, root: e.root, img: kRmWordImg, price: p)),
      onOpenCategory: (cat) => showStoreViewAllPanel(
        x,
        title: cat.label,
        items: [
          for (final w in cat.words)
            StoreViewAllItem(
              title: w.word,
              sub: w.root,
              art: kStoreProductArt,
              word: w.word,
              root: w.root,
              img: kRmWordImg,
              price: StorePrices.instance.priceFor('word:${w.word.toLowerCase()}'),
            ),
        ],
        onOpenWord: (w, r, img, p) => openAtelierWord(x, word: w, root: r, img: img, price: p),
      ),
    );

/// Trending — the destination of the home Trending cards.
class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key, this.controller, this.now, this.debugAngle, this.debugTilt});
  final ScrollController? controller;
  final DateTime? now;
  final double? debugAngle;
  final Offset? debugTilt;

  @override
  Widget build(BuildContext x) => PosterTrending(
        controller: controller,
        now: now,
        debugAngle: debugAngle,
        debugTilt: debugTilt,
        onBack: () => posterBack(x),
        onOpenBag: () => posterBag(x),
        onOpenWord: (i) {
          final w = PosterTrending.wordAt(i);
          if (w != null) openAtelierWord(x, word: w.word, root: w.deva, img: w.img, price: wordPrice(w.word));
        },
        onBuy: (w) => storeBuyNow(x, wordBagItem(name: w.word, root: w.deva, img: w.img, price: wordPrice(w.word))),
        onOpenLibrary: () => posterPush(x, const LibraryScreen()),
      );
}

final Map<String, PosterBuild> kPosterPages = {
  'trending': (c, now) => TrendingScreen(controller: c, now: now, debugAngle: .5, debugTilt: const Offset(-.3, .12)),
  'atelier': (c, now) => Builder(builder: (x) => posterAtelierPage(x, controller: c, now: now)),
};
