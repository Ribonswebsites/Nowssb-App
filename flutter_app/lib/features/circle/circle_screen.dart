import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/nwsb_icon.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../earn/earn_loyalty.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../../admin/template/editable.dart';
import '../programs/program_kit.dart';
import '../programs/earn_program.dart';
import '../programs/program_router.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key, this.initialTab});

  /// Opens scrolled to one programme tab (e.g. 'payouts').
  final String? initialTab;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _code = TextEditingController();
  late final Widget _tabs = ProgramTabsBlock(spec: kEarnSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, showDisclaimer: false);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      film: false,
      goodToKnow: kEarnDisclaimer,
      title: 'NowssB Earn',
      mark: NwsbMarks.earn,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && w.uid != null;
          final units = w.unitsSold > 0 ? w.unitsSold : w.paidReferrals;
          final rank = EarnStanding.of(w).step.title;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              const EarnLoyaltyBoard(),
              const SizedBox(height: 18),
              const CoinCollectCard(pageKey: 'earn', amount: 10, title: 'Earn coins'),
              const SizedBox(height: 12),
              const TrioRail(current: Programme.earn),
              const SizedBox(height: 18),
              if (!signedIn)
                GoldButton(
                  label: 'Sign in to see your code',
                  onTap: () => NwsbSignInPage.open(context),
                )
              else if (!w.subscribed) ...[
                const EconomyNote('Your code stays paused until a paid plan is active. The count you already have is kept.'),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'See plans',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
              ] else ...[
                Text(w.code.isEmpty ? '—' : w.code, style: const TextStyle(fontSize: 32, color: NwsbColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: 2)),
                Text('$rank · $units sales through your code', style: const TextStyle(color: NwsbColors.mist)),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Copy code',
                  filled: false,
                  onTap: w.code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: w.code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('circle_screen.CircleScreen', 'Code copied.')));
                          }
                        },
                ),
              ],
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
                onTap: signedIn && w.referredBy.isEmpty
                    ? () => runPrivate(context, () => EconomyApi.call('applyReferralCode', {'code': _code.text.trim()}))
                    : signedIn
                        ? null
                        : () => NwsbSignInPage.open(context),
              ),
              const SizedBox(height: 18),
              const EditableLabel('circle_screen.CircleScreen', 'YOUR TEAM', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              const EconomyNote(
                'One level only. You see yourself and the people who used your code. Their recruits are never shown and never paid. An invite by itself pays nothing.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x29FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signedIn ? 'You · $rank' : 'You', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      signedIn && units > 0
                          ? '$units sales on your code. People you invited show here only after a cleared sale.'
                          : 'No one under you yet. Share your code. This stays empty until someone you invited makes a cleared sale.',
                      style: const TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const EditableLabel('circle_screen.CircleScreen', 'LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              if (!NwsbFirebase.ready || w.uid == null)
                const EconomyNote('Sign in to see referral payments.')
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _refLedger(w.uid!),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const EconomyNote('No referral payments yet. Nothing here is a payout.');
                    return Column(
                      children: [
                        for (final doc in docs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${doc.data()['kind'] == 'gift' ? 'Gift purchase · ' : ''}L${doc.data()['level']} · ${doc.data()['status']} · ${FxBook.instance.formatCents((doc.data()['commissionAmount'] as num?)?.toInt() ?? 0)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 18),
              _tabs,
            ],
          );
        },
      ),
    );
  }
}

final _refLedgers = <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};
Stream<QuerySnapshot<Map<String, dynamic>>> _refLedger(String uid) => _refLedgers.putIfAbsent(
    uid, () => FirebaseFirestore.instance.collection('referralLedger').where('referrerUid', isEqualTo: uid).limit(20).snapshots().asBroadcastStream());
