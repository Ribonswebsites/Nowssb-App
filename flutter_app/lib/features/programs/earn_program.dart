/// NowssB Earn (Plan B 3): Overview · My Team · Sales · Targets and Bonuses ·
/// Payouts · Academy · Rules and Disclaimer. Commission is computed by the
/// server through the money lock on real cleared Play sales only.
library;

import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/money.dart';
import '../economy/reward_fx.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../circle/circle_screen.dart';
import 'reference_program.dart';
import '../../admin/template/editable.dart';

const kEarnDisclaimer =
    'Commission is paid only on completed, verified purchases made by other customers. Earnings depend entirely on '
    'your own sales and are not guaranteed. Most people will earn little or nothing. Ranks cannot be bought. Refunded '
    'sales are reversed. Amounts are shown in your local currency and may be adjusted for exchange rates and taxes.';

const kEarnSpec = ProgramSpec(
  pageId: 'earn.program',
  title: 'NowssB Earn',
  mark: NwsbMarks.piggy,
  disclaimer: kEarnDisclaimer,
  accent: ProgramAccent.earn,
  tabs: [
    ProgramTab('overview', 'Overview', _overview),
    ProgramTab('team', 'My Team', _team),
    ProgramTab('sales', 'Sales', _sales),
    ProgramTab('targets', 'Targets and Bonuses', _targets),
    ProgramTab('payouts', 'Payouts', _payouts),
    ProgramTab('academy', 'Academy', _academy),
    ProgramTab('rules', 'Rules and Disclaimer', _rules),
  ],
);

/// Kept for every existing entry point: opens the one Earn page.
class EarnProgramPage extends StatelessWidget {
  const EarnProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => initialTab == null
      ? const CircleScreen()
      : EarnTabsPage(tab: kEarnSpec.tabs[initialTab!.clamp(0, kEarnSpec.tabs.length - 1)].id);
}

/// Index of an Earn tab id ('sales', 'payouts'…), for [EarnProgramPage].
int earnTabIndex(String id) => kEarnSpec.tabs.indexWhere((t) => t.id == id).clamp(0, kEarnSpec.tabs.length - 1);

/// The Earn tabs opened at one tab. One Android back returns to the caller.
class EarnTabsPage extends StatelessWidget {
  const EarnTabsPage({super.key, required this.tab});
  final String tab;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF07070C),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [ProgramTabsBlock(spec: kEarnSpec, initialTab: tab, scrollTo: true, showDisclaimer: false)],
          ),
        ),
      );
}

