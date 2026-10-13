/// `newui_coupons` gate for the rebuilt Coupons page.
///
/// OFF for users by default, ON for admin accounts (an `admins/{uid}` doc),
/// read from `config/app.flags.newui_coupons` through [AppControl].
/// Page-local until the shared kit exposes an admin getter; swap then.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/app_control.dart';
import '../../data/firebase.dart';

const kNewUiCouponsFlag = 'newui_coupons';

abstract final class CouponsNewUi {
  /// Tests can force the gate.
  @visibleForTesting
  static bool? debugOverride;

  static bool? _admin;

  static Future<bool> enabled() async {
    final o = debugOverride;
    if (o != null) return o;
    if (AppControl.instance.flag(kNewUiCouponsFlag, fallback: false)) return true;
    return _isAdmin();
  }

  static Future<bool> _isAdmin() async {
    if (_admin != null) return _admin!;
    if (!NwsbFirebase.ready) return false;
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return false;
      final s = await FirebaseFirestore.instance.collection('admins').doc(u.uid).get();
      return _admin = s.exists;
    } catch (_) {
      return false;
    }
  }
}
