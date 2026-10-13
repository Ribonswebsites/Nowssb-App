/// Feature flag `newui_profile` for the rebuilt Profile page.
///
/// Default OFF for users, ON for admin accounts. Read from Firestore
/// `config/app` field `newui_profile` (bool). Page-local until the shared
/// kit from NowssB Bug Hunter provides a flag service.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../../admin/admin_state.dart';
import '../../data/firebase.dart';

const kNewUiProfileFlag = 'newui_profile';

/// Pure decision, unit tested.
bool resolveNewUiProfile({required bool isAdmin, bool? remote}) => isAdmin || (remote ?? false);

class ProfileFlag {
  ProfileFlag._();

  /// Tests set this to force the result.
  static bool? debugOverride;

  static Future<bool> load() async {
    if (debugOverride != null) return debugOverride!;
    final admin = AdminState.instance.isAdmin;
    if (admin) return true;
    if (!NwsbFirebase.ready) return false;
    try {
      final s = await FirebaseFirestore.instance.doc('config/app').get().timeout(const Duration(seconds: 4));
      final v = s.data()?[kNewUiProfileFlag];
      return resolveNewUiProfile(isAdmin: admin, remote: v is bool ? v : null);
    } catch (_) {
      return false; // fail safe: old page
    }
  }
}

/// Shows [newUi] when the flag is on, otherwise [legacy]. While the flag
/// loads, the legacy page is shown so users never see a blank frame.
class ProfileFlagGate extends StatefulWidget {
  const ProfileFlagGate({super.key, required this.newUi, required this.legacy});
  final WidgetBuilder newUi;
  final WidgetBuilder legacy;
  @override
  State<ProfileFlagGate> createState() => _ProfileFlagGateState();
}

class _ProfileFlagGateState extends State<ProfileFlagGate> {
  bool? _on = ProfileFlag.debugOverride;

  @override
  void initState() {
    super.initState();
    if (_on == null) {
      ProfileFlag.load().then((v) {
        if (mounted) setState(() => _on = v);
      });
      AdminState.instance.addListener(_adminChanged);
    }
  }

  void _adminChanged() {
    if (AdminState.instance.isAdmin && _on != true && mounted) setState(() => _on = true);
  }

  @override
  void dispose() {
    AdminState.instance.removeListener(_adminChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _on == true ? widget.newUi(context) : widget.legacy(context);
}
