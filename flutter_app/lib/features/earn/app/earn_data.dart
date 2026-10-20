// Earn data from the server's `earnSummary` (functions/_lib/economy/earn.js).
// Nothing is guessed: missing fields stay empty.
import '../../economy/economy_api.dart';

enum EarnLoad { loading, ready, error, offline, signedOut }

class EarnTarget {
  const EarnTarget(this.words, this.reached, this.title);
  final int words;
  final bool reached;
  final String title;
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
  });
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
        .map((t) => EarnTarget((t['words'] as num?)?.toInt() ?? 0, t['reached'] == true || words >= ((t['words'] as num?) ?? 1 << 30), '${t['title'] ?? ''}'))
        .where((t) => t.words > 0)
        .toList()
      ..sort((a, b) => a.words.compareTo(b.words));
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
