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
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/app_thinking_loader.dart';
import '../coupons/coupon_home_style.dart';
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
    ProgramTab('expired', 'Expired', _expired),
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
    LSection('today', 'Today\u2019s box', HomeDarkSection(margin: EdgeInsets.zero, children: [
      _GRow(
        title: t['boxOpened'] != null ? 'Today\u2019s box is open' : 'Today\u2019s free gift box',
        sub: '${sInt(t['minutes'])} minutes today. More minutes, a better box.',
        mark: NwsbMarks.gift,
        trailing: PClaim(label: 'Open', action: 'openDailyBox', enabled: t['boxOpened'] == null, title: 'Today\u2019s gift'),
      ),
      for (final st in ladder)
        _GRow(
          title: '${sInt(st['minutes'])} min · ${st['box'] ?? ''} box',
          sub: '+${sInt(st['coins'])} coins',
          mark: NwsbMarks.hourglass,
          trailing: st['claimed'] == true ? const _GPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimTimeStep', data: {'minutes': sInt(st['minutes'])}, enabled: st['reached'] == true, title: 'Time ladder'),
        ),
    ])),
    LSection('boxes', 'Unopened boxes', HomeDarkSection(margin: EdgeInsets.zero, children: [
      const PHeading('Waiting for you', 'Unopened boxes', slot: 'gifts_program.free'),
      if (boxes.isEmpty) const _GEmpty('No unopened boxes. Boxes come from quests, streaks, the season and the Partner Program.'),
      for (final b in boxes)
        _GRow(
          title: '${b['box'] ?? 'Gift'} box'.replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase()),
          sub: 'From ${b['source'] ?? 'a reward'}${sInt(b['expiresAt']) > 0 ? ' · open by ${shortDate(b['expiresAt'])}' : ''}',
          mark: NwsbMarks.gift,
          trailing: PClaim(label: 'Open', action: 'openBox', data: {'id': b['id']}, title: 'Gift box'),
        ),
    ])),
    LSection('weekly', 'Weekly and monthly', HomeDarkSection(margin: EdgeInsets.zero, children: [
      _GRow(
        title: 'Weekly gift',
        sub: '${sInt(wg['daysAt20'])} days with 20+ minutes this week',
        mark: NwsbMarks.gift,
        trailing: wg['claimed'] == true ? const _GPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimWeeklyGift', enabled: wg['ready'] == true, title: 'Weekly gift'),
      ),
      _GRow(
        title: 'Monthly gift',
        sub: '${sInt(mg['activeDays'])} of ${sInt(mg['goal'])} active days',
        mark: NwsbMarks.gift,
        trailing: mg['claimed'] == true ? const _GPill('Claimed', color: NwsbColors.goldLight) : PClaim(label: 'Claim', action: 'claimMonthlyGift', enabled: sInt(mg['goal']) > 0 && sInt(mg['activeDays']) >= sInt(mg['goal']), title: 'Monthly gift'),
      ),
    ])),
    if (passes.isNotEmpty)
      LSection('passes', 'Banked passes', HomeDarkSection(margin: EdgeInsets.zero, children: [
        const PHeading('Banked', 'Passes waiting for your plan to end', slot: 'gifts_program.free'),
        for (final p in passes) _GRow(title: '${sInt(p['days'])}-day ${p['tier']} pass', sub: 'Starts on its own when your current plan ends.', mark: NwsbMarks.crown),
      ])),
  ];
}

List<Widget> _send(BuildContext context, Map<String, dynamic> s) => const [
      LSection('intro', 'Send intro', HomeHeaderBox(icon: Icons.card_giftcard, title: 'Send a gift', subtitle: 'Pick a card, write a note, pay on Google Play. The NWSB code is created only after Play accepts the payment. Your link still earns on gift purchases.')),
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
        for (final (i, c) in cards.indexed)
          GiftSplitCard(
            key: ValueKey('giftcard-${c.id}'),
            index: i,
            title: '${c.label}\n${c.id == id ? 'Selected' : 'Price on Google Play'}',
            cta: c.id == id ? 'Write the card' : 'Choose',
            onTap: () => c.id == id ? showGiftCardSheet(context, c.id) : setState(() => _id = c.id),
          ),
        const SizedBox(height: 6),
        if (id != null) GoldButton(label: 'Write the card and pay on Play', onTap: () => showGiftCardSheet(context, id)),
      ],
    );
  }
}

