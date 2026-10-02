/// Earn & Gifts — the manual UPI payout queue, the referral network, gift
/// card codes, coupons and every reward number. All numbers live in ONE
/// settings doc, `config/economy`, versioned with history in
/// `configHistory`, so they change without an app update. Starting values
/// are the plan PDFs' (NowssB Plan · Earn · Rewards · Gifts · Coupons).
/// Payouts are approved by a person here first ("launch mode"); there is no
/// card/wallet gateway — UPI transfers are made by hand and the UTR is
/// recorded.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_data.dart';
import 'admin_kit.dart';
import 'config_store.dart';
import 'person_admin.dart';

/// Starting values from the plan PDFs. Used only to fill an empty
/// config/economy the first time it is saved; the doc is the source.
const Map<String, dynamic> kEconomyDefaults = {
  'payouts': {'minCents': 1500, 'capPct': 65, 'holdDays': 30, 'payoutDay': 10, 'autoApprove': false, 'rails': ['upi']},
  'coins': {'dailyCeiling': 250, 'expiryMonths': 12, 'coinsPerRupee': 10, 'loginMin': 5, 'loginMax': 15, 'practiceRing': 25},
  'ranks': [
    {'name': 'Assistant Officer', 'minUnits': 0, 'ratePct': 15, 'leg1Pct': 0, 'leg2Pct': 0, 'coinsPerSale': 5, 'team': 0},
    {'name': 'Officer', 'minUnits': 100, 'ratePct': 22, 'leg1Pct': 3, 'leg2Pct': 0, 'coinsPerSale': 8, 'team': 5},
    {'name': 'Executive Officer I', 'minUnits': 500, 'ratePct': 30, 'leg1Pct': 5, 'leg2Pct': 1.5, 'coinsPerSale': 12, 'team': 10},
    {'name': 'Executive Officer II', 'minUnits': 1000, 'ratePct': 38, 'leg1Pct': 5, 'leg2Pct': 1.5, 'coinsPerSale': 12, 'team': 10},
    {'name': 'Partner I', 'minUnits': 2000, 'ratePct': 45, 'leg1Pct': 7, 'leg2Pct': 3, 'coinsPerSale': 20, 'team': 25},
    {'name': 'Partner II', 'minUnits': 3000, 'ratePct': 50, 'leg1Pct': 7, 'leg2Pct': 3, 'coinsPerSale': 20, 'team': 25},
  ],
  'fastStart': {'bonusPct': 5, 'days': 30},
  'topPool': {'pct': 1, 'top': 20},
  'scratch': [
    {'rarity': 'common', 'weight': 7000, 'coins': 5},
    {'rarity': 'uncommon', 'weight': 2000, 'coins': 15},
    {'rarity': 'rare', 'weight': 800, 'coins': 40},
    {'rarity': 'epic', 'weight': 200, 'coins': 100},
  ],
  'coupons': {'freeExpiryDays': 30, 'paidEnabled': false, 'paidMinAge': 18},
  'gifts': {'codeExpiryDays': 180, 'boughtValidMonths': 12, 'perDayLimit': 10, 'coolingOffDays': 7},
  'earnEnabled': true,
  'giftsEnabled': true,
  'couponsEnabled': true,
};

class EarnAdminScreen extends StatefulWidget {
  const EarnAdminScreen({super.key});
  @override
  State<EarnAdminScreen> createState() => _EarnAdminScreenState();
}

class _EarnAdminScreenState extends State<EarnAdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  Map<String, dynamic>? _d;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _err = null);
    try {
      final d = await AdminData.run('earn');
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  List<Map> _l(String k) => ((_d?[k] as List?) ?? const []).cast<Map>();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Money & rewards',
      title: 'Earn & Gifts',
      actions: [IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: kGold))],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: kGold,
        labelColor: kGold,
        unselectedLabelColor: kDim,
        dividerColor: Colors.transparent,
        onTap: (_) => tapFeel(),
        tabs: const [Tab(text: 'Payouts'), Tab(text: 'Network'), Tab(text: 'Gift codes'), Tab(text: 'Coupons'), Tab(text: 'Settings')],
      ),
      body: _d == null
          ? (_err != null ? AdminProblem(error: _err!, onRetry: _load) : const OrbLoading(label: 'Opening the books…', state: OrbState.solving))
          : TabBarView(controller: _tabs, children: [
              _Payouts(rows: _l('payouts'), onChanged: _load),
              _Network(d: _d!),
              _GiftCodes(rows: _l('gifts'), onChanged: _load),
              _Coupons(rows: _l('coupons')),
              const _EconomySettings(),
            ]),
    );
  }
}

