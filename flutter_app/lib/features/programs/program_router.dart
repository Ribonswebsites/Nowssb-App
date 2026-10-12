/// One destination per programme. Every entry point (home, drawer, rails,
/// shelves, banners, profile) opens the same single page for a programme,
/// optionally at one of its tabs.
library;

import 'package:flutter/material.dart';

import '../economy/partner_screen.dart';
import '../earn/earnings_screen.dart';
import '../earn/nowssb_one.dart';
import '../coins/free_coins_page.dart';

enum Programme { earn, rewards, coupons, gifts, reference, partner, earnings, freeCoins }

abstract final class Programmes {
  static Widget page(Programme p, {String? tab}) => switch (p) {
        Programme.earn => NowssbOnePage(focus: tab ?? 'ranks'),
        Programme.rewards => const NowssbOnePage(focus: 'ranks'),
        Programme.coupons => const NowssbOnePage(focus: 'coupons'),
        Programme.gifts => const NowssbOnePage(focus: 'gifts'),
        Programme.reference => const NowssbOnePage(focus: 'links'),
        Programme.partner => PartnerScreen(initialTab: tab),
        Programme.earnings => const EarningsScreen(),
        Programme.freeCoins => const FreeCoinsPage(),
      };

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
        'free coins' => Programme.freeCoins,
        _ => null,
      };
}
