import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// One line in the Earnings breakdown. Money is integer minor units.
class EarningRow {
  const EarningRow({required this.tab, required this.title, required this.cents, required this.status, this.at});
  final String tab; // words | meanings | subscriptions | bonuses | payout
  final String title;
  final int cents;
  final String status; // Pending | Available | Paid | Reversed | Requested | Processing | Failed
  final DateTime? at;
}

class EarningsSnapshot {
  const EarningsSnapshot({this.rows = const [], this.payouts = const []});
  final List<EarningRow> rows;
  final List<EarningRow> payouts;

  int get pendingCents => rows.where((r) => r.status == 'Pending').fold(0, (a, r) => a + r.cents);
  int get paidCents => payouts.where((r) => r.status == 'Paid').fold(0, (a, r) => a + r.cents);
  int get directCents => rows.where((r) => r.tab != 'bonuses').fold(0, (a, r) => a + r.cents);
  int get teamCents => rows.where((r) => r.tab == 'bonuses').fold(0, (a, r) => a + r.cents);
}

/// Reads only collections the screen already read before (no new server contracts).
abstract class EarningsSource {
  Stream<EarningsSnapshot> watch(String uid);
}

String statusLabel(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('revers') || s.contains('refund') || s.contains('revok')) return 'Reversed';
  if (s.contains('fail') || s.contains('reject')) return 'Failed';
  if (s.contains('process')) return 'Processing';
  if (s.contains('request')) return 'Requested';
  if (s.contains('paid') || s.contains('sent') || s.contains('complete')) return 'Paid';
  if (s.contains('pend') || s.contains('hold')) return 'Pending';
  return 'Available';
}

String tabFor(String reason) {
  final r = reason.toLowerCase();
  if (r.contains('meaning')) return 'meanings';
  if (r.contains('sub') || r.contains('plan')) return 'subscriptions';
  if (r.contains('bonus') || r.contains('circle') || r.contains('level') || r.contains('team')) return 'bonuses';
  return 'words';
}

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

class FirestoreEarningsSource implements EarningsSource {
  const FirestoreEarningsSource();

  @override
  Stream<EarningsSnapshot> watch(String uid) {
    final db = FirebaseFirestore.instance;
    final cash = db.collection('cashLedger').where('uid', isEqualTo: uid).limit(60).snapshots();
    final refs = db.collection('referralLedger').where('referrerUid', isEqualTo: uid).limit(60).snapshots();
    final pays = db.collection('payoutRequests').where('uid', isEqualTo: uid).limit(30).snapshots();
    late StreamController<EarningsSnapshot> out;
    QuerySnapshot<Map<String, dynamic>>? c, r, p;
    final subs = <StreamSubscription<dynamic>>[];
    void emit() {
      if (c == null || r == null || p == null) return;
      final rows = <EarningRow>[];
      for (final d in c!.docs) {
        final reason = '${d.data()['reason'] ?? 'Sale'}';
        if (reason.toLowerCase().contains('payout')) continue;
        rows.add(EarningRow(tab: tabFor(reason), title: reason, cents: (d.data()['delta'] as num?)?.toInt() ?? 0, status: statusLabel('${d.data()['status'] ?? 'available'}'), at: _date(d.data()['at'] ?? d.data()['createdAt'])));
      }
      for (final d in r!.docs) {
        rows.add(EarningRow(tab: 'bonuses', title: 'Team sale · level ${d.data()['level'] ?? 1}', cents: (d.data()['commissionAmount'] as num?)?.toInt() ?? 0, status: statusLabel('${d.data()['status'] ?? ''}'), at: _date(d.data()['createdAt'])));
      }
      final payouts = [
        for (final d in p!.docs)
          EarningRow(tab: 'payout', title: '${d.data()['reason'] ?? 'Withdrawal'}', cents: (d.data()['amountBase'] as num?)?.toInt() ?? 0, status: statusLabel('${d.data()['status'] ?? 'requested'}'), at: _date(d.data()['createdAt'])),
      ];
      rows.sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
      out.add(EarningsSnapshot(rows: rows, payouts: payouts));
    }

    out = StreamController<EarningsSnapshot>(
      onListen: () {
        subs
          ..add(cash.listen((s) { c = s; emit(); }, onError: out.addError))
          ..add(refs.listen((s) { r = s; emit(); }, onError: out.addError))
          ..add(pays.listen((s) { p = s; emit(); }, onError: out.addError));
      },
      onCancel: () async { for (final s in subs) { await s.cancel(); } },
    );
    return out.stream;
  }
}
