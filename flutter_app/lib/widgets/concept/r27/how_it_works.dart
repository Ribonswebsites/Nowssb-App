/// B035 — one-time "how it works" pop-ups for the R27 pages (Rewards, Gifts,
/// Earn, Coupons) plus Lucky draw and Plus. Reuses [StoreFirstUseGuide]:
/// shown once per page (persisted `guide_seen_<key>`), "?" reopens it.
/// Copy describes only what the code does.
library;

import 'package:flutter/material.dart';

import '../../../screens/store/store_first_use_guide.dart';

const r27RewardsGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.toll_rounded, 'How rewards work',
      'Sign in, then claim your coins once a day. Claiming on consecutive days builds your streak.'),
  StoreGuideStep(Icons.calendar_view_week_rounded, 'This week',
      'Each day of your streak lights one of seven tiles.'),
  StoreGuideStep(Icons.inventory_2_rounded, 'The chest',
      'Every 40 coins fills a chest. Open the vault to see your coins and rewards.'),
];

const r27GiftsGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.card_giftcard_rounded, 'How gifts work',
      'Pick a gift card to send. You pay in your own currency at checkout.'),
  StoreGuideStep(Icons.confirmation_number_rounded, 'Have a code?',
      'Redeem a gift code someone sent you from this page.'),
  StoreGuideStep(Icons.history_rounded, 'Your gifts',
      'See how many gifts you have sent and received, and open the full history.'),
];

const r27EarnGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.trending_up_rounded, 'How Earn works',
      'You earn a commission on net sales from people you invite, across two levels. It is paid from net, after tax and the Play fee.'),
  StoreGuideStep(Icons.stairs_rounded, 'Ranks',
      'The more words sold, the higher your rank and the higher your commission rate.'),
  StoreGuideStep(Icons.person_add_alt_1_rounded, 'Invite',
      'Share your invite code with friends from this page.'),
];

const r27CouponsGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.style_rounded, 'How coupons work',
      'A scratch card is ready each day. Scratch it to reveal what is inside.'),
  StoreGuideStep(Icons.auto_awesome_rounded, 'Sealed cards',
      'Sealed cards are grouped by rarity. Tap one to scratch it.'),
  StoreGuideStep(Icons.percent_rounded, 'Discounts',
      'Discounts take a percentage off, up to a cap, and you use them at checkout. See Rules and odds for details.'),
];

const r27DrawGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.casino_rounded, 'How the lucky draw works',
      'Free to enter, one entry per person per day. No purchase and no coins are needed.'),
  StoreGuideStep(Icons.emoji_events_rounded, 'Winners',
      'Winners are picked at random by the server. Prizes are gifts or coupons with no cash value.'),
  StoreGuideStep(Icons.gavel_rounded, 'Rules',
      'The full official rules and the odds are on this page.'),
];

const r27PlusGuide = <StoreGuideStep>[
  StoreGuideStep(Icons.motion_photos_on_rounded, 'How Plus works',
      'Off, page backgrounds show a still picture. On, those same backgrounds play.'),
  StoreGuideStep(Icons.wallpaper_rounded, 'Backgrounds',
      'Choose the background film and the start art from this page.'),
  StoreGuideStep(Icons.battery_charging_full_rounded, 'Battery',
      'It is off by default because moving pictures cost battery. At most four clips play at once.'),
];

/// Wraps [child] in the one-time guide for [key]. The transparent Material
/// gives the card its theme text style (the pages are bare routes).
Widget r27Guide(String key, List<StoreGuideStep> steps, Widget child) => Material(
    type: MaterialType.transparency,
    child: StoreFirstUseGuide(guideKey: key, steps: steps, showIcons: false, child: child));

/// Reopens the nearest guide (for in-page "How … works" links).
void r27OpenGuide(BuildContext c) => c.findAncestorStateOfType<StoreFirstUseGuideState>()?.open();