List<Widget> _received(BuildContext context, Map<String, dynamic> s) {
  final rows = sList(sMap(s['gifts'])['received']).where((g) => g['status'] != 'expired').toList();
  return [
    LSection('inbox', 'Inbox', HomeDarkSection(margin: EdgeInsets.zero, children: [
      if (rows.isEmpty) const _GEmpty('No gifts received yet. Redeem a code and it shows here.'),
      for (final g in rows)
        _GRow(
          title: '${g['title'] ?? 'Gift'}${'${g['fromName'] ?? ''}'.isEmpty ? '' : ' · from ${g['fromName']}'}',
          sub: '${g['granted'] ?? ''}${'${g['message'] ?? ''}'.isEmpty ? '' : ' · “${g['message']}”'} · ${shortDate(g['at'])}',
          mark: NwsbMarks.gift,
        ),
    ])),
  ];
}

List<Widget> _sent(BuildContext context, Map<String, dynamic> s) {
  final rows = sList(sMap(s['gifts'])['sent']).where((g) => g['status'] != 'expired').toList();
  return [
    LSection('sent', 'Sent', HomeDarkSection(margin: EdgeInsets.zero, children: [
      if (rows.isEmpty) const _GEmpty('No gifts sent yet.'),
      for (final g in rows)
        _GRow(
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

List<Widget> _expired(BuildContext context, Map<String, dynamic> s) {
  final g = sMap(s['gifts']);
  final rows = [
    for (final r in sList(g['received'])) if (r['status'] == 'expired') ('Received', r),
    for (final r in sList(g['sent'])) if (r['status'] == 'expired') ('Sent', r),
  ];
  return [
    LSection('expired', 'Expired', HomeDarkSection(margin: EdgeInsets.zero, children: [
      if (rows.isEmpty) const _GEmpty('Nothing has expired. Open free boxes and redeem codes before their date.'),
      for (final (dir, r) in rows)
        _GRow(
          title: '${r['title'] ?? 'Gift'}',
          sub: '$dir · expired${sInt(r['expiresAt']) > 0 ? ' ${shortDate(r['expiresAt'])}' : ''}',
          mark: NwsbMarks.gift,
          trailing: const _GPill('Expired', color: NwsbColors.mist),
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
  Widget build(BuildContext context) => HomeDarkSection(margin: EdgeInsets.zero, children: [
        const PHeading('Got a code?', 'Redeem a gift', slot: 'gifts_program.redeem'),
        TextField(
          controller: _c,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.4),
          decoration: InputDecoration(
            hintText: 'NWSB-XXXX-XXXX',
            hintStyle: const TextStyle(color: kHomeGrey),
            prefixIcon: const Icon(Icons.redeem, color: kHomeGold, size: 18),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x24FFFFFF))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kHomeGold)),
          ),
        ),
        const SizedBox(height: 10),
        if (_peek == null)
          Align(alignment: Alignment.centerRight, child: HomeEnterPill(key: const Key('gift_preview'), label: _busy ? 'Looking…' : 'Preview the gift', onTap: _busy ? null : _look))
        else ...[
          HomeBlackBox(
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
            TextButton(onPressed: () => setState(() => _peek = null), child: const EditableLabel('gifts_program.Redeem', 'Back', style: TextStyle(color: kHomeGrey))),
            const Spacer(),
            Flexible(
              child: GiftRedeemPill(
                label: _busy ? 'Opening…' : (_peek!['yours'] == true ? 'Send this code to your friend' : 'Redeem'),
                onTap: _busy || _peek!['status'] != 'ready' || _peek!['yours'] == true ? null : _go,
              ),
            ),
          ]),
        ],
        if (_err != null) _GEmpty(_err!),
        if (_peek == null && _err == null) const _GEmpty('Codes look like NWSB-XXXX-XXXX. Nothing is used until you tap Redeem.'),
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


/// Gifts-local row in Home's style: purple-dot timeline, uppercase title,
/// grey subtitle, thin divider. Same arguments as the kit's PRow.
class _GRow extends StatelessWidget {
  // ignore: unused_element_parameter
  const _GRow({required this.title, this.sub, this.trailing, this.mark});
  final String title;
  final String? sub;
  final Widget? trailing;
  final String? mark;
  @override
  Widget build(BuildContext context) => HomeBlackBox(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: HomeTimelineRow(title: title, subtitle: sub ?? '', trailing: trailing, last: true),
      );
}

class _GEmpty extends StatelessWidget {
  // ignore: unused_element_parameter
  const _GEmpty(this.text, {this.slot});
  final String text;
  final String? slot;
  @override
  Widget build(BuildContext context) => HomeBlackBox(
        child: Row(children: [
          homeRoundIcon(Icons.card_giftcard, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: kHomeGrey, fontSize: 12.5, height: 1.4))),
        ]),
      );
}

class _GPill extends StatelessWidget {
  // ignore: unused_element_parameter
  const _GPill(this.text, {this.color = kHomeGold});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.7))),
        child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
      );
}

/// Gifts' own tab block in Home's style: gold/dark-glass chips, Home sign-in
/// row, then the selected tab. Other pages keep the kit's ProgramTabsBlock.
class GiftsTabsBlock extends StatefulWidget {
  const GiftsTabsBlock({super.key, this.initialTab, this.signedInForTest = false});
  final String? initialTab;
  @visibleForTesting
  final bool signedInForTest;
  @override
  State<GiftsTabsBlock> createState() => _GiftsTabsBlockState();
}

class _GiftsTabsBlockState extends State<GiftsTabsBlock> {
  late int _tab = kGiftsSpec.indexOf(widget.initialTab).clamp(0, kGiftsSpec.tabs.length - 1);
  var _loading = false;

  @override
  void initState() {
    super.initState();
    if (EconomyMirror.instance.summary.isEmpty && !widget.signedInForTest) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await EconomyMirror.instance.refresh();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(String id) {
    final i = kGiftsSpec.indexOf(id);
    if (i >= 0) setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = kGiftsSpec.tabs;
    return ProgramTabsScope(
      go: _go,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final on = i == _tab;
              return GestureDetector(
                key: Key('gifts_tab_${tabs[i].id}'),
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? kHomeGold : const Color(0x8C000000),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: on ? kHomeGold : const Color(0x24FFFFFF)),
                  ),
                  child: Text(tabs[i].title, style: TextStyle(color: on ? NwsbColors.ink : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: EconomyMirror.instance,
          builder: (context, _) {
            final m = EconomyMirror.instance;
            if (m.uid == null && !widget.signedInForTest) {
              return HomeActionRow(icon: Icons.person_outline, eyebrow: 'Your gifts live on your account', title: 'Sign in', onTap: () => NwsbSignInPage.open(context), pill: HomeEnterPill(label: 'Sign in', onTap: () => NwsbSignInPage.open(context)));
            }
            if (m.summary.isEmpty && _loading) {
              return const Padding(padding: EdgeInsets.all(40), child: Center(child: AppThinkingLoader(label: 'Opening your gifts…')));
            }
            final kids = layoutChildren(context, '${kGiftsSpec.pageId}.${tabs[_tab].id}', tabs[_tab].build(context, m.summary));
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(height: 10), kids[i]],
            ]);
          },
        ),
      ]),
    );
  }
}


/// Redeem's cream pill. Long labels scale down so it never overflows.
class GiftRedeemPill extends StatelessWidget {
  const GiftRedeemPill({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: HomeShopPill(key: const Key('gift_redeem'), icon: Icons.redeem, label: label, onTap: onTap),
        ),
      );
}
