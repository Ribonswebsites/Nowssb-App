import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../widgets/routine_deck.dart';
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
  final _email = TextEditingController();
  final _legal = TextEditingController();
  String _method = 'wise';
  late String _country = defaultPayoutCountry();
  String _filter = 'all';

  @override
  void dispose() {
    _email.dispose();
    _legal.dispose();
    super.dispose();
  }

  /// Same checks the server makes, so people see the problem before sending.
  String? _accountProblem() {
    if (_country == 'XX') return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(_email.text.trim())) {
      return 'Enter the email on your ${_method == 'paypal' ? 'PayPal' : 'Wise'} account.';
    }
    if (_legal.text.trim().length < 3) return 'Enter your legal name as on that account.';
    return null;
  }

  Future<void> _saveAccount() async {
    final result = await EconomyApi.call('savePayoutAccount', {
      'country': _country,
      'legalName': _legal.text.trim(),
      'method': _method,
      'email': _email.text.trim(),
    });
    final url = '${result['onboardUrl'] ?? ''}';
    if (url.startsWith('http')) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    // The Request card reads the saved account from the mirror.
    await EconomyMirror.instance.refresh();
    final message = '${result['message'] ?? ''}';
    final rail = '${result['rail'] ?? ''}';
    if (!mounted) return;
    final text = message.isNotEmpty
        ? message
        : rail == 'unsupported'
            ? 'Payouts are not available in your country yet. Your balance stays safe here.'
            : 'Payout account saved.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: EditableLabel('earnings_screen.EarningsScreen', text)));
  }

  void _openAccount(BuildContext context) {
    String? problem;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final unsupported = _country == 'XX';
          final valid = !unsupported && looksLikeEmail(_email.text) && _legal.text.trim().length >= 2;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Payout account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Where your earnings are sent. Each payout is reviewed before it goes out.', style: TextStyle(color: NwsbColors.mist, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('earnings-country'),
                    initialValue: _country,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141820),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Payout country'),
                    items: [for (final item in kPayoutCountries) DropdownMenuItem(value: item.$1, child: Text(item.$2))],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _country = value);
                      setSheet(() => problem = null);
                    },
                  ),
                  if (unsupported)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Payouts are not available in your country yet. Your balance stays safe here.', style: TextStyle(color: Color(0xCCFFFFFF))),
                    )
                  else ...[
                    Wrap(spacing: 8, children: [
                      ChoiceChip(label: const Text('Wise'), selected: _method == 'wise', onSelected: (_) => setSheet(() => _method = 'wise')),
                      ChoiceChip(label: const Text('PayPal'), selected: _method == 'paypal', onSelected: (_) => setSheet(() => _method = 'paypal')),
                    ]),
                    TextField(key: const Key('earnings-email'), controller: _email, onChanged: (_) => setSheet(() {}), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _method == 'paypal' ? 'PayPal email' : 'Wise email')),
                    TextField(key: const Key('earnings-legal'), controller: _legal, onChanged: (_) => setSheet(() {}), textInputAction: TextInputAction.done, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Full legal name')),
                  ],
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(problem!, key: const Key('earnings-problem'), style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13)),
                    ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: valid ? 1 : 0.4,
                    child: GoldButton(
                      label: unsupported ? 'Close' : 'Save payout account',
                      onTap: () {
                        if (unsupported) {
                          Navigator.pop(ctx);
                          return;
                        }
                        if (!valid) {
                          setSheet(() => problem = _accountProblem() ?? 'Add a valid email and your full name.');
                          return;
                        }
                        Navigator.pop(ctx);
                        runPrivate(context, _saveAccount);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestPayout(BuildContext context, int cash) async {
    if (cash <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to withdraw yet. Sales and referral earnings land here first.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141820),
        title: const Text('Request payout?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your whole available balance, ${FxBook.instance.formatCents(cash)}, goes into the payout queue. It is reviewed and then sent to your saved account.',
          style: const TextStyle(color: NwsbColors.mist),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(key: const Key('earnings-confirm-payout'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runPrivate(context, () => EconomyApi.call('requestPayout'));
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kEarnDisclaimer,
      title: 'Your Earnings',
      mark: NwsbMarks.bars,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final unsupported = _country == 'XX';
          // The server checks the minimum, the hold and the saved account.
          final canPay = !unsupported && w.payoutRail.isNotEmpty && w.cash > 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const IdentityRails(RailKind.earnings),
              RoutineDeck(
                title: 'Earnings',
                banner: 'Your earning',
                bannerSub: 'Sales and referrals',
                onBanner: () => _openAccount(context),
                cards: [
                  WorkCard(category: 'Cash', title: 'Lifetime', meta: FxBook.instance.formatCents(w.lifetimeCents), action: 'Open sales', image: 'assets/rails/gen-54.jpg', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EarnProgramPage(initialTab: earnTabIndex('sales'))))),
                  WorkCard(category: 'Cash', title: 'Available', meta: FxBook.instance.formatCents(w.cash), action: 'Open payouts', image: 'assets/rails/gen-55.jpg', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EarnProgramPage(initialTab: earnTabIndex('payouts'))))),
                  WorkCard(category: 'Account', title: 'Payout account', meta: w.payoutRail.isEmpty ? 'Wise or PayPal' : 'Saved', action: w.payoutRail.isEmpty ? 'Set account' : 'Change', image: 'assets/rails/earnings-02.jpg', onTap: () => _openAccount(context)),
                  WorkCard(category: 'Cash', title: 'Request payout', meta: FxBook.instance.formatCents(w.cash), action: canPay ? 'Request' : w.payoutRail.isEmpty ? 'Save account first' : 'Nothing to pay yet', image: 'assets/rails/earnings-03.jpg', onTap: canPay ? () => _requestPayout(context, w.cash) : w.payoutRail.isEmpty ? () => _openAccount(context) : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing is available to pay out yet. Cleared sales show up here after 30 days.')))),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const [('all', 'All'), ('sale', 'Sales'), ('circle', 'Team'), ('payout', 'Payouts')])
                    ChoiceChip(key: Key('earnings-filter-${f.$1}'), label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
                ],
              ),
              const SizedBox(height: 10),
              if ((NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null) case final user?)
                _History(uid: user.uid, filter: _filter)
              else
                const EconomyMessage(title: 'Sign in to see your earnings', body: 'Sales, referral commissions and payouts show up here.'),
            ],
          );
        },
      ),
    );
  }
}

