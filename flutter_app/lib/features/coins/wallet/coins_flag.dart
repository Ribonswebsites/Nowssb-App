import '../../../admin/admin_state.dart';
import '../../../data/app_control.dart';

/// Feature flag for the rebuilt Coins wallet (spec §18.1).
/// Key `newui_coins` in the app control doc's `flags` map.
/// Default OFF for users, always ON for admins, until Ribon approves.
const kNewUiCoinsFlag = 'newui_coins';

bool newUiCoinsEnabled({bool? isAdmin, Map<String, bool>? flags}) {
  final admin = isAdmin ?? AdminState.instance.isAdmin;
  if (admin) return true;
  final f = flags ?? AppControl.instance.flags;
  return f[kNewUiCoinsFlag] ?? false;
}
