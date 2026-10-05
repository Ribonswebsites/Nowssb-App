/// Admin inbox — what needs an admin: new word requests, payout requests,
/// new sign-ups, purchases, feedback. Written by the server
/// (adminAlerts/{id}, functions/_lib/admin_alerts.js), which also pushes each
/// one to every admin's phone. Plus a live strip of what is waiting now.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_app.dart';
import 'admin_kit.dart';
import 'earn_admin.dart';
import 'person_admin.dart';
import 'requests_admin.dart';

Future<void> openPerson(BuildContext context, String uid) => pushAdmin(context, PersonAdminScreen(uid: uid));
Future<void> openRequests(BuildContext context) => pushAdmin(context, const RequestsAdminScreen());

const _kindLook = <String, (IconData, Color, String)>{
  'request': (Icons.inbox_rounded, kAmber, 'Word request'),
  'payout': (Icons.account_balance_wallet_rounded, kMint, 'Payout'),
  'signup': (Icons.person_add_alt_1_rounded, kSky, 'Sign-up'),
  'purchase': (Icons.workspace_premium_rounded, kViolet, 'Purchase'),
  'feedback': (Icons.rate_review_rounded, kGold, 'Feedback'),
  'deletion': (Icons.person_remove_rounded, kRose, 'Deletion'),
};

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});
  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  final _db = FirebaseFirestore.instance;
  String _kind = '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _alerts =
      _db.collection('adminAlerts').orderBy('at', descending: true).limit(150).snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _openReq =
      _db.collection('requests').where('status', isEqualTo: 'new').limit(200).snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _payouts =
      _db.collection('payoutRequests').where('status', whereIn: ['pending_review', 'queued']).limit(200).snapshots();

  Future<void> _markAll(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final unseen = docs.where((d) => d.data()['seen'] != true).toList();
    if (unseen.isEmpty) return;
    final b = _db.batch();
    for (final d in unseen.take(400)) {
      b.update(d.reference, {'seen': true});
    }
    try {
      await b.commit();
      if (mounted) adminSnack(context, '${unseen.length} marked as seen.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Could not mark: $e', error: true);
    }
  }

  void _open(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m['seen'] != true) unawaited(d.reference.update({'seen': true}).catchError((_) {}));
    final route = '${m['route'] ?? ''}';
    final uid = '${m['uid'] ?? ''}';
    if (route.isNotEmpty) {
      openAdminRoute(context, route);
    } else if (uid.isNotEmpty) {
      unawaited(openPerson(context, uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _alerts,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final shown = _kind.isEmpty ? docs : docs.where((d) => d.data()['kind'] == _kind).toList();
        final unseen = docs.where((d) => d.data()['seen'] != true).length;
        return AdminPage(
          eyebrow: unseen == 0 ? 'All caught up' : '$unseen new',
          title: 'Admin inbox',
          actions: [
            if (unseen > 0)
              TextButton.icon(
                onPressed: () => _markAll(docs),
                icon: const Icon(Icons.done_all_rounded, color: kGold, size: 18),
                label: const Text('Mark all seen', style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
              ),
          ],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 60),
            children: [
              Row(children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _openReq,
                    builder: (_, s) => StatTile(
                      label: 'Word requests waiting',
                      value: s.hasData ? fmtNum(s.data!.docs.length) : '…',
                      icon: Icons.inbox_rounded,
                      color: kAmber,
                      onTap: () => openRequests(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _payouts,
                    builder: (_, s) => StatTile(
                      label: 'Payouts waiting',
                      value: s.hasData ? fmtNum(s.data!.docs.length) : '…',
                      icon: Icons.account_balance_wallet_rounded,
                      color: kMint,
                      onTap: () => pushAdmin(context, const EarnAdminScreen()),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Padding(padding: const EdgeInsets.only(right: 6), child: Pill('Everything', dense: true, selected: _kind.isEmpty, onTap: () => setState(() => _kind = ''))),
                  for (final e in _kindLook.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Pill(e.value.$3, dense: true, icon: e.value.$1, color: e.value.$2, selected: _kind == e.key, onTap: () => setState(() => _kind = e.key)),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              if (snap.hasError)
                AdminProblem(error: snap.error!)
              else if (!snap.hasData)
                const Padding(padding: EdgeInsets.only(top: 40), child: OrbLoading(label: 'Opening the inbox…'))
              else if (shown.isEmpty)
                const EmptyNote('Nothing here yet. New word requests, payout requests, sign-ups and purchases land here the moment they happen — and buzz your phone.')
              else
                for (final d in shown) _AlertRow(d.data(), onTap: () => _open(d)),
            ],
          ),
        );
      },
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow(this.m, {required this.onTap});
  final Map<String, dynamic> m;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final look = _kindLook['${m['kind']}'] ?? (Icons.notifications_rounded, kGold, 'Alert');
    final seen = m['seen'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 18,
        onTap: onTap,
        edge: seen ? kGlassEdge : look.$2.withValues(alpha: 0.55),
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: look.$2.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(look.$1, color: look.$2, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('${m['title'] ?? look.$3}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: seen ? FontWeight.w600 : FontWeight.w800, fontSize: 14)),
                ),
                if (!seen) Container(width: 8, height: 8, decoration: BoxDecoration(color: look.$2, shape: BoxShape.circle)),
              ]),
              if ('${m['body'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${m['body']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 12, height: 1.3)),
              ],
              const SizedBox(height: 4),
              Text('${look.$3} · ${fmtDate(m['at'], time: true)} · ${fmtAgo(m['at'])}', style: const TextStyle(color: kFaint, fontSize: 10.5)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: kFaint),
        ]),
      ),
    );
  }
}
