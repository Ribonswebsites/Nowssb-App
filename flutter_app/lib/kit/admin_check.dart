/// Shared, public "is this account an admin?" for app code outside
/// lib/admin. Wraps [AdminState] (server-decided: `admins/{uid}` doc or the
/// `admin` token claim). While the live check loads, the last answer this
/// phone cached for the signed-in uid is used so admins don't flash member UI.
/// This only decides what the app SHOWS; firestore.rules are the real lock.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../admin/admin_state.dart';
import '../data/firebase.dart';

abstract final class NwsbAdmin {
  /// Fires when the admin answer changes.
  static Listenable get listenable => AdminState.instance;

  static bool get isAdmin {
    final a = AdminState.instance;
    if (a.isAdmin) return true;
    if (a.resolved) return false;
    try {
      final uid = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser?.uid : null;
      return a.cachedFor(uid) == true;
    } catch (_) {
      return false;
    }
  }
}
