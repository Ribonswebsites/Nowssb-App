import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/routine_deck.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../programs/earn_program.dart';
import 'earnings_data.dart';

/// NowssB Earnings (spec 18.2). Money dashboard on the app's own background
/// video (EconomyPage is transparent). Server contracts are unchanged:
/// savePayoutAccount and requestPayout are sent exactly as before.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key, this.source = const FirestoreEarningsSource(), this.showGuide = true});
  final EarningsSource source;
  final bool showGuide;

  static const guideKey = 'earnings_guide_v1_seen';

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

const _tabs = <(String, String)>[('words', 'Words'), ('meanings', 'Meanings'), ('subscriptions', 'Subscriptions'), ('bonuses', 'Bonuses')];
const _targets = [100, 500, 1000, 2000];

String money(int cents) => FxBook.instance.formatCents(cents);

class _EarningsScreenState extends State<EarningsScreen> {
  String _tab = 'words';
  Stream<EarningsSnapshot>? _stream;
  String? _uid;

  @override
  void initState() {
    super.initState();
    if (widget.showGuide) WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGuide());
  }

  Future<void> _maybeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(EarningsScreen.guideKey) ?? false) return;
    if (!mounted) return;
    await showEarningsGuide(context);
    await prefs.setBool(EarningsScreen.guideKey, true);
  }

  Stream<EarningsSnapshot>? _streamFor(String? uid) {
    if (uid != _uid) {
      _uid = uid;
      _stream = uid == null ? null : widget.source.watch(uid).asBroadcastStream();
    }
    return _stream;
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kEarnDisclaimer,
      title: 'Your Earnings',
      mark: NwsbMarks.bars,
      action: IconButton(key: const Key('earnings.help'), tooltip: 'Help', visualDensity: VisualDensity.compact, icon: const Icon(Icons.help_outline_rounded, color: Colors.white), onPressed: () => showEarningsHelp(context)),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          if (w.uid == null) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              FrostCard(
                title: 'Sign in to see your money',
                body: 'Your earnings and withdrawals stay on your account.',
                next: 'Sign in',
                onNext: () => runPrivate(context, () async {}),
              ),
            ]);
          }
          return StreamBuilder<EarningsSnapshot>(
            stream: _streamFor(w.uid),
            builder: (context, snap) {
              final data = snap.data ?? const EarningsSnapshot();
              final loading = !snap.hasData && !snap.hasError;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _MoneyPanel(available: w.cash, pending: data.pendingCents, paid: data.paidCents, onWithdraw: () => openWithdraw(context)),
                  const SizedBox(height: 14),
                  RoutineDeck(
                    title: 'Earnings',
                    banner: 'Your money',
                    bannerSub: w.payoutRail.isEmpty ? 'Link a payout account' : 'Payout account linked',
                    onBanner: () => openPayoutAccount(context),
                    cards: [
                      WorkCard(category: 'Withdraw', title: 'Withdraw', meta: money(w.cash), action: 'Start', image: 'assets/rails/earnings-03.jpg', onTap: () => openWithdraw(context)),
                      WorkCard(category: 'Account', title: 'Payout account', meta: w.payoutRail.isEmpty ? 'Not linked' : 'Linked', action: w.payoutRail.isEmpty ? 'Link' : 'Change', image: 'assets/rails/earnings-02.jpg', onTap: () => openPayoutAccount(context)),
                      WorkCard(category: 'Team', title: 'Your team', meta: money(data.teamCents), action: 'Open team', image: 'assets/rails/earnings-04.jpg', onTap: () => _push(context, const CircleScreen(initialTab: 'team'))),
                      WorkCard(category: 'History', title: 'Statements', meta: 'Monthly summaries', action: 'Open', image: 'assets/rails/earnings-05.jpg', onTap: () => _push(context, const EarningsStatementsPage())),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Breakdown(tab: _tab, onTab: (t) => setState(() => _tab = t), data: data, loading: loading, error: snap.hasError),
                  const SizedBox(height: 14),
                  _Team(direct: data.directCents, team: data.teamCents),
                  const SizedBox(height: 14),
                  _Target(sold: w.wordsSold, tier: w.sellerTier),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

// ---------- Glass pieces (approved card: frosted glass, soft white border, big radius, white title, grey body, Skip / Next pill) ----------

class Frost extends StatelessWidget {
  const Frost({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 28});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

class FrostCard extends StatelessWidget {
  const FrostCard({super.key, required this.title, required this.body, required this.next, this.onNext, this.skip, this.onSkip});
  final String title;
  final String body;
  final String next;
  final VoidCallback? onNext;
  final String? skip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Frost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13, height: 1.35)),
        const SizedBox(height: 14),
        Row(children: [
          if (skip != null) Flexible(child: TextButton(onPressed: onSkip, child: Text(skip!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)))),
          const Spacer(),
          Flexible(flex: 3, child: NextPill(label: next, onTap: onNext)),
        ]),
      ]),
    );
  }
}

