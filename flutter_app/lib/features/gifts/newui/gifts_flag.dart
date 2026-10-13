import '../../../admin/admin_state.dart';
import '../../../data/app_control.dart';

/// Feature flag for the rebuilt Gifts page: `newui_gifts`.
/// OFF for users by default, ON for admin accounts, unless the console
/// sets the key explicitly (config flags map, read by [AppControl]).
bool newUiGiftsEnabled({bool? override}) {
  if (override != null) return override;
  final set = AppControl.instance.flags['newui_gifts'];
  if (set != null) return set;
  return AdminState.instance.isAdmin;
}