/* ─────────────── Payouts ─────────────── */

class _Payouts extends StatefulWidget {
  const _Payouts({required this.rows, required this.onChanged});
  final List<Map> rows;
  final VoidCallback onChanged;
  @override
  State<_Payouts> createState() => _PayoutsState();
}

class _PayoutsState extends State<_Payouts> {
  String _f = 'open';
  String? _busy;

  Future<void> _decide(Map p, String decision) async {
    final id = '${p['id']}';
    String note = '';
    String utr = '';
    if (decision == 'paid') {
      final c = TextEditingController();
      final r = await showDialog<String>(
        context: context,
        builder: (ctx) => Theme(
          data: adminTheme(),
          child: AlertDialog(
            title: Text('Paid ${usd(p['amountBase'] as num? ?? 0)} to ${p['upi'] ?? 'UPI'}?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            content: TextField(controller: c, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'UPI reference (UTR)')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk), onPressed: () => c.text.trim().isEmpty ? null : Navigator.pop(ctx, c.text.trim()), child: const Text('Mark paid')),
            ],
          ),
        ),
      );
      if (r == null) return;
      utr = r;
    } else if (decision == 'reject') {
      final r = await askReason(context, 'Reject and return the balance?', hint: 'Why (they will see this)', yes: 'Reject');
      if (r == null) return;
      note = r;
    } else {
      final ok = await confirmAction(context, 'Approve this payout?', '${usd(p['amountBase'] as num? ?? 0)} to ${p['upi'] ?? '—'}. You send the UPI transfer, then mark it paid with the UTR.', yes: 'Approve');
      if (!ok) return;
    }
    if (!mounted) return;
    setState(() => _busy = id);
    final r = await runAdmin(context, 'payout-decide', {'id': id, 'decision': decision, 'note': note, 'utr': utr}, ok: 'Payout $decision.');
    if (mounted) setState(() => _busy = null);
    if (r != null) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final open = const ['pending_review', 'queued', 'approved'];
    final rows = widget.rows.where((p) => _f == 'all' || (_f == 'open' ? open.contains(p['status']) : p['status'] == _f)).toList();
    final waiting = widget.rows.where((p) => open.contains(p['status'])).fold<num>(0, (a, p) => a + (p['amountBase'] as num? ?? 0));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 60), children: [
      TileGrid(children: [
        StatTile(label: 'Waiting', value: '${widget.rows.where((p) => open.contains(p['status'])).length}', sub: usd(waiting), icon: Icons.hourglass_top_rounded, color: kAmber),
        StatTile(label: 'Paid', value: '${widget.rows.where((p) => p['status'] == 'paid').length}', sub: 'of the latest ${widget.rows.length}', icon: Icons.verified_rounded, color: kMint),
      ]),
      SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in const {'open': 'Open', 'approved': 'Approved', 'paid': 'Paid', 'rejected': 'Rejected', 'all': 'All'}.entries)
            Padding(padding: const EdgeInsets.only(right: 6), child: Pill(f.value, dense: true, selected: _f == f.key, onTap: () => setState(() => _f = f.key))),
        ]),
      ),
      const SizedBox(height: 10),
      if (rows.isEmpty) const EmptyNote('No payout requests here.', icon: Icons.account_balance_wallet_outlined),
      for (final p in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Glass(
            radius: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(usd(p['amountBase'] as num? ?? 0), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text('${p['currency'] ?? 'USD'}', style: const TextStyle(color: kDim, fontSize: 11)),
                const Spacer(),
                Tag('${p['status'] ?? ''}', color: p['status'] == 'paid' ? kMint : (p['status'] == 'rejected' ? kRose : kAmber)),
              ]),
              const SizedBox(height: 6),
              KV('UPI', '${p['upi'] ?? ''}', selectable: true),
              KV('Country', '${p['country'] ?? ''} · ${p['rail'] ?? ''}'),
              KV('Asked', fmtDate(p['at'], time: true)),
              if ('${p['utr'] ?? ''}'.isNotEmpty) KV('UTR', '${p['utr']}', selectable: true),
              if ('${p['note'] ?? ''}'.isNotEmpty) KV('Note', '${p['note']}'),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Pill('Person', icon: Icons.person_rounded, dense: true, onTap: () => pushAdmin(context, PersonAdminScreen(uid: '${p['uid']}'))),
                if ('${p['upi'] ?? ''}'.isNotEmpty)
                  Pill('Copy UPI', icon: Icons.copy_rounded, dense: true, onTap: () {
                    Clipboard.setData(ClipboardData(text: '${p['upi']}'));
                    adminSnack(context, 'UPI id copied.');
                  }),
                if (_busy == p['id']) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kGold)),
                if (_busy != p['id'] && (p['status'] == 'pending_review' || p['status'] == 'queued'))
                  Pill('Approve', icon: Icons.check_rounded, dense: true, color: kMint, selected: true, onTap: () => _decide(p, 'approve')),
                if (_busy != p['id'] && open.contains(p['status'])) Pill('Mark paid', icon: Icons.payments_rounded, dense: true, color: kGold, onTap: () => _decide(p, 'paid')),
                if (_busy != p['id'] && open.contains(p['status'])) Pill('Reject', icon: Icons.close_rounded, dense: true, color: kRose, onTap: () => _decide(p, 'reject')),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