class NextPill extends StatelessWidget {
  const NextPill({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: on ? () { HapticFeedback.selectionClick(); onTap!(); } : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: on ? 1 : 0.4), borderRadius: BorderRadius.circular(40)),
          child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1B1530), fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pending' || 'Requested' || 'Processing' => const Color(0xFFFFD27A),
      'Paid' => const Color(0xFF7FE0C2),
      'Reversed' || 'Failed' => const Color(0xFFFF8A8A),
      _ => const Color(0xFFB9A8FF),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: color.withValues(alpha: 0.18), border: Border.all(color: color.withValues(alpha: 0.6))),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

Widget _info(BuildContext context, String term, String definition, String example) => IconButton(
      key: Key('earnings.info.$term'),
      tooltip: 'What is $term?',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline_rounded, size: 16, color: Colors.white70),
      onPressed: () => showInfo(context, term, definition, example),
    );

Future<void> showInfo(BuildContext context, String term, String definition, String example) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: FrostCard(title: term, body: '$definition\n\nExample: $example', next: 'Got it', onNext: () => Navigator.pop(ctx)),
    ),
  );
}

// ---------- Top panel ----------

class _MoneyPanel extends StatelessWidget {
  const _MoneyPanel({required this.available, required this.pending, required this.paid, required this.onWithdraw});
  final int available;
  final int pending;
  final int paid;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, int cents, String def, String ex) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))), _info(context, label, def, ex)]),
            FittedBox(fit: BoxFit.scaleDown, child: Text(money(cents), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
          ]),
        );
    return Frost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          stat('Available', available, 'Money you can withdraw now.', 'You earn ${money(500)} and it clears. It shows here.'),
          stat('Pending', pending, 'Money still on hold, so refunds can be reversed fairly.', 'A sale today shows as Pending until the hold ends.'),
          stat('Paid out', paid, 'Money already sent to your payout account.', 'You withdrew ${money(1000)} last month.'),
        ]),
        const SizedBox(height: 6),
        Text('Pending money is released after a short hold window.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Text('Withdraw to your payout account', style: TextStyle(color: Colors.white70, fontSize: 12))),
          NextPill(key: const Key('earnings.withdraw'), label: 'Withdraw', onTap: onWithdraw),
        ]),
      ]),
    );
  }
}

// ---------- Breakdown tabs ----------

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.tab, required this.onTab, required this.data, required this.loading, required this.error});
  final String tab;
  final ValueChanged<String> onTab;
  final EarningsSnapshot data;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final rows = data.rows.where((r) => r.tab == tab).toList();
    return Frost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Money you earn', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in _tabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('earnings.tab.${t.$1}'),
                  label: Text(t.$2),
                  selected: tab == t.$1,
                  onSelected: (_) => onTab(t.$1),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  labelStyle: TextStyle(color: tab == t.$1 ? const Color(0xFF1B1530) : Colors.white),
                  shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                  showCheckmark: false,
                ),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        if (error)
          const Text('Could not load your earnings. Check your connection and try again.', style: TextStyle(color: Colors.white70))
        else if (loading)
          const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (rows.isEmpty)
          Text(tab == 'bonuses' ? 'No bonuses yet. Hit a target to earn one.' : 'Nothing here yet. Share your link to make your first sale.', style: const TextStyle(color: Colors.white70))
        else
          for (final r in rows) _RowTile(r),
      ]),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile(this.row);
  final EarningRow row;

  @override
  Widget build(BuildContext context) {
    final d = row.at;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            if (d != null) Text(MaterialLocalizations.of(context).formatMediumDate(d), style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        Text(money(row.cents), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        StatusChip(row.status),
      ]),
    );
  }
}

