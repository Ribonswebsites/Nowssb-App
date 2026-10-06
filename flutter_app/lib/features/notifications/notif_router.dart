/// Where a notification tap goes.
///
/// Routes are short strings carried in the payload (local notifications) or
/// in `data.route` (pushes): `practice`, `practice:<wordKey>`,
/// `word:<wordKey>`, `progress`, `rewards`, `coupons`, `gifts`, `earn`,
/// `reference`, `subscription`, `ebooks`, `library`, `store`, `inbox`,
/// `requests`, `reader`, `notifications`, `home`.
///
/// The shell attaches once it is on screen ([attach]); a tap that arrives
/// before that — a cold start from the notification — waits until the
/// shell is there and the start animation is done ([markReady]).
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../screens/practice_player.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/reader/reader_hub.dart';
import '../../screens/store/ebooks_store.dart';
import '../../screens/store/request_words.dart';
import '../../screens/subscription.dart';
import '../../screens/word_detail.dart';
import '../earn/earn_hub_screen.dart';
import '../economy/reference_screen.dart';
import '../gifts/gifts_screen.dart';
import '../programs/coupons_program.dart';
import '../programs/rewards_program.dart';
import 'inbox_screen.dart';
import 'notif_preferences_screen.dart';

class NotifRouter {
  NotifRouter._();
  static final NotifRouter instance = NotifRouter._();

  BuildContext? _context;
  void Function(int tab)? _goTab;
  VoidCallback? _popToRoot;
  bool _ready = false;
  String? _pending;

  /// Called by the shell (NavShell). [goTab] switches the bottom tab after
  /// popping anything pushed over it; [popToRoot] only pops.
  void attach(BuildContext context,
      {required void Function(int tab) goTab, required VoidCallback popToRoot}) {
    _context = context;
    _goTab = goTab;
    _popToRoot = popToRoot;
    // The shell attaches from initState. A tap waiting from before sign-in
    // would otherwise push a route / switch the tab in the middle of that
    // build (setState during build). Route on the next frame instead.
    WidgetsBinding.instance.addPostFrameCallback((_) => _flush());
  }

  void detach(BuildContext context) {
    if (identical(_context, context)) {
      _context = null;
      _goTab = null;
      _popToRoot = null;
    }
  }

  /// After the start animation (PhoneNotifications.announceAfterLaunch).
  void markReady() {
    _ready = true;
    _flush();
  }

  void open(String? route) {
    final r = (route ?? '').trim();
    if (r.isEmpty) return;
    _pending = r;
    _flush();
  }

  void _flush() {
    final r = _pending;
    final ctx = _context;
    if (r == null || ctx == null || !_ready || !ctx.mounted) return;
    _pending = null;
    _go(ctx, r);
  }

  static Word? _word(String key) {
    final k = key.toLowerCase();
    for (final w in ContentStore.instance.library) {
      if (w.key.toLowerCase() == k || w.word.toLowerCase() == k) return w;
    }
    return null;
  }

  /// Screen for [route], or null when the route is a tab (or unknown).
  static Widget? screenFor(String route) {
    final i = route.indexOf(':');
    final head = i < 0 ? route : route.substring(0, i);
    final arg = i < 0 ? '' : route.substring(i + 1);
    switch (head) {
      case 'practice':
        final lib = ContentStore.instance.library;
        final w = (arg.isEmpty ? null : _word(arg)) ?? HomeWidgetSync.wordFor(DateTime.now(), lib);
        if (w == null) return null;
        return PracticePlayerScreen(words: [w], title: 'Word of the day', showIntro: false);
      case 'word':
        final w = _word(arg);
        return w == null ? const RequestWordsScreen() : WordDetail(word: w);
      case 'progress':
        return PracticeProgressScreen(words: ContentStore.instance.library);
      case 'rewards':
        return const RewardsProgramPage();
      case 'coupons':
        return const CouponsProgramPage();
      case 'gifts':
        return const GiftsScreen();
      case 'earn':
        return const EarnHubScreen();
      case 'reference':
        return const ReferenceScreen();
      case 'subscription':
        return const SubscriptionScreen();
      case 'ebooks':
        return const EbooksStoreScreen();
      case 'requests':
        return const RequestWordsScreen();
      case 'reader':
        return const ReaderHubScreen();
      case 'inbox':
        return const InboxScreen();
      case 'notifications':
        return const NotifPreferencesScreen();
    }
    return null;
  }

  /// Bottom tab for [route]: 0 Connect · 1 Practice · 2 Library · 3 Store · 4 Profile.
  static int? tabFor(String route) => switch (route) {
        'home' => 0,
        'library' => 2,
        'store' => 3,
        'profile' => 4,
        _ => null,
      };

  void _go(BuildContext ctx, String route) {
    final tab = tabFor(route);
    final screen = screenFor(route);
    if (tab != null) {
      _goTab?.call(tab);
      return;
    }
    if (screen == null) return;
    _popToRoot?.call();
    Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