/* ─────────────── Network ─────────────── */

class _Network extends StatefulWidget {
  const _Network({required this.d});
  final Map<String, dynamic> d;
  @override
  State<_Network> createState() => _NetworkState();
}

class _NetworkState extends State<_Network> {
  final _uid = TextEditingController();
  @override
  void dispose() {
    _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = (widget.d['network'] as Map?) ?? const {};
    final top = ((n['top'] as List?) ?? const []).cast<Map>();
    final led = ((widget.d['referralLedger'] as List?) ?? const []).cast<Map>();
    final partner = ((widget.d['partner'] as List?) ?? const []).cast<Map>();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 60), children: [
      TileGrid(columns: 3, children: [
        StatTile(label: 'Referrals', value: fmtNum(n['referrals'] as num?), icon: Icons.group_add_rounded),
        StatTile(label: 'Referrers', value: fmtNum(n['referrers'] as num?), icon: Icons.campaign_rounded, color: kSky),
        StatTile(label: 'Subscribed', value: fmtNum(n['subscribed'] as num?), icon: Icons.workspace_premium_rounded, color: kMint),
      ]),
      Row(children: [
        Expanded(child: TextField(controller: _uid, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Look up a network by user id'))),
        const SizedBox(width: 8),
        GoldButton('Open', icon: Icons.account_tree_rounded, onTap: () {
          if (_uid.text.trim().isEmpty) return;
          pushAdmin(context, NetworkScreen(uid: _uid.text.trim()));
        }),
      ]),
      const SectionHead('Leaders', 'Top referrers'),
      if (top.isEmpty) const EmptyNote('No referrals recorded yet.'),
      for (final t in top)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(10),
            onTap: () => pushAdmin(context, NetworkScreen(uid: '${t['uid']}')),
            child: Row(children: [
              Avatar(name: '${t['name'] ?? t['email'] ?? ''}', size: 34),
              const SizedBox(width: 10),
              Expanded(child: Text('${'${t['name'] ?? ''}'.isNotEmpty ? t['name'] : ('${t['email'] ?? ''}'.isNotEmpty ? t['email'] : t['uid'])}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13))),
              Text('${t['invited']} invited · ${t['subscribed']} subscribed', style: const TextStyle(color: kDim, fontSize: 11)),
            ]),
          ),
        ),
      const SectionHead('Ledger', 'Referral & partner rewards'),
      if (led.isEmpty && partner.isEmpty) const EmptyNote('No referral or partner ledger rows yet.'),
      for (final r in [...led, ...partner].take(60))
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${fmtDate(r['at'], time: true)} · ${r['reason'] ?? r['kind'] ?? r['type'] ?? ''} · ${r['referrerUid'] ?? r['uid'] ?? ''} ${r['delta'] ?? r['cents'] ?? r['amount'] ?? ''}',
              style: const TextStyle(color: kDim, fontSize: 11.5)),
        ),
    ]);
  }
}

/* ─────────────── Gift codes ─────────────── */

class _GiftCodes extends StatefulWidget {
  const _GiftCodes({required this.rows, required this.onChanged});
  final List<Map> rows;
  final VoidCallback onChanged;
  @override
  State<_GiftCodes> createState() => _GiftCodesState();
}

class _GiftCodesState extends State<_GiftCodes> {
  String _item = 'word';
  int _count = 1;
  int _days = 180;
  final _campaign = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  List<String> _made = const [];

