/// One destination per programme. Every entry point (home, drawer, rails,
/// shelves, banners, profile) opens the same single page for a programme,
/// optionally at one of its tabs.
library;

import 'package:flutter/material.dart';

import '../economy/partner_screen.dart';
import '../circle/circle_screen.dart';
import '../earn/earnings_screen.dart';
import '../vault/vault_screen.dart';

enum Programme { earn, rewards, reference, partner, earnings }


abstract final class Programmes {
  static Widget page(Programme p, {String? tab}) {
    return switch (p) {
        Programme.earn => CircleScreen(initialTab: tab),
        Programme.rewards => VaultScreen(initialTab: tab),
        // Invite link lives in Earn now (one page, its 'invite' tab).
        Programme.reference => CircleScreen(initialTab: tab ?? 'invite'),
        Programme.partner => PartnerScreen(initialTab: tab),
        Programme.earnings => const EarningsScreen(),
      };
  }

  static Future<void> open(BuildContext context, Programme p, {String? tab}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page(p, tab: tab)));

  /// Programme for a shelf poster title ("Earn", "Rewards", "Gift" …).
  static Programme? forPoster(String title) => switch (title.toLowerCase()) {
        'earn' => Programme.earn,
        'rewards' => Programme.rewards,
        'bonus' => Programme.earn,
        'partner' => Programme.partner,
        'reference' => Programme.reference,
        _ => null,
      };
}
