/// One destination per programme. Every entry point (home, drawer, rails,
/// shelves, banners, profile) opens the same single page for a programme,
/// optionally at one of its tabs.
library;

import 'package:flutter/material.dart';

import '../economy/partner_screen.dart';
import '../economy/reference_screen.dart';
import 'program_hub.dart';

enum Programme { earn, rewards, coupons, gifts, reference, partner, earnings }

typedef ProgrammeBuilder = Widget Function(String? tab);

abstract final class Programmes {
  static final Map<Programme, ProgrammeBuilder> _bound = {};

  /// Real pages register here so this file does not import them (they already
  /// import this router).
  static void bind(Programme p, ProgrammeBuilder builder) => _bound[p] = builder;

  static Widget page(Programme p, {String? tab}) {
    final built = _bound[p];
    if (built != null) return built(tab);
    return switch (p) {
        Programme.earn => const ProgramHub(title: 'NowssB Earn', subs: ['Ranks', 'Team', 'Payouts']),
        Programme.rewards => const ProgramHub(title: 'NowssB Rewards', subs: ['Wallet', 'Streaks', 'Quests']),
        Programme.coupons => const ProgramHub(title: 'NowssB Coupons', subs: ['Scratch', 'My coupons', 'Shop']),
        Programme.gifts => const ProgramHub(title: 'NowssB Gifts', subs: ['Send', 'Redeem', 'History']),
        Programme.reference => ReferenceScreen(initialTab: tab),
        Programme.partner => PartnerScreen(initialTab: tab),
        Programme.earnings => const ProgramHub(title: 'Earnings', subs: ['Sales', 'Referrals', 'Payouts']),
      };
  }

  static Future<void> open(BuildContext context, Programme p, {String? tab}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page(p, tab: tab)));

  /// Programme for a shelf poster title ("Earn", "Rewards", "Gift" …).
  static Programme? forPoster(String title) => switch (title.toLowerCase()) {
        'earn' => Programme.earn,
        'rewards' => Programme.rewards,
        'gift' || 'gifts' => Programme.gifts,
        'bonus' => Programme.earn,
        'partner' => Programme.partner,
        'coupons' => Programme.coupons,
        'reference' => Programme.reference,
        _ => null,
      };
}