  @override
  void dispose() {
    for (final c in [_campaign, _email, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _make() async {
    setState(() => _busy = true);
    final r = await runAdmin(context, 'gift-codes', {'item': _item, 'count': _count, 'expiresDays': _days, 'campaign': _campaign.text.trim(), 'recipientEmail': _email.text.trim(), 'note': _note.text.trim()}, ok: '$_count code${_count > 1 ? 's' : ''} made.');
    if (mounted) {
      setState(() {
        _busy = false;
        if (r != null) _made = ((r['codes'] as List?) ?? const []).map((e) => '$e').toList();
      });
    }
    if (r != null) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 60), children: [
      Glass(
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MAKE GIFT CARDS', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final g in kGiftItems.entries) Pill(g.value, dense: true, selected: _item == g.key, onTap: () => setState(() => _item = g.key)),
          ]),
          const SizedBox(height: 10),
          LabeledSlider(label: 'How many', value: _count.toDouble(), min: 1, max: 50, divisions: 49, format: (v) => '${v.round()}', onChanged: (v) => setState(() => _count = v.round())),
          LabeledSlider(label: 'Expires after (days)', value: _days.toDouble(), min: 7, max: 730, divisions: 103, format: (v) => '${v.round()} d', onChanged: (v) => setState(() => _days = v.round())),
          TextField(controller: _campaign, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Campaign (optional)')),
          const SizedBox(height: 8),
          TextField(controller: _email, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'For email (optional)')),
          const SizedBox(height: 8),
          TextField(controller: _note, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message on the card (optional)')),
          const SizedBox(height: 12),
          GoldButton('Make codes', icon: Icons.card_giftcard_rounded, busy: _busy, onTap: _make),
          if (_made.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(_made.join('\n'), style: const TextStyle(color: kGold, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700)),
            Pill('Copy all', icon: Icons.copy_rounded, dense: true, onTap: () {
              Clipboard.setData(ClipboardData(text: _made.join('\n')));
              adminSnack(context, 'Codes copied.');
            }),
          ],
        ]),
      ),
      SectionHead('Codes', 'Latest ${rows.length}'),
      if (rows.isEmpty) const EmptyNote('No gift codes yet.'),
      for (final g in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(11),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText('${g['code'] ?? g['id']}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  Text('${g['label'] ?? g['item'] ?? ''} · ${g['source'] ?? ''}${'${g['campaign'] ?? ''}'.isNotEmpty ? ' · ${g['campaign']}' : ''} · made ${fmtDate(g['at'])} · expires ${fmtDate(g['expiresAt'])}',
                      style: const TextStyle(color: kFaint, fontSize: 10.5)),
                ]),
              ),
              Tag('${g['status'] ?? ''}', color: g['status'] == 'redeemed' ? kMint : (g['status'] == 'void' ? kRose : kAmber)),
              if (g['status'] == 'unredeemed')
                IconButton(
                  tooltip: 'Void',
                  icon: const Icon(Icons.block_rounded, color: kRose, size: 18),
                  onPressed: () async {
                    final ok = await confirmAction(context, 'Void ${g['code'] ?? g['id']}?', 'It can no longer be opened.', yes: 'Void');
                    if (!ok || !context.mounted) return;
                    final r = await runAdmin(context, 'gift-void', {'code': '${g['code'] ?? g['id']}'}, ok: 'Voided.');
                    if (r != null) widget.onChanged();
                  },
                ),
            ]),
          ),
        ),
    ]);
  }
}

/* ─────────────── Coupons ─────────────── */

