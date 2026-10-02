/// One person: who they are, how they sign in, their plan, coins, Earn
/// network, gifts, purchases, requests and every admin change — plus every
/// action, each through the admin server (or rules-gated Firestore when the
/// server is off) and each written to adminLog.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/billing_config.dart';
import 'admin_data.dart';
import 'admin_log.dart';
import 'admin_kit.dart';

class PersonAdminScreen extends StatefulWidget {
  const PersonAdminScreen({super.key, required this.uid, this.seed});
  final String uid;
  final Map<String, dynamic>? seed;
  @override
  State<PersonAdminScreen> createState() => _PersonAdminScreenState();
}

class _PersonAdminScreenState extends State<PersonAdminScreen> {
  Map<String, dynamic>? _p;
  Object? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _err = null);
    try {
      final p = await AdminData.run('user', {'uid': widget.uid});
      if (mounted) setState(() => _p = p);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  Future<void> _act(String action, Map<String, dynamic> body, String ok) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await AdminData.run(action, {'uid': widget.uid, ...body});
      if (!mounted) return;
      final warn = '${r['warning'] ?? ''}';
      adminSnack(context, warn.isEmpty ? ok : '$ok $warn');
      await _load();
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map get _row => (_p?['row'] as Map?) ?? widget.seed ?? const {};

  @override
  Widget build(BuildContext context) {
    final name = '${_row['name'] ?? ''}'.trim();
    return AdminPage(
      eyebrow: 'Person',
      title: name.isNotEmpty ? name : '${_row['email'] ?? widget.uid}',
      actions: [
        if (_busy) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kGold))),
        IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: kGold)),
      ],
      body: _p == null
          ? (_err != null ? AdminProblem(error: _err!, onRetry: _load) : const OrbLoading(label: 'Opening their profile…'))
          : RefreshIndicator(color: kGold, onRefresh: _load, child: _body(_p!)),
    );
  }

  Widget _body(Map<String, dynamic> p) {
    final row = _row;
    final user = (p['user'] as Map?) ?? const {};
    final plan = (p['plan'] as Map?) ?? const {};
    final wallet = p['wallet'] as Map?;
    final ref = p['referral'] as Map?;
    final payout = p['payout'] as Map?;
    final auth = p['auth'] as Map?;
    final restrictions = (user['restrictions'] as Map?) ?? const {};
    final roles = ((user['roles'] as List?) ?? const []).map((e) => '$e').toList();
    final blocked = user['blocked'] == true || row['blocked'] == true;
    final helper = roles.contains('helper');
    List<Map> L(String k) => ((p[k] as List?) ?? const []).cast<Map>();
    final gifts = (p['gifts'] as Map?) ?? const {};

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 80), children: [
      if (p['local'] == true) MissingSecrets(AdminData.serverMissing, what: 'Admin server is off — profile read straight from Firestore. Sign-in providers and Auth disable need:'),
      // ── identity
      Glass(
        radius: 26,
        padding: const EdgeInsets.all(16),
        glow: blocked ? kRose.withValues(alpha: 0.2) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(name: '${row['name'] ?? row['email'] ?? ''}', photo: '${row['photo'] ?? ''}', size: 58, online: row['online'] == true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${row['email'] ?? ''}'.isEmpty ? 'No email on file' : '${row['email']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Wrap(spacing: 5, runSpacing: 4, children: [
                  Tag('${plan['name'] ?? 'Free'}', color: plan['active'] == true ? (kTierColors[plan['tier']] ?? kGold) : kFaint),
                  if (blocked) const Tag('Blocked', color: kRose, icon: Icons.block_rounded),
                  if (auth?['disabled'] == true) const Tag('Sign-in disabled', color: kRose),
                  if (helper) const Tag('Helper', color: kSky),
                  Tag(row['online'] == true ? 'Online now' : 'Seen ${fmtAgo(row['lastSeen'])}', color: row['online'] == true ? kMint : kFaint),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          KV('User id', widget.uid, selectable: true),
          KV('Phone', '${row['phone'] ?? ''}'),
          KV('Sign-in with', ((row['providers'] as List?) ?? const []).join(', ')),
          KV('Joined', fmtDate(row['createdAt'], time: true)),
          KV('Last sign-in', fmtDate(row['lastLoginAt'], time: true)),
          KV('Last seen', fmtDate(user['lastSeen'] ?? row['lastSeen'], time: true)),
          KV('Device', [user['lastPlatform'], user['lastOs'], user['lastDevice']].where((e) => '${e ?? ''}'.isNotEmpty).join(' · ')),
          KV('App build', '${user['lastBuild'] ?? ''}${'${user['lastApp'] ?? ''}'.isNotEmpty ? ' (${user['lastApp']})' : ''}'),
          if (L('devices').isNotEmpty) KV('Push devices', '${L('devices').length} (${L('devices').map((d) => d['platform']).join(', ')})'),
          if (blocked) KV('Blocked', '${user['blockedReason'] ?? ''} · ${user['blockedBy'] ?? ''} · ${fmtDate(user['blockedAt'])}', color: kRose),
          if ('${p['authNote'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${p['authNote']}', style: const TextStyle(color: kFaint, fontSize: 11))),
          const SizedBox(height: 8),
          Row(children: [
            Pill('Copy id', icon: Icons.copy_rounded, dense: true, onTap: () {
              Clipboard.setData(ClipboardData(text: widget.uid));
              adminSnack(context, 'User id copied.');
            }),
          ]),
        ]),
      ),
      // ── actions
      const SectionHead('Actions', 'Control this account'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _ActionChip(Icons.workspace_premium_rounded, 'Grant plan', kViolet, () => _grant()),
        if ('${plan['tier'] ?? ''}'.isNotEmpty) _ActionChip(Icons.more_time_rounded, 'Extend', kGold, () => _extend()),
        if (plan['active'] == true) _ActionChip(Icons.remove_circle_outline_rounded, 'Revoke plan', kRose, () => _revoke(plan)),
        _ActionChip(Icons.inventory_2_rounded, 'Grant item', kMint, () => _grantItem()),
        _ActionChip(Icons.toll_rounded, 'Adjust coins', kAmber, () => _coins(wallet)),
        _ActionChip(Icons.send_rounded, 'Message', kSky, () => _message()),
        _ActionChip(Icons.tune_rounded, 'Restrictions${restrictions.values.where((v) => v == true).isEmpty ? '' : ' (${restrictions.values.where((v) => v == true).length})'}', kAmber, () => _restrict(restrictions)),
        _ActionChip(Icons.local_fire_department_rounded, 'Reset streak', kRose, () => _streak(wallet)),
        _ActionChip(helper ? Icons.person_remove_rounded : Icons.support_agent_rounded, helper ? 'Remove helper' : 'Make helper', kSky,
            () => _act('helper', {'on': !helper}, helper ? 'Helper role removed.' : 'Marked as helper.')),
        _ActionChip(blocked ? Icons.lock_open_rounded : Icons.block_rounded, blocked ? 'Unblock' : 'Block', blocked ? kMint : kRose, () => _block(blocked)),
      ]),
      // ── plan
      const SectionHead('Subscription', 'Plan'),
      Glass(
        radius: 22,
        child: Column(children: [
          KV('Plan', '${plan['name'] ?? 'Free'}', color: plan['active'] == true ? kGold : Colors.white),
          KV('Billing', '${plan['billing'] ?? ''}'),
          KV('Source', _sourceName('${plan['source'] ?? ''}')),
          KV('Started', fmtDate(plan['since'])),
          KV('Ends', fmtDate(plan['until']), color: plan['expired'] == true ? kRose : Colors.white),
          if ('${plan['productId'] ?? ''}'.isNotEmpty) KV('Play product', '${plan['productId']}'),
          if (plan['source'] == 'play') KV('Auto-renew', plan['autoRenew'] == true ? 'on' : 'off'),
        ]),
      ),
      // ── coins
      const SectionHead('Coins', 'Balance and ledger'),
      Glass(
        radius: 22,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (wallet == null)
            const Text('No wallet yet (never earned or spent a coin).', style: TextStyle(color: kDim, fontSize: 12.5))
          else ...[
            Row(children: [
              Expanded(child: _Mini('Coins', fmtNum(wallet['coins'] as num?), kAmber)),
              Expanded(child: _Mini('Streak', '${fmtNum(wallet['streak'] as num?)} d', kRose)),
              Expanded(child: _Mini('Lifetime', fmtNum(wallet['lifetimeEarned'] as num?), kMint)),
            ]),
            const SizedBox(height: 8),
            KV('Longest streak', fmtNum(wallet['longestStreak'] as num?)),
            KV('Word credits', fmtNum(wallet['wordCredits'] as num?)),
            KV('Freezes', fmtNum(wallet['freezesOwned'] as num?)),
          ],
          const SizedBox(height: 6),
          if (L('coinLedger').isEmpty) const Text('No coin ledger rows.', style: TextStyle(color: kFaint, fontSize: 12)),
          for (final e in L('coinLedger').take(30))
            _LedgerRow(
              '${e['reason'] ?? e['refId'] ?? ''}',
              '${(e['delta'] as num? ?? 0) > 0 ? '+' : ''}${e['delta'] ?? 0}',
              '${fmtDate(e['at'], time: true)} · after ${e['balanceAfter'] ?? '—'}',
              (e['delta'] as num? ?? 0) >= 0 ? kMint : kRose,
            ),
        ]),
      ),
      // ── earn
      const SectionHead('Earn', 'Rank, referrals and payouts'),
      Glass(
        radius: 22,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ref == null && L('invited').isEmpty && payout == null)
            const Text('Not in the Earn program yet.', style: TextStyle(color: kDim, fontSize: 12.5)),
          if (ref != null) ...[
            KV('Code', '${ref['code'] ?? ''}'),
            KV('Rank', '${ref['tier'] ?? ''}'),
            KV('Sign-ups', fmtNum(ref['signups'] as num?)),
            KV('Subscribers', fmtNum(ref['subscribers'] as num?)),
            KV('Units sold', fmtNum(ref['unitsSold'] as num?)),
          ],
          if (p['invitedBy'] != null) KV('Invited by', '${(p['invitedBy'] as Map)['uid']}', selectable: true),
          KV('Invited', '${L('invited').length} (${L('invited').where((x) => x['subscribed'] == true).length} subscribed)'),
          if (payout != null) ...[
            KV('Cash balance', usd(payout['cashBalance'] as num? ?? 0)),
            KV('Pending', usd(payout['pendingCents'] as num? ?? 0)),
            KV('Paid out', usd(payout['paidCents'] as num? ?? 0)),
            KV('UPI', '${payout['upi'] ?? ''}', selectable: true),
          ],
          for (final x in L('payouts').take(10))
            _LedgerRow('Payout ${usd(x['amountBase'] as num? ?? 0)}', '${x['status'] ?? ''}', fmtDate(x['at'], time: true), x['status'] == 'paid' ? kMint : kAmber),
          const SizedBox(height: 8),
          Pill('See their network', icon: Icons.account_tree_rounded, dense: true, onTap: () => pushAdmin(context, NetworkScreen(uid: widget.uid))),
        ]),
      ),
      // ── gifts / purchases / requests
      const SectionHead('Gifts & purchases', 'What they bought, sent and opened'),
      Glass(
        radius: 22,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _group('Play payments', L('payments'), (x) => _LedgerRow('${kTiers[x['tier']] ?? x['productId'] ?? 'Purchase'} ${x['billing'] ?? ''}', '${x['orderId'] ?? ''}'.isEmpty ? '' : 'order', fmtDate(x['at'], time: true), kGold)),
          _group('Words owned', L('owned'), (x) => _LedgerRow('${x['title'] ?? x['word'] ?? x['id']}', '${x['source'] ?? x['kind'] ?? ''}', fmtDate(x['at']), kSky)),
          _group('Gifts sent', ((gifts['sent'] as List?) ?? const []).cast<Map>(), (x) => _LedgerRow('${x['label'] ?? x['code']}', '${x['status'] ?? ''}', '${x['code'] ?? x['id']} · ${fmtDate(x['at'])}', kViolet)),
          _group('Gifts opened', ((gifts['opened'] as List?) ?? const []).cast<Map>(), (x) => _LedgerRow('${x['label'] ?? x['code']}', 'opened', fmtDate(x['at']), kMint)),
          _group('Coupons', L('coupons'), (x) => _LedgerRow('${x['rarity'] ?? 'Coupon'}', x['coins'] != null ? '+${x['coins']}' : '', fmtDate(x['at']), kAmber)),
          _group('Word requests', L('requests'), (x) => _LedgerRow('${x['word'] ?? ''}', '${x['status'] ?? ''}', fmtDate(x['at']), x['status'] == 'done' ? kMint : kAmber)),
        ]),
      ),
      const SectionHead('History', 'Admin changes and activity'),
      Glass(
        radius: 22,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (L('adminLog').isEmpty && L('activity').isEmpty) const Text('No admin changes or recorded activity.', style: TextStyle(color: kFaint, fontSize: 12)),
          for (final x in L('adminLog').take(40))
            _LedgerRow('${x['action'] ?? ''}', '', '${x['email'] ?? ''} · ${fmtDate(x['at'], time: true)}${x['detail'] is Map ? ' · ${(x['detail'] as Map).entries.where((e) => '${e.value}'.isNotEmpty).map((e) => '${e.key}: ${e.value}').join(', ')}' : ''}', kGold),
          for (final x in L('activity').where((a) => a['type'] != 'admin').take(20))
            _LedgerRow('${x['summary'] ?? x['type'] ?? ''}', '${x['platform'] ?? ''}', fmtDate(x['at'], time: true), kSky),
        ]),
      ),
    ]);
  }

  Widget _group(String title, List<Map> rows, Widget Function(Map) one) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$title · ${rows.length}', style: const TextStyle(color: kGold, fontSize: 11.5, fontWeight: FontWeight.w800)),
          if (rows.isEmpty) const Text('none', style: TextStyle(color: kFaint, fontSize: 11.5)),
          for (final r in rows.take(12)) one(r),
        ]),
      );

  String _sourceName(String s) => switch (s) {
        'play' => 'Google Play',
        'admin' => 'Admin grant',
        'admin_revoked' => 'Revoked by admin',
        'gift' => 'Gift',
        '' => '—',
        _ => s,
      };

  /* ── dialogs ─────────────────────────────────────────── */

  Future<void> _grant() async {
    String tier = 'frequency';
    String billing = 'custom';
    int days = 30;
    DateTime? until;
    final reason = TextEditingController();
    bool notify = true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(builder: (ctx, set) {
          return Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GRANT A PLAN', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Text('Which plan, for how long', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: [
                for (final t in kTiers.entries) Pill(t.value, selected: tier == t.key, color: kTierColors[t.key]!, onTap: () => set(() => tier = t.key)),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [
                for (final b in ['monthly', 'yearly', 'custom'])
                  Pill(b, dense: true, selected: billing == b, onTap: () => set(() {
                        billing = b;
                        if (b == 'monthly') days = 30;
                        if (b == 'yearly') days = 365;
                        until = null;
                      })),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final d in [7, 30, 90, 180, 365])
                  Pill('$d days', dense: true, selected: until == null && days == d, onTap: () => set(() {
                        days = d;
                        until = null;
                      })),
                Pill(until == null ? 'Until date…' : 'Until ${fmtDate(until)}', dense: true, icon: Icons.event_rounded, selected: until != null, onTap: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      builder: (c, w) => Theme(data: adminTheme(), child: w!));
                  if (d != null) set(() => until = DateTime(d.year, d.month, d.day, 23, 59));
                }),
              ]),
              const SizedBox(height: 10),
              TextField(controller: reason, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Reason (audit log)')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: notify,
                activeThumbColor: kGold,
                onChanged: (v) => set(() => notify = v),
                title: const Text('Tell them in the app', style: TextStyle(color: Colors.white, fontSize: 13.5)),
              ),
              SizedBox(width: double.infinity, child: GoldButton('Grant ${kTiers[tier]}', icon: Icons.workspace_premium_rounded, onTap: () => Navigator.pop(ctx, true))),
            ]),
          );
        }),
      ),
    );
    if (ok != true) return;
    await _act('grant-sub', {
      'tier': tier,
      'billing': billing,
      if (until != null) 'until': until!.millisecondsSinceEpoch else 'days': days,
      'reason': reason.text.trim(),
      'notify': notify,
    }, '${kTiers[tier]} granted.');
  }

  Future<void> _extend() async {
    final d = await _askNumber('Extend the plan', 'Days to add', initial: '30');
    if (d == null || d <= 0) return;
    await _act('extend-sub', {'days': d}, 'Extended by $d days.');
  }

  Future<void> _revoke(Map plan) async {
    final r = await askReason(context, 'Revoke ${plan['name']}?',
        hint: plan['source'] == 'play' ? 'This is a Play subscription — cancel billing in Play Console too. Reason:' : 'Reason (kept in the audit log)', yes: 'Revoke');
    if (r == null) return;
    await _act('revoke-sub', {'reason': r}, 'Plan revoked.');
  }

  Future<void> _coins(Map? wallet) async {
    final amount = TextEditingController();
    final reason = TextEditingController();
    bool add = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: Text('Coins · now ${fmtNum(wallet?['coins'] as num? ?? 0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Pill('Add', icon: Icons.add_rounded, selected: add, color: kMint, onTap: () => set(() => add = true)),
                const SizedBox(width: 6),
                Pill('Remove', icon: Icons.remove_rounded, selected: !add, color: kRose, onTap: () => set(() => add = false)),
              ]),
              const SizedBox(height: 10),
              TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Coins')),
              const SizedBox(height: 8),
              TextField(controller: reason, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Reason (shown in their coin history)')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
                  onPressed: () {
                    if ((int.tryParse(amount.text) ?? 0) <= 0 || reason.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Save to ledger')),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final n = int.parse(amount.text);
    await _act('adjust-coins', {'delta': add ? n : -n, 'reason': reason.text.trim()}, add ? '+$n coins.' : '-$n coins.');
  }

  /// Give (or take back) one word / meaning / signature / ebook:
  /// users/{uid}/owned/{cleanId} — the same doc a Play purchase writes,
  /// marked source 'admin' (rules allow nothing else from the console).
  Future<void> _grantItem() async {
    final id = TextEditingController();
    String kind = 'word';
    bool revoke = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: const Text('Grant an item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final k in const ['word', 'meaning', 'signature', 'ebook']) Pill(k, dense: true, selected: kind == k, onTap: () => set(() => kind = k)),
              ]),
              TextField(controller: id, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Word or book id (e.g. phoenix)')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: revoke,
                activeThumbColor: kRose,
                onChanged: (v) => set(() => revoke = v),
                title: const Text('Revoke instead', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
                  onPressed: () => id.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
                  child: Text(revoke ? 'Revoke' : 'Grant')),
            ],
          ),
        ),
      ),
    );
    if (ok != true || _busy) return;
    final raw = id.text.trim().toLowerCase();
    final itemId = raw.contains(':') ? raw : '$kind:$raw';
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.doc('users/${widget.uid}/owned/${ownedDocId(itemId)}').set({
        'id': itemId,
        'kind': itemId.split(':').first,
        'title': raw.contains(':') ? raw.split(':').last : raw,
        'source': 'admin',
        'status': revoke ? 'revoked' : 'active',
        'at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await adminLog(revoke ? 'owned.revoke' : 'owned.grant', widget.uid, {'item': itemId});
      if (mounted) adminSnack(context, revoke ? '$itemId revoked.' : '$itemId granted — it opens for them now.');
      await _load();
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _message() async {
    final title = TextEditingController();
    final body = TextEditingController();
    bool push = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: const Text('Message this person', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, maxLength: 80, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: body, maxLength: 600, maxLines: 4, minLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: push,
                activeThumbColor: kGold,
                onChanged: (v) => set(() => push = v),
                title: const Text('Also send a phone push', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Always lands in their bell + inbox', style: TextStyle(color: kDim, fontSize: 11)),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
                  onPressed: () => title.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
                  child: const Text('Send')),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await AdminData.run('message', {'uid': widget.uid, 'title': title.text.trim(), 'body': body.text.trim(), 'push': push});
      final pushR = (r['push'] as Map?) ?? const {};
      final warn = '${r['warning'] ?? ''}';
      if (mounted) {
        adminSnack(context, warn.isNotEmpty ? warn : 'Sent in the app${push ? ' · push to ${pushR['sent'] ?? 0} of ${pushR['devices'] ?? 0} devices' : ''}${(pushR['missing'] as List?)?.isNotEmpty == true ? ' · push needs ${(pushR['missing'] as List).join(', ')}' : ''}.');
      }
      await _load();
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restrict(Map current) async {
    final on = <String, bool>{for (final k in kRestrictions.keys) k: current[k] == true};
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RESTRICTIONS', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Text('Enforced by the app, the rules and the server', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              for (final e in kRestrictions.entries)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: on[e.key]!,
                  activeThumbColor: kAmber,
                  onChanged: (v) => set(() => on[e.key] = v),
                  title: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                ),
              TextField(controller: reason, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Reason (audit log)')),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: GoldButton('Save restrictions', icon: Icons.tune_rounded, onTap: () => Navigator.pop(ctx, true))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    await _act('restrict', {'restrictions': on, 'reason': reason.text.trim()}, 'Restrictions saved.');
  }

  Future<void> _streak(Map? wallet) async {
    final r = await askReason(context, 'Reset the ${fmtNum(wallet?['streak'] as num? ?? 0)}-day streak?', yes: 'Reset');
    if (r == null) return;
    await _act('reset-streak', {'reason': r}, 'Streak reset.');
  }

  Future<void> _block(bool blocked) async {
    if (blocked) {
      final ok = await confirmAction(context, 'Unblock?', 'They can sign in and use the app again.', yes: 'Unblock');
      if (ok != true) return;
      await _act('block', {'blocked': false}, 'Unblocked.');
      return;
    }
    final r = await askReason(context, 'Block this account?', hint: 'Reason (shown to them on the blocked screen)', yes: 'Block');
    if (r == null) return;
    bigFeel();
    await _act('block', {'blocked': true, 'reason': r}, 'Blocked.');
  }

  Future<int?> _askNumber(String title, String label, {String initial = ''}) async {
    final c = TextEditingController(text: initial);
    final r = await showDialog<int>(
      context: context,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk), onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)), child: const Text('OK')),
          ],
        ),
      ),
    );
    return r;
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () {
          tapFeel();
          onTap();
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: kDim, fontSize: 11)),
      ]);
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(this.title, this.value, this.sub, this.color);
  final String title;
  final String value;
  final String sub;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.only(top: 5, right: 8), width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kFaint, fontSize: 10.5)),
            ]),
          ),
          if (value.isNotEmpty) Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
      );
}

