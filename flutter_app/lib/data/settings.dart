/// The app's own switches, remembered between launches.
///
/// Two of them matter and both are real behaviour rather than decoration:
///
///   fashionPlus  Motion mode. On by default so every on-screen film plays
///                (matching the website and the WebView). Off, page
///                backgrounds hold their first frame. The page that turns
///                it off says so.
///
///   fashionHome  Which home. The dark one or the pale neumorphic one.
///
/// Written through [ChangeNotifier] so a screen rebuilds the moment the
/// switch moves, and through SharedPreferences so it survives a relaunch.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  static const _kPlus = 'nwsb_fashplus_v2';
  static const _kHome = 'nwsb_home_mode';

  bool _fashionPlus = true;
  bool _fashionHome = false;

  /// Motion mode: do page backgrounds play, or hold their first frame?
  bool get fashionPlus => _fashionPlus;

  /// Which home is behind the Connect tab.
  bool get fashionHome => _fashionHome;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fashionPlus = p.getBool(_kPlus) ?? true;
      _fashionHome = p.getBool(_kHome) ?? false;
      notifyListeners();
    } catch (_) {
      // A platform that refuses storage is not a reason to fail to start.
      // The defaults are the safe ones: still backgrounds, pale home.
    }
  }

  Future<void> setFashionPlus(bool on) async {
    if (_fashionPlus == on) return;
    _fashionPlus = on;
    notifyListeners();
    await _save(_kPlus, on);
  }

  Future<void> setFashionHome(bool on) async {
    if (_fashionHome == on) return;
    _fashionHome = on;
    notifyListeners();
    await _save(_kHome, on);
  }

  Future<void> _save(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }
}
