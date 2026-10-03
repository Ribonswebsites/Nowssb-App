/// NowssB Coupons (Plan B 5): My Coupons · Scratch · Coupon Shop · History ·
/// Rules and Odds. Cards are sealed by the server when issued; scratching
/// only uncovers what the server drew.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/play_billing.dart';
import '../economy/reward_fx.dart';
import '../economy/scratch_card.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../economy/coupon_screen.dart';
import '../../admin/template/editable.dart';

const kCouponsDisclaimer =
    'Coupon prizes are random. The odds for every coupon are shown before you buy. Paid coupons are for users aged 18 '
    'and over, may not be available in your country, and always return at least the price paid in coins or discounts. Prizes '
    'have no cash value and cannot be transferred. Set a monthly limit any time in Settings.';

const kCouponsSpec = ProgramSpec(
  pageId: 'coupons.program',
  title: 'NowssB Coupons',
  mark: NwsbMarks.coupon,
  disclaimer: kCouponsDisclaimer,
  accent: ProgramAccent.coupons,
  tabs: [
    ProgramTab('mine', 'My Coupons', _mine),
    ProgramTab('scratch', 'Scratch', _scratch),
    ProgramTab('shop', 'Coupon Shop', _shop),
    ProgramTab('history', 'History', _history),
    ProgramTab('odds', 'Rules and Odds', _odds),
  ],
);

/// Kept for every existing entry point: opens the one Coupons page
/// (CouponScreen), at tab [initialTab] when given.
class CouponsProgramPage extends StatelessWidget {
  const CouponsProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => CouponScreen(
        initialTab: initialTab == null ? null : kCouponsSpec.tabs[initialTab!.clamp(0, kCouponsSpec.tabs.length - 1)].id,
      );
}

List<Widget> _mine(BuildContext context, Map<String, dynamic> s) {
  final coupons = sList(s['coupons']);
  final tokens = sList(s['tokens']);
  final cards = sList(s['scratchCards']);
  final soon = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
  return [
    LSection('cards', 'Sealed cards', PCard(children: [
      const PHeading('Waiting to scratch', 'Your cards', slot: 'coupons_program.mine'),
      if (cards.isEmpty) const PEmpty('No sealed cards. Earn them from streaks, quests, gift boxes and purchases, or get one in the Coupon Shop.'),
      for (final r in const ['mythic', 'legendary', 'epic', 'rare', 'common'])
        if (cards.any((c) => c['rarity'] == r))
          GestureDetector(
            onTap: () => ProgramTabsScope.goTo(context, 'scratch'),
            child: PRow(title: '${rarityTitle(r)} · ${cards.where((c) => c['rarity'] == r).length}', sub: 'Open them in Scratch', mark: NwsbMarks.coupon, color: rarityColor(r), trailing: const Icon(Icons.chevron_right, color: NwsbColors.goldLight)),
          ),
    ])),
    LSection('coupons', 'Discounts', PCard(children: [
      const PHeading('Use at checkout', 'Discounts', slot: 'coupons_program.mine'),
      if (coupons.isEmpty) const PEmpty('No discounts yet.'),
      for (final c in coupons)
        PRow(
          title: '${c['label'] ?? '${sInt(c['pct'])}% off'}',
          sub: '${c['scope'] ?? 'any'} · cap ${inr(sNum(c['capINR']))}${sInt(c['expiresAt']) > 0 ? ' · until ${shortDate(c['expiresAt'])}' : ''}',
          mark: NwsbMarks.bag,
          trailing: sInt(c['expiresAt']) > 0 && sInt(c['expiresAt']) < soon ? const PPill('Expiring soon', color: Color(0xFFFFA24C)) : null,
        ),
    ])),
    LSection('tokens', 'Tokens', PCard(children: [
      const PHeading('Unlocks', 'Tokens', slot: 'coupons_program.mine'),
      if (tokens.isEmpty) const PEmpty('No tokens yet. Tokens unlock a stage, a word or a sample.'),
      for (final t in tokens) PRow(title: '${t['label'] ?? t['item']}', sub: 'From ${t['source'] ?? 'a reward'} · ${shortDate(t['at'])}', mark: NwsbMarks.stages),
    ])),
    const LSection('code', 'Enter a code', _CodeBox()),
  ];
}

