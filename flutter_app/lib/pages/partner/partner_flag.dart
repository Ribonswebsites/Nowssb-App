/// `newui_partner` gate. Delegates to the shared kit's [NewUi] rules
/// (remote release flag, then admins on, everyone else off).
library;

import 'package:flutter/foundation.dart';

import '../../kit/kit.dart';

const kNewUiPartnerFlag = 'newui_partner';

abstract final class PartnerNewUi {
  @visibleForTesting
  static bool? debugOverride;

  static Future<bool> enabled() async => debugOverride ?? NewUi.isOn('partner');
}