/// Payout countries. Payouts go through a global provider (Wise / PayPal);
/// nothing here is tied to one country's ID or bank rails.
const kPayoutCountries = <(String, String)>[
  ('US', 'United States'),
  ('GB', 'United Kingdom'),
  ('CA', 'Canada'),
  ('AU', 'Australia'),
  ('IN', 'India'),
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

/// The user's payout country, or 'XX' when it is not on the list.
String defaultPayoutCountry([String? saved]) {
  final pick = (saved != null && saved.isNotEmpty) ? saved : FxBook.instance.region;
  return kPayoutCountries.any((c) => c.$1 == pick) ? pick! : 'XX';
}

/// A rough email check so Save is not offered for an obvious typo.
bool looksLikeEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

/// True when the saved payout account can receive money. Reads the server's
/// global flag and accepts the older field name.
bool payoutReady(Map<String, dynamic> acct) => acct['ready'] == true || acct['kyc'] == true;

/// A signed money amount in the user's currency ("+$1.20", "−€3.00").
String signedMoney(num v) => '${v >= 0 ? '+' : '\u2212'}${FxBook.instance.formatPrice(v.abs())}';

Widget _earn(Widget Function(BuildContext, Map<String, dynamic>, VoidCallback) b) => ServerView(action: 'earnSummary', builder: b);

const _metal = {'Bronze': Color(0xFFCD8B54), 'Silver': Color(0xFFD9DDE3), 'Gold': Color(0xFFFFC857), 'Diamond': Color(0xFF9EE7FF)};

List<Widget> _overview(BuildContext context, Map<String, dynamic> s) => [
      LSection('standing', 'Standing', _earn((context, r, _) {
        final st = sMap(r['standing']);
        final bal = sMap(r['balances']);
        final color = _metal['${st['metal']}'] ?? NwsbColors.gold;
        final words = sInt(r['words']);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (r['enabled'] == false || r['countryOk'] == false)
            const PCard(children: [PEmpty('NowssB Earn is not open in your country yet. Links, coins and gifts still work.')]),
          PCard(glow: color, children: [
            Text('${st['metal'] ?? ''}'.toUpperCase(), style: TextStyle(color: color, letterSpacing: 1.6, fontSize: 11, fontWeight: FontWeight.w800)),
            Text('${st['title'] ?? 'No rank yet'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            Text('You earn ${sNum(st['ratePct'])}% of each cleared sale after tax and store fees${sNum(st['fastStartPct']) > 0 ? ', plus ${sNum(st['fastStartPct'])}% early bonus' : ''}${st['provisional'] == true ? ' · not final yet' : ''}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
            if (st['canEarn'] != true) const PEmpty('Commission needs your own active paid plan. Sales still count toward your rank.'),
            if (st['planShort'] == true) const PEmpty('Your rank needs the top plan to pay at its full rate. You earn at the rate your plan allows.'),
            if (st['nextWords'] != null) PProgress(value: words, goal: sInt(st['nextWords']), label: '$words / ${sInt(st['nextWords'])} words to ${st['nextTitle']}'),
            Text('Last 90 days: ${sInt(r['words90'])} words sold · ${sInt(st['keep90'])} needed to keep this rank', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ]),
          PCard(children: [
            Row(children: [
              Expanded(child: _money('Pending', sNum(bal['pendingINR']), 'in the 30-day refund window')),
              Expanded(child: _money('Available', sNum(bal['availableINR']), 'ready to request')),
            ]),
            const SizedBox(height: 8),
            _money('Lifetime', sNum(bal['lifetimeINR']), 'commission and bonuses earned'),
          ]),
          if (r['sponsor'] != null) PCard(children: [PRow(title: 'Your sponsor', sub: '${sMap(r['sponsor'])['name'] ?? ''}', mark: NwsbMarks.people)]),
        ]);
      })),
    ];

Widget _money(String label, num v, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: NwsbColors.gold, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
      Text(FxBook.instance.formatPrice(v), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      EditableLabel('earn_program.shared', sub, style: const TextStyle(color: NwsbColors.mist, fontSize: 11)),
    ]);

List<Widget> _team(BuildContext context, Map<String, dynamic> s) => [
      LSection('team', 'Team', _earn((context, r, reload) {
        final team = sList(r['team']);
        final invites = sList(r['invites']);
        final sent = sList(r['sentInvites']);
        final st = sMap(r['standing']);
        final appoints = ((st['appoints'] as List?) ?? const []).map((e) => '$e').toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (invites.isNotEmpty)
            PCard(glow: NwsbColors.gold, children: [
              const PHeading('Invitations', 'You were invited to a team', slot: 'earn_program.team'),
              for (final i in invites)
                PRow(
                  title: '${i['fromName'] ?? 'Someone'} invites you as ${i['rank'] ?? 'a member'}',
                  sub: shortDate(i['at']),
                  mark: NwsbMarks.people,
                  trailing: Wrap(spacing: 6, children: [
                    PClaim(label: 'Accept', action: 'answerAppointment', data: {'id': i['id'], 'accept': true}, onDone: (_) => reload()),
                    PClaim(label: 'No', action: 'answerAppointment', data: {'id': i['id'], 'accept': false}, filled: false, onDone: (_) => reload()),
                  ]),
                ),
            ]),
          PCard(children: [
            PHeading('Team', 'My team · ${team.length} of ${sInt(st['teamMax'])}', slot: 'earn_program.team'),
            if (team.isEmpty) const PEmpty('No team yet. Officers and above can appoint people who already sell through their own links.'),
            for (final m in team)
              PRow(title: '${m['name'] ?? 'Team member'}', sub: '${m['rank'] ?? ''} · level ${sInt(m['level'])} · ${sInt(m['words'])} words (${sInt(m['words90'])} in 90 days)', mark: NwsbMarks.user),
            Text('Team share: ${((st['leg'] as List?) ?? const [0, 0]).map((e) => '$e%').join(' (level 1) / ')} (level 2) of what your team\u2019s cleared sales make after tax and store fees', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ]),
          if (appoints.isNotEmpty) _Appoint(ranks: appoints, onDone: reload),
          if (sent.isNotEmpty)
            PCard(children: [
              const PHeading('Sent', 'Invitations you sent', slot: 'earn_program.team'),
              for (final i in sent) PRow(title: '${'${i['toName'] ?? ''}'.isEmpty ? 'Invite' : i['toName']} · ${i['rank'] ?? ''}', sub: '${i['status']} · ${shortDate(i['at'])}', mark: NwsbMarks.people),
            ]),
        ]);
      })),
    ];

