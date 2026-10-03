/// Three different banner types, never the same one twice in a row.
///
/// Black glass, the split colour promo, and the older black bar. [seed]
/// rotates which one leads so two pages, or two spots on one page, do not
/// open on the same shape.
library;

import 'package:flutter/material.dart';

import 'black_glass_banner.dart';
import 'colored_split_promo_banner.dart';
import 'home_parts.dart';
import 'nwsb_icon.dart';
import '../features/programs/program_router.dart';
import '../shell/nwsb_links.dart';

class BannerMix extends StatelessWidget {
  const BannerMix({
    super.key,
    required this.seed,
    this.onTap,
  });

  final int seed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Each banner opens what it names unless the page passes its own tap.
    final i = seed.abs() % 4;
    final black = BlackGlassBanner(
      title: _blackTitle,
      subtitle: _blackSub,
      mark: NwsbMarks.bell,
      margin: EdgeInsets.zero,
      onTap: onTap ??
          () => switch (i) {
                0 => NwsbLinks.subscription(context),
                1 => NwsbLinks.tab(context, 2),
                2 => Programmes.open(context, Programme.rewards, tab: 'streaks'),
                _ => NwsbLinks.tab(context, 1),
              },
    );
    final split = ColoredSplitPromoBanner(
      spec: SplitPromoExtras.at(seed + 3, onTap: onTap),
      margin: EdgeInsets.zero,
    );
    final bar = SecBanner(
      title: _barTitle,
      sub: _barSub,
      mark: NwsbMarks.gift,
      onTap: onTap ??
          () => switch (i) {
                0 => NwsbLinks.tab(context, 3),
                1 => Programmes.open(context, Programme.rewards),
                2 => Programmes.open(context, Programme.gifts, tab: 'send'),
                _ => NwsbLinks.tasks(context),
              },
    );
    final order = <Widget>[black, split, bar];
    final start = seed.abs() % order.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < order.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          order[(start + i) % order.length],
        ],
      ],
    );
  }

  String get _blackTitle {
    const titles = [
      'Today’s offer',
      'Open the library',
      'Keep the streak',
      'A word for tonight',
    ];
    return titles[seed.abs() % titles.length];
  }

  String get _blackSub {
    const subs = [
      'The plans, at today’s Google Play price.',
      'Saved words, meanings, and the ones you own.',
      'One sitting today keeps it.',
      'Sit with it. The recording is the whole practice.',
    ];
    return subs[seed.abs() % subs.length];
  }

  String get _barTitle {
    const titles = [
      'Enter the store',
      'Rewards are waiting',
      'Send a gift',
      'Your practice',
    ];
    return titles[seed.abs() % titles.length];
  }

  String get _barSub {
    const subs = [
      'Words, meanings, and the plans.',
      'Coins from practice. Not for sale.',
      'A real purchase, sent as a code.',
      'The tasks you set for this account.',
    ];
    return subs[seed.abs() % subs.length];
  }
}
