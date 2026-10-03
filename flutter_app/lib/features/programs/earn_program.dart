/// NowssB Earn (Plan B 3): Overview · My Team · Sales · Targets and Bonuses ·
/// Payouts · Academy · Rules and Disclaimer. Commission is computed by the
/// server through the money lock on real cleared Play sales only.
library;

import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
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
  Widget build(BuildContext context) => CircleScreen(
        initialTab: initialTab == null ? null : kEarnSpec.tabs[initialTab!.clamp(0, kEarnSpec.tabs.length - 1)].id,
      );
}

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
            Text('${st['title'] ?? 'Assistant Officer'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            Text('Own rate ${sNum(st['ratePct'])}% of Net${sNum(st['fastStartPct']) > 0 ? ' + ${sNum(st['fastStartPct'])}% fast start' : ''}${st['provisional'] == true ? ' · provisional' : ''}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
            if (st['canEarn'] != true) const PEmpty('Commission needs your own active paid plan. Sales still count toward your rank.'),
            if (st['planShort'] == true) const PEmpty('Your rank needs the top plan to pay at its full rate. You earn at the rate your plan allows.'),
            if (st['nextWords'] != null) PProgress(value: words, goal: sInt(st['nextWords']), label: '$words / ${sInt(st['nextWords'])} words to ${st['nextTitle']}'),
            Text('Last 90 days: ${sInt(r['words90'])} words · keep ${sInt(st['keep90'])} to hold the rank', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ]),
          PCard(children: [
            Row(children: [
              Expanded(child: _money('Pending', sNum(bal['pendingINR']), 'in the 30-day refund window')),
              Expanded(child: _money('Available', sNum(bal['availableINR']), 'ready to request')),
            ]),
            const SizedBox(height: 8),
            _money('Lifetime', sNum(bal['lifetimeINR']), 'commission and bonuses earned'),
          ]),
          if (r['sponsor'] != null) PCard(children: [PRow(title: 'Your sponsor', sub: '${sMap(r['sponsor'])['name']}', mark: NwsbMarks.people)]),
        ]);
      })),
    ];

