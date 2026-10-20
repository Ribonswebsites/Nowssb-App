import 'package:shared_preferences/shared_preferences.dart';

/// Run-once storage for the first-use guide on the nav shell.
/// 'welcome' shows once per install, then each tab shows its mark once.
class FirstUseGuide {
  static const welcomeKey = 'nwsb_guide_welcome_v1';
  static const tabsKey = 'nwsb_tab_guide_v1';
  static const tabCount = 5;

  /// The coach id to show now ('welcome' or the tab index), or null.
  static Future<String?> next(int tab) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(welcomeKey) ?? false)) return 'welcome';
    final seen = prefs.getStringList(tabsKey) ?? const <String>[];
    final id = '$tab';
    return seen.contains(id) ? null : id;
  }

  static Future<void> markDone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == 'welcome') {
      await prefs.setBool(welcomeKey, true);
      return;
    }
    final seen = List<String>.from(prefs.getStringList(tabsKey) ?? const <String>[]);
    if (!seen.contains(id)) {
      seen.add(id);
      await prefs.setStringList(tabsKey, seen);
    }
  }

  /// "Skip guide": never show any guide mark again on this install.
  static Future<void> skipAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(welcomeKey, true);
    await prefs.setStringList(tabsKey, [for (var i = 0; i < tabCount; i++) '$i']);
  }
}
