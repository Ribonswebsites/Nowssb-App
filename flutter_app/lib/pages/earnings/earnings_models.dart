// Earnings (newui_earnings) view models and the global payout abstraction.
// All amounts are USD cents from the server, shown with KitMoney.cents in the
// user's local currency. No country-specific rules live in the app: identity
// and tax checks are owned by the payout provider (verify with provider / legal).
library;

import 'dart:async';

import '../../kit/kit.dart';

enum EarningKind { sale, commission, payout }

enum EarningsStatus { loading, ready, empty, error, offline, signedOut }

class EarningRow {
  const EarningRow({required this.kind, required this.title, required this.cents, this.status = '', this.isNew = false});
  final EarningKind kind;
  final String title, status;
  final int cents;
  final bool isNew;

  /// Failed / cancelled payouts render greyed like the approved "Expired" card.
  bool get inactive => const {'failed', 'cancelled', 'canceled', 'rejected'}.contains(status.toLowerCase());
}

class EarningsData {
  const EarningsData({this.status = EarningsStatus.loading, this.balanceCents = 0, this.rows = const [], this.message = '', this.payoutLinked = false});
  final EarningsStatus status;
  final int balanceCents;
  final List<EarningRow> rows;
  final String message;
  final bool payoutLinked;

  int sum(EarningKind k) => rows.where((r) => r.kind == k && !r.inactive).fold(0, (a, r) => a + r.cents);
}

/// One payout country. [code] is ISO 3166-1 alpha-2. Names only; every rule
/// (KYC, tax forms such as W-8/W-9 or VAT IDs, limits) comes from the provider.
class PayoutCountry {
  const PayoutCountry(this.code, this.name);
  final String code, name;
}

class PayoutOnboarding {
  const PayoutOnboarding({this.url, this.message = '', this.supported = true});
  final String? url;
  final String message;
  final bool supported;
}

/// Global payout provider abstraction (Wise / PayPal Payouts / Stripe Connect / Payoneer).
abstract class PayoutProvider {
  String get name;
  List<PayoutCountry> get countries;
  /// Starts provider-hosted onboarding where identity and tax checks for the
  /// country happen. The app never collects ID or tax numbers itself.
  Future<KitResult<PayoutOnboarding>> onboard(String country);
  Future<KitResult<Json>> requestPayout();
}

/// Default: the existing server rail (`savePayoutAccount` method "wise"), which
/// returns a provider onboarding URL.
class ServerPayoutProvider implements PayoutProvider {
  const ServerPayoutProvider({this.method = 'wise'});
  final String method;
  @override
  String get name => method == 'paypal' ? 'PayPal' : 'Wise';
  @override
  List<PayoutCountry> get countries => kPayoutCountries;
  @override
  Future<KitResult<PayoutOnboarding>> onboard(String country) async {
    final r = await EarningsRepository.savePayoutAccount({'country': country, 'method': method});
    return switch (r) {
      KitOk(:final value) => KitOk(PayoutOnboarding(
          url: '${value['onboardUrl'] ?? ''}'.startsWith('http') ? '${value['onboardUrl']}' : null,
          message: '${value['message'] ?? ''}',
          supported: '${value['rail'] ?? ''}' != 'unsupported')),
      KitErr(:final message, :final code) => KitErr(message, code),
    };
  }
  @override
  Future<KitResult<Json>> requestPayout() => EarningsRepository.requestPayout({});
}

const kPayoutCountries = <PayoutCountry>[
  PayoutCountry('US', 'United States'), PayoutCountry('GB', 'United Kingdom'),
  PayoutCountry('DE', 'Germany'), PayoutCountry('FR', 'France'), PayoutCountry('ES', 'Spain'),
  PayoutCountry('CA', 'Canada'), PayoutCountry('AU', 'Australia'), PayoutCountry('JP', 'Japan'),
  PayoutCountry('BR', 'Brazil'), PayoutCountry('MX', 'Mexico'), PayoutCountry('SG', 'Singapore'),
  PayoutCountry('AE', 'United Arab Emirates'), PayoutCountry('IN', 'India'), PayoutCountry('NZ', 'New Zealand'),
];

/// Source of earnings data; the default merges the kit's EarningsRepository streams.
abstract class EarningsSource {
  Stream<EarningsData> watch();
}

class KitEarningsSource implements EarningsSource {
  const KitEarningsSource();
  @override
  Stream<EarningsData> watch() {
    if (EconomyMirror.instance.uid == null) {
      return Stream.value(const EarningsData(status: EarningsStatus.signedOut));
    }
    late StreamController<EarningsData> out;
    final parts = <int, List<EarningRow>>{};
    final subs = <StreamSubscription<DocList>>[];
    void emit() {
      if (parts.length < 3) return;
      final rows = [for (final p in parts.values) ...p];
      out.add(EarningsData(status: rows.isEmpty ? EarningsStatus.empty : EarningsStatus.ready,
          balanceCents: EarningsRepository.cashCents, rows: rows));
    }
    void listen(int i, Stream<DocList> s, EarningRow Function(Json) map) {
      subs.add(s.listen((docs) { parts[i] = [for (final d in docs) map(d.data())]; emit(); },
          onError: (Object e) {
        final offline = '$e'.contains('unavailable');
        out.add(EarningsData(status: offline ? EarningsStatus.offline : EarningsStatus.error, message: '$e'));
      }));
    }
    out = StreamController<EarningsData>(onListen: () {
      out.add(const EarningsData());
      listen(0, EarningsRepository.cashLedger(), (m) => EarningRow(kind: EarningKind.sale,
          title: '${m['reason'] ?? 'Sale'}', cents: (m['delta'] as num?)?.toInt() ?? 0));
      listen(1, EarningsRepository.commissionLedger(), (m) => EarningRow(kind: EarningKind.commission,
          title: 'Commission', cents: (m['amount'] as num?)?.toInt() ?? (m['commissionAmount'] as num?)?.toInt() ?? 0,
          status: '${m['status'] ?? ''}'));
      listen(2, EarningsRepository.payoutRequests(), (m) => EarningRow(kind: EarningKind.payout,
          title: 'Payout', cents: (m['amountBase'] as num?)?.toInt() ?? 0, status: '${m['status'] ?? ''}'));
    }, onCancel: () { for (final s in subs) { s.cancel(); } });
    return out.stream;
  }
}