// ---------- Team and targets ----------

class _Team extends StatelessWidget {
  const _Team({required this.direct, required this.team});
  final int direct;
  final int team;

  @override
  Widget build(BuildContext context) {
    final total = direct + team;
    final share = total == 0 ? 0.0 : direct / total;
    return Frost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Your team', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
          _info(context, 'Your team', 'Money from people who joined with your link, up to 2 levels.', 'A friend you invited sells a word. You get a share.'),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: share, minHeight: 10, backgroundColor: const Color(0xFFB9A8FF).withValues(alpha: 0.4), color: Colors.white)),
        const SizedBox(height: 8),
        Text('Your sales ${money(direct)} · Team ${money(team)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: NextPill(key: const Key('earnings.team'), label: 'See team', onTap: () => _push(context, const CircleScreen(initialTab: 'team')))),
      ]),
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({required this.sold, required this.tier});
  final int sold;
  final String tier;

  @override
  Widget build(BuildContext context) {
    final target = _targets.firstWhere((t) => sold < t, orElse: () => _targets.last);
    final value = (sold / target).clamp(0.0, 1.0);
    return Frost(
      child: Row(children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(value: value, strokeWidth: 7, color: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.15)),
            Center(child: Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Target: $target words', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('$sold sold · rank $tier', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Finish it to unlock a bonus and your next rank.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            TextButton(key: const Key('earnings.targets'), onPressed: () => _push(context, const EarnProgramPage()), child: const Text('See all targets', style: TextStyle(color: Colors.white))),
          ]),
        ),
      ]),
    );
  }
}

// ---------- Payout account (link) ----------

/// Global, provider-led: the app only collects country and the provider
/// email. Identity and tax checks happen at the payout provider.
const payoutCountries = <(String, String)>[
  ('US', 'United States'), ('GB', 'United Kingdom'), ('CA', 'Canada'), ('AU', 'Australia'), ('DE', 'Germany'), ('FR', 'France'),
  ('ES', 'Spain'), ('IT', 'Italy'), ('NL', 'Netherlands'), ('AE', 'United Arab Emirates'), ('SG', 'Singapore'), ('JP', 'Japan'),
  ('BR', 'Brazil'), ('MX', 'Mexico'), ('NZ', 'New Zealand'), ('IN', 'India'), ('XX', 'Another country'),
];

Future<void> openPayoutAccount(BuildContext context) {
  return showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const PayoutAccountSheet());
}

class PayoutAccountSheet extends StatefulWidget {
  const PayoutAccountSheet({super.key});
  @override
  State<PayoutAccountSheet> createState() => _PayoutAccountSheetState();
}

