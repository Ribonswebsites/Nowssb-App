/// Feature flag `newui_menu_settings` for the rebuilt Menu & Settings page.
///
/// Delegates to the shared kit's [NewUi] (admins ON, users OFF, Ribon's
/// release switch `config/app.flags.newui_menu_settings` read live through
/// AppControl, so no separate refresh is needed).
library;

import '../../kit/feature_flags.dart';

const String kMenuSettingsPage = 'menu_settings';
const String kNewUiMenuSettingsFlag = 'newui_menu_settings';

class NewUiMenuSettingsFlag {
  NewUiMenuSettingsFlag._();

  /// Test hook: forces the flag regardless of admin / remote state.
  static bool? debugOverride;

  static bool resolve({required bool isAdmin, bool? remote}) =>
      NewUi.decide(NewUiInputs(
          isAdmin: isAdmin, remote: remote, debugOverride: debugOverride));

  static bool get isOn => debugOverride ?? NewUi.isOn(kMenuSettingsPage);
}