/// Cards opened this session stay on screen (the summary lists only sealed
/// cards, so without this a just-scratched card would vanish mid-reveal).
final _revealedThisSession = <String, Map<String, dynamic>>{};

List<Widget> _scratch(BuildContext context, Map<String, dynamic> s) {
  final t = sMap(s['today']);
  final sealed = sList(s['scratchCards']);
  final ids = {for (final c in sealed) '${c['id']}'};
  final cards = [...sealed, for (final e in _revealedThisSession.entries) if (!ids.contains(e.key)) e.value];
  return [
    LSection('daily', 'Daily scratch', PCard(children: [
      PRow(
        title: 'Today\u2019s free scratch',
        sub: t['scratch'] == true ? 'Scratched today. A new card comes tomorrow.' : 'One free card every day.',
        mark: NwsbMarks.coupon,
        trailing: PClaim(label: t['scratch'] == true ? 'Done' : 'Get card', action: 'dailyScratch', enabled: t['scratch'] != true, title: 'Daily scratch'),
      ),
    ])),
    if (cards.isEmpty) const LSection('empty', 'No cards', PEmpty('No sealed cards right now.')),
    for (final c in cards) LSection('card_${c['id']}', 'Scratch card', Padding(padding: const EdgeInsets.only(bottom: 14), child: SealedScratch(key: ValueKey('scratch_${c['id']}'), card: c))),
  ];
}

/// One sealed card: scratch → server reveal → prize + celebration.
class SealedScratch extends StatefulWidget {
  const SealedScratch({super.key, required this.card});
  final Map<String, dynamic> card;
  @override
  State<SealedScratch> createState() => _SealedScratchState();
}

class _SealedScratchState extends State<SealedScratch> {
  Future<Map<String, dynamic>>? _reveal;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final kept = _revealedThisSession['${widget.card['id']}'];
    if (kept != null && kept['_result'] is Map<String, dynamic>) _result = kept['_result'] as Map<String, dynamic>;
  }

  void _open() {
    _reveal ??= EconomyApi.call('revealScratch', {'id': widget.card['id']}).then((r) {
      _revealedThisSession['${widget.card['id']}'] = {...widget.card, '_result': r};
      if (mounted) setState(() => _result = r);
      return r;
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e is EconomyException ? e.message : 'That did not open. Try again.');
      return <String, dynamic>{};
    });
  }

  Future<void> _cleared() async {
    _open();
    final r = await _reveal!;
    if (r.isEmpty || r['already'] == true) return;
    // "You won X" + coin fly on the root overlay: plays even if this card
    // scrolls away or the list reloads.
    unawaited(celebrate(context, r, title: '${rarityTitle('${r['rarity'] ?? widget.card['rarity'] ?? ''}')} card'));
  }

  @override
  Widget build(BuildContext context) {
    final rarity = '${widget.card['rarity'] ?? 'common'}';
    final paid = widget.card['paid'] == true;
    if (_result != null && _reveal == null) {
      // Opened earlier this session: show it open, not sealed again.
      return PCard(glow: rarityColor(rarity), children: [
        PRow(title: '${_result!['label'] ?? 'Prize'}', sub: '${rarityTitle(rarity)} · scratched · on your account', mark: NwsbMarks.coupon, color: rarityColor(rarity)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text(rarityTitle(rarity).toUpperCase(), style: TextStyle(color: rarityColor(rarity), letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text('${paid ? 'Paid' : 'Free'} · from ${widget.card['source'] ?? 'a reward'}', style: const TextStyle(color: NwsbColors.mist, fontSize: 11)),
      ]),
      const SizedBox(height: 6),
      NwsbScratchCard(
        height: 170,
        rarity: rarity,
        onFirstTouch: _open,
        onCleared: _cleared,
        prize: _result == null
            ? (_error != null
                ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)))
                : const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: NwsbColors.goldLight)))
            : Column(mainAxisSize: MainAxisSize.min, children: [
                EditableImage.asset('assets/icons/nwsb-coin.webp', width: 40, height: 40, errorBuilder: (_, __, ___) => const SizedBox(), slot: 'coupons_program.SealedScratch'),
                const SizedBox(height: 6),
                Text('${_result!['label'] ?? 'Prize'}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                Text('${rarityTitle('${_result!['rarity'] ?? rarity}')} · on your account', style: TextStyle(color: rarityColor('${_result!['rarity'] ?? rarity}'), fontSize: 12)),
              ]),
      ),
    ]);
  }
}

