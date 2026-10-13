/// Page-local view model for the new Earn hub (spec 14, 15 "Earn", 19.1).
/// Swap to Bug Hunter's shared EarnRepository (Part D 20) when it lands.
enum EarnLoad { loading, ready, empty, error, offline }

/// Word targets named in the spec (100 / 500 / 1000 / 2000 words).
const kEarnWordTargets = <int>[100, 500, 1000, 2000];

/// Rank ladder named in the spec. Rank itself always comes from the server.
const kEarnRanks = <String>['Assistant Officer', 'Officer', 'Executive Officer', 'Partner'];

class EarnViewData {
  const EarnViewData({
    this.load = EarnLoad.loading,
    this.signedIn = false,
    this.rank = '',
    this.ratePct = 0,
    this.wordsSold = 0,
    this.teamSize = 0,
    this.cashCents = 0,
    this.code = '',
    this.errorMessage = '',
  });

  final EarnLoad load;
  final bool signedIn;
  final String rank;
  final int ratePct;
  final int wordsSold;
  final int teamSize;
  final int cashCents;
  final String code;
  final String errorMessage;

  /// Next spec target above [wordsSold]; null once all are done.
  int? get nextTarget {
    for (final t in kEarnWordTargets) {
      if (wordsSold < t) return t;
    }
    return null;
  }

  int get previousTarget {
    var p = 0;
    for (final t in kEarnWordTargets) {
      if (wordsSold >= t) p = t;
    }
    return p;
  }

  /// 0..1 progress from the last reached target to the next one.
  double get targetProgress {
    final n = nextTarget;
    if (n == null) return 1;
    final p = previousTarget;
    return ((wordsSold - p) / (n - p)).clamp(0.0, 1.0);
  }

  int get wordsToNext => (nextTarget ?? wordsSold) - wordsSold;

  /// Medal tone by position in the rank ladder (Bronze, Silver, Gold, Diamond).
  int get rankIndex {
    final i = kEarnRanks.indexWhere((r) => r.toLowerCase() == rank.toLowerCase());
    return i < 0 ? 0 : i;
  }

  /// A signed-in agent with nothing sold, no team and no cash yet.
  bool get isFresh => wordsSold == 0 && teamSize == 0 && cashCents == 0;
}
