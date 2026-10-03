/// NowssB Gifts (Plan B 6): Free Gifts · Send a Gift · Received · Sent ·
/// Redeem · Rules. Free boxes are drawn by the server; gift cards are real
/// Play purchases that become NWSB codes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/layout/layout_sections.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/reward_fx.dart';
import '../gifts/gifts_screen.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../economy/economy_theme.dart';
import '../../admin/template/editable.dart';

const kGiftsDisclaimer =
    'Gifts are for the item shown and have no cash value. Free gifts must be claimed before they expire. Bought gifts are '
    'valid for 12 months and can be refunded only under Google Play\u2019s rules before they are opened. Coins cannot be gifted.';

const kGiftsSpec = ProgramSpec(
  pageId: 'gifts.program',
  title: 'NowssB Gifts',
  mark: NwsbMarks.gift,
  disclaimer: kGiftsDisclaimer,
  accent: ProgramAccent.gifts,
  tabs: [
    ProgramTab('free', 'Free Gifts', _free),
    ProgramTab('send', 'Send a Gift', _send),
    ProgramTab('received', 'Received', _received),
    ProgramTab('sent', 'Sent', _sent),
    ProgramTab('redeem', 'Redeem', _redeem),
    ProgramTab('rules', 'Rules', _rules),
  ],
);

/// Kept for every existing entry point: opens the one Gifts page.
class GiftsProgramPage extends StatelessWidget {
  const GiftsProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => GiftsScreen(
        initialTab: initialTab == null ? null : kGiftsSpec.tabs[initialTab!.clamp(0, kGiftsSpec.tabs.length - 1)].id,
      );
}

List<Widget> _free(BuildContext context, Map<String, dynamic> s) {
  final t = sMap(s['today']);
  final ladder = sList(t['ladder']);
  final q = sMap(s['quests']);
  final wg = sMap(q['weeklyGift']);
  final mg = sMap(q['monthlyGift']);
  final boxes = sList(s['boxes']);
  final passes = sList(s['passes']).where((p) => p['status'] == 'banked').toList();
  return [
    LSection('today', 'Today\u2019s box', PCard(glow: NwsbColors.gold, children: [
      PRow(
        title: t['boxOpened'] != null ? 'Today\u2019s box is open' : 'Today\u2019s free gift box',
        sub: '${sInt(t['minutes'])} minutes today. More minutes, a better box.',
        mark: NwsbMarks.gift,
        trailing: PClaim(label: 'Open', action: 'openDailyBox', enabled: t['boxOpened'] == null, title: 'Today\u2019s gift'),
      ),
      for (final st in ladder)
        PRow(
          title: '${sInt(st['minutes'])} min · ${st['box'] ?? ''} box',
          sub: '+${sInt(st['coins'])} coins',
          mark: NwsbMarks.hourglass,
          trailing: st['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimTimeStep', data: {'minutes': sInt(st['minutes'])}, enabled: st['reached'] == true, title: 'Time ladder'),
        ),
    ])),
    LSection('boxes', 'Unopened boxes', PCard(children: [
      const PHeading('Waiting for you', 'Unopened boxes', slot: 'gifts_program.free'),
      if (boxes.isEmpty) const PEmpty('No unopened boxes. Boxes come from quests, streaks, the season and the Partner Program.'),
      for (final b in boxes)
        PRow(
          title: '${b['box'] ?? 'Gift'} box'.replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase()),
          sub: 'From ${b['source'] ?? 'a reward'}${sInt(b['expiresAt']) > 0 ? ' · open by ${shortDate(b['expiresAt'])}' : ''}',
          mark: NwsbMarks.gift,
          trailing: PClaim(label: 'Open', action: 'openBox', data: {'id': b['id']}, title: 'Gift box'),
        ),
    ])),
    LSection('weekly', 'Weekly and monthly', PCard(children: [
      PRow(
        title: 'Weekly gift',
        sub: '${sInt(wg['daysAt20'])} days with 20+ minutes this week',
        mark: NwsbMarks.gift,
        trailing: wg['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimWeeklyGift', enabled: wg['ready'] == true, title: 'Weekly gift'),
      ),
      PRow(
        title: 'Monthly gift',
        sub: '${sInt(mg['activeDays'])} of ${sInt(mg['goal'])} active days',
        mark: NwsbMarks.gift,
        trailing: mg['claimed'] == true ? const PPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimMonthlyGift', enabled: sInt(mg['goal']) > 0 && sInt(mg['activeDays']) >= sInt(mg['goal']), title: 'Monthly gift'),
      ),
    ])),
    if (passes.isNotEmpty)
      LSection('passes', 'Banked passes', PCard(children: [
        const PHeading('Banked', 'Passes waiting for your plan to end', slot: 'gifts_program.free'),
        for (final p in passes) PRow(title: '${sInt(p['days'])}-day ${p['tier']} pass', sub: 'Starts on its own when your current plan ends.', mark: NwsbMarks.crown),
      ])),
  ];
}

