/// Signature Store — the poster page (POSTER PAGES · Signature, "THE SEAL"):
/// the real signature words and meanings at their Play prices, wired to the
/// real item pages, bag and checkout. Store terms still open from the host.
library;

import 'package:flutter/material.dart';

import '../poster/poster_pages.dart';
import 'store_first_use_guide.dart';
import 'store_terms_sheet.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreFirstUseGuide(
        guideKey: 'signature_store',
        helpButton: false,
        steps: kSignatureGuideSteps,
        child: StoreTermsHost(
        which: 'signature',
        head: 'Signatures described by sound',
        child: Builder(builder: (x) => posterSignaturePage(x)),
        ),
      );
}

/// What the Signature Store first-use guide walks through.
const kSignatureGuideSteps = <StoreGuideStep>[
  StoreGuideStep(Icons.workspace_premium_rounded, 'Signature words',
      'The rarest words in NowssB. Each Signature is personally crafted for you and delivered within 48 hours.'),
  StoreGuideStep(Icons.touch_app_rounded, 'Open or own',
      'Tap a card to see its details. Tap Own to buy it now, or Add to cart to save it for later. Prices show in your local currency.'),
  StoreGuideStep(Icons.shopping_bag_rounded, 'Your bag',
      'The bag at the top shows what you have saved and takes you to checkout.'),
  StoreGuideStep(Icons.edit_note_rounded, 'Request a Signature',
      'Can\'t find your word? Scroll to the end and tap Request to ask for one.'),
];
