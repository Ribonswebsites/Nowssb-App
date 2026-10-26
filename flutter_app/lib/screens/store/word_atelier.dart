/// The Word Atelier — the poster page (POSTER PAGES · Atelier): cloth
/// swatches of the real word catalogue, wired to the real item page, bag
/// and checkout. Store terms still open from the host.
library;

import 'package:flutter/material.dart';

import '../poster/poster_pages.dart';
import 'store_terms_sheet.dart';

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key, this.now});

  /// Fixed clock for tests / shots.
  final DateTime? now;

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'word',
        head: 'Words described by sound',
        child: Builder(builder: (x) => posterAtelierPage(x, now: now)),
      );
}
