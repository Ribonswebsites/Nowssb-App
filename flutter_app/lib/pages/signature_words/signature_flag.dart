import '../../admin/admin_state.dart';
import '../../data/app_control.dart';

/// Feature flag for the rebuilt Signature Words page: `newui_signature`.
/// OFF for users, ON for admins, unless the console sets the key.
const kSignatureFlag = 'newui_signature';

bool newUiSignatureEnabled({bool? override}) {
  if (override != null) return override;
  final set = AppControl.instance.flags[kSignatureFlag];
  if (set != null) return set;
  return AdminState.instance.isAdmin;
}
