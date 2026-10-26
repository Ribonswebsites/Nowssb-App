/// NORMAL HOME v5 — the sections below the ritual card, wired to real data.
///
/// Each widget here only reads live stores and passes the values into the
/// v5 section widgets (lib/widgets/concept/normal). Nothing is invented: a
/// value that has no real source is left out of the section.
library;

import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../features/economy/economy_api.dart';
import '../../widgets/concept/normal/invite.dart';
import '../../widgets/concept/normal/rewards.dart';

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

