/// View model for the new Earn hub (spec 14, 15 "Earn", 19.1), built from the
/// shared kit's `EarnRepository.summary()` (server `earnSummary`).
import '../../../kit/data_layer.dart';

enum EarnLoad { loading, ready, empty, error, offline }

/// Fallback word targets from the spec, used only if the server sends none.
const kEarnWordTargets = <int>[100, 500, 1000, 2000];

/// Medal metals in ladder order (spec: Bronze, Silver, Gold, Diamond).
const kEarnMetals = <String>['Bronze', 'Silver', 'Gold', 'Diamond'];

/// One person in the user's team, as the server reports it (max 2 levels).
class EarnTeamMember {
  const EarnTeamMember({required this.id, required this.name, this.rank = '', this.words = 0, this.level = 1});
  final String id;
  final String name;
  final String rank;
  final int words;
  final int level;

  static EarnTeamMember fromJson(Map m) => EarnTeamMember(
        id: '${m['uid'] ?? ''}',
        name: '${m['name'] ?? 'Team member'}',
        rank: '${m['rank'] ?? ''}',
        words: (m['words'] as num?)?.toInt() ?? 0,
        level: ((m['level'] as num?)?.toInt() ?? 1).clamp(1, 2),
      );
}

class EarnViewData {
  const EarnViewData({
    this.load = EarnLoad.loading,
    this.signedIn = false,
    this.rank = '',
    this.metal = '',
    this.ratePct = 0,
    this.wordsSold = 0,
    this.targets = kEarnWordTargets,
    this.team = const [],
    this.code = '',
    this.errorMessage = '',
  });

  final EarnLoad load;
  final bool signedIn;
  final String rank;
  final String metal;
  final int ratePct;
  final int wordsSold;
  final List<int> targets;
  final List<EarnTeamMember> team;
  final String code;
  final String errorMessage;

  int get teamSize => team.length;

  /// Maps the server's `earnSummary` reply. Missing fields stay empty/zero:
  /// nothing is guessed or inflated.
  factory EarnViewData.fromSummary(Json s, {String code = ''}) {
    final st = s['standing'] is Map ? s['standing'] as Map : const {};
    final ts = (s['targets'] is List ? s['targets'] as List : const [])
        .whereType<Map>()
        .map((t) => (t['words'] as num?)?.toInt())
        .whereType<int>()
        .toList()
      ..sort();
    final team = (s['team'] is List ? s['team'] as List : const []).whereType<Map>().map(EarnTeamMember.fromJson).toList();
    final data = EarnViewData(
      load: EarnLoad.ready,
      signedIn: true,
      rank: '${st['title'] ?? ''}',
      metal: '${st['metal'] ?? ''}',
      ratePct: (st['ratePct'] as num?)?.round() ?? 0,
      wordsSold: (s['words'] as num?)?.toInt() ?? 0,
      targets: ts.isEmpty ? kEarnWordTargets : ts,
      team: team,
      code: code,
    );
    return data.isFresh ? data.copyWith(load: EarnLoad.empty) : data;
  }

  /// Turns a kit error into the right page state.
  factory EarnViewData.fromError(KitErr<Json> e) {
    if (e.signedOut) return const EarnViewData(load: EarnLoad.empty);
    if (e.code == 'offline' || e.code == 'timeout') return const EarnViewData(load: EarnLoad.offline, signedIn: true);
    return EarnViewData(load: EarnLoad.error, signedIn: true, errorMessage: e.message);
  }

  EarnViewData copyWith({EarnLoad? load}) => EarnViewData(
        load: load ?? this.load,
        signedIn: signedIn,
        rank: rank,
        metal: metal,
        ratePct: ratePct,
        wordsSold: wordsSold,
        targets: targets,
        team: team,
        code: code,
        errorMessage: errorMessage,
      );

  int? get nextTarget {
    for (final t in targets) {
      if (wordsSold < t) return t;
    }
    return null;
  }

  int get previousTarget {
    var p = 0;
    for (final t in targets) {
      if (wordsSold >= t) p = t;
    }
    return p;
  }

  double get targetProgress {
    final n = nextTarget;
    if (n == null) return 1;
    final p = previousTarget;
    return ((wordsSold - p) / (n - p)).clamp(0.0, 1.0);
  }

  int get wordsToNext => (nextTarget ?? wordsSold) - wordsSold;

  /// Medal tone: the server's metal, else Bronze.
  int get rankIndex {
    final i = kEarnMetals.indexWhere((m) => m.toLowerCase() == metal.toLowerCase());
    return i < 0 ? 0 : i;
  }

  bool get isFresh => wordsSold == 0 && team.isEmpty;
}
