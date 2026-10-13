/// Rewards (new UI) view model. Page-local until the shared data layer
/// (RewardsRepository, owned by NowssB Bug Hunter) lands; then swap
/// [RewardsLoader] for the repository stream. Every number is the server's.
library;

import 'dart:async';
import 'dart:io';

import '../economy/economy_api.dart';

enum RewardKind { coupon, gift, chest }

class RewardItem {
  const RewardItem({required this.id, required this.title, required this.kind, this.caption = '', this.validTill, this.expired = false});
  final String id;
  final String title;
  final RewardKind kind;
  final String caption;
  final DateTime? validTill;
  final bool expired;
}

class RewardsData {
  const RewardsData({
    required this.coins,
    required this.streak,
    required this.checkedInToday,
    required this.questsOpen,
    required this.chestsReady,
    required this.items,
    this.dealTitle,
    this.dealEndsAt,
  });
  final int coins;
  final int streak;
  final bool checkedInToday;
  final int questsOpen;
  final int chestsReady;
  final List<RewardItem> items;
  final String? dealTitle;
  final DateTime? dealEndsAt;

  bool get isEmpty => items.isEmpty && coins == 0 && streak == 0 && questsOpen == 0 && chestsReady == 0;

  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static Map<String, dynamic> _m(Object? v) => v is Map ? v.map((k, v) => MapEntry('$k', v)) : const {};
  static List<Object?> _l(Object? v) => v is List ? v : const [];
  static DateTime? _t(Object? v) => v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : (v is String ? DateTime.tryParse(v) : null);

  /// Maps the economy `summary` into the hub's view model.
  factory RewardsData.fromSummary(Map<String, dynamic> s, {int? coins, DateTime? now}) {
    final clock = now ?? DateTime.now();
    final w = _m(s['wallet']);
    final t = _m(s['today']);
    final q = _m(s['quests']);
    final quests = [..._l(q['weekly']), ..._l(q['starter'])].map(_m).where((e) => e['claimed'] != true).length;
    final items = <RewardItem>[];
    for (final raw in _l(s['myRewards'])) {
      final r = _m(raw);
      final till = _t(r['validTill']);
      items.add(RewardItem(
        id: '${r['id'] ?? items.length}',
        title: '${r['title'] ?? 'Reward'}',
        caption: '${r['caption'] ?? ''}',
        kind: switch ('${r['kind']}') { 'gift' => RewardKind.gift, 'chest' => RewardKind.chest, _ => RewardKind.coupon },
        validTill: till,
        expired: r['expired'] == true || (till != null && till.isBefore(clock)),
      ));
    }
    final deal = _m(s['deal']);
    return RewardsData(
      coins: coins ?? _i(w['coins']),
      streak: _i(_m(s['streaks'])['current'] ?? w['streak']),
      checkedInToday: t['login'] == true,
      questsOpen: quests,
      chestsReady: _i(_m(s['chests'])['ready']),
      items: items,
      dealTitle: deal['title'] as String?,
      dealEndsAt: _t(deal['endsAt']),
    );
  }
}

/// Offline is its own state so the page can say so plainly.
class RewardsOffline implements Exception {
  const RewardsOffline();
}

typedef RewardsLoader = Future<RewardsData> Function();

Future<RewardsData> loadRewardsFromServer() async {
  try {
    final s = await EconomyApi.summary();
    return RewardsData.fromSummary(s, coins: EconomyMirror.instance.coins);
  } on SocketException {
    throw const RewardsOffline();
  } on TimeoutException {
    throw const RewardsOffline();
  }
}
