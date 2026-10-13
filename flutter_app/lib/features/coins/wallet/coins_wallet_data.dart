/// Page-local data model for the Coins wallet. Reads only; every balance and
/// ledger entry is written by the Worker (server-authoritative, §18.1).
enum LedgerKind { earned, spent, expired }

class LedgerEntry {
  const LedgerEntry({required this.kind, required this.amount, required this.label, required this.at});
  final LedgerKind kind;
  final int amount;
  final String label;
  final DateTime at;

  static LedgerEntry fromMap(Map<String, dynamic> m) {
    final raw = (m['amount'] as num?)?.toInt() ?? 0;
    final k = '${m['kind'] ?? m['type'] ?? ''}';
    final kind = k == 'expired'
        ? LedgerKind.expired
        : (k == 'spent' || raw < 0) ? LedgerKind.spent : LedgerKind.earned;
    final ts = m['at'];
    final at = ts is DateTime
        ? ts
        : ts is num
            ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
            : DateTime.tryParse('$ts') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return LedgerEntry(kind: kind, amount: raw.abs(), label: '${m['label'] ?? m['reason'] ?? 'Coins'}', at: at);
  }
}

class CoinsWalletState {
  const CoinsWalletState({
    required this.balance,
    this.worthLabel,
    this.capPercent = 35,
    this.coinValue = 0.01,
    this.currency = '\$',
    this.expiringSoon = 0,
    this.expiresOn,
    this.ledger = const [],
  });
  final int balance;
  /// "Worth up to X off" string computed by the Worker (localized). Null = unknown.
  final String? worthLabel;
  final int capPercent;
  /// Fixed redemption ratio: currency value of one coin (Play loyalty rule: show it).
  final double coinValue;
  final String currency;
  final int expiringSoon;
  final DateTime? expiresOn;
  final List<LedgerEntry> ledger;
}

/// Pure calculator used by the Use pop-up. Display only; the Worker enforces the cap.
class CoinCalc {
  const CoinCalc({required this.coinsUsable, required this.discount, required this.youPay});
  final int coinsUsable;
  final double discount;
  final double youPay;

  /// [coinValue] = currency value of one coin (from Worker config).
  static CoinCalc of({required double price, required int balance, required int capPercent, double coinValue = 0.01}) {
    if (price <= 0 || coinValue <= 0) return const CoinCalc(coinsUsable: 0, discount: 0, youPay: 0);
    final maxDiscount = price * capPercent / 100;
    final maxCoins = (maxDiscount / coinValue).floor();
    final use = balance < maxCoins ? balance : maxCoins;
    final disc = use * coinValue;
    return CoinCalc(coinsUsable: use, discount: disc, youPay: price - disc);
  }
}

abstract class CoinsWalletSource {
  Future<CoinsWalletState> load();
}
