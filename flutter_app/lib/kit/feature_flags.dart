/// `newui_<page>` gates for the rebuilt pages.
///
/// Order (first match wins):
///   1. Debug override (debug/profile builds only, kept in memory + prefs).
///   2. Remote `config/app.flags.newui_<page>` set to **false** → off
///      (kill switch).
///   3. Everyone else (absent or true) → ON for all users.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_control.dart';
import 'admin_check.dart';

/// Inputs to the decision, split out so tests need no Firebase.
class NewUiInputs {
  const NewUiInputs({required this.isAdmin, required this.remote, this.debugOverride});
  final bool isAdmin;
  final bool? remote;
  final bool? debugOverride;
}

abstract final class NewUi {
  static String key(String page) => 'newui_$page';

  /// Pure decision. Unit-tested.
  static bool decide(NewUiInputs i) {
    if (i.debugOverride != null) return i.debugOverride!;
    // Ribon: rebuilt pages are ON for everyone. Only an explicit remote
    // `false` (kill switch) turns a page off.
    return i.remote != false;
  }

  static final Map<String, bool> _overrides = {};
  static const _prefsPrefix = 'nwsb.debug.';

  /// Fires when an override changes; [NwsbAdmin] and [AppControl] fire on
  /// their own. [listenable] merges all three.
  static final ValueNotifier<int> _bump = ValueNotifier(0);
  static Listenable get listenable =>
      Listenable.merge([_bump, NwsbAdmin.listenable, AppControl.instance]);

  /// Is the rebuilt [page] on for this account right now?
  static bool isOn(String page) {
    final k = key(page);
    return decide(NewUiInputs(
      isAdmin: NwsbAdmin.isAdmin,
      remote: AppControl.instance.flags[k],
      debugOverride: kReleaseMode ? null : _overrides[k],
    ));
  }

  /// Debug-only override; `null` clears it. No-op in release builds.
  static Future<void> setDebugOverride(String page, bool? on) async {
    if (kReleaseMode) return;
    final k = key(page);
    if (on == null) {
      _overrides.remove(k);
    } else {
      _overrides[k] = on;
    }
    _bump.value++;
    // Fire-and-forget: the in-memory override is what isOn reads.
    unawaited(_persist('$_prefsPrefix$k', on));
  }

  static Future<void> _persist(String k, bool? on) async {
    try {
      final p = await SharedPreferences.getInstance();
      on == null ? await p.remove(k) : await p.setBool(k, on);
    } catch (_) {}
  }

  /// Loads saved debug overrides. Call once at startup (no-op in release).
  static Future<void> loadDebugOverrides() async {
    if (kReleaseMode) return;
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in p.getKeys()) {
        if (k.startsWith('$_prefsPrefix${'newui_'}')) {
          final v = p.getBool(k);
          if (v != null) _overrides[k.substring(_prefsPrefix.length)] = v;
        }
      }
      _bump.value++;
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest() {
    _overrides.clear();
    _bump.value++;
  }
}

/// Shows [rebuilt] when `newui_<page>` is on, otherwise [legacy]. Rebuilds
/// when the admin check, remote config or a debug override changes.
class NewUiGate extends StatelessWidget {
  const NewUiGate({super.key, required this.page, required this.legacy, required this.rebuilt});
  final String page;
  final WidgetBuilder legacy;
  final WidgetBuilder rebuilt;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: NewUi.listenable,
        builder: (context, _) => NewUi.isOn(page) ? rebuilt(context) : legacy(context),
      );
}
