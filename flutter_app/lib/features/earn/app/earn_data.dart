// Earn data from the server's `earnSummary` (functions/_lib/economy/earn.js).
// Nothing is guessed: missing fields stay empty.
import '../../economy/economy_api.dart';

enum EarnLoad { loading, ready, error, offline, signedOut }

class EarnTarget {
  const EarnTarget(this.words, this.reached, this.title, {this.coins = 0, this.coupon = '', this.cash = 0});
  final int words;
  final bool reached;
  final String title;
  final int coins;
  final String coupon;

  /// Bonus money in [EarnData.currency] units (0 = none / unknown).
  final num cash;
}

class EarnRank {
  const EarnRank(this.title, this.metal, this.minWords, this.ratePct);
  final String title, metal;
  final int minWords, ratePct;
}

class EarnMember {
  const EarnMember({required this.id, required this.name, this.rank = '', this.words = 0, this.level = 1});
  final String id, name, rank;
  final int words, level;
}

class EarnInvite {
  const EarnInvite(this.id, this.rank, this.from);
  final String id, rank, from;
}

class EarnData {
  const EarnData({
    this.load = EarnLoad.loading,
    this.message = '',
    this.enabled = true,
    this.rank = '',
    this.metal = '',
    this.ratePct = 0,
    this.words = 0,
    this.targets = const [],
    this.team = const [],
    this.invites = const [],
    this.payoutCountry = '',
    this.ranks = const [],
    this.currency = '',
    this.earned = 0,
    this.pending = 0,
    this.available = 0,
  });
  final List<EarnRank> ranks;
  final String currency;
  final num earned, pending, available;

  /// The next rank above the current one, from the server's ladder.
  EarnRank? get nextRank {
    for (final r in ranks) {
      if (r.minWords > words) return r;
    }
    return null;
  }
  final EarnLoad load;
  final String message;
  final bool enabled;
  final String rank, metal;
  final int ratePct, words;
  final List<EarnTarget> targets;
  final List<EarnMember> team;
  final List<EarnInvite> invites;
  final String payoutCountry;

  factory EarnData.fromSummary(Map<String, dynamic> s) {
    final st = s['standing'] is Map ? s['standing'] as Map : const {};
    final words = (s['words'] as num?)?.toInt() ?? 0;
    List<Map> list(String k) => (s[k] is List ? s[k] as List : const []).whereType<Map>().toList();
    final targets = list('targets')
        .map((t) => EarnTarget((t['words'] as num?)?.toInt() ?? 0, t['reached'] == true || words >= ((t['words'] as num?) ?? 1 << 30), '${t['title'] ?? ''}',
            coins: (t['coins'] as num?)?.toInt() ?? 0, coupon: '${t['coupon'] ?? ''}', cash: (t['cash'] ?? t['cashINR'] ?? 0) as num))
        .where((t) => t.words > 0)
        .toList()
      ..sort((a, b) => a.words.compareTo(b.words));
    final bal = s['balances'] is Map ? s['balances'] as Map : const {};
    // The server still names INR fields; [currency] says what unit they are.
    final currency = '${bal['currency'] ?? (bal.containsKey('lifetimeINR') ? 'INR' : '')}';
    final ranks = list('ranks')
        .map((r) => EarnRank('${r['title'] ?? ''}', '${r['metal'] ?? ''}', (r['minWords'] as num?)?.toInt() ?? 0, (r['ratePct'] as num?)?.round() ?? 0))
        .toList()
      ..sort((a, b) => a.minWords.compareTo(b.minWords));
    final pa = s['payoutAccount'] is Map ? s['payoutAccount'] as Map : const {};
    return EarnData(
      load: EarnLoad.ready,
      enabled: s['enabled'] != false,
      rank: '${st['title'] ?? ''}',
      metal: '${st['metal'] ?? ''}',
      ratePct: (st['ratePct'] as num?)?.round() ?? 0,
      words: words,
      targets: targets,
      team: [
        for (final m in list('team'))
          EarnMember(
            id: '${m['uid'] ?? ''}',
            name: '${m['name'] ?? 'Team member'}',
            rank: '${m['rank'] ?? ''}',
            words: (m['words'] as num?)?.toInt() ?? 0,
            level: ((m['level'] as num?)?.toInt() ?? 1).clamp(1, 2),
          ),
      ],
      invites: [for (final i in list('invites')) EarnInvite('${i['id'] ?? ''}', '${i['rank'] ?? ''}', '${i['fromName'] ?? 'A NowssB officer'}')],
      payoutCountry: '${pa['country'] ?? ''}',
      ranks: ranks,
      currency: currency,
      earned: (bal['lifetime'] ?? bal['lifetimeINR'] ?? 0) as num,
      pending: (bal['pending'] ?? bal['pendingINR'] ?? 0) as num,
      available: (bal['available'] ?? bal['availableINR'] ?? 0) as num,
    );
  }

  factory EarnData.fromError(EconomyException e) => switch (e.code) {
        'unauthenticated' => const EarnData(load: EarnLoad.signedOut),
        'offline' || 'timeout' => const EarnData(load: EarnLoad.offline),
        _ => EarnData(load: EarnLoad.error, message: e.message),
      };

  /// Next unreached target, or null when all are reached.
  EarnTarget? get next {
    for (final t in targets) {
      if (!t.reached) return t;
    }
    return null;
  }

  double get progress {
    final n = next;
    if (n == null) return targets.isEmpty ? 0 : 1;
    var prev = 0;
    for (final t in targets) {
      if (t.reached) prev = t.words;
    }
    return ((words - prev) / (n.words - prev)).clamp(0.0, 1.0);
  }

  List<EarnMember> get direct => team.where((m) => m.level == 1).toList();
  List<EarnMember> get second => team.where((m) => m.level == 2).toList();
}

/// Loads Earn. Tests swap [earnLoader].
Future<EarnData> Function() earnLoader = () async {
  try {
    return EarnData.fromSummary(await EconomyApi.call('earnSummary'));
  } on EconomyException catch (e) {
    return EarnData.fromError(e);
  } catch (_) {
    return const EarnData(load: EarnLoad.error, message: 'Something went wrong. Try again.');
  }
};
