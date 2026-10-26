/// Signature Store — the poster page (POSTER PAGES · Signature, "THE SEAL"):
/// the real signature words and meanings at their Play prices, wired to the
/// real item pages, bag and checkout. Store terms still open from the host.
library;

import 'package:flutter/material.dart';

import '../poster/poster_pages.dart';
import 'store_terms_sheet.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'signature',
        head: 'Signatures described by sound',
        child: Builder(builder: (x) => posterSignaturePage(x)),
      );
}
