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
import '../../widgets/hub_rails.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../admin/template/editable.dart';
import '../programs/program_kit.dart';
import '../programs/earn_program.dart';
import '../programs/program_router.dart';
import '../circle/circle_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _upi = TextEditingController();
  final _legal = TextEditingController();
  final _pan = TextEditingController();
  final _email = TextEditingController();
  String _method = 'wise';
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
    _legal.dispose();
    _pan.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final result = await EconomyApi.call('savePayoutAccount', {
      'country': _country,
      'upi': _upi.text.trim(),
      'legalName': _legal.text.trim(),
      'pan': _pan.text.trim(),
      'method': _method,
      'email': _email.text.trim(),
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

  void _openAccount(BuildContext context, bool india, bool unsupported, bool canPay) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _country,
                dropdownColor: const Color(0xFF141820),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Payout country'),
                items: [for (final item in _countries) DropdownMenuItem(value: item.$1, child: Text(item.$2))],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _country = value);
                  Navigator.pop(ctx);
                  _openAccount(context, value == 'IN', value == 'XX', canPay);
                },
              ),
              if (india) ...[
                TextField(controller: _upi, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'UPI id, name@bank')),
                TextField(controller: _legal, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Legal name')),
                TextField(controller: _pan, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'PAN')),
              ],
              if (!india && !unsupported)
                TextField(controller: _email, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Wise or PayPal email')),
              const SizedBox(height: 12),
              GoldButton(label: 'Save payout account', onTap: () { Navigator.pop(ctx); runPrivate(context, _saveAccount); }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kEarnDisclaimer,
      title: 'Your Earning',
      mark: NwsbMarks.bars,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final india = _country == 'IN';
          final unsupported = _country == 'XX';
          // The server checks the minimum, the hold and the saved account.
          final canPay = !unsupported && w.payoutRail.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              HubRails(
                labels: const ['Cash', 'Payout', 'Sales', 'Glass', 'Clear'],
                openGuide: false,
                onOpen: (card) {
                  switch (card.title) {
                    case 'Lifetime':
                    case 'Sales':
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CircleScreen(initialTab: 'sales')));
                    break;
                    case 'Available':
                    case 'Referrals':
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CircleScreen(initialTab: 'payouts')));
                    break;
                    case 'NowssB Earn':
                      Programmes.open(context, Programme.earn);
                    break;
                    case 'Rewards':
                      Programmes.open(context, Programme.rewards);
                    break;
                    case 'Payout account':
                      _openAccount(context, india, unsupported, canPay);
                    break;
                    case 'Request payout':
                      if (canPay) {
                        runPrivate(context, () => EconomyApi.call('requestPayout'));
                      } else {
                        _openAccount(context, india, unsupported, canPay);
                      }
                    break;
                  }
                },
                a: [
                  RailCard('Lifetime', FxBook.instance.formatCents(w.lifetimeCents), 'Cash', art: 'assets/rails/earnings-01.jpg'),
                  RailCard('Available', FxBook.instance.formatCents(w.cash), 'Cash', art: 'assets/rails/earnings-02.jpg'),
                  RailCard('NowssB Earn', 'Sales ledger and lock', 'Open', art: 'assets/rails/earnings-06.jpg'),
                ],
                b: [
                  RailCard('Payout account', india ? 'India · UPI' : unsupported ? 'Country not supported yet' : 'Wise or PayPal', 'Account', art: 'assets/rails/gen-54.jpg'),
                  RailCard('Request payout', FxBook.instance.formatCents(w.cash), canPay ? 'Request' : 'Save account first', art: 'assets/rails/gen-55.jpg'),
                  RailCard('Sales', 'What this account sold', 'Open', art: 'assets/rails/gen-56.jpg'),
                  RailCard('Referrals', 'The second level', 'Open', art: 'assets/rails/gen-57.jpg'),
                ],
                c: [
                  RailCard('Rewards', 'Coins on this account', 'Open', art: 'assets/rails/art-coins.jpg'),
                  RailCard('Payout account', w.payoutRail.isEmpty ? 'No rail saved yet' : w.payoutRail, 'Account', art: 'assets/rails/earnings-03.jpg'),
                  RailCard('Request payout', 'The server checks the minimum', 'Cash', art: 'assets/rails/earnings-04.jpg'),
                ],
                d: [
                  RailCard('Lifetime', 'Everything this account earned', 'Cash', art: 'assets/rails/gen-40.jpg'),
                  RailCard('Available', 'Ready to request', 'Cash', art: 'assets/rails/gen-41.jpg'),
                ],
                e: [
                  RailCard('Sales', 'Cleared purchases', 'Open', art: 'assets/rails/gen-42.jpg'),
                  RailCard('Referrals', 'Paid one level down', 'Open', art: 'assets/rails/gen-43.jpg'),
                ],
              ),
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
