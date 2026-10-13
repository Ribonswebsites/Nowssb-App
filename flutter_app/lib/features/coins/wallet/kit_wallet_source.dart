import 'dart:async';
import '../../../kit/kit.dart';
import '../../economy/economy_api.dart';
import 'coins_wallet_data.dart';

/// Live source over the kit data layer (CoinsRepository). Read-only: every
/// balance and ledger entry is written by the Worker.
class KitWalletSource implements CoinsWalletSource {
  @override
  Future<CoinsWalletState> load() async {
    await CoinsRepository.refresh();
    final docs = await CoinsRepository.ledger(limit: 100).first.timeout(const Duration(seconds: 12));
    final m = EconomyMirror.instance.summary;
    final c = m['coins'] is Map ? Map<String, dynamic>.from(m['coins'] as Map) : const <String, dynamic>{};
    final exp = c['expiresOn'] ?? m['coinsExpireOn'];
    return CoinsWalletState(
      balance: CoinsRepository.coins,
      worthLabel: (c['worthLabel'] ?? m['coinsWorthLabel'])?.toString(),
      capPercent: ((c['capPercent'] ?? m['coinCapPercent']) as num?)?.toInt() ?? 35,
      coinValue: ((c['coinValue'] ?? m['coinValue']) as num?)?.toDouble() ?? 0.01,
      currency: '${c['currencySymbol'] ?? m['currencySymbol'] ?? r'$'}',
      expiringSoon: ((c['expiringSoon'] ?? m['coinsExpiringSoon']) as num?)?.toInt() ?? 0,
      expiresOn: exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt()) : DateTime.tryParse('${exp ?? ''}'),
      ledger: [for (final d in docs) LedgerEntry.fromMap(d.data())],
    );
  }
}
