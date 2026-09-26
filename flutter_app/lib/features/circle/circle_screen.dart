import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/subscription.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Circle',
      requireAuth: true,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          if (!w.subscribed) {
            return EconomyMessage(
              title: 'Circle opens with a paid plan',
              body: 'A free or lapsed plan cannot share a code or earn from one. Your tier is kept when you renew.',
              action: 'See plans',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
              ),
            );
          }
          final next = w.paidReferrals >= 100
              ? 100
              : w.paidReferrals >= 50
                  ? 100
                  : w.paidReferrals >= 20
                      ? 50
                      : w.paidReferrals >= 5
                          ? 20
                          : 5;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Text(w.code.isEmpty ? '—' : w.code, style: const TextStyle(fontSize: 32, color: NwsbColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: 2)),
              Text('${w.circleTier} · ${w.paidReferrals} paid referrals', style: const TextStyle(color: NwsbColors.mist)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: next == 0 ? 0 : (w.paidReferrals / next).clamp(0, 1),
                color: NwsbColors.gold,
                backgroundColor: const Color(0x22FFFFFF),
              ),
              const SizedBox(height: 6),
              Text('Squad volume ${w.paidReferrals} / $next toward the next Circle tier', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
              const SizedBox(height: 12),
              const EconomyNote(
                'Your code works only while your paid plan is active. After 5 paid referrals you earn cash: 20%, then 25, 30, and 35 at Platinum. Level 2 is 5% and only while you and your direct referral both have an active plan. Nothing pays on an invite alone.',
              ),
              const SizedBox(height: 14),
              GoldButton(
                label: 'Copy code',
                filled: false,
                onTap: w.code.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: w.code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Enter a referral code', hintStyle: TextStyle(color: NwsbColors.mist)),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: w.referredBy.isEmpty ? 'Apply code' : 'Code already applied',
                onTap: w.referredBy.isEmpty
                    ? () => runEconomy(context, () => EconomyApi.call('applyReferralCode', {'code': _code.text.trim()}))
                    : null,
              ),
              const SizedBox(height: 18),
              const Text('LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              if (!NwsbFirebase.ready || w.uid == null)
                const EconomyNote('Sign in to see referral payments.')
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('referralLedger')
                      .where('referrerUid', isEqualTo: w.uid)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const EconomyNote('No referral payments yet.');
                    return Column(
                      children: [
                        for (final doc in docs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'L${doc.data()['level']} · ${doc.data()['status']} · ${FxBook.instance.formatCents((doc.data()['commissionAmount'] as num?)?.toInt() ?? 0)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