List<Widget> _send(BuildContext context, Map<String, dynamic> s) => const [
      LSection('intro', 'Send intro', PEmpty('Pick a card, write a note, pay on Google Play. The NWSB code is created only after Play accepts the payment. Your link still earns on gift purchases.', slot: 'gifts_program.send')),
      LSection('cards', 'Gift cards', _SendPicker()),
    ];

/// Pick one gift card (real selection, no made-up progress), then write it.
class _SendPicker extends StatefulWidget {
  const _SendPicker();
  @override
  State<_SendPicker> createState() => _SendPickerState();
}

class _SendPickerState extends State<_SendPicker> {
  String? _id;

  @override
  Widget build(BuildContext context) {
    final cards = kGiftCatalog;
    final id = _id ?? (cards.isEmpty ? null : cards.first.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in cards)
          BlackOffer(
            title: c.label,
            mark: NwsbMarks.gift,
            selected: c.id == id,
            progress: c.id == id ? 1 : 0,
            line: c.id == id ? 'Selected · \u20b9${c.cents} on Google Play' : '\u20b9${c.cents} on Google Play',
            onTap: () => setState(() => _id = c.id),
          ),
        const SizedBox(height: 6),
        if (id != null) GoldButton(label: 'Write the card and pay on Play', onTap: () => showGiftCardSheet(context, id)),
      ],
    );
  }
}

List<Widget> _received(BuildContext context, Map<String, dynamic> s) {
  final rows = sList(sMap(s['gifts'])['received']);
  return [
    LSection('inbox', 'Inbox', PCard(children: [
      if (rows.isEmpty) const PEmpty('No gifts received yet. Redeem a code and it shows here.'),
      for (final g in rows)
        PRow(
          title: '${g['title'] ?? 'Gift'}${'${g['fromName'] ?? ''}'.isEmpty ? '' : ' · from ${g['fromName']}'}',
          sub: '${g['granted'] ?? ''}${'${g['message'] ?? ''}'.isEmpty ? '' : ' · “${g['message']}”'} · ${shortDate(g['at'])}',
          mark: NwsbMarks.gift,
        ),
    ])),
  ];
}

List<Widget> _sent(BuildContext context, Map<String, dynamic> s) {
  final rows = sList(sMap(s['gifts'])['sent']);
  return [
    LSection('sent', 'Sent', PCard(children: [
      if (rows.isEmpty) const PEmpty('No gifts sent yet.'),
      for (final g in rows)
        PRow(
          title: '${g['title'] ?? 'Gift'}${'${g['toName'] ?? ''}'.isEmpty ? '' : ' · to ${g['toName']}'}',
          sub: '${g['code']} · ${g['status']} · ${shortDate(g['at'])}',
          mark: NwsbMarks.gift,
          trailing: g['status'] == 'active'
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${g['code']}'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('gifts_program.shared', 'Code copied.')));
                    },
                    icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                  ),
                  PClaim(label: 'Cancel', action: 'cancelGift', data: {'code': g['code']}, filled: false),
                ])
              : null,
        ),
    ])),
  ];
}

