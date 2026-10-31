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

  @override
  void dispose() {
    _email.dispose();
    _legal.dispose();
    super.dispose();
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

  Future<void> _requestPayout() async {
    await EconomyApi.call('requestPayout');
    await EconomyMirror.instance.refresh();
  }

  void _openAccount(BuildContext context) {
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
                  DropdownButtonFormField<String>(
                    initialValue: _country,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141820),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Payout country'),
                    items: [for (final item in kPayoutCountries) DropdownMenuItem(value: item.$1, child: Text(item.$2))],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _country = value);
                      setSheet(() {});
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
                    TextField(controller: _email, onChanged: (_) => setSheet(() {}), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _method == 'paypal' ? 'PayPal email' : 'Wise email')),
                    TextField(controller: _legal, onChanged: (_) => setSheet(() {}), textInputAction: TextInputAction.done, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Full legal name')),
                  ],
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a valid email and your full name.')));
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
                  WorkCard(category: 'Cash', title: 'Request payout', meta: FxBook.instance.formatCents(w.cash), action: canPay ? 'Request' : w.payoutRail.isEmpty ? 'Save account first' : 'Nothing to pay yet', image: 'assets/rails/earnings-03.jpg', onTap: canPay ? () => runPrivate(context, _requestPayout) : w.payoutRail.isEmpty ? () => _openAccount(context) : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing is available to pay out yet. Cleared sales show up here after 30 days.')))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

