/// Every real place in the app the Menu and Settings search can take you.
///
/// One list so the hamburger and Settings find the same things; each entry
/// either switches a bottom tab or opens a page — nothing here is a dead end.
library;

import 'package:flutter/material.dart';

import '../features/social/connect_screen.dart';
import '../features/wordprint/word_print_screen.dart';
import '../screens/about_page.dart';
import '../screens/app_settings.dart';
import '../screens/fashion_plus.dart';
import '../screens/notifications_settings.dart';
import '../screens/player_settings.dart';
import '../screens/quick_access.dart';
import '../screens/sound_library.dart';
import '../screens/store/request_words.dart';
import '../screens/subscription.dart';
import '../shell/nav_shell.dart';

class AppDest {
  const AppDest({
    required this.id,
    required this.icon,
    required this.overline,
    required this.title,
    required this.pill,
    required this.sub,
    this.tab,
    this.page,
    this.action,
    this.keywords = '',
  });

  final String id;
  final IconData icon;
  final String overline;
  final String title;
  final String pill;
  final String sub;

  /// Bottom tab to switch to (0 Connect, 1 Practice, 2 Library, 3 Store, 4 Profile).
  final int? tab;
  final WidgetBuilder? page;
  final void Function(BuildContext context)? action;
  final String keywords;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final hay = '$title $overline $pill $sub $keywords'.toLowerCase();
    return q.toLowerCase().split(RegExp(r'\s+')).every(hay.contains);
  }
}

/// The hamburger's own destinations, in menu order.
final List<AppDest> menuDestinations = [
  const AppDest(id: 'practice', icon: Icons.self_improvement_rounded, overline: 'Practice', title: "Today's words", pill: 'Practice', sub: 'Tap a word and the player opens on it', tab: 1, keywords: 'meditate daily words play'),
  const AppDest(id: 'library', icon: Icons.library_music_outlined, overline: 'Library', title: 'Everything you can hear', pill: 'Library', sub: 'Saved words, playlists, now playing', tab: 2, keywords: 'saved playlist listen'),
  AppDest(id: 'sound', icon: Icons.graphic_eq_rounded, overline: 'Sound', title: 'Sound Library', pill: 'Root frequencies', sub: 'Tones and frequencies to listen to', page: (_) => const SoundLibraryScreen(), keywords: 'tones frequency healing'),
  AppDest(id: 'science', icon: Icons.science_outlined, overline: 'Learn', title: 'Word Science', pill: 'The NowssB system', sub: 'How Prakrit words carry meaning', page: (_) => const AboutNowssbScreen(science: true), keywords: 'about prakrit learn system'),
  const AppDest(id: 'store', icon: Icons.shopping_bag_outlined, overline: 'Store', title: 'NowssB Store', pill: 'Words, meanings, eBooks', sub: 'Word Atelier, Meanings and eBooks', tab: 3, keywords: 'buy shop meaning atelier ebooks'),
  AppDest(id: 'plans', icon: Icons.workspace_premium_outlined, overline: 'Plans', title: 'Your plan', pill: 'Resonance, Frequency, Frequency X', sub: 'Compare and change plans', page: (_) => const SubscriptionScreen(), keywords: 'subscription premium upgrade billing'),
  AppDest(id: 'connect', icon: Icons.forum_outlined, overline: 'Community', title: 'NowssB Connect', pill: 'Thoughts, quotes and images', sub: 'Post and read the board', page: (_) => const ConnectScreen(), keywords: 'community post share board'),
  AppDest(id: 'wordprint', icon: Icons.fingerprint_rounded, overline: 'You', title: 'Word Print', pill: 'Your public profile', sub: 'What others see of your practice', page: (_) => const WordPrintScreen(), keywords: 'public profile'),
  const AppDest(id: 'profile', icon: Icons.person_outline_rounded, overline: 'You', title: 'Profile', pill: 'Account and plan', sub: 'Your name, photo and account', tab: 4, keywords: 'account me edit'),
  AppDest(id: 'settings', icon: Icons.settings_outlined, overline: 'Settings', title: 'Settings', pill: 'Player, look, alerts, account', sub: 'Everything you can change', page: (_) => const AppSettingsScreen(), keywords: 'preferences options'),
];

/// Settings pages the hamburger search can also reach directly.
final List<AppDest> settingsDestinations = [
  AppDest(id: 'notifications', icon: Icons.notifications_none_rounded, overline: 'Settings · Alerts', title: 'Notifications', pill: 'Daily words and reminders', sub: 'What this phone tells you', page: (_) => const NotificationsSettingsPage(), keywords: 'alerts push reminders'),
  AppDest(id: 'player', icon: Icons.equalizer_rounded, overline: 'Settings · Player', title: 'Player Settings', pill: 'Equalizer, quality, sleep', sub: 'How words play', page: (_) => const PlayerSettingsScreen(), keywords: 'equalizer bass crossfade sleep timer audio quality download'),
  AppDest(id: 'zenplus', icon: Icons.auto_awesome_outlined, overline: 'Settings · Look', title: 'Zen Plus', pill: 'Moving backgrounds', sub: 'Motion on or still', page: (_) => const FashionPlusScreen(), keywords: 'motion video background animation'),
  AppDest(id: 'quickaccess', icon: Icons.dashboard_customize_outlined, overline: 'Settings · Nav', title: 'Quick Access', pill: 'Bottom navigation', sub: 'Shape, colour and icons', page: (_) => const QuickAccessScreen(), keywords: 'nav bar bottom tabs customize'),
  AppDest(id: 'request', icon: Icons.edit_note_rounded, overline: 'Words', title: 'Request Words', pill: 'Ask the atelier', sub: 'Request a word to be made', action: openRequestWords, keywords: 'request word atelier'),
];

/// Opens [d] from anywhere. [goTab] is the hamburger's own tab switcher.
void openDest(BuildContext context, AppDest d, {void Function(int tab)? goTab, bool replace = false}) {
  final nav = Navigator.of(context);
  if (d.tab != null) {
    if (goTab != null) {
      nav.pop();
      goTab(d.tab!);
    } else {
      NavScope.goTo(context, d.tab!);
    }
    return;
  }
  if (d.action != null) {
    d.action!(context);
    return;
  }
  final route = MaterialPageRoute<void>(builder: d.page!);
  if (replace) {
    nav.pushReplacement(route);
  } else {
    nav.push(route);
  }
}

