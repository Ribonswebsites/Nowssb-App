/// Data for the rebuilt Partner hub (spec Part C, "Partner Program").
/// Page-local until Bug Hunter's shared data layer ships `PartnerRepository`.
library;

import '../../features/economy/economy_api.dart';

class PartnerTarget {
  const PartnerTarget({required this.label, required this.goal, required this.done, required this.reward});
  final String label;
  final int goal;
  final int done;
  final String reward;
  double get progress => goal == 0 ? 0 : (done / goal).clamp(0, 1).toDouble();
}

class PartnerLeader {
  const PartnerLeader(this.name, this.points);
  final String name;
  final int points;
}

class PartnerData {
  const PartnerData({
    required this.points,
    required this.perk,
    required this.tier,
    required this.toNextTier,
    required this.targets,
    required this.leaders,
    required this.referralLink,
    required this.buyerDiscountUsdCents,
  });
  final int points;
  final String perk;
  final String tier;
  final int toNextTier;
  final List<PartnerTarget> targets;
  final List<PartnerLeader> leaders;
  final String referralLink;

  /// Discount shown to buyers, stored in USD cents and shown in local currency.
  final int buyerDiscountUsdCents;

  bool get isEmpty => points == 0 && targets.every((t) => t.done == 0);
}

class PartnerOfflineException implements Exception {
  const PartnerOfflineException();
}

abstract class PartnerRepository {
  Future<PartnerData> load();
}

/// Reads the live mirror the old page uses. Targets follow the spec
/// (50 basic / 30 higher / 15 top subscriptions); progress per target
/// comes from the server partnerLedger once Bug Hunter's data layer exposes it.
class MirrorPartnerRepository implements PartnerRepository {
  const MirrorPartnerRepository();

  @override
  Future<PartnerData> load() async {
    final m = EconomyMirror.instance;
    return PartnerData(
      points: m.partnerPoints,
      perk: m.partnerPerk,
      tier: m.partnerPerk.isEmpty ? 'Starter' : m.partnerPerk,
      toNextTier: 0,
      targets: const [
        PartnerTarget(label: 'Basic subscriptions', goal: 50, done: 0, reward: 'Coins + coupon pack'),
        PartnerTarget(label: 'Higher subscriptions', goal: 30, done: 0, reward: 'Gift + early access'),
        PartnerTarget(label: 'Top subscriptions', goal: 15, done: 0, reward: 'Partner mark'),
      ],
      leaders: const [],
      referralLink: '',
      buyerDiscountUsdCents: 0,
    );
  }
}