class _Appoint extends StatefulWidget {
  const _Appoint({required this.ranks, required this.onDone});
  final List<String> ranks;
  final VoidCallback onDone;
  @override
  State<_Appoint> createState() => _AppointState();
}

class _AppointState extends State<_Appoint> {
  final _c = TextEditingController();
  late String _rank = widget.ranks.first;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Grow the team', 'Appoint by their NowssB code', slot: 'earn_program.team'),
        TextField(
          controller: _c,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Their referral code', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        Wrap(spacing: 8, children: [
          for (final r in widget.ranks) ChoiceChip(label: Text(r), selected: _rank == r, onSelected: (_) => setState(() => _rank = r)),
        ]),
        Align(alignment: Alignment.centerLeft, child: PClaim(label: 'Send invitation', action: 'appoint', enabled: _c.text.trim().length >= 3, data: {'code': _c.text.trim(), 'rank': _rank}, onDone: (_) {
          _c.clear();
          widget.onDone();
        })),
        const PEmpty('They accept in their own app. Nobody pays to join, and appointing earns nothing by itself — only real sales do.', slot: 'earn_program.team'),
      ]);
}

String _type(String t) => switch (t) {
      'direct' => 'Your sale',
      'leg1' => 'Team share · level 1',
      'leg2' => 'Team share · level 2',
      'target' => 'Target bonus',
      'pool' => 'Monthly top pool',
      'payout' => 'Payout requested',
      'payout-return' => 'Payout returned',
      'reversal' => 'Refund reversed',
      _ => t,
    };

List<Widget> _sales(BuildContext context, Map<String, dynamic> s) => [
      LSection('ledger', 'Commission ledger', _earn((context, r, _) {
        final rows = sList(r['ledger']);
        final now = DateTime.now().millisecondsSinceEpoch;
        return PCard(children: [
          const PHeading('History', 'Sales and commission', slot: 'earn_program.sales'),
          if (rows.isEmpty) const PEmpty('No sales yet. When someone buys through your link and Google Play clears it, the sale shows here — pending for 30 days, then available.'),
          for (final x in rows)
            PRow(
              title: _type('${x['type']}'),
              sub: '${x['note'] ?? ''}${sInt(x['availableAt']) > now ? ' · available ${shortDate(x['availableAt'])}' : ''} · ${shortDate(x['at'])}',
              mark: NwsbMarks.earn,
              trailing: Text(signedMoney(sNum(x['inr'] ?? x['amount'])), style: TextStyle(color: sNum(x['inr'] ?? x['amount']) >= 0 ? NwsbColors.goldLight : const Color(0xFFFF8A8A), fontWeight: FontWeight.w800)),
            ),
        ]);
      })),
      const LSection('board', 'Leaderboard', SellersBoard()),
    ];

