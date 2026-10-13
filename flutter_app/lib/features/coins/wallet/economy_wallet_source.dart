import '../../economy/economy_api.dart';
import 'coins_wallet_data.dart';

/// Live source: reads the server summary (Worker-written). Will move to Bug
/// Hunter's shared data layer when it lands.
class EconomyWalletSource implements CoinsWalletSource {
  @override
  Future<CoinsWalletState> load() async {
    final m = await EconomyApi.summary();
    final coins = m['coins'] as Map? ?? const {};
    final ledger = (m['coinLedger'] ?? coins['ledger']) as List? ?? const [];
    final exp = coins['expiresOn'] ?? m['coinsExpireOn'];
    return CoinsWalletState(
      balance: (m['coins'] is num ? m['coins'] as num : (coins['balance'] as num?) ?? EconomyMirror.instance.coins).toInt(),
      worthLabel: (coins['worthLabel'] ?? m['coinsWorthLabel'])?.toString(),
      capPercent: ((coins['capPercent'] ?? m['coinCapPercent']) as num?)?.toInt() ?? 35,
      expiringSoon: ((coins['expiringSoon'] ?? m['coinsExpiringSoon']) as num?)?.toInt() ?? 0,
      expiresOn: exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt()) : DateTime.tryParse('${exp ?? ''}'),
      ledger: [for (final e in ledger) if (e is Map) LedgerEntry.fromMap(Map<String, dynamic>.from(e))],
    );
  }
}
