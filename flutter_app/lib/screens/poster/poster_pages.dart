/// POSTER PAGES — the store's poster-language pages, wired to the app's real
/// routes: item pages, add-to-bag / buy-now (StorePrices, ₹ region money),
/// the bag sheet, the store picker and the library. No tap is dead.
library;

import 'package:flutter/material.dart';

import '../library.dart';
import '../store/bag_ui.dart';
import '../store/product_detail.dart';
import '../store/store_actions.dart';
import '../store/store_cards.dart';
import 'poster_kit.dart';
import 'poster_trending.dart';

export 'poster_kit.dart';
export 'poster_orbit.dart';
export 'poster_trending.dart';

typedef PosterBuild = Widget Function(ScrollController? c, DateTime? now);

void posterBack(BuildContext x) => Navigator.of(x).maybePop();
void posterBag(BuildContext x) => showBagSheet(x, BagKind.cart);
void posterPush(BuildContext x, Widget page) => Navigator.of(x).push(MaterialPageRoute<void>(builder: (_) => page));

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
};
