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
