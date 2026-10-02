/// Google Play Billing — the ONE place the subscription product ids live.
///
/// Create exactly these subscription products in Play Console
/// (Monetize → Products → Subscriptions) for package [kPlayPackageName],
/// each with an auto-renewing base plan (monthly or yearly). Prices come from
/// Play Console and are shown in the buyer's currency via
/// ProductDetails.price — nothing here sets a price.
///
/// The server keeps the same table: functions/_lib/play.js PLAY_PRODUCTS.
library;

/// applicationId (tools/flutter-android.mjs, android-config/google-services.json).
const kPlayPackageName = 'com.nowssb.app';

/// Server-side verification (Cloudflare Pages Function).
const kPlayVerifyUrl = 'https://nowssb.com/api/play/verify';

const kResonanceMonthly = 'nowssb_resonance_monthly';
const kResonanceYearly = 'nowssb_resonance_yearly';
const kFrequencyMonthly = 'nowssb_frequency_monthly';
const kFrequencyYearly = 'nowssb_frequency_yearly';
const kFrequencyXMonthly = 'nowssb_frequencyx_monthly';
const kFrequencyXYearly = 'nowssb_frequencyx_yearly';

class PlayPlan {
  const PlayPlan(this.productId, this.tier, this.name, this.yearly);
  final String productId;

  /// Same tier keys the website and Firestore use: resonance, frequency, frequencyX.
  final String tier;
  final String name;
  final bool yearly;
}

const kPlayPlans = <PlayPlan>[
  PlayPlan(kResonanceMonthly, 'resonance', 'Resonance', false),
  PlayPlan(kResonanceYearly, 'resonance', 'Resonance', true),
  PlayPlan(kFrequencyMonthly, 'frequency', 'Frequency', false),
  PlayPlan(kFrequencyYearly, 'frequency', 'Frequency', true),
  PlayPlan(kFrequencyXMonthly, 'frequencyX', 'Frequency X', false),
  PlayPlan(kFrequencyXYearly, 'frequencyX', 'Frequency X', true),
];

Set<String> get kPlayProductIds => {for (final p in kPlayPlans) p.productId};

PlayPlan? playPlanFor(String tier, {required bool yearly}) {
  for (final p in kPlayPlans) {
    if (p.tier == tier && p.yearly == yearly) return p;
  }
  return null;
}

PlayPlan? playPlanById(String productId) {
  for (final p in kPlayPlans) {
    if (p.productId == productId) return p;
  }
  return null;
}

/// Plan display name ("Frequency X") → tier key ("frequencyX").
String? tierForPlanName(String name) {
  for (final p in kPlayPlans) {
    if (p.name == name) return p.tier;
  }
  return null;
}

// ── Content prices (words, meanings, Signature, ebooks) ─────────────────
//
// Paid content is bought through the economy's server checkout
// (lib/features/programs/store_extras.dart CheckoutPanel → beginCheckout →
// a `nowssb_tier_<₹>` Play product → users/{uid}/owned/{itemId}). The phone
// only decides the list price it sends, which the server bounds per kind.
// These are friendly price points inside PDF-2's band (about ₹70–₹350 for
// words), all of them Play price tiers the checkout can charge.

/// India-tier price points (₹) per kind.
const kContentPriceTiers = <String, List<int>>{
  'word': [79, 99, 149, 199, 249, 299, 349],
  'meaning': [79, 99, 149, 199, 249, 299, 349],
  'signature': [199, 249, 299, 349, 399, 499, 599, 699, 799, 999],
  'ebook': [149, 199, 249, 299, 349, 399, 499, 599, 699, 799, 999],
};

/// Default prices until an admin sets one (Admin → Settings → Products & prices).
const kContentDefaultPrice = <String, int>{
  'word': 99,
  'meaning': 99,
  'signature': 299,
  'ebook': 399,
};

/// The smallest price point that covers [price], or the top one.
int contentTierFor(String kind, num price) {
  final tiers = kContentPriceTiers[kind] ?? const <int>[];
  if (tiers.isEmpty) return price.ceil();
  for (final t in tiers) {
    if (t >= price) return t;
  }
  return tiers.last;
}

/// Bag ids are `word:<name>`, `signature:<name>`, `meaning:<word>`,
/// `ebook:<title>`; the part before the colon is the product kind.
String? contentKindOfItem(String itemId) {
  final i = itemId.indexOf(':');
  if (i <= 0) return null;
  final k = itemId.substring(0, i);
  return kContentPriceTiers.containsKey(k) ? k : null;
}

/// Same doc id the server writes under users/{uid}/owned (cleanId).
String ownedDocId(String itemId) {
  var s = itemId.replaceAll(RegExp(r'[^A-Za-z0-9_.@-]'), '_');
  s = s.replaceFirst(RegExp(r'^\.+'), '_');
  if (s.length > 300) s = s.substring(0, 300);
  return s.isEmpty ? '_' : s;
}
