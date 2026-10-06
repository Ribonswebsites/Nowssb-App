/// "Remember me" on the sign-in screens: when it is off, the next cold start
/// signs the account out (AuthGate.forgetUnremembered).
///
/// Builds before 3 Oct 2026 (80f3cf0d) wrote `nwsb.rememberMe = false` on
/// every sign-out from Settings, when the flag only switched notifications
/// off. 80f3cf0d started signing out at cold start whenever the flag is
/// false, but never reset that stale value, and the sign-in screens load the
/// flag into the tick and save it again on every sign-in. So anyone who had
/// signed out once on an older build was signed out on every launch, with
/// "Remember me" unticked by an app write they never made.
///
/// [read] drops that stale value once (marker [_resetKey]); a choice made on
/// the sign-in screen after that is kept.
library;

import 'package:shared_preferences/shared_preferences.dart';

class RememberMe {
  RememberMe._();

  static const key = 'nwsb.rememberMe';
  static const _resetKey = 'nwsb.rememberMe.reset1';

  /// Whether the session should survive a cold start. Defaults to true.
  static Future<bool> read([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (!(p.getBool(_resetKey) ?? false)) {
      await p.remove(key);
      await p.setBool(_resetKey, true);
    }
    return p.getBool(key) ?? true;
  }

  static Future<void> write(bool remember, [SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    // A choice made now is a real one: the one-time reset must not drop it.
    await p.setBool(_resetKey, true);
    await p.setBool(key, remember);
  }
}
