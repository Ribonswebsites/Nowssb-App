/// R27 — plain data the sections draw, plus live adapters that read the
/// real sources (EconomyMirror summary, kGiftCatalog, GiftBook, EarnWallet).
/// Widgets never invent numbers; Builder wires [R27Live] in the homes.
library;

import '../../../data/earn_wallet.dart';
import '../../../features/economy/economy_api.dart';
import '../../../features/gifts/gifts_screen.dart';

class R27Rewards {
  const R27Rewards({required this.coins, required this.streak, required this.loginToday, this.chestEvery = 40, this.signedIn = true});
  final int coins, streak, chestEvery;
  final bool loginToday, signedIn;
  int get toChest => chestEvery - coins % chestEvery;
}

class R27Gift {
  const R27Gift(this.id, this.label, this.priceInr);
  final String id, label;
  final int priceInr;
}

class R27Gifts {
  const R27Gifts({required this.cards, required this.sent, required this.received});
  final List<R27Gift> cards;
  final int sent, received;
}

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

class R27Coupon {
  const R27Coupon({required this.label, required this.pct, required this.scope, required this.capInr, this.expiresAt = 0});
  final String label, scope;
  final int pct;
  final num capInr;
  final int expiresAt;
}

class R27Coupons {
  const R27Coupons({required this.coupons, required this.sealed, required this.scratchedToday});
  final List<R27Coupon> coupons;
  /// rarity → sealed card count, mythic first.
  final Map<String, int> sealed;
  final bool scratchedToday;
  int get sealedTotal => sealed.values.fold(0, (a, b) => a + b);
}

/// Mirrors `_defaultRanks` in lib/features/earn/earn_home_sections.dart —
/// shown only before the summary answers (same rule as kGiftCatalog).
const kR27RankDefaults = [
  R27Rank('Assistant Officer', 0, 15),
  R27Rank('Officer', 100, 22),
  R27Rank('Executive Officer I', 500, 30),
  R27Rank('Executive Officer II', 1000, 38),
  R27Rank('Diamond I', 2000, 45),
  R27Rank('Diamond II', 3000, 50),
];

const kR27Rarities = ['mythic', 'legendary', 'epic', 'rare', 'common'];

/// Live reads. Listen to EconomyMirror.instance / GiftBook.instance and
/// rebuild with these.
class R27Live {
  static EconomyMirror get _m => EconomyMirror.instance;

  static R27Rewards rewards() => R27Rewards(coins: _m.coins, streak: _m.streak, loginToday: _m.loginToday, signedIn: _m.uid != null);

  static R27Gifts gifts() {
    final items = GiftBook.instance.items;
    return R27Gifts(
      cards: [for (final g in kGiftCatalog) R27Gift(g.id, g.label, g.cents)],
      sent: items.where((g) => g.direction == 'sent').length,
      received: items.where((g) => g.direction == 'received').length,
    );
  }

  static R27Earn earn() {
    final cfg = _m.summary['config'];
    final raw = cfg is Map && cfg['earn'] is Map ? (cfg['earn'] as Map)['ranks'] : null;
    final ranks = raw is List && raw.isNotEmpty
        ? [for (final r in raw.whereType<Map>()) R27Rank('${r['title'] ?? ''}', (r['minWords'] as num?)?.toInt() ?? 0, (r['ratePct'] as num?) ?? 0)]
        : kR27RankDefaults;
    return R27Earn(ranks: ranks, wordsSold: _m.wordsSold, ratePct: EarnWallet.instance.commissionPercent,
        nextTarget: _m.nextSellerTarget, code: _m.code);
  }

  static R27Coupons coupons() {
    final s = _m.summary;
    final list = (s['coupons'] as List?)?.whereType<Map>() ?? const <Map>[];
    final cards = (s['scratchCards'] as List?)?.whereType<Map>() ?? const <Map>[];
    return R27Coupons(
      coupons: [
        for (final c in list)
          R27Coupon(
            label: '${c['label'] ?? ''}',
            pct: (c['pct'] as num?)?.toInt() ?? 0,
            scope: '${c['scope'] ?? 'any'}',
            capInr: (c['capINR'] as num?) ?? 0,
            expiresAt: (c['expiresAt'] as num?)?.toInt() ?? 0,
          ),
      ],
      sealed: {
        for (final r in kR27Rarities)
          if (cards.any((c) => c['rarity'] == r)) r: cards.where((c) => c['rarity'] == r).length,
      },
      scratchedToday: _m.scratchToday,
    );
  }
}