/// Builds readable rows from the server's ledgers. Pure so it can be tested.
List<EarningsRow> earningsRows({
  required List<Map<String, dynamic>> cash,
  required List<Map<String, dynamic>> payouts,
  required int nowMs,
}) {
  final rows = <EarningsRow>[];
  for (final d in cash) {
    final reason = '${d['reason'] ?? ''}'.toLowerCase();
    final cents = (d['delta'] as num?)?.toInt() ?? 0;
    final at = (d['at'] as num?)?.toInt() ?? 0;
    // Payouts already come from payoutRequests; skip their ledger mirror to avoid counting twice.
    if (reason.contains('payout')) continue;
    final team = reason.contains('commission') && !reason.contains('direct');
    final availableAt = (d['availableAt'] as num?)?.toInt() ?? 0;
    final held = d['held'] == true && availableAt > nowMs;
    final status = held ? 'Pending until ${_date(availableAt)}' : 'Available';
    rows.add(EarningsRow(team ? 'circle' : 'sale', team ? 'Team commission' : (reason.contains('direct') ? 'Your sale' : 'Earning'), cents, status, at));
  }
  for (final d in payouts) {
    final cents = (d['amountBase'] as num?)?.toInt() ?? 0;
    rows.add(EarningsRow('payout', 'Payout', -cents, _status(d['status']), (d['at'] as num?)?.toInt() ?? 0));
  }
  rows.sort((x, y) => y.at.compareTo(x.at));
  return rows;
}

String _date(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]}';
}

class _History extends StatelessWidget {
  const _History({required this.uid, required this.filter});
  final String uid;
  final String filter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cashLedger').where('uid', isEqualTo: uid).limit(60).snapshots(),
      builder: (context, cashSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('payoutRequests').where('uid', isEqualTo: uid).limit(20).snapshots(),
          builder: (context, paySnap) {
            if (cashSnap.hasError || paySnap.hasError) {
              return const EconomyMessage(title: 'Could not load earnings', body: 'Check your connection and open this page again.');
            }
            if (!cashSnap.hasData || !paySnap.hasData) return const EconomySkeleton();
            final rows = earningsRows(
              cash: [for (final d in cashSnap.data!.docs) d.data()],
              payouts: [for (final d in paySnap.data!.docs) d.data()],
              nowMs: DateTime.now().millisecondsSinceEpoch,
            );
            final shown = rows.where((row) => filter == 'all' || row.kind == filter).toList();
            if (shown.isEmpty) {
              return const EconomyMessage(title: 'Nothing here yet', body: 'Sales, team commissions and payouts will show up here.');
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
  }
}

String _status(Object? raw) => switch ('$raw') {
      'queued' => 'In the queue',
      'approved' => 'Approved, sends on payout day',
      'paid' => 'Paid',
      'rejected' => 'Returned to your balance',
      'pending' => 'Pending',
      'null' || '' => '',
      final other => other[0].toUpperCase() + other.substring(1),
    };

class EarningsRow {
  EarningsRow(this.kind, this.title, this.cents, this.status, this.at);
  final String kind;
  final String title;
  final int cents;
  final String status;
  final int at;
}
