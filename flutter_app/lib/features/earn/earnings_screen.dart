import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../admin/template/editable.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _upi = TextEditingController();
  String _filter = 'all';
  String _country = 'IN';

  static const _countries = <(String, String)>[
    ('IN', 'India — bank / UPI, INR'),
    ('US', 'United States'),
    ('GB', 'United Kingdom'),
    ('CA', 'Canada'),
    ('AU', 'Australia'),
    ('AE', 'United Arab Emirates'),
    ('SG', 'Singapore'),
    ('DE', 'Germany'),
    ('FR', 'France'),
    ('JP', 'Japan'),
    ('BR', 'Brazil'),
    ('MX', 'Mexico'),
    ('NZ', 'New Zealand'),
    ('XX', 'Another country'),
  ];

  @override
  void dispose() {
    _upi.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final result = await EconomyApi.call('savePayoutAccount', {
      'country': _country,
      'upi': _upi.text.trim(),
    });
    final url = '${result['onboardUrl'] ?? ''}';
    if (url.startsWith('http')) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    final message = '${result['message'] ?? ''}';
    final rail = '${result['rail'] ?? ''}';
    if (!mounted) return;
    final text = message.isNotEmpty
        ? message
        : rail == 'unsupported'
            ? 'This country is not supported yet. Your balance stays here.'
            : rail == 'upi_manual'
                ? 'India payouts will settle in INR to your UPI.'
                : 'Payout account saved.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: EditableLabel('earnings_screen.EarningsScreen', text)));
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Your Earning',
      mark: NwsbMarks.bars,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final india = _country == 'IN';
          final unsupported = _country == 'XX';
          final canPay = w.cash >= 500 && !unsupported && (india ? w.upi.isNotEmpty || _upi.text.trim().contains('@') : w.payoutRail == 'stripe_connect');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const BrandTopBanner(
                bare: true,
                title: 'Your Earning',
                mark: NwsbMarks.piggy,
              ),
              const SizedBox(height: 12),
              const ColoredSplitPromoBanner(
                margin: EdgeInsets.zero,
                spec: SplitPromoSpec(
                  title: 'Your Earning',
                  cta: 'Sales and referrals',
                  leftColor: Color(0xFF143028),
                  rightColor: Color(0xFF2D6A4F),
                  art: SplitPromoArts.blondeLotus,
                ),
              ),
              const SizedBox(height: 12),
              const ProgramShelf(),
              const SizedBox(height: 12),
              const GlassLine(text: 'Pending for 30 days, then available. A person approves the payout.'),
              const SizedBox(height: 12),
              EconomyNote(
                unsupported
                    ? 'This country is not on a payout rail yet. Earnings stay in your balance and are not sent in the wrong currency.'
                    : india
                        ? 'India settles in INR to your UPI id.'
                        : 'Everywhere else uses Stripe Connect. You finish identity checks in Stripe, then payouts go to your local bank.',
              ),
              const SizedBox(height: 12),
              const EditableLabel('earnings_screen.EarningsScreen', 'Lifetime', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
              MoneyCount(cents: w.lifetimeCents),
              const SizedBox(height: 4),
              const EditableLabel('earnings_screen.EarningsScreen', 'Available', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
              MoneyCount(cents: w.cash),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _country,
                dropdownColor: const Color(0xFF141820),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Payout country', labelStyle: TextStyle(color: NwsbColors.mist)),
                items: [
                  for (final item in _countries)
                    DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _country = value);
                },
              ),
              if (india) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _upi,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: w.upi.isEmpty ? 'UPI id, name@bank' : w.upi,
                    hintStyle: const TextStyle(color: NwsbColors.mist),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              GoldButton(
                label: india ? 'Save India payout account' : unsupported ? 'Save country' : 'Set up Stripe payouts',
                filled: false,
                onTap: () => runPrivate(context, _saveAccount),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Request payout',
                onTap: canPay
                    ? () => runPrivate(context, () => EconomyApi.call('requestPayout'))
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                w.payoutRail.isEmpty ? 'No payout rail saved yet.' : 'Saved rail: ${w.payoutRail}',
                style: const TextStyle(color: NwsbColors.mist, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final item in const [('all', 'All'), ('sale', 'Sales'), ('circle', 'Referrals'), ('payout', 'Payouts')])
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
                  return const EconomyMessage(title: 'No earnings yet', body: 'Sales and referral commissions will show up here.');
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