class _PayoutAccountSheetState extends State<PayoutAccountSheet> {
  late String _country = EconomyMirror.instance.country.isEmpty ? 'US' : EconomyMirror.instance.country;
  final _email = TextEditingController();
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (_country != 'XX' && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter the email you use with Wise.');
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    nav.pop();
    await runPrivate(context, () async {
      // Same keys as before; India-only fields are sent empty.
      final result = await EconomyApi.call('savePayoutAccount', {
        'country': _country, 'upi': '', 'legalName': _name.text.trim(), 'pan': '', 'method': 'wise', 'email': email,
      });
      final url = '${result['onboardUrl'] ?? ''}';
      if (url.startsWith('http')) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      final msg = '${result['message'] ?? ''}';
      messenger.showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : result['rail'] == 'unsupported' ? 'Payouts are not available in this country yet. Your balance stays safe here.' : 'Payout account saved.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final unsupported = _country == 'XX';
    final field = InputDecoration(
      filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: Colors.white70), helperStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.viewInsetsOf(context).bottom),
      child: Frost(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Link your payout account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: 0.5, color: Colors.white),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('payout.country'),
              isExpanded: true,
              initialValue: payoutCountries.any((c) => c.$1 == _country) ? _country : 'XX',
              dropdownColor: const Color(0xFF221A3A),
              style: const TextStyle(color: Colors.white),
              decoration: field.copyWith(labelText: 'Country you get paid in'),
              items: [for (final c in payoutCountries) DropdownMenuItem(value: c.$1, child: Text(c.$2))],
              onChanged: (v) => setState(() => _country = v ?? 'US'),
            ),
            const SizedBox(height: 10),
            if (unsupported)
              const Text('We can not pay out there yet. Your money stays safe here.', style: TextStyle(color: Colors.white70))
            else ...[
              TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: field.copyWith(labelText: 'Full legal name', helperText: 'As on your ID. Wise checks it.')),
              const SizedBox(height: 10),
              TextField(key: const Key('payout.email'), controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: field.copyWith(labelText: 'Wise email', helperText: 'Wise may ask for ID and tax details for your country.', errorText: _error)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip', style: TextStyle(color: Colors.white70))),
              const Spacer(),
              NextPill(key: const Key('payout.save'), label: 'Save account', onTap: unsupported ? null : _save),
            ]),
            const Text('Next: Wise may open to verify you.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

// ---------- Withdraw: 3 steps (amount -> account -> confirm) ----------

Future<void> openWithdraw(BuildContext context) {
  return showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const WithdrawSheet());
}

class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({super.key});
  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final w = EconomyMirror.instance;
    final linked = w.payoutRail.isNotEmpty;
    final (title, body, next) = switch (_step) {
      0 => ('Amount', 'You can withdraw ${money(w.cash)}. The full available balance is sent. The minimum and any fee are checked by the server before it goes out.', w.cash > 0 ? 'Next' : null),
      1 => linked
          ? ('Payout account', 'Paying to your Wise account${w.country.isEmpty ? '' : ' (${w.country})'}.', 'Next')
          : ('Link your payout account', 'You need a payout account before you can withdraw.', 'Link account'),
      _ => ('Confirm', 'Withdraw ${money(w.cash)} to Wise. You will see it as Requested, then Processing, then Paid. Expected timing depends on your country.', 'Withdraw'),
    };
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Frost(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Step ${_step + 1} of 3', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: (_step + 1) / 3, color: Colors.white, backgroundColor: Colors.white24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(w.cash <= 0 && _step == 0 ? 'Nothing to withdraw yet. Money shows here once the hold ends.' : body, style: const TextStyle(color: Colors.white70, height: 1.35)),
          const SizedBox(height: 14),
          Row(children: [
            TextButton(key: const Key('withdraw.back'), onPressed: () => _step == 0 ? Navigator.pop(context) : setState(() => _step--), child: Text(_step == 0 ? 'Cancel' : 'Back', style: const TextStyle(color: Colors.white70))),
            const Spacer(),
            NextPill(key: const Key('withdraw.next'), label: next ?? 'Next', onTap: next == null ? null : () => _advance(linked)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _advance(bool linked) async {
    if (_step == 1 && !linked) {
      final nav = Navigator.of(context);
      final ctx = nav.context;
      nav.pop();
      await openPayoutAccount(ctx);
      return;
    }
    if (_step < 2) return setState(() => _step++);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostCard(title: 'Withdraw now?', body: 'This can not be undone once it is processing.', skip: 'Cancel', onSkip: () => Navigator.pop(ctx, false), next: 'Yes, withdraw', onNext: () => Navigator.pop(ctx, true)),
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    // Contract unchanged: requestPayout with no arguments.
    await runPrivate(context, () async {
      await EconomyApi.call('requestPayout');
      messenger.showSnackBar(const SnackBar(content: Text('Withdrawal requested. We will update its status here.')));
    });
  }
}

// ---------- Statements sub-page ----------

class EarningsStatementsPage extends StatelessWidget {
  const EarningsStatementsPage({super.key, this.source = const FirestoreEarningsSource()});
  final EarningsSource source;

  @override
  Widget build(BuildContext context) {
    final uid = EconomyMirror.instance.uid;
    return EconomyPage(
      title: 'Statements',
      mark: NwsbMarks.bars,
      showBalance: false,
      child: uid == null
          ? const EconomyMessage(title: 'Sign in first', body: 'Statements stay on your account.')
          : StreamBuilder<EarningsSnapshot>(
              stream: source.watch(uid),
              builder: (context, snap) {
                if (snap.hasError) return const EconomyMessage(title: 'Could not load statements', body: 'Check your connection and try again.');
                if (!snap.hasData) return const EconomySkeleton();
                final months = <String, List<EarningRow>>{};
                for (final r in [...snap.data!.rows, ...snap.data!.payouts]) {
                  final d = r.at;
                  months.putIfAbsent(d == null ? 'Undated' : '${d.year}-${d.month.toString().padLeft(2, '0')}', () => []).add(r);
                }
                final keys = months.keys.toList()..sort((a, b) => b.compareTo(a));
                return ListView(padding: const EdgeInsets.all(16), children: [
                  const FrostCard(title: 'Download PDF or CSV', body: 'Export files are coming soon. They will be made by our server.', next: 'Soon'),
                  const SizedBox(height: 12),
                  if (keys.isEmpty) const FrostCard(title: 'No statements yet', body: 'Your first monthly summary appears after your first sale.', next: 'OK'),
                  for (final k in keys) ...[
                    _MonthCard(month: k, rows: months[k]!),
                    const SizedBox(height: 12),
                  ],
                ]);
              },
            ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, required this.rows});
  final String month;
  final List<EarningRow> rows;

  @override
  Widget build(BuildContext context) {
    final earned = rows.where((r) => r.tab != 'payout' && r.status != 'Reversed').fold(0, (a, r) => a + r.cents);
    final paid = rows.where((r) => r.tab == 'payout' && r.status == 'Paid').fold(0, (a, r) => a + r.cents);
    return Frost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(month, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        Text('Earned ${money(earned)} · Paid out ${money(paid)} · ${rows.length} items', style: const TextStyle(color: Colors.white70)),
        for (final r in rows.take(6)) _RowTile(r),
      ]),
    );
  }
}

// ---------- First-use guide and help ----------

const _slides = <(String, String)>[
  ('Share your link', 'Send your NowssB link to friends.'),
  ('Someone buys', 'When they buy words or a plan, you earn a share.'),
  ('Money shows as Pending', 'It waits a short time in case of refunds.'),
  ('Withdraw', 'Link Wise once. Then tap Withdraw.'),
];

Future<void> showEarningsGuide(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const EarningsGuide());
}

class EarningsGuide extends StatefulWidget {
  const EarningsGuide({super.key});
  @override
  State<EarningsGuide> createState() => _EarningsGuideState();
}

class _EarningsGuideState extends State<EarningsGuide> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final last = _i == _slides.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        FrostCard(
          key: const Key('earnings.guide'),
          title: _slides[_i].$1,
          body: _slides[_i].$2,
          skip: 'Skip',
          onSkip: () => Navigator.pop(context),
          next: last ? 'Done' : 'Next',
          onNext: () => last ? Navigator.pop(context) : setState(() => _i++),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var d = 0; d < _slides.length; d++)
            Container(margin: const EdgeInsets.all(3), width: d == _i ? 18 : 7, height: 7, decoration: BoxDecoration(color: Colors.white.withValues(alpha: d == _i ? 1 : 0.4), borderRadius: BorderRadius.circular(4))),
        ]),
      ]),
    );
  }
}

