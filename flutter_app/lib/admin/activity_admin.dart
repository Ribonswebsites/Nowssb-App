/// Activity — sign-ups, sign-ins, purchases, requests, gifts, coupons,
/// payouts and every admin action in one feed, newest first. The merged
/// history comes from the server (or Firestore as the admin); the
/// `activity` and `adminLog` collections are also streamed live so new
/// rows slide in without a refresh.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_data.dart';
import 'admin_kit.dart';
import 'person_admin.dart';

const _types = {
  'all': ('Everything', Icons.all_inclusive_rounded, kGold),
  'signup': ('Sign-ups', Icons.person_add_alt_1_rounded, kMint),
  'login': ('Sign-ins', Icons.login_rounded, kSky),
  'purchase': ('Purchases', Icons.receipt_long_rounded, kViolet),
  'request': ('Requests', Icons.inbox_rounded, kAmber),
  'gift': ('Gifts', Icons.card_giftcard_rounded, kRose),
  'coupon': ('Coupons', Icons.local_activity_rounded, kAmber),
  'payout': ('Payouts', Icons.account_balance_wallet_rounded, kMint),
  'admin': ('Admin', Icons.admin_panel_settings_rounded, kGold),
};

class ActivityAdminScreen extends StatefulWidget {
  const ActivityAdminScreen({super.key});
  @override
  State<ActivityAdminScreen> createState() => _ActivityAdminScreenState();
}

class _ActivityAdminScreenState extends State<ActivityAdminScreen> {
  String _type = 'all';
  List<Map<String, dynamic>> _base = [];
  final Map<String, Map<String, dynamic>> _live = {};
  final _subs = <StreamSubscription<dynamic>>[];
  bool _loading = true;
  Object? _err;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    final db = FirebaseFirestore.instance;
    _subs.add(db.collection('activity').orderBy('at', descending: true).limit(60).snapshots().listen((s) {
      for (final d in s.docs) {
        final x = d.data();
        _live['a_${d.id}'] = {
          'id': 'a_${d.id}', 'type': x['type'] == 'admin' ? 'admin' : '${x['type'] ?? 'event'}', 'title': '${x['summary'] ?? x['type'] ?? ''}',
          'uid': '${x['uid'] ?? ''}', 'by': '${x['by'] ?? ''}', 'detail': '${x['platform'] ?? ''}${x['build'] != null ? ' · build ${x['build']}' : ''}',
          'at': toMsAny(x['at']), 'live': true,
        };
      }
      if (mounted) setState(() {});
    }, onError: (_) {}));
    _subs.add(db.collection('adminLog').orderBy('at', descending: true).limit(40).snapshots().listen((s) {
      for (final d in s.docs) {
        final x = d.data();
        if (x['via'] == 'console') continue; // the server's activity row covers it
        final det = x['detail'] is Map ? (x['detail'] as Map).entries.where((e) => '${e.value}'.isNotEmpty).map((e) => '${e.key}: ${e.value}').join(' · ') : '';
        _live['l_${d.id}'] = {
          'id': 'l_${d.id}', 'type': 'admin', 'title': '${x['summary'] ?? x['action'] ?? ''}', 'uid': '${x['target'] ?? ''}',
          'by': '${x['email'] ?? ''}', 'detail': det.length > 160 ? det.substring(0, 160) : det, 'at': toMsAny(x['at']), 'live': true,
        };
      }
      if (mounted) setState(() {});
    }, onError: (_) {}));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _base.isEmpty;
      _err = null;
    });
    try {
      final r = await AdminData.run('feed', {'limit': 60});
      _base = ((r['rows'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _err = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final merged = <String, Map<String, dynamic>>{for (final r in _base) '${r['id']}': r, ..._live};
    final needle = _q.text.trim().toLowerCase();
    final rows = merged.values.where((r) {
      if (_type != 'all' && r['type'] != _type) return false;
      if (needle.isEmpty) return true;
      return ['title', 'uid', 'by', 'detail'].any((k) => '${r[k] ?? ''}'.toLowerCase().contains(needle));
    }).toList()
      ..sort((a, b) => (b['at'] as int? ?? 0).compareTo(a['at'] as int? ?? 0));
    return AdminPage(
      eyebrow: 'Live',
      title: 'Activity',
      actions: [IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: kGold))],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Column(children: [
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in _types.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Pill(e.value.$1, icon: e.value.$2, dense: true, color: e.value.$3, selected: _type == e.key, onTap: () => setState(() => _type = e.key)),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: kGold), hintText: 'Filter by text, uid or email'),
          ),
        ]),
      ),
      body: _loading
          ? const OrbLoading(label: 'Gathering the latest activity…', state: OrbState.listening)
          : RefreshIndicator(
              color: kGold,
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
                itemCount: rows.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (_err != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('History: $_err', style: const TextStyle(color: kAmber, fontSize: 11.5))),
                      Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: kMint, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Live · ${rows.length} events', style: const TextStyle(color: kDim, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      if (rows.isEmpty) const EmptyNote('No events of this kind yet.', icon: Icons.timeline_rounded),
                    ]);
                  }
                  final r = rows[i - 1];
                  final t = _types[r['type']] ?? ('Event', Icons.bolt_rounded, kSky);
                  final uid = '${r['uid'] ?? ''}';
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(r['id']),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Glass(
                        radius: 16,
                        padding: const EdgeInsets.all(11),
                        onTap: RegExp(r'^[A-Za-z0-9_-]{20,128}$').hasMatch(uid) ? () => pushAdmin(context, PersonAdminScreen(uid: uid)) : null,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: t.$3.withValues(alpha: 0.16), shape: BoxShape.circle),
                            child: Icon(t.$2, color: t.$3, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${r['title'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text([r['by'], uid.isNotEmpty ? uid : null, r['detail']].where((e) => '${e ?? ''}'.isNotEmpty).join(' · '),
                                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kFaint, fontSize: 10.5)),
                            ]),
                          ),
                          const SizedBox(width: 6),
                          Text(fmtAgo(r['at']), style: const TextStyle(color: kDim, fontSize: 10.5)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