class _Coupons extends StatelessWidget {
  const _Coupons({required this.rows});
  final List<Map> rows;
  @override
  Widget build(BuildContext context) {
    final by = <String, int>{};
    for (final r in rows) {
      by['${r['rarity'] ?? 'unknown'}'] = (by['${r['rarity'] ?? 'unknown'}'] ?? 0) + 1;
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 60), children: [
      StreamBuilder<Map<String, dynamic>>(
        stream: watchConfig('economy'),
        builder: (context, snap) {
          final scratch = ((snap.data?['scratch'] ?? kEconomyDefaults['scratch']) as List).cast<Map>();
          final total = scratch.fold<num>(0, (a, r) => a + (r['weight'] as num? ?? 0));
          return Glass(
            radius: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SCRATCH ODDS${snap.data?['scratch'] == null ? ' · plan defaults (not saved yet)' : ''}', style: const TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
              const SizedBox(height: 8),
              for (final r in scratch)
                ShareBar(label: '${r['rarity']} · ${r['coins']} coins · ${total > 0 ? ((r['weight'] as num) / total * 100).toStringAsFixed(1) : 0}%', value: r['weight'] as num? ?? 0, total: total, color: _rarity('${r['rarity']}')),
              const SizedBox(height: 6),
              const Text('Edit odds and prizes in Settings. The app shows these before every scratch.', style: TextStyle(color: kFaint, fontSize: 11)),
            ]),
          );
        },
      ),
      const SectionHead('Redeemed', 'Latest coupons'),
      if (rows.isEmpty) const EmptyNote('No coupons scratched yet.', icon: Icons.local_activity_outlined),
      if (by.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: [for (final e in by.entries) Tag('${e.key}: ${e.value}', color: _rarity(e.key))]),
      const SizedBox(height: 8),
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${fmtDate(r['at'], time: true)} · ${r['rarity'] ?? ''} · ${r['coins'] != null ? '+${r['coins']} coins' : (r['prize'] ?? '')} · ${r['uid'] ?? ''}', style: const TextStyle(color: kDim, fontSize: 11.5)),
        ),
    ]);
  }
}

Color _rarity(String r) => switch (r) {
      'uncommon' => kMint,
      'rare' => kSky,
      'epic' => kViolet,
      'legendary' => kAmber,
      'mythic' => kRose,
      _ => kGold,
    };

/* ─────────────── Settings (config/economy) ─────────────── */

class _EconomySettings extends StatefulWidget {
  const _EconomySettings();
  @override
  State<_EconomySettings> createState() => _EconomySettingsState();
}

class _EconomySettingsState extends State<_EconomySettings> {
  Map<String, dynamic>? _cfg;
  bool _fromDefaults = false;
  bool _busy = false;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    watchConfig('economy').first.then((d) {
      if (!mounted) return;
      setState(() {
        _fromDefaults = d.isEmpty;
        _version = (d['version'] as num?)?.toInt() ?? 0;
        _cfg = _deep({...kEconomyDefaults, ...d}..removeWhere((k, _) => const {'version', 'updatedAt', 'updatedBy'}.contains(k)));
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _cfg = _deep(kEconomyDefaults));
    });
  }

  static Map<String, dynamic> _deep(Map m) => m.map((k, v) => MapEntry('$k', v is Map ? _deep(v) : (v is List ? v.map((e) => e is Map ? _deep(e) : e).toList() : v)));

