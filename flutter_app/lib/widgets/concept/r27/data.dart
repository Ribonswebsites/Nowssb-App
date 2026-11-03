/// R27 — plain data the sections draw, plus live adapters that read the
/// real sources (EconomyMirror summary, EarnWallet).
/// Widgets never invent numbers; Builder wires [R27Live] in the homes.
library;

import '../../../data/earn_wallet.dart';
import '../../../features/economy/economy_api.dart';




class R27Rank {
  const R27Rank(this.title, this.minWords, this.ratePct);
  final String title;
  final int minWords;
  final num ratePct;
}

class R27Earn {
  const R27Earn({required this.ranks, required this.wordsSold, required this.ratePct, required this.nextTarget, this.code = ''});
  final List<R27Rank> ranks;
  final int wordsSold;
  /// Server rate (EarnWallet.commissionPercent); 0 = not yet ranked.
  final int ratePct;
  final int nextTarget;
  final String code;
  int get current {
    var k = 0;
    for (var i = 0; i < ranks.length; i++) {
      if (wordsSold >= ranks[i].minWords) k = i;
    }
    return k;
  }
  num get topRate => ranks.isEmpty ? 0 : ranks.map((r) => r.ratePct).reduce((a, b) => a > b ? a : b);
  num get shownRate => ratePct > 0 ? ratePct : (ranks.isEmpty ? 0 : ranks[current].ratePct);
}



/// Mirrors `_defaultRanks` in lib/features/earn/earn_home_sections.dart —
/// shown only before the summary answers.
const kR27RankDefaults = [
  R27Rank('Assistant Officer', 0, 15),
  R27Rank('Officer', 100, 22),
  R27Rank('Executive Officer I', 500, 30),
  R27Rank('Executive Officer II', 1000, 38),
  R27Rank('Diamond I', 2000, 45),
  R27Rank('Diamond II', 3000, 50),
];


/// Live reads. Listen to EconomyMirror.instance and
/// rebuild with these.
class R27Live {
  static EconomyMirror get _m => EconomyMirror.instance;

  static R27Earn earn() {
    final cfg = _m.summary['config'];
    final raw = cfg is Map && cfg['earn'] is Map ? (cfg['earn'] as Map)['ranks'] : null;
    final ranks = raw is List && raw.isNotEmpty
        ? [for (final r in raw.whereType<Map>()) R27Rank('${r['title'] ?? ''}', (r['minWords'] as num?)?.toInt() ?? 0, (r['ratePct'] as num?) ?? 0)]
        : kR27RankDefaults;
    return R27Earn(ranks: ranks, wordsSold: _m.wordsSold, ratePct: EarnWallet.instance.commissionPercent,
        nextTarget: _m.nextSellerTarget, code: _m.code);
  }

}
