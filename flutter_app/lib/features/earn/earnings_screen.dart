import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _upi = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Earnings',
      requireAuth: true,
      banner: const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: EconomyNote('Shown in your currency. Settlement to an Indian account is in INR until another payout rail is added.'),
      ),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const Text('Lifetime', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
              MoneyCount(cents: w.lifetimeCents),
              const SizedBox(height: 4),
              const Text('Available', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
              MoneyCount(cents: w.cash),
              const SizedBox(height: 12),
              TextField(
                controller: _upi,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: w.upi.isEmpty ? 'UPI id for settlement' : w.upi,
                  hintStyle: const TextStyle(color: NwsbColors.mist),
                ),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Save payout account',
                filled: false,
                onTap: () => runEconomy(context, () => EconomyApi.call('savePayoutAccount', {'upi': _upi.text.trim()})),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Request payout',
                onTap: w.cash >= 500 && w.upi.isNotEmpty
                    ? () => runEconomy(context, () => EconomyApi.call('requestPayout'))
                    : null,
              ),
              const SizedBox(height: 8),
              const EconomyNote('Minimum applies in the base balance. If the payout rail is not connected, the request stays queued and is not marked paid.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final item in const [('all', 'All'), ('sale', 'Sales'), ('circle', 'Circle'), ('payout', 'Payouts')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.$2),
                        selected: _filter == item.$1,
                        onSelected: (_) => setState(() => _filter = item.$1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!NwsbFirebase.ready || w.uid == null)
                const EconomyMessage(title: 'Nothing to show', body: 'Sign in to see earnings.')
              else
                _History(uid: w.uid!, filter: _filter),
            ],
          );
        },
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.uid, required this.filter});
  final String uid;
  final String filter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cashLedger').where('uid', isEqualTo: uid).limit(40).snapshots(),
      builder: (context, cashSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('referralLedger').where('referrerUid', isEqualTo: uid).limit(40).snapshots(),
          builder: (context, refSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('payoutRequests').where('uid', isEqualTo: uid).limit(20).snapshots(),
              builder: (context, paySnap) {
                if (cashSnap.hasError || refSnap.hasError || paySnap.hasError) {
                  return const EconomyMessage(title: 'Could not load earnings', body: 'Try again in a moment.');
                }
                if (!cashSnap.hasData || !refSnap.hasData || !paySnap.hasData) return const EconomySkeleton();
                final rows = <_Row>[];
                for (final doc in cashSnap.data!.docs) {
                  final reason = '${doc.data()['reason'] ?? ''}';
                  final kind = reason.toLowerCase().contains('circle') ? 'circle' : reason.toLowerCase().contains('payout') ? 'payout' : 'sale';
                  rows.add(_Row(kind, reason, (doc.data()['delta'] as num?)?.toInt() ?? 0, '${doc.data()['reason'] ?? ''}'));
                }
                for (final doc in refSnap.data!.docs) {
                  rows.add(_Row('circle', 'Level ${doc.data()['level']}', (doc.data()['commissionAmount'] as num?)?.toInt() ?? 0, '${doc.data()['status']}'));
                }
                for (final doc in paySnap.data!.docs) {
                  rows.add(_Row('payout', 'Payout', (doc.data()['amountBase'] as num?)?.toInt() ?? 0, '${doc.data()['status']}'));
                }
                final shown = rows.where((row) => filter == 'all' || row.kind == filter).toList();
                if (shown.isEmpty) {
                  return const EconomyMessage(title: 'No earnings yet', body: 'Sales and Circle commissions will show up here.');
                }
                return Column(
                  children: [
                    for (final row in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text('${row.title}\n${row.status}', style: const TextStyle(color: Colors.white, height: 1.3))),
                            Text(FxBook.instance.formatCents(row.cents), style: const TextStyle(color: NwsbColors.goldLight)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Row {
  _Row(this.kind, this.title, this.cents, this.status);
  final String kind;
  final String title;
  final int cents;
  final String status;
}
