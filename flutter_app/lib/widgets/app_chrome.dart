/// Home's chrome for any page: the top bar ([AppTopBar]) and the floating
/// pill nav ([AppBottomNav], drawn by NavShell over every main tab).
library;

import 'package:flutter/material.dart';

import '../data/notifications.dart';
import '../screens/app_settings.dart';
import '../screens/fashion/header.dart';
import '../screens/notifications_sheet.dart';
import '../shell/nav_shell.dart';
import 'home_menu_drawer.dart';

export '../screens/fashion/header.dart' show HomeHeader;
export '../shell/nav_shell.dart' show AppBottomNav, AppNavItem, NavScope;

/// Home's top bar, already wired: bell (live unread badge) opens the
/// notifications panel, gear opens Settings, hamburger opens the menu.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotifStore.instance,
      builder: (context, _) => HomeHeader(
        notifications: NotifStore.instance.unreadRaw,
        onNotifications: () => showNotificationsSheet(context),
        onSettings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AppSettingsScreen())),
        onMenu: () => showHomeMenuDrawer(context, goTab: (i) => NavScope.goTo(context, i)),
      ),
    );
  }
}