List<Widget> _shop(BuildContext context, Map<String, dynamic> s) {
  final odds = sMap(sMap(s['config'])['odds']);
  final paid = sList(odds['paid']);
  final coins = sInt(sMap(s['wallet'])['coins']);
  return [
    const LSection('note', 'Shop note', PEmpty('Every paid card returns at least its price in coins or discounts. Odds are listed on each card. 18+ only.', slot: 'coupons_program.shop')),
    for (final c in paid)
      LSection('card_${c['id']}', '${c['title']}', PCard(glow: rarityColor('${c['id']}'), children: [
        EditableLabel('coupons_program.shared', 'PAID CARD', style: TextStyle(color: rarityColor('${c['id']}').withValues(alpha: 0.8), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text('${c['title']}', style: TextStyle(color: rarityColor('${c['id']}'), fontSize: 18, fontWeight: FontWeight.w800))),
          Text(inr(sNum(c['priceINR'])), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
        Text('Rarest prize: ${c['rarest'] ?? ''}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
        const SizedBox(height: 6),
        for (final o in sList(c['odds']))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text('${o['label']}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Text('${sNum(o['pct'])}%', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _PaidBuy(cardId: '${c['id']}'),
          if (sInt(c['coinPrice']) > 0)
            _PaidBuy(cardId: '${c['id']}', coinPrice: sInt(c['coinPrice']), enabled: coins >= sInt(c['coinPrice']), title: '${c['title']}'),
        ]),
      ])),
  ];
}

class _PaidBuy extends StatefulWidget {
  const _PaidBuy({required this.cardId, this.coinPrice = 0, this.enabled = true, this.title});
  final String cardId;

  /// > 0: buys the card with coins (same 18+ / country / monthly checks as
  /// Google Play) instead of opening the Play sheet.
  final int coinPrice;
  final bool enabled;
  final String? title;
  @override
  State<_PaidBuy> createState() => _PaidBuyState();
}

class _PaidBuyState extends State<_PaidBuy> {
  var _busy = false;

  Future<void> _buy({bool adult = false}) async {
    setState(() => _busy = true);
    try {
      if (widget.coinPrice > 0) {
        final r = await EconomyApi.call('buyScratchWithCoins', {'cardId': widget.cardId, if (adult) 'adult': true});
        if (mounted) await celebrate(context, r, title: widget.title ?? 'Your card is ready in Scratch');
        await EconomyMirror.instance.refresh();
        return;
      }
      final r = await PlayCheckout.purchase({'kind': 'scratch', 'cardId': widget.cardId, if (adult) 'adult': true});
      if (!mounted) return;
      unawaited(celebrate(context, r, title: 'Your card is ready in Scratch'));
      ProgramTabsScope.goTo(context, 'scratch');
      await EconomyMirror.instance.refresh();
    } on EconomyException catch (e) {
      if (e.extra['needsAdult'] == true && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const EditableLabel('coupons_program.PaidBuy', 'Are you 18 or over?', style: TextStyle(color: Colors.white)),
            content: const EditableLabel('coupons_program.PaidBuy', 'Paid scratch cards are for adults only. Free cards stay open to everyone.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const EditableLabel('coupons_program.PaidBuy', 'No')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const EditableLabel('coupons_program.PaidBuy', 'I am 18+')),
            ],
          ),
        );
        if (ok == true && mounted) {
          setState(() => _busy = false);
          return _buy(adult: true);
        }
      } else if (mounted) {
        showEconomyError(context, e);
      }
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coinPrice > 0) {
      final on = widget.enabled && !_busy;
      return TextButton(
        onPressed: on ? _buy : null,
        style: TextButton.styleFrom(
          foregroundColor: NwsbColors.goldLight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: const BorderSide(color: Color(0x66E8D5A3))),
        ),
        child: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: NwsbColors.goldLight))
            : Text('${widget.coinPrice} coins', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
    }
    return TextButton(
        onPressed: _busy ? null : _buy,
        style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 14)),
        child: Text(_busy ? 'Waiting for Play…' : 'Buy on Play', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
  }
}

