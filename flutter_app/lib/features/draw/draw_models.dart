/// Daily lucky draw: data shapes. Every value comes from the server.
/// The client never decides odds, outcomes, winners or counts.
library;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
int? _int(Object? v) => v is num ? v.toInt() : null;
String _str(Object? v) => v is String ? v : '';

/// One prize in today's pool (a gift or a coupon). No cash value.
class DrawPrize {
  const DrawPrize({required this.id, required this.kind, required this.title, this.detail = ''});
  final String id;

  /// 'gift' or 'coupon'.
  final String kind;
  final String title;
  final String detail;

  factory DrawPrize.fromJson(Map<String, dynamic> j) => DrawPrize(
    id: _str(j['id']),
    kind: _str(j['kind']) == 'coupon' ? 'coupon' : 'gift',
    title: _str(j['title']),
    detail: _str(j['detail']),
  );
}

/// GET draw status. `entered`/`result` are for the signed-in user only.
class DrawStatus {
  const DrawStatus({
    required this.drawId,
    required this.oddsText,
    this.oddsNumerator,
    this.oddsDenominator,
    this.closesAt,
    this.resultsAt,
    this.entered = false,
    this.result,
    this.prizes = const [],
    this.rulesText = '',
    this.open = true,
  });
  final String drawId;

  /// Server-written, e.g. "About 1 in 150 entries wins". Shown as-is.
  final String oddsText;
  final int? oddsNumerator;
  final int? oddsDenominator;
  final DateTime? closesAt;
  final DateTime? resultsAt;
  final bool entered;
  final bool open;

  /// Null until the server has drawn and the user entered.
  final DrawResult? result;
  final List<DrawPrize> prizes;

  /// Optional server rules copy; the app has a fixed short sheet as well.
  final String rulesText;

  factory DrawStatus.fromJson(Map<String, dynamic> j) {
    final odds = j['odds'] is Map ? Map<String, dynamic>.from(j['odds'] as Map) : const <String, dynamic>{};
    final res = j['result'];
    return DrawStatus(
      drawId: _str(j['drawId']),
      oddsText: _str(odds['text']),
      oddsNumerator: _int(odds['numerator']),
      oddsDenominator: _int(odds['denominator']),
      closesAt: _date(j['closesAt']),
      resultsAt: _date(j['resultsAt']),
      entered: j['entered'] == true,
      open: j['open'] != false,
      result: res is Map ? DrawResult.fromJson(Map<String, dynamic>.from(res)) : null,
      prizes: [
        for (final p in (j['prizes'] as List? ?? const []))
          if (p is Map) DrawPrize.fromJson(Map<String, dynamic>.from(p)),
      ],
      rulesText: _str(j['rulesText']),
    );
  }

  /// Plain odds line. Empty when the server sent none (then it is hidden).
  String get oddsLine {
    if (oddsText.isNotEmpty) return oddsText;
    final n = oddsNumerator, d = oddsDenominator;
    if (n != null && d != null && n > 0 && d > 0) return 'Odds: $n in $d entries win';
    return '';
  }
}

class DrawResult {
  const DrawResult({required this.won, this.prize, this.claimId = ''});
  final bool won;
  final DrawPrize? prize;

  /// Where the prize lives once won (coupon wallet / gifts).
  final String claimId;

  factory DrawResult.fromJson(Map<String, dynamic> j) => DrawResult(
    won: j['won'] == true,
    prize: j['prize'] is Map ? DrawPrize.fromJson(Map<String, dynamic>.from(j['prize'] as Map)) : null,
    claimId: _str(j['claimId']),
  );
}

/// One real winner, as published by the server (first name + initial only).
class DrawWinner {
  const DrawWinner({required this.id, required this.displayName, required this.prizeTitle, this.wonAt, this.review});
  final String id;
  final String displayName;
  final String prizeTitle;
  final DateTime? wonAt;
  final WinnerReview? review;

  factory DrawWinner.fromJson(Map<String, dynamic> j) => DrawWinner(
    id: _str(j['id']),
    displayName: _str(j['displayName']),
    prizeTitle: _str(j['prizeTitle']),
    wonAt: _date(j['wonAt']),
    review: j['review'] is Map ? WinnerReview.fromJson(Map<String, dynamic>.from(j['review'] as Map)) : null,
  );
}

/// A review written by the winner themself, after moderation.
class WinnerReview {
  const WinnerReview({required this.text, this.stars});
  final String text;
  final int? stars;
  factory WinnerReview.fromJson(Map<String, dynamic> j) => WinnerReview(text: _str(j['text']), stars: _int(j['stars']));
}

class WinnersPage {
  const WinnersPage({this.winners = const [], this.nextCursor});
  final List<DrawWinner> winners;
  final String? nextCursor;
  factory WinnersPage.fromJson(Map<String, dynamic> j) => WinnersPage(
    winners: [
      for (final w in (j['winners'] as List? ?? const []))
        if (w is Map) DrawWinner.fromJson(Map<String, dynamic>.from(w)),
    ],
    nextCursor: j['nextCursor'] is String ? j['nextCursor'] as String : null,
  );
}
