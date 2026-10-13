/// Feature flag for the rebuilt Store hub: `config/app flags.newui_store`.
///
/// Default OFF for users, always ON for admin accounts, so the old Store
/// stays live until Ribon approves the rebuild.
library;

import '../../../admin/admin_state.dart';
import '../../../data/app_control.dart';

const kNewUiStoreFlag = 'newui_store';

/// Test hook: forces the flag on or off when non-null.
bool? debugNewUiStoreOverride;

bool newUiStoreEnabled() {
  final o = debugNewUiStoreOverride;
  if (o != null) return o;
  if (AdminState.instance.isAdmin) return true;
  return AppControl.instance.flag(kNewUiStoreFlag, fallback: false);
}
