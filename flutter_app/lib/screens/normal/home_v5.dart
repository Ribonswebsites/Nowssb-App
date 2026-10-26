/// NORMAL HOME v5 — the sections below the ritual card, wired to real data.
///
/// Each widget here only reads live stores and passes the values into the
/// v5 section widgets (lib/widgets/concept/normal). Nothing is invented: a
/// value that has no real source is left out of the section.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/billing_config.dart';
import '../../data/cart_bag.dart';
import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/models.dart';
import '../../data/play_subscriptions.dart';
import '../../features/economy/economy_api.dart';
import '../../widgets/concept/normal/edition.dart';
import '../../widgets/concept/normal/invite.dart';
import '../../widgets/concept/normal/own.dart';
import '../../widgets/concept/normal/partner.dart';
import '../../widgets/concept/normal/rewards.dart';
import '../../widgets/concept/normal/trending.dart';

Map<String, dynamic> _map(Object? o) => o is Map ? Map<String, dynamic>.from(o) : const {};
int? _int(Object? o) => o is num ? o.toInt() : int.tryParse('${o ?? ''}');

/// Rewards + Invite, from EconomyMirror (coins, streak, referral code and
/// the server's `config.reference.friendDiscount`).
class V5RewardsInvite extends StatelessWidget {
  const V5RewardsInvite({super.key, required this.onOpenRewards, required this.onSignIn, required this.onInvite});
  final VoidCallback onOpenRewards, onSignIn, onInvite;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && w.uid != null;
          final fd = _map(_map(_map(w.summary['config'])['reference'])['friendDiscount']);
          return Column(key: const ValueKey('v5-rewards-invite'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            NRewards(coins: w.coins, streak: w.streak, signedIn: signedIn, onOpenRewards: onOpenRewards, onSignIn: onSignIn),
            NInvite(
              onInvite: onInvite,
              wordPct: _int(fd['wordPct']),
              wordFirstN: _int(fd['wordFirstN']),
              subscriptionPct: _int(fd['subscriptionPct']),
              code: signedIn && w.code.isNotEmpty ? w.code : null,
            ),
          ]);
        },
      );
}

/// The day's library pick (same rule as the old Trending row).
List<String> v5TrendingPick(List<Word> words, DateTime now) => [
      for (var i = 0; i < 3 && i < words.length; i++) words[(now.day + 3 + i * 5) % words.length].word,
    ];

class V5Trending extends StatelessWidget {
  const V5Trending({super.key, required this.onWord, required this.onLibrary});
  final void Function(Word word) onWord;
  final VoidCallback onLibrary;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ContentStore.instance,
        builder: (context, _) {
          final lib = ContentStore.instance.library;
          return NTrending(
            key: const ValueKey('v5-trending'),
            words: v5TrendingPick(lib, DateTime.now()),
            onWord: (s) {
              for (final w in lib) {
                if (w.word == s) return onWord(w);
              }
            },
            onLibrary: onLibrary,
          );
        },
      );
}

ImageProvider? v5Thumb(String src) {
  if (src.startsWith('assets/')) return AssetImage(src);
  if (src.startsWith('http://') || src.startsWith('https://')) return CachedNetworkImageProvider(src);
  return null;
}

List<ImageProvider> _thumbs(Iterable<BagItem> items) => [
      for (final i in items)
        if (v5Thumb(i.image) case final p?) p,
    ].take(3).toList();

/// Cart, wishlist and orders from CartBag (counts and item images).
class V5Own extends StatelessWidget {
  const V5Own({super.key, required this.onCart, required this.onWishlist, required this.onOrders});
  final VoidCallback onCart, onWishlist, onOrders;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: CartBag.instance,
        builder: (context, _) {
          final b = CartBag.instance;
          return NOwn(
            key: const ValueKey('v5-own'),
            onCart: onCart,
            onWishlist: onWishlist,
            onOrders: onOrders,
            cartCount: b.cartCount,
            wishlistCount: b.wishCount,
            orderCount: b.orders.length,
            cartThumbs: _thumbs(b.cart),
            wishlistThumbs: _thumbs(b.wishlist),
            orderThumbs: _thumbs(b.orders.expand((o) => o.items)),
          );
        },
      );
}

/// Edition (Play prices, availability, active tier) + Partner (points and
/// the server's `config.partner.levels`).
class V5EditionPartner extends StatelessWidget {
  const V5EditionPartner({super.key, required this.onJoin, required this.onPartner});
  final void Function(String tier) onJoin;
  final VoidCallback onPartner;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([PlaySubscriptions.instance, EconomyMirror.instance]),
        builder: (context, _) {
          final ps = PlaySubscriptions.instance;
          final w = EconomyMirror.instance;
          final levels = <(String, int)>[
            for (final l in (_map(_map(w.summary['config'])['partner'])['levels'] is List
                ? _map(_map(w.summary['config'])['partner'])['levels'] as List
                : const []))
              if (l is Map && l['title'] != null && _int(l['points']) != null) ('${l['title']}', _int(l['points'])!),
          ];
          return Column(key: const ValueKey('v5-edition-partner'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            NEdition(
              onJoin: onJoin,
              prices: {
                for (final p in NEdition.plans)
                  p.$1: switch (playPlanFor(p.$1, yearly: false)) { final plan? => ps.priceFor(plan.productId), null => null },
              },
              playAvailable: ps.available,
              currentTier: ps.activeTier,
            ),
            NPartner(points: w.partnerPoints, levels: levels.isEmpty ? null : levels, onPartner: onPartner),
          ]);
        },
      );
}