Widget _money(String label, num v, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: NwsbColors.gold, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
      CountUp(v, prefix: '\u20b9', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
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
                  title: '${i['fromName']} invites you as ${i['rank']}',
                  sub: shortDate(i['at']),
                  mark: NwsbMarks.people,
                  trailing: Wrap(spacing: 6, children: [
                    PClaim(label: 'Accept', action: 'answerAppointment', data: {'id': i['id'], 'accept': true}, onDone: (_) => reload()),
                    PClaim(label: 'No', action: 'answerAppointment', data: {'id': i['id'], 'accept': false}, filled: false, onDone: (_) => reload()),
                  ]),
                ),
            ]),
          PCard(children: [
            PHeading('Legs', 'My team · ${team.length} of ${sInt(st['teamMax'])}', slot: 'earn_program.team'),
            if (team.isEmpty) const PEmpty('No team yet. Officers and above can appoint people who already sell through their own links.'),
            for (final m in team)
              PRow(title: '${m['name']}', sub: '${m['rank']} · leg ${sInt(m['level'])} · ${sInt(m['words'])} words (${sInt(m['words90'])} in 90 days)', mark: NwsbMarks.user),
            Text('Leg share: ${((st['leg'] as List?) ?? const [0, 0]).map((e) => '$e%').join(' / ')} of Net on your legs\u2019 sales', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ]),
          if (appoints.isNotEmpty) _Appoint(ranks: appoints, onDone: reload),
          if (sent.isNotEmpty)
            PCard(children: [
              const PHeading('Sent', 'Invitations you sent', slot: 'earn_program.team'),
              for (final i in sent) PRow(title: '${i['toName'].toString().isEmpty ? 'Invite' : i['toName']} · ${i['rank']}', sub: '${i['status']} · ${shortDate(i['at'])}', mark: NwsbMarks.people),
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
          decoration: const InputDecoration(hintText: 'Their referral code', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        Wrap(spacing: 8, children: [
          for (final r in widget.ranks) ChoiceChip(label: Text(r), selected: _rank == r, onSelected: (_) => setState(() => _rank = r)),
        ]),
        Align(alignment: Alignment.centerLeft, child: PClaim(label: 'Send invitation', action: 'appoint', data: {'code': _c.text.trim(), 'rank': _rank}, onDone: (_) => widget.onDone())),
        const PEmpty('They accept in their own app. Nobody pays to join, and appointing earns nothing by itself — only real sales do.', slot: 'earn_program.team'),
      ]);
}

String _type(String t) => switch (t) {
      'direct' => 'Your sale',
      'leg1' => 'Leg 1 share',
      'leg2' => 'Leg 2 share',
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
          const PHeading('Append-only', 'Sales and commission', slot: 'earn_program.sales'),
          if (rows.isEmpty) const PEmpty('No sales yet. When someone buys through your link and Google Play clears it, the sale shows here — pending for 30 days, then available.'),
          for (final x in rows)
            PRow(
              title: _type('${x['type']}'),
              sub: '${x['note']}${sInt(x['availableAt']) > now ? ' · available ${shortDate(x['availableAt'])}' : ''} · ${shortDate(x['at'])}',
              mark: NwsbMarks.earn,
              trailing: Text('${sNum(x['inr']) >= 0 ? '+' : '\u2212'}\u20b9${sNum(x['inr']).abs().toStringAsFixed(2)}', style: TextStyle(color: sNum(x['inr']) >= 0 ? NwsbColors.goldLight : const Color(0xFFFF8A8A), fontWeight: FontWeight.w800)),
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
          for (final x in t)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PRow(
                title: '${sInt(x['words'])} words sold',
                sub: '\u20b9${sInt(x['cashINR'])} bonus (pending 30 days) · ${sInt(x['coins'])} coins · ${rarityTitle('${x['coupon']}')} card',
                mark: NwsbMarks.rewards,
                trailing: x['reached'] == true ? const PPill('Reached', color: NwsbColors.goldLight) : null,
              ),
              if (x['reached'] != true) PProgress(value: words, goal: sInt(x['words'])),
            ]),
          const PEmpty('Bonuses land on their own when a target is crossed by cleared sales and reverse if those sales are refunded.', slot: 'earn_program.targets'),
        ]);
      })),
      LSection('ranks', 'Rank ladder', _earn((context, r, _) {
        final ranks = sList(r['ranks']);
        return PCard(children: [
          const PHeading('Ranks', 'The ladder', slot: 'earn_program.targets'),
          for (final x in ranks)
            PRow(
              title: '${x['title']}',
              sub: 'From ${sInt(x['minWords'])} words · ${sNum(x['ratePct'])}% own rate · legs ${((x['leg'] as List?) ?? const []).join('/')}% · ${x['plan'] == 'top' ? 'top plan' : 'any plan'}',
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
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PCard(glow: NwsbColors.gold, children: [
            _money('Available', sNum(bal['availableINR']), 'Minimum \u20b9${sInt(bal['minPayoutINR'])} · paid by UPI after a person approves it'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PClaim(label: 'Request payout', action: 'requestPayout', enabled: acct['kyc'] == true && sNum(bal['availableINR']) >= sNum(bal['minPayoutINR']), onDone: (_) => reload()),
            ),
            if (acct['kyc'] != true) const PEmpty('Add your UPI id, legal name and PAN below to request a payout.'),
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
  final _upi = TextEditingController();
  late final _name = TextEditingController(text: '${widget.account['legalName'] ?? ''}');
  final _pan = TextEditingController();
  var _busy = false;
  @override
  void dispose() {
    _upi.dispose();
    _name.dispose();
    _pan.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('savePayoutAccount', {'country': 'IN', 'upi': _upi.text.trim(), 'legalName': _name.text.trim(), 'pan': _pan.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['kyc'] == true ? 'Saved. You can request payouts.' : 'Saved. Add the missing details to request payouts.')));
      widget.onSaved();
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Payout details', 'UPI account', slot: 'earn_program.payouts'),
        if ('${widget.account['upi'] ?? ''}'.isNotEmpty) Text('Saved UPI ${widget.account['upi']}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
        TextField(controller: _upi, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'name@bank', hintStyle: TextStyle(color: NwsbColors.mist))),
        TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Legal name (as on PAN)', hintStyle: TextStyle(color: NwsbColors.mist))),
        TextField(controller: _pan, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'PAN', hintStyle: TextStyle(color: NwsbColors.mist))),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : _save,
          style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(_busy ? 'Saving…' : 'Save payout details', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const PEmpty('One payout identity per person. The same UPI id or PAN cannot be used on two accounts. TDS may apply.', slot: 'earn_program.payouts'),
      ]);
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