List<Widget> _targets(BuildContext context, Map<String, dynamic> s) => [
      LSection('targets', 'Targets', _earn((context, r, _) {
        final t = sList(r['targets']);
        final words = sInt(r['words']);
        return PCard(children: [
          const PHeading('One-time bonuses', 'Targets', slot: 'earn_program.targets'),
          if (t.isEmpty) const PEmpty('No targets are set right now.', slot: 'earn_program.targets'),
          for (final x in t)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PRow(
                title: '${sInt(x['words'])} words sold',
                sub: [
                  if (sNum(x['cashINR']) > 0) '${FxBook.instance.formatPrice(sNum(x['cashINR']))} bonus (pending 30 days)',
                  if (sInt(x['coins']) > 0) '${sInt(x['coins'])} coins',
                  if ('${x['coupon'] ?? ''}'.isNotEmpty) '${rarityTitle('${x['coupon']}')} card',
                ].join(' · '),
                mark: NwsbMarks.rewards,
                trailing: x['reached'] == true ? const PPill('Reached', color: NwsbColors.goldLight) : null,
              ),
              if (x['reached'] != true && sInt(x['words']) > 0) PProgress(value: words, goal: sInt(x['words']), label: '$words / ${sInt(x['words'])} words · ${(sInt(x['words']) - words).clamp(0, 1 << 31)} to go'),
            ]),
          const PEmpty('Bonuses land on their own when a target is crossed by cleared sales and reverse if those sales are refunded.', slot: 'earn_program.targets'),
        ]);
      })),
      LSection('ranks', 'Rank ladder', _earn((context, r, _) {
        final ranks = sList(r['ranks']);
        return PCard(children: [
          const PHeading('Ranks', 'The ladder', slot: 'earn_program.targets'),
          if (ranks.isEmpty) const PEmpty('The rank ladder did not load. Pull back and open it again.', slot: 'earn_program.targets'),
          for (final x in ranks)
            PRow(
              title: '${x['title']}',
              sub: 'From ${sInt(x['minWords'])} words sold · you earn ${sNum(x['ratePct'])}% · team ${((x['leg'] as List?) ?? const []).join('/')}% · needs ${x['plan'] == 'top' ? 'the top plan' : 'any paid plan'}',
              mark: NwsbMarks.crown,
              color: _metal['${x['metal']}'],
            ),
        ]);
      })),
    ];

List<Widget> _payouts(BuildContext context, Map<String, dynamic> s) => [
      LSection('payouts', 'Payouts', _earn((context, r, reload) {
        final bal = sMap(r['balances']);
        final acct = sMap(r['payoutAccount']);
        final ready = payoutReady(acct);
        final available = sNum(bal['availableINR']);
        final min = sNum(bal['minPayoutINR']);
        final enough = available > 0 && available >= min;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PCard(glow: NwsbColors.gold, children: [
            _money('Available', available, '${min > 0 ? 'Minimum ${FxBook.instance.formatPrice(min)} · ' : ''}paid out after a person approves it'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PClaim(label: 'Request payout', action: 'requestPayout', enabled: ready && enough, onDone: (_) => reload()),
            ),
            if (!ready)
              const PEmpty('Add your payout details below to request a payout.', slot: 'earn_program.payouts')
            else if (!enough)
              PEmpty(min > 0 ? 'You can request a payout once ${FxBook.instance.formatPrice(min)} is available.' : 'Nothing is available to pay out yet.', slot: 'earn_program.payouts'),
          ]),
          _PayoutForm(account: acct, onSaved: reload),
        ]);
      })),
    ];

class _PayoutForm extends StatefulWidget {
  const _PayoutForm({required this.account, required this.onSaved});
  final Map<String, dynamic> account;
  final VoidCallback onSaved;
  @override
  State<_PayoutForm> createState() => _PayoutFormState();
}

