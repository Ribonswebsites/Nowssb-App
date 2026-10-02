/// Admin mode — home.
///
/// Reached from App Settings → Admin or the floating Edit layout button,
/// both of which exist only for an account the SERVER marks as admin
/// (Firestore `admins/{uid}`, or the `admin` custom claim). Every write made
/// from here is also enforced by firestore.rules, so the switch in the app
/// is a convenience, not the security.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'activity_admin.dart';
import 'admin_data.dart';
import 'admin_kit.dart';
import 'admin_state.dart';
import 'admin_ui.dart';
import 'broadcast_admin.dart';
import 'dashboard_admin.dart';
import 'earn_admin.dart';
import 'editor/ui_editor_screen.dart';
import 'people_admin.dart';
import 'quotes_admin.dart';
import 'requests_admin.dart';
import 'settings_admin.dart';
import 'template/all_slots_screen.dart';
import 'template/ui_overrides.dart';
import 'words_admin.dart';

void openAdminHome(BuildContext context) {
  if (!AdminState.instance.isAdmin) return;
  bigFeel();
  Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => const AdminHome(),
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(opacity: c, child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(c), child: child));
    },
  ));
}

/// The admin console hub: a separate area for running the app and its
/// people, in the Fashion home's look (film behind frosted glass, gold,
/// thinking orbs). Live numbers on top, then a card for every section —
/// the UI Editor is one of them.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, dynamic>? _stats;
  Object? _err;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 90), (_) => _load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AdminState.instance.isAdmin) return;
    try {
      final s = await AdminData.run('stats', {'tzOffsetMin': DateTime.now().timeZoneOffset.inMinutes});
      if (mounted) setState(() => _stats = s);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  void _go(Widget w) => pushAdmin(context, w);

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final a = AdminState.instance;
    if (!a.isAdmin) {
      return const AdminScaffold(
        title: 'Admin',
        body: Center(child: Text('This account is not an admin.', style: TextStyle(color: kAdminDim))),
      );
    }
    final top = MediaQuery.of(context).padding.top;
    final s = _stats;
    int n(String g, String k) => ((s?[g] as Map?)?[k] as num?)?.toInt() ?? 0;
    final accounts = (s?['users'] as Map?)?['accounts'];
    String v(int x) => s == null ? '…' : fmtNum(x);
    return Theme(
      data: adminTheme(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AdminBackdrop(
          dim: 0.45,
          child: RefreshIndicator(
            color: kGold,
            onRefresh: () async {
              AdminData.retryServer();
              await _load();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 48),
              children: [
                Row(children: [
                  IconButton(
                    tooltip: 'Back to the app',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Pill(EditMode.instance.on ? 'Pencils on' : 'Pencils off',
                      icon: Icons.edit_rounded,
                      dense: true,
                      selected: EditMode.instance.on,
                      tooltip: 'Show a pencil on every picture, clip and line in the live app',
                      onTap: () => EditMode.instance.setOn(!EditMode.instance.on)),
                ]),
                const _Hero(),
                const SizedBox(height: 4),
                Text('Signed in as ${a.email ?? a.uid} · admin via ${a.how}',
                    textAlign: TextAlign.center, style: const TextStyle(color: kFaint, fontSize: 11)),
                const SizedBox(height: 14),
                if (s?['local'] == true) MissingSecrets(AdminData.serverMissing, what: 'Admin server is off — the console works straight from Firestore. Push, Auth disable and full sign-up history need:'),
                if (s == null && _err != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Live numbers: $_err', style: const TextStyle(color: kAmber, fontSize: 11.5))),
                // ── live strip
                Glass(
                  radius: 26,
                  glow: kGold.withValues(alpha: 0.12),
                  onTap: () => _go(const DashboardAdminScreen()),
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: kMint, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(color: kMint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                      const Spacer(),
                      const Text('Dashboard', style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w700)),
                      const Icon(Icons.chevron_right_rounded, color: kGold, size: 18),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _Num(v(n('users', 'online')), 'online now', kMint),
                      _Num(v(n('users', 'signedInToday')), 'today', kSky),
                      _Num(s == null ? '…' : fmtNum(accounts is num ? accounts : n('users', 'profiles')), accounts != null ? 'accounts' : 'profiles', Colors.white),
                      _Num(v(n('subscriptions', 'active')), 'subscribers', kViolet),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                _BigCard(
                  title: 'UI Editor',
                  sub: 'Change any page live — pictures, SVGs, words, colours, animations, the order of sections — preview full screen, then publish.',
                  icon: Icons.auto_awesome_mosaic_rounded,
                  cta: 'Open editor',
                  onTap: () {
                    bigFeel();
                    openUiEditor(context);
                  },
                ),
                const SectionHead('Run the app', 'People & money'),
                TileGrid(children: [
                  _Tile(Icons.insights_rounded, 'Dashboard', 'Members, plans, coins, growth', kGold, () => _go(const DashboardAdminScreen())),
                  _Tile(Icons.people_alt_rounded, 'People', 'Search, profile, grant, block', kSky, () => _go(const PeopleAdminScreen()),
                      badge: s == null ? null : '${n('users', 'blocked')} blocked'),
                  _Tile(Icons.redeem_rounded, 'Earn & Gifts', 'Payouts, network, codes, odds', kMint, () => _go(const EarnAdminScreen()),
                      badge: s == null || n('payouts', 'pending') + n('payouts', 'queued') == 0 ? null : '${n('payouts', 'pending') + n('payouts', 'queued')} payouts'),
                  _Tile(Icons.timeline_rounded, 'Activity', 'Sign-ups, purchases, actions — live', kViolet, () => _go(const ActivityAdminScreen())),
                  _Tile(Icons.campaign_rounded, 'Notifications', 'Push + in-app banner', kAmber, () => _go(const BroadcastAdminScreen())),
                  _Tile(Icons.tune_rounded, 'Settings', 'Force update, maintenance, flags, audit', kRose, () => _go(const SettingsAdminScreen())),
                ]),
                const SectionHead('Content', 'Words, quotes, requests'),
                _Card(Icons.inbox_rounded, 'Word requests', s == null ? 'Create the asked-for word right there' : '${n('requests', 'open')} open · create the word right there',
                    () => _go(const RequestsAdminScreen())),
                _Card(Icons.menu_book_rounded, 'Words', 'Edit every field, voice, video, stages, pictures; publish or archive',
                    () => _go(const WordsAdminScreen())),
                _Card(Icons.format_quote_rounded, 'Quotes', 'Dated lines and the rotation queue',
                    () => _go(const QuotesAdminScreen())),
                const SectionHead('This phone', 'Editing tools'),
                Glass(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(children: [
                    SwitchListTile(
                      value: EditMode.instance.on,
                      onChanged: EditMode.instance.setOn,
                      activeThumbColor: kGold,
                      title: const Text('Pencils on the live app', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Tap a pencil on any picture, clip or line to replace it',
                          style: TextStyle(color: kDim, fontSize: 12)),
                    ),
                    SwitchListTile(
                      value: EditMode.instance.fabPreference,
                      onChanged: (v) => EditMode.instance.setFab(v),
                      activeThumbColor: kGold,
                      title: const Text('Floating Edit button', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('A small button on every screen, only on this phone',
                          style: TextStyle(color: kDim, fontSize: 12)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.grid_view_rounded, color: kGold),
                      title: const Text('Every slot in the app', style: TextStyle(color: Colors.white)),
                      subtitle: Text('${UiOverrides.instance.all.length} changed',
                          style: const TextStyle(color: kDim, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: kFaint),
                      onTap: () => _go(const AllSlotsScreen()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.history_rounded, color: kGold),
                      title: const Text('Audit log', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: kFaint),
                      onTap: () => _go(const AuditLogScreen()),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Text(label, style: const TextStyle(color: kDim, fontSize: 10.5)),
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.sub, this.color, this.onTap, {this.badge});
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14)]),
              child: Icon(icon, color: color, size: 19),
            ),
            const Spacer(),
            if (badge != null) Tag(badge!, color: color),
          ]),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5)),
        ]),
      );
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.28), blurRadius: 40, spreadRadius: 2)],
        ),
        alignment: Alignment.center,
        child: const ThinkingOrb(state: OrbState.composing, size: 70, theme: OrbTheme.dark),
      ),
      const SizedBox(height: 12),
      const Text('ADMIN CONSOLE', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 2),
      const Text('Run NowssB',
          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
      const SizedBox(height: 2),
      const Text('People, money, content and every screen', style: TextStyle(color: kDim, fontSize: 13, letterSpacing: 0.2)),
    ]);
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.title, required this.sub, required this.icon, required this.cta, required this.onTap});
  final String title;
  final String sub;
  final IconData icon;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 28,
      padding: const EdgeInsets.all(18),
      glow: kGold.withValues(alpha: 0.18),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: Icon(icon, color: kGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ),
          if (UiOverrides.instance.all.isNotEmpty)
            AdminChip('${UiOverrides.instance.all.length} live edits', color: kMint),
        ]),
        const SizedBox(height: 10),
        Text(sub, style: const TextStyle(color: kDim, fontSize: 13, height: 1.35)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cta, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, color: kInk, size: 18),
          ]),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.icon, this.title, this.sub, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Glass(
          radius: 20,
          onTap: onTap,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              child: Icon(icon, color: kGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: kDim, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: kFaint),
          ]),
        ),
      );
}

/// `adminLog`, newest first. Read-only: the rules allow no edits or deletes.
class AdminLogScreen extends StatelessWidget {
  const AdminLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('adminLog').orderBy('at', descending: true).limit(200);
    return AdminScaffold(
      title: 'Activity log',
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load: ${snap.error}', style: const TextStyle(color: kAdminDim)));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nothing yet.', style: TextStyle(color: kAdminDim)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final detail = d['detail'];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${d['action'] ?? ''} · ${d['target'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                subtitle: Text(
                  [
                    '${d['email'] ?? d['uid'] ?? ''}',
                    adminAgo(d['at']),
                    if (detail is Map && detail.isNotEmpty)
                      detail.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kAdminDim, fontSize: 11.5),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