final _historyStreams = <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};

List<Widget> _history(BuildContext context, Map<String, dynamic> s) {
  final uid = EconomyMirror.instance.uid;
  return [
    LSection('revealed', 'Revealed cards', PCard(children: [
      const PHeading('Scratched', 'History', slot: 'coupons_program.history'),
      if (!NwsbFirebase.ready || uid == null)
        const PEmpty('Sign in to see your history.')
      else
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // One stream per account, so a rebuild never re-subscribes (no loader flash).
          stream: _historyStreams.putIfAbsent(uid, () => FirebaseFirestore.instance.collection('users/$uid/scratchCards').where('status', isEqualTo: 'revealed').limit(60).snapshots()),
          builder: (context, snap) {
            final docs = [...?snap.data?.docs]..sort((a, b) => sInt(b.data()['revealedAt'] ?? b.data()['at']).compareTo(sInt(a.data()['revealedAt'] ?? a.data()['at'])));
            if (docs.isEmpty) return const PEmpty('Nothing scratched yet.');
            return Column(children: [
              for (final d in docs)
                PRow(
                  title: '${d.data()['label'] ?? 'Prize'}',
                  sub: '${rarityTitle('${d.data()['rarity'] ?? ''}')} · ${shortDate(d.data()['revealedAt'] ?? d.data()['at'])}',
                  mark: NwsbMarks.coupon,
                  color: rarityColor('${d.data()['rarity'] ?? ''}'),
                ),
            ]);
          },
        ),
    ])),
  ];
}

List<Widget> _odds(BuildContext context, Map<String, dynamic> s) {
  final odds = sMap(sMap(s['config'])['odds']);
  final free = sMap(odds['free']);
  final daily = sList(odds['daily']);
  final after = sList(odds['afterPurchase']);
  final afterSub = sMap(odds['afterSubscription']);
  final spin = sList(odds['spin']);
  Widget table(String title, List<Map<String, dynamic>> rows) => PCard(children: [
        EditableLabel('coupons_program.shared', title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        for (final o in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text('${o['label']}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Text('${sNum(o['pct'])}%', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]);
  return [
    const LSection('rules', 'Rules', PRules([
      'Every card is sealed by the server when it is issued. Scratching only shows what was drawn.',
      'Free cards expire after 30 days. Discounts expire after 30 days and apply before coins at checkout.',
      'Paid cards are 18+, have a monthly limit, and always return at least their price in coins or discounts.',
      'Prizes have no cash value and cannot be transferred or sold.',
    ], slot: 'coupons_program.odds')),
    LSection('daily', 'Daily scratch odds', table('Daily free scratch', daily)),
    for (final e in free.entries) LSection('free_${e.key}', '${rarityTitle(e.key)} odds', table('${rarityTitle(e.key)} free card', sList(e.value))),
    LSection('after', 'After a purchase', PCard(children: [
      const EditableLabel('coupons_program.shared', 'Rarity of the free card after a purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      for (final b in after)
        Text('Up to ${sNum(b['maxINR']) > 1e9 ? 'any amount' : inr(sNum(b['maxINR']))}: ${sMap(b['odds']).entries.map((e) => '${rarityTitle(e.key)} ${e.value}%').join(' · ')}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
      Text('Subscriptions: ${afterSub.entries.map((e) => '${rarityTitle(e.key)} ${e.value}%').join(' · ')}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
    ])),
    LSection('spin', 'Daily Spin odds', table('Daily Spin', spin)),
  ];
}

class _CodeBox extends StatefulWidget {
  const _CodeBox();
  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  final _c = TextEditingController();
  String? _note;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Have a code?', 'Claim a coupon code', slot: 'coupons_program.mine'),
        TextField(
          controller: _c,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'NWSB-…', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: PClaim(
            label: 'Claim',
            action: 'claimTicket',
            data: {'code': _c.text.trim()},
            title: 'Coupon',
            onDone: (r) => setState(() => _note = r['locked'] == true || r['action'] != null ? '${r['label']}: ${r['how']}' : r['win'] == false ? 'No win this time (${r['winPct']}% chance).' : '${r['label'] ?? 'Claimed'} is on your account.'),
          ),
        ),
        if (_note != null) PEmpty(_note!),
      ]);
}
