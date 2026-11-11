/// "NowssB Earn": the Programmes row, the NowssB Store section again.
///
/// It IS the Store's own [StoreNowCarousel]: the same glass wrapper, the
/// same black pill title with the gold tag at the right, the same black
/// rounded [StoreNowCard]s (square picture, small caps eyebrow, big title,
/// grey line, round white button) at the same height, the next card peeking
/// in from the right. Only the words, pictures and pages are its own.
///
/// It moves every 5 s over 600 ms (easeInOutCubic), holds while a finger is
/// on it and carries on 5 s after the finger lifts.
library;

import 'package:flutter/material.dart';

import '../features/coins/coins_screen.dart';
import '../features/programs/program_router.dart';
import '../screens/fashion/home_cards.dart';
import '../screens/subscription.dart';

/// Where "Coins" opens, shared with the cards below.
void openCoinsPage(BuildContext c) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const CoinsScreen()));

void _openPlans(BuildContext c) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));

/// Dark, quiet, people-free meditation stills (assets/rails/subj-*), none of
/// them used anywhere else on the home.
const kEarnNowArt = <String>[
  'assets/rails/subj-dawn.jpg',
  'assets/rails/subj-harmony.jpg',
  'assets/rails/subj-moon.jpg',
  'assets/rails/subj-grace.jpg',
];

class EarnNowSection extends StatelessWidget {
  const EarnNowSection({super.key, this.onOpen});

  /// Tests: called with the card's id instead of opening its page.
  final void Function(String id)? onOpen;

  static const every = Duration(seconds: 5);
  static const glide = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    void go(String id, void Function(BuildContext) open) => onOpen != null ? onOpen!(id) : open(context);
    return StoreNowCarousel(
      title: 'NowssB Earn',
      kicker: 'Earn · Collect today',
      every: every,
      glide: glide,
      curve: Curves.easeInOutCubic,
      items: [
        StoreNowItem(
          word: 'Earn',
          category: '',
          price: '',
          eyebrow: 'EARN COINS',
          line: 'Daily coins',
          icon: Icons.stars_rounded,
          art: kEarnNowArt[0],
          onTap: () => go('earn', (c) => Programmes.open(c, Programme.earn)),
        ),
        StoreNowItem(
          word: 'Reference',
          category: '',
          price: '',
          eyebrow: 'YOUR LINKS',
          line: 'Invite and share',
          icon: Icons.link_rounded,
          art: kEarnNowArt[1],
          onTap: () => go('reference', (c) => Programmes.open(c, Programme.reference)),
        ),
        StoreNowItem(
          word: 'Coins',
          category: '',
          price: '',
          eyebrow: 'EARNED TODAY',
          line: 'Your wallet',
          icon: Icons.account_balance_wallet_rounded,
          art: kEarnNowArt[2],
          onTap: () => go('coins', openCoinsPage),
        ),
        StoreNowItem(
          word: 'Zen Plus',
          category: '',
          price: '',
          eyebrow: 'MEMBERSHIP',
          line: 'The full library',
          icon: Icons.workspace_premium_rounded,
          art: kEarnNowArt[3],
          onTap: () => go('plus', _openPlans),
        ),
      ],
    );
  }
}
