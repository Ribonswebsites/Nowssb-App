/// Dashboard — real counts only. Asks the admin server for aggregates
/// (service account, no client-wide reads); with the server off, the same
/// numbers come from Firestore count()/sum() queries as the admin.
/// Anything that cannot be counted shows 0 or an empty state, never a guess.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_data.dart';
import 'admin_kit.dart';
import 'people_admin.dart';
import 'requests_admin.dart';
import 'earn_admin.dart';
import 'activity_admin.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});
  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  Map<String, dynamic>? _s;
  Object? _err;
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 60), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      if (!quiet) _err = null;
    });
    try {
      final s = await AdminData.run('stats', {'tzOffsetMin': DateTime.now().timeZoneOffset.inMinutes});
      if (mounted) setState(() => _s = s);
    } catch (e) {
      if (mounted && !quiet) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Live numbers',
      title: 'Dashboard',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () {
            AdminData.retryServer();
            _load();
          },
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kGold))
              : const Icon(Icons.refresh_rounded, color: kGold),
        ),
      ],
      body: _s == null
          ? (_err != null ? AdminProblem(error: _err!, onRetry: _load) : const OrbLoading(label: 'Counting members, plans and coins…', state: OrbState.solving))
          : RefreshIndicator(
              color: kGold,
              onRefresh: () async {
                AdminData.retryServer();
                await _load();
              },
              child: _body(_s!),
            ),
    );
  }

  Widget _body(Map<String, dynamic> s) {
    Map m(String k) => (s[k] as Map?) ?? const {};
    int n(Map x, String k) => (x[k] as num?)?.toInt() ?? 0;
    final u = m('users');
    final sub = m('subscriptions');
    final plans = (sub['plans'] as Map?) ?? const {};
    final pay = m('payments');
    final req = m('requests');
    final coins = m('coins');
    final gifts = m('gifts');
    final po = m('payouts');
    final signups = ((s['signups'] as List?) ?? const []).cast<Map>();
    final errors = (s['errors'] as Map?) ?? const {};
    final local = s['local'] == true;
    final accounts = u['accounts'];
    final planParts = <(String, num, Color)>[
      for (final t in kTiers.keys) (kTiers[t]!, n((plans[t] as Map?) ?? const {}, 'active'), kTierColors[t]!),
    ];
    final totalSubs = n(sub, 'active');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
      children: [
        if (local)
          MissingSecrets(AdminData.serverMissing,
              what: 'Admin server is off, so these are counted in the app from Firestore (profiles of people who opened the app). Set in Cloudflare (Production):'),
        Text('Updated ${fmtDate(s['at'], time: true)}${local ? ' · in-app count' : ' · server count'}',
            style: const TextStyle(color: kFaint, fontSize: 11)),
        const SizedBox(height: 10),
        _Hero(online: n(u, 'online'), today: n(u, 'signedInToday'), week: n(u, 'signedIn7d')),
        const SizedBox(height: 10),
        TileGrid(children: [
          StatTile(
            label: accounts != null ? 'Accounts (Firebase Auth)' : 'Profiles in Firestore',
            value: fmtNum(accounts is num ? accounts : n(u, 'profiles')),
            sub: accounts != null ? '${fmtNum(n(u, 'profiles'))} with a profile' : 'Auth total needs the server key',
            icon: Icons.people_alt_rounded,
            onTap: () => pushAdmin(context, const PeopleAdminScreen()),
          ),
          StatTile(
            label: 'New sign-ups',
            value: fmtNum(n(u, 'signupsToday')),
            sub: 'today · ${fmtNum(n(u, 'signups7d'))} in 7 days',
            icon: Icons.person_add_alt_1_rounded,
            color: kMint,
          ),
          StatTile(
            label: 'Active subscribers',
            value: fmtNum(totalSubs),
            sub: '${fmtNum(n(sub, 'expired'))} expired · ${fmtNum(n(sub, 'lapsedFlagged'))} lapsed',
            icon: Icons.workspace_premium_rounded,
            color: kViolet,
            onTap: () => pushAdmin(context, const PeopleAdminScreen(initialFilter: 'plan')),
          ),
          StatTile(
            label: 'Word requests open',
            value: fmtNum(n(req, 'open')),
            sub: '${fmtNum(n(req, 'done'))} done of ${fmtNum(n(req, 'total'))}',
            icon: Icons.inbox_rounded,
            color: kAmber,
            onTap: () => pushAdmin(context, const RequestsAdminScreen()),
          ),
        ]),
        const SectionHead('Growth', 'Sign-ups, last 30 days'),
        Glass(
          radius: 22,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (signups.every((d) => (d['n'] as num? ?? 0) == 0))
              EmptyNote(s['signupsSource'] == 'profiles'
                  ? 'No sign-up dates recorded yet. The app now records each account’s creation date on open; the full history comes from Firebase Auth once FIREBASE_SERVICE_ACCOUNT is set.'
                  : 'No sign-ups in the last 30 days.')
            else
              BarChart(
                values: [for (final d in signups) (d['n'] as num? ?? 0)],
                labels: [for (final d in signups) '${d['day']}'.substring(5)],
              ),
            const SizedBox(height: 6),
            Text('${fmtNum(signups.fold<num>(0, (a, d) => a + (d['n'] as num? ?? 0)))} in 30 days',
                style: const TextStyle(color: kDim, fontSize: 12)),
          ]),
        ),
        const SectionHead('Plans', 'Subscribers by plan'),
        Glass(
          radius: 22,
          child: Row(children: [
            DonutChart(
              parts: planParts,
              size: 118,
              center: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(fmtNum(totalSubs), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const Text('active', style: TextStyle(color: kDim, fontSize: 10.5)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final t in kTiers.keys) ...[
                  Row(children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: kTierColors[t], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(kTiers[t]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                    Text(fmtNum(n((plans[t] as Map?) ?? const {}, 'active')), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 8, top: 2),
                    child: Text(
                        '${n((plans[t] as Map?) ?? const {}, 'monthly')} monthly · ${n((plans[t] as Map?) ?? const {}, 'yearly')} yearly · ${n((plans[t] as Map?) ?? const {}, 'other')} granted/other',
                        style: const TextStyle(color: kDim, fontSize: 11)),
                  ),
                ],
              ]),
            ),
          ]),
        ),
        if ((sub['bySource'] as Map?)?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in (sub['bySource'] as Map).entries) Tag('${e.key}: ${e.value}', color: kSky),
            ]),
          ),
        const SectionHead('Money', 'Payments, coins and payouts'),
        TileGrid(children: [
          StatTile(label: 'Play payments', value: fmtNum(n(pay, 'total')), sub: '${fmtNum(n(pay, 'last30d'))} in 30 days', icon: Icons.receipt_long_rounded),
          StatTile(
              label: 'Payouts waiting',
              value: fmtNum(n(po, 'pending') + n(po, 'queued')),
              sub: '${fmtNum(n(po, 'paid'))} paid',
              icon: Icons.account_balance_wallet_rounded,
              color: kMint,
              onTap: () => pushAdmin(context, const EarnAdminScreen())),
          StatTile(label: 'Coins issued', value: fmtNum(n(coins, 'issued')), sub: '${fmtNum(n(coins, 'entries'))} ledger rows', icon: Icons.toll_rounded, color: kAmber),
          StatTile(label: 'Coins spent', value: fmtNum(n(coins, 'spent')), sub: 'from coinLedger', icon: Icons.shopping_bag_rounded, color: kRose),
        ]),
        const SectionHead('Gifts', 'Gift cards and coupons'),
        TileGrid(columns: 3, children: [
          StatTile(label: 'Gift codes', value: fmtNum(n(gifts, 'codes')), icon: Icons.card_giftcard_rounded),
          StatTile(label: 'Opened', value: fmtNum(n(gifts, 'opened')), icon: Icons.mark_email_read_rounded, color: kMint),
          StatTile(label: 'Coupons', value: fmtNum(n(gifts, 'coupons')), icon: Icons.local_activity_rounded, color: kViolet),
        ]),
        const SectionHead('Safety', 'Access'),
        TileGrid(children: [
          StatTile(
              label: 'Blocked',
              value: fmtNum(n(u, 'blocked')),
              icon: Icons.block_rounded,
              color: kRose,
              onTap: () => pushAdmin(context, const PeopleAdminScreen(initialFilter: 'blocked'))),
          StatTile(
              label: 'Helpers',
              value: fmtNum(n(u, 'helpers')),
              icon: Icons.support_agent_rounded,
              color: kSky,
              onTap: () => pushAdmin(context, const PeopleAdminScreen(initialFilter: 'helper'))),
        ]),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Some counts could not be read: ${errors.keys.join(', ')}', style: const TextStyle(color: kAmber, fontSize: 11.5)),
        ],
        const SizedBox(height: 12),
        Center(
          child: Pill('Open the live activity feed', icon: Icons.timeline_rounded, onTap: () => pushAdmin(context, const ActivityAdminScreen())),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.online, required this.today, required this.week});
  final int online;
  final int today;
  final int week;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 26,
        glow: kMint.withValues(alpha: 0.12),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, boxShadow: [BoxShadow(color: kMint.withValues(alpha: 0.3), blurRadius: 24)]),
            child: ThinkingOrb(state: online > 0 ? OrbState.listening : OrbState.working, size: 48, theme: OrbTheme.dark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ONLINE NOW', style: TextStyle(color: kMint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              Text(fmtNum(online), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.1)),
              Text('${fmtNum(today)} signed in today · ${fmtNum(week)} in 7 days', style: const TextStyle(color: kDim, fontSize: 12)),
            ]),
          ),
        ]),
      );
}
