/// Country-aware payout hand-off (global, not tied to any one country).
///
/// Partner perks are NOT cash (see kPartnerDisclaimer), so the Partner page
/// never pays out money itself. Cash commissions belong to Earn/Earnings and
/// go through one global payout provider that runs its own per-country
/// identity (KYC) and tax checks. This file only describes that hand-off so
/// the Partner page can explain it and link to Earnings.
///
/// Every check below is marked "verify with payout provider / legal".
/// Nothing here is a legal rule we enforce ourselves.
library;

enum PayoutProviderKind { stripeConnect, paypalPayouts, wise, payoneer }

extension PayoutProviderName on PayoutProviderKind {
  String get label => switch (this) {
        PayoutProviderKind.stripeConnect => 'Stripe Connect',
        PayoutProviderKind.paypalPayouts => 'PayPal Payouts',
        PayoutProviderKind.wise => 'Wise',
        PayoutProviderKind.payoneer => 'Payoneer',
      };
}

/// Pending decision for Ribon: no provider is wired in the app yet.
const PayoutProviderKind kDefaultPayoutProvider = PayoutProviderKind.stripeConnect;

const kVerifyNote = 'Verify with payout provider / legal';

class PayoutCountryInfo {
  const PayoutCountryInfo({required this.countryCode, required this.checks, required this.provider});
  final String countryCode;
  final PayoutProviderKind provider;

  /// Human-readable checks the provider is expected to run. Examples only.
  final List<String> checks;
}

/// Resolves what the provider will ask for. Examples come from the page rules
/// (W-8/W-9 for the US, VAT ID for EU businesses); everything else defers to
/// the provider's own onboarding.
PayoutCountryInfo payoutInfoFor(String countryCode, {PayoutProviderKind provider = kDefaultPayoutProvider}) {
  final cc = countryCode.toUpperCase();
  const eu = {
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'CZ',
    'DK',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HU',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SK',
    'SI',
    'ES',
    'SE',
  };
  final checks = <String>[
    'Identity check run by ${provider.label} ($kVerifyNote)',
    if (cc == 'US') 'US tax form (W-9) collected by ${provider.label} ($kVerifyNote)',
    if (cc != 'US') 'Foreign-status tax form (e.g. W-8BEN) if required ($kVerifyNote)',
    if (eu.contains(cc)) 'VAT ID for businesses, if any ($kVerifyNote)',
    'Payout method and currency chosen in ${provider.label} onboarding',
  ];
  return PayoutCountryInfo(countryCode: cc, checks: checks, provider: provider);
}
