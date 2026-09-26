import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import 'earnings_screen.dart';
import '../social/echo_wall_screen.dart';
import '../vault/vault_screen.dart';
import '../wordprint/word_print_screen.dart';

class EarnHubScreen extends StatelessWidget {
  const EarnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn',
      requireAuth: true,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              CoinCount(value: w.coins, style: const TextStyle(fontSize: 28, color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
              MoneyCount(cents: w.cash, style: const TextStyle(color: NwsbColors.mist)),
              Text(w.plan, style: const TextStyle(color: NwsbColors.mist)),
              const SizedBox(height: 6),
              Text('${w.sellerTier} · ${w.wordsSold}/${w.nextSellerTarget} sold', style: const TextStyle(color: NwsbColors.mist)),
              Text('${w.circleTier} · ${w.code}', style: const TextStyle(color: NwsbColors.mist)),
              const SizedBox(height: 8),
              const EconomyNote('This page is only yours. Coin and cash balances are not on the public Word Print.'),
              const SizedBox(height: 14),
              GoldButton(label: 'Vault', onTap: () => _open(context, const VaultScreen())),
              const SizedBox(height: 8),
              GoldButton(label: 'Word Bazaar', filled: false, onTap: () => _open(context, const BazaarScreen())),
              const SizedBox(height: 8),
              GoldButton(label: 'Circle', filled: false, onTap: () => _open(context, const CircleScreen())),
              const SizedBox(height: 8),
              GoldButton(label: 'Word Print', filled: false, onTap: () => _open(context, WordPrintScreen(uid: w.uid))),
              const SizedBox(height: 8),
              GoldButton(label: 'Echo Wall', filled: false, onTap: () => _open(context, const EchoWallScreen())),
              const SizedBox(height: 14),
              GoldButton(label: 'Earnings', filled: false, onTap: () => _open(context, const EarningsScreen())),
              const SizedBox(height: 18),
              const Text('COIN LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              _ledger('coinLedger', w.uid),
              const SizedBox(height: 16),
              const Text('CASH LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              _ledger('cashLedger', w.uid),
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _ledger(String collection, String? uid) {
    if (!NwsbFirebase.ready || uid == null) return const EconomyNote('Sign in to see the ledger.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).where('uid', isEqualTo: uid).limit(15).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EconomyNote('Nothing here yet.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final doc in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${doc.data()['reason'] ?? ''}  ${doc.data()['delta'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}
