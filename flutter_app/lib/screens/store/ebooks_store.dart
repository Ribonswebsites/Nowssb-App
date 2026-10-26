/// The Ebooks Store — the poster page (POSTER PAGES · eBooks, "THE SPINE"):
/// the real ebook catalogue, wired to the real item page, bag and checkout.
/// Store terms still open from the host.
library;

import 'package:flutter/material.dart';

import '../poster/poster_pages.dart';
import 'store_terms_sheet.dart';

class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'ebooks',
        head: 'Ebooks described by sound',
        child: Builder(builder: (x) => posterEbooksPage(x)),
      );
}