class _PayoutFormState extends State<_PayoutForm> {
  late final _email = TextEditingController(text: '${widget.account['email'] ?? ''}');
  late final _name = TextEditingController(text: '${widget.account['legalName'] ?? ''}');
  late String _country = defaultPayoutCountry('${widget.account['country'] ?? ''}');
  late String _method = '${widget.account['method'] ?? ''}' == 'paypal' ? 'paypal' : 'wise';
  var _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _supported => _country != 'XX';
  bool get _valid => _supported && looksLikeEmail(_email.text) && _name.text.trim().length >= 2;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('savePayoutAccount', {
        'country': _country,
        'method': _method,
        'email': _email.text.trim(),
        'legalName': _name.text.trim(),
      });
      if (!mounted) return;
      final msg = '${r['message'] ?? ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.isNotEmpty
              ? msg
              : payoutReady(r)
                  ? 'Saved. You can request payouts.'
                  : 'Saved. We will tell you if anything else is needed.')));
      widget.onSaved();
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = '${widget.account['email'] ?? ''}';
    return PCard(children: [
      const PHeading('Payout details', 'Where your money goes', slot: 'earn_program.payouts'),
      if (saved.isNotEmpty) Text('Saved: $saved', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
      DropdownButtonFormField<String>(
        key: const ValueKey('earn.payout.country'),
        initialValue: _country,
        isExpanded: true,
        dropdownColor: const Color(0xFF141820),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Payout country', labelStyle: TextStyle(color: NwsbColors.mist)),
        items: [for (final c in kPayoutCountries) DropdownMenuItem(value: c.$1, child: Text(c.$2))],
        onChanged: (v) => setState(() => _country = v ?? _country),
      ),
      if (!_supported)
        const PEmpty('Payouts are not available in your country yet. Your balance stays safe here.', slot: 'earn_program.payouts')
      else ...[
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Wise'), selected: _method == 'wise', onSelected: (_) => setState(() => _method = 'wise')),
          ChoiceChip(label: const Text('PayPal'), selected: _method == 'paypal', onSelected: (_) => setState(() => _method = 'paypal')),
        ]),
        TextField(
          key: const ValueKey('earn.payout.email'),
          controller: _email,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: _method == 'paypal' ? 'PayPal email' : 'Wise email', hintStyle: const TextStyle(color: NwsbColors.mist)),
        ),
        TextField(
          key: const ValueKey('earn.payout.name'),
          controller: _name,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_valid && !_busy) _save();
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Full legal name', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy || !_valid ? null : _save,
          style: TextButton.styleFrom(backgroundColor: _valid ? NwsbColors.goldLight : const Color(0x33E8D5A3), foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(_busy ? 'Saving…' : 'Save payout details', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
      const PEmpty('One payout account per person. Paid in your local currency where the provider supports it; taxes may apply where you live.', slot: 'earn_program.payouts'),
    ]);
  }
}

List<Widget> _academy(BuildContext context, Map<String, dynamic> s) => const [
      LSection('lessons', 'Academy', PRules([
        'Share what you use. A link for the exact word or plan you love converts better than a general link.',
        'Make a link per word, meaning or plan in Reference → Link Hub. Each one shows its opens, installs and buyers.',
        'Your friend gets a discount on their first words and plan period, so lead with that.',
        'Sales count only when Google Play clears them. They stay pending for 30 days (the refund window).',
        'Never buy through your own link or ask for fake accounts — those sales are blocked and can close your Earn account.',
        'Ranks come from words sold, not from money paid. Nobody can buy a rank.',
      ], slot: 'earn_program.academy')),
    ];

List<Widget> _rules(BuildContext context, Map<String, dynamic> s) {
  final lock = sMap(sMap(s['config'])['lock']);
  return [
    LSection('lock', 'The money lock', PRules([
      'Every sale goes through the same order: tax comes off first, then the store fee (at least ${sNum(lock['storeReservePct'])}%, the real Play fee when higher). What is left is Net.',
      'All commission together can never pass ${sNum(lock['payoutCapPct'])}% of Net; NowssB keeps at least ${sNum(lock['companyFloorPct'])}%.',
      'When the cap binds, leg 2 shrinks first, then leg 1. Your own rate is never cut.',
      'Commission waits ${sInt(lock['holdDays'])} days for refunds, then becomes available. A refund or chargeback reverses it.',
      'Renewals pay a reduced rate. Gifted passes and coins do not count toward ranks.',
    ], slot: 'earn_program.rules')),
    const LSection('blocks', 'What never counts', PRules([
      'Buying through your own link, accounts you control, the same device, the same payment or payout identity.',
      'Circular buying inside a team, or a sponsor buying for their own leg.',
      'Coins cannot be turned into cash. Coins in a cart lower the price, so they lower Net too.',
    ], slot: 'earn_program.rules')),
  ];
}