  Future<void> _save() async {
    final c = _cfg!;
    final scratch = (c['scratch'] as List).cast<Map>();
    final total = scratch.fold<num>(0, (a, r) => a + (r['weight'] as num? ?? 0));
    if (total != 10000) {
      adminSnack(context, 'Scratch weights must add up to 10000 (now $total).', error: true);
      return;
    }
    final ok = await confirmAction(context, 'Save economy settings?', 'Every app and the server read config/economy live. Version ${_version + 1} will be recorded with what changed.', yes: 'Save');
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await saveConfig('economy', c, label: 'economy settings');
      _version++;
      _fromDefaults = false;
      if (mounted) adminSnack(context, 'Saved v$_version.');
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _num(Map m, String k, String label, {String suffix = ''}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          key: ValueKey('${identityHashCode(m)}$k'),
          initialValue: '${m[k] ?? ''}',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: label, suffixText: suffix),
          onChanged: (v) => m[k] = num.tryParse(v) ?? m[k],
        ),
      );

  Widget _switch(Map m, String k, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: m[k] == true,
        activeThumbColor: kGold,
        onChanged: (v) => setState(() => m[k] = v),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
      );

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    if (c == null) return const OrbLoading(label: 'Reading config/economy…');
    final pay = c['payouts'] as Map;
    final coins = c['coins'] as Map;
    final coupons = c['coupons'] as Map;
    final gifts = c['gifts'] as Map;
    final ranks = (c['ranks'] as List).cast<Map>();
    final scratch = (c['scratch'] as List).cast<Map>();
    final fast = c['fastStart'] as Map;
    final pool = c['topPool'] as Map;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 80), children: [
      Text(_fromDefaults ? 'config/economy is empty — showing the plan PDF starting values. Save to make them live.' : 'config/economy · v$_version',
          style: TextStyle(color: _fromDefaults ? kAmber : kDim, fontSize: 12)),
      const SectionHead('Switches', 'Programs'),
      Glass(radius: 20, child: Column(children: [
        _switch(c, 'earnEnabled', 'Earn program on'),
        _switch(c, 'giftsEnabled', 'Gifts on'),
        _switch(c, 'couponsEnabled', 'Coupons on'),
        _switch(coupons, 'paidEnabled', 'Paid coupons (18+, odds shown first)'),
        _switch(pay, 'autoApprove', 'Automatic payouts (off = launch mode, every payout approved here)'),
      ])),
      const SectionHead('Payouts', 'Manual UPI queue'),
      Glass(radius: 20, child: Column(children: [
        _num(pay, 'minCents', 'Minimum payout (US cents)', suffix: '¢'),
        _num(pay, 'capPct', 'Payout cap (% of net)', suffix: '%'),
        _num(pay, 'holdDays', 'Pending → available after', suffix: 'days'),
        _num(pay, 'payoutDay', 'Payout day of the month'),
      ])),
      const SectionHead('Coins', 'Rewards'),
      Glass(radius: 20, child: Column(children: [
        _num(coins, 'dailyCeiling', 'Daily ceiling from free activity', suffix: 'coins'),
        _num(coins, 'expiryMonths', 'Expire after inactivity', suffix: 'months'),
        _num(coins, 'coinsPerRupee', 'Coins per ₹1 of store value'),
        _num(coins, 'loginMin', 'Daily login — from', suffix: 'coins'),
        _num(coins, 'loginMax', 'Daily login — up to (streak)', suffix: 'coins'),
        _num(coins, 'practiceRing', 'Practice ring', suffix: 'coins'),
      ])),
      const SectionHead('Ranks', 'Commission ladder'),
      for (final r in ranks)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Glass(
            radius: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r['name']}', style: const TextStyle(color: kGold, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _num(r, 'minUnits', 'From units')),
                const SizedBox(width: 8),
                Expanded(child: _num(r, 'ratePct', 'Rate', suffix: '%')),
              ]),
              Row(children: [
                Expanded(child: _num(r, 'leg1Pct', 'Leg L1', suffix: '%')),
                const SizedBox(width: 8),
                Expanded(child: _num(r, 'leg2Pct', 'Leg L2', suffix: '%')),
              ]),
              Row(children: [
                Expanded(child: _num(r, 'coinsPerSale', 'Coins / sale')),
                const SizedBox(width: 8),
                Expanded(child: _num(r, 'team', 'Team size')),
              ]),
            ]),
          ),
        ),
      Glass(radius: 20, child: Column(children: [
        Row(children: [
          Expanded(child: _num(fast, 'bonusPct', 'Fast-Start bonus', suffix: '%')),
          const SizedBox(width: 8),
          Expanded(child: _num(fast, 'days', 'for', suffix: 'days')),
        ]),
        Row(children: [
          Expanded(child: _num(pool, 'pct', 'Top pool (% of net)', suffix: '%')),
          const SizedBox(width: 8),
          Expanded(child: _num(pool, 'top', 'Top sellers')),
        ]),
      ])),
      const SectionHead('Coupons', 'Scratch odds (weights out of 10000)'),
      Glass(radius: 20, child: Column(children: [
        for (final r in scratch)
          Row(children: [
            SizedBox(width: 82, child: Text('${r['rarity']}', style: TextStyle(color: _rarity('${r['rarity']}'), fontWeight: FontWeight.w800))),
            Expanded(child: _num(r, 'weight', 'Weight')),
            const SizedBox(width: 8),
            Expanded(child: _num(r, 'coins', 'Coins')),
          ]),
        _num(coupons, 'freeExpiryDays', 'Free coupon expiry', suffix: 'days'),
      ])),
      const SectionHead('Gifts', 'Gift cards'),
      Glass(radius: 20, child: Column(children: [
        _num(gifts, 'codeExpiryDays', 'Code expiry', suffix: 'days'),
        _num(gifts, 'boughtValidMonths', 'Bought gifts valid', suffix: 'months'),
        _num(gifts, 'perDayLimit', 'Gifts per person per day'),
        _num(gifts, 'coolingOffDays', 'Cooling-off (unopened refund)', suffix: 'days'),
      ])),
      const SizedBox(height: 14),
      GoldButton('Save config/economy', icon: Icons.save_rounded, busy: _busy, onTap: _save),
    ]);
  }
}
