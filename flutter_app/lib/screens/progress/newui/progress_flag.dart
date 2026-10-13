import '../../../admin/admin_state.dart';
import '../../../data/app_control.dart';

/// Feature flag for the rebuilt Progress page: `newui_progress`.
/// OFF for users by default, ON for admin accounts, unless the console
/// sets the key explicitly (config flags map, read by [AppControl]).
bool newUiProgressEnabled({bool? override}) {
  if (override != null) return override;
  final set = AppControl.instance.flags['newui_progress'];
  if (set != null) return set;
  return AdminState.instance.isAdmin;
}
