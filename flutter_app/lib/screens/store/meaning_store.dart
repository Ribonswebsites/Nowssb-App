/// The Meaning Store — the poster page (POSTER PAGES · Meaning, "THE ROOT"):
/// the real meaning catalogue, wired to the real item page, bag and
/// checkout. Store terms and the first-use guide still open from the host.
library;

import 'package:flutter/material.dart';

import '../poster/poster_pages.dart';
import 'store_first_use_guide.dart';
import 'store_terms_sheet.dart';

class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key, this.now});

  /// Fixed clock for tests / shots.
  final DateTime? now;

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'meaning',
        head: 'Meanings described by sound',
        child: Builder(builder: (x) => posterMeaningPage(x, now: now)),
      ).withStoreGuide('meaning_store', false);
}