List<Widget> _redeem(BuildContext context, Map<String, dynamic> s) => const [LSection('redeem', 'Redeem', _Redeem())];

class _Redeem extends StatefulWidget {
  const _Redeem();
  @override
  State<_Redeem> createState() => _RedeemState();
}

class _RedeemState extends State<_Redeem> {
  final _c = TextEditingController();
  var _busy = false;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _peek;
  String? _err;

  /// Step 1: look inside (nothing moves). Step 2: open it.
  Future<void> _look() async {
    setState(() {
      _busy = true;
      _err = null;
      _peek = null;
    });
    try {
      final r = await EconomyApi.call('peekGift', {'code': _c.text.trim()});
      if (mounted) setState(() => _peek = r);
    } on EconomyException catch (e) {
      if (mounted) setState(() => _err = e.message);
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('redeemGift', {'code': _c.text.trim()});
      if (!mounted) return;
      final g = r['granted'];
      unawaited(GiftBoxOpening.show(context,
          box: 'gold',
          title: '${r['title'] ?? 'A gift for you'}${'${r['fromName'] ?? ''}'.isEmpty ? '' : ' · from ${r['fromName']}'}',
          items: g is Map ? [Map<String, dynamic>.from(g)] : const []));
      _c.clear();
      setState(() => _peek = null);
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Got a code?', 'Redeem a gift', slot: 'gifts_program.redeem'),
        TextField(
          controller: _c,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.4),
          decoration: const InputDecoration(hintText: 'NWSB-XXXX-XXXX', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        const SizedBox(height: 10),
        if (_peek == null)
          TextButton(
            onPressed: _busy ? null : _look,
            style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text(_busy ? 'Looking…' : 'Preview the gift', style: const TextStyle(fontWeight: FontWeight.w800)),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66E4C56A))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_peek!['title'] ?? 'A gift'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Inside: ${_peek!['inside'] ?? ''}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
              if ('${_peek!['fromName'] ?? ''}'.isNotEmpty) Text('From ${_peek!['fromName']}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
              if ('${_peek!['message'] ?? ''}'.isNotEmpty) Text('\u201c${_peek!['message']}\u201d', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12.5)),
              if (_peek!['status'] != 'ready')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(switch ('${_peek!['status']}') {
                    'redeemed' => _peek!['mine'] == true ? 'You already opened this gift.' : 'This gift was already claimed.',
                    'later' => 'This gift opens on ${shortDate(_peek!['opensAt'])}.',
                    'expired' => 'This gift expired.',
                    _ => 'This gift is no longer active.',
                  }, style: const TextStyle(color: Color(0xFFFFA24C), fontSize: 12)),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: _busy || _peek!['status'] != 'ready' || _peek!['yours'] == true ? null : _go,
                style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(_busy ? 'Opening…' : (_peek!['yours'] == true ? 'Send this code to your friend' : 'Redeem'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => setState(() => _peek = null), child: const EditableLabel('gifts_program.Redeem', 'Back', style: TextStyle(color: Colors.white70))),
          ]),
        ],
        if (_err != null) PEmpty(_err!),
      ]);
}

List<Widget> _rules(BuildContext context, Map<String, dynamic> s) => const [
      LSection('rules', 'Gift rules', PRules([
        'Free gifts come from time spent: 10, 20, 40 and 60 minutes a day open better boxes. One free box a day.',
        'Weekly gift: 5 days with 20+ minutes. Monthly gift: 20 active days. Claim within 30 days.',
        'Gift cards are real Google Play purchases. The code is valid for 12 months; unopened cards can be cancelled within 7 days.',
        'A gifted plan pass does not count toward Earn ranks or the Partner Program. Coins cannot be gifted.',
        'If a gift card purchase is refunded, the unopened code stops working.',
      ], slot: 'gifts_program.rules')),
    ];