const _faq = <(String, String)>[
  ('When can I withdraw?', 'When money is Available and above the minimum.'),
  ('Why is money Pending?', 'Sales wait a short hold in case of refunds.'),
  ('Who pays me?', 'Wise, our payout partner. It checks ID and tax rules for your country.'),
  ('What is Your team?', 'People who joined with your link, up to 2 levels.'),
];

Future<void> showEarningsHelp(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(12),
      child: Frost(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Help', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ListTile(key: const Key('help.statements'), leading: const Icon(Icons.receipt_long_rounded, color: Colors.white), title: const Text('Statements', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); _push(context, const EarningsStatementsPage()); }),
            ListTile(key: const Key('help.replay'), leading: const Icon(Icons.replay_rounded, color: Colors.white), title: const Text('Replay How it works', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); showEarningsGuide(context); }),
            for (final q in _faq) ExpansionTile(iconColor: Colors.white, collapsedIconColor: Colors.white70, title: Text(q.$1, style: const TextStyle(color: Colors.white)), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(q.$2, style: const TextStyle(color: Colors.white70)))]),
            ListTile(leading: const Icon(Icons.mail_outline_rounded, color: Colors.white), title: const Text('Contact support', style: TextStyle(color: Colors.white)), onTap: () => launchUrl(Uri.parse('mailto:support@nowssb.com?subject=Earnings'))),
          ]),
        ),
      ),
    ),
  );
}