/// Referral network: who invited them, who they invited, and the next level.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key, required this.uid});
  final String uid;
  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  Map<String, dynamic>? _n;
  Object? _err;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final n = await AdminData.run('network', {'uid': widget.uid});
      if (mounted) setState(() => _n = n);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _n;
    Widget who(Map w, {String extra = ''}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(10),
            onTap: () => pushAdmin(context, PersonAdminScreen(uid: '${w['uid']}')),
            child: Row(children: [
              Avatar(name: '${w['name'] ?? w['email'] ?? ''}', size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    '${'${w['name'] ?? ''}'.isNotEmpty ? w['name'] : ('${w['email'] ?? ''}'.isNotEmpty ? w['email'] : w['uid'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              if (w['subscribed'] == true) const Tag('subscribed', color: kMint),
              if (extra.isNotEmpty) Text(extra, style: const TextStyle(color: kFaint, fontSize: 10.5)),
            ]),
          ),
        );
    return AdminPage(
      eyebrow: 'Earn',
      title: 'Referral network',
      body: n == null
          ? (_err != null ? AdminProblem(error: _err!, onRetry: _load) : const OrbLoading(label: 'Tracing the network…', state: OrbState.shaping))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 60), children: [
              const SectionHead('Upline', 'Invited by'),
              if (n['upline'] == null) const EmptyNote('Joined without an invite.') else who(n['upline'] as Map),
              SectionHead('Level 1', 'Invited directly · ${((n['level1'] as List?) ?? const []).length}'),
              if (((n['level1'] as List?) ?? const []).isEmpty) const EmptyNote('Nobody yet.'),
              for (final w in ((n['level1'] as List?) ?? const []).cast<Map>()) who(w, extra: fmtDate(w['at'])),
              SectionHead('Level 2', 'Invited by their invites · ${((n['level2'] as List?) ?? const []).length}'),
              if (((n['level2'] as List?) ?? const []).isEmpty) const EmptyNote('Nobody yet.'),
              for (final w in ((n['level2'] as List?) ?? const []).cast<Map>()) who(w, extra: fmtDate(w['at'])),
            ]),
    );
  }
}
