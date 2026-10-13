/// Feature flag `newui_menu_settings` for the rebuilt Menu & Settings page.
///
/// Default OFF for users, ON for admin accounts. Users can be switched on
/// remotely with the Firestore doc `app_config/flags`, field
/// `newui_menu_settings: true`. The old page stays live while this is off.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/admin_state.dart';

const String kNewUiMenuSettingsFlag = 'newui_menu_settings';

class NewUiMenuSettingsFlag {
  NewUiMenuSettingsFlag._();

  static bool? _remote;

  /// Test hook: forces the flag regardless of admin / remote state.
  static bool? debugOverride;

  /// Synchronous resolution used by the router.
  static bool resolve({required bool isAdmin, bool? remote}) {
    if (debugOverride != null) return debugOverride!;
    if (isAdmin) return true;
    return remote ?? false;
  }

  static bool get isOn =>
      resolve(isAdmin: AdminState.instance.isAdmin, remote: _remote);

  /// Best-effort fetch of the remote value; never throws.
  static Future<void> refresh() async {
    try {
      final d = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('flags')
          .get();
      final v = d.data()?[kNewUiMenuSettingsFlag];
      _remote = v is bool ? v : false;
    } catch (_) {
      _remote = false;
    }
  }
}
