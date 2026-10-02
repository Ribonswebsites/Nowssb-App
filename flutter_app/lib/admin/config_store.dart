/// Settings the app reads live, without an update:
///   config/app      force update, maintenance, feature flags, announcement
///   config/economy  every Earn / Gifts / Coupons number (one doc, PDF plan)
/// Each save merges the change, bumps `version`, stamps who and when, and
/// appends the before/after to `configHistory` (append-only in the rules).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_log.dart';

Future<void> saveConfig(String docId, Map<String, dynamic> patch, {String label = ''}) async {
  final db = FirebaseFirestore.instance;
  final ref = db.collection('config').doc(docId);
  final u = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> before = const {};
  await db.runTransaction((tx) async {
    final s = await tx.get(ref);
    before = s.data() ?? {};
    final version = ((before['version'] as num?)?.toInt() ?? 0) + 1;
    tx.set(ref, {...patch, 'version': version, 'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': u?.email ?? u?.uid ?? ''}, SetOptions(merge: true));
    tx.set(db.collection('configHistory').doc(), {
      'doc': docId,
      'label': label,
      'version': version,
      'changed': patch.keys.toList(),
      'before': {for (final k in patch.keys) k: before[k]},
      'after': patch,
      'by': u?.email ?? u?.uid ?? '',
      'uid': u?.uid ?? '',
      'at': FieldValue.serverTimestamp(),
    });
  });
  await adminLog('config.$docId', label.isEmpty ? docId : label, {'keys': patch.keys.join(',')});
}

Stream<Map<String, dynamic>> watchConfig(String docId) =>
    FirebaseFirestore.instance.collection('config').doc(docId).snapshots().map((s) => s.data() ?? <String, dynamic>{});
