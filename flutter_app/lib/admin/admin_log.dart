/// Every admin change leaves a line in `adminLog`. Only admins can create or
/// read it and nobody can edit or delete it (firestore.rules).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> adminLog(String action, String target, [Map<String, dynamic>? detail]) async {
  try {
    final u = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('adminLog').add({
      'action': action,
      'target': target,
      if (detail != null) 'detail': detail,
      'uid': u?.uid,
      'email': u?.email,
      'at': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // A missing log line must never block the change itself.
  }
}
