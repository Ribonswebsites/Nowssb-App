/// `newui_coupons` gate for the rebuilt Coupons page.
///
/// ON for everyone by default; `config/app.flags.newui_coupons` set to
/// false (read through [AppControl]) acts as a kill switch.
library;

import 'package:flutter/foundation.dart';

import '../../data/app_control.dart';

const kNewUiCouponsFlag = 'newui_coupons';

abstract final class CouponsNewUi {
  /// Tests can force the gate.
  @visibleForTesting
  static bool? debugOverride;

  static Future<bool> enabled() async {
    final o = debugOverride;
    if (o != null) return o;
    return AppControl.instance.flag(kNewUiCouponsFlag, fallback: true);
  }
}
