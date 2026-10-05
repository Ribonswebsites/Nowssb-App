/// Entry points into NowssB Admin from the user app: App Settings → Admin
/// and a long-press on the floating Edit button. Both exist only for an
/// account the SERVER marks as admin (Firestore `admins/{uid}`, or the
/// `admin` custom claim); every write is also enforced by firestore.rules.
///
/// The Admin app itself is admin_app.dart (its own shell and tabs); the
/// switch between the two apps is admin_mode.dart.
library;

import 'package:flutter/material.dart';

import 'admin_kit.dart';
import 'admin_mode.dart';
import 'admin_state.dart';

void openAdminHome(BuildContext context) {
  if (!AdminState.instance.isAdmin) return;
  bigFeel();
  openAdminApp(context);
}
