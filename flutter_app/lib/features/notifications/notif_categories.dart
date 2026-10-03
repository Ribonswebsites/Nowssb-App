/// Every kind of phone notification NowssB sends, one Android channel each.
///
/// Each category has its own trigger (see notif_scheduler.dart for the local
/// schedules and functions/_lib/notify/push.js for the server events), its
/// own switch in Settings › Notifications › Preferences, and its own channel
/// so the person can also tune it in Android's settings.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifCategory {
  const NotifCategory({
    required this.id,
    required this.label,
    required this.sub,
    required this.channelId,
    required this.channelName,
    required this.importance,
    required this.defaultRoute,
    this.group = 'Your practice',
    this.promo = false,
    this.legacyKind,
  });

  /// Matches `data.cat` in server pushes.
  final String id;
  final String label;
  final String sub;
  final String channelId;
  final String channelName;
  final Importance importance;

  /// Where a tap goes when the notification carries no route of its own.
  final String defaultRoute;
  final String group;

  /// Promotional: dropped for admins and during quiet hours.
  final bool promo;

  /// The older NotifStore kind with the same meaning, so a switch turned
  /// off on either settings page stops it.
  final String? legacyKind;

  Priority get priority => switch (importance) {
        Importance.high || Importance.max => Priority.high,
        Importance.low || Importance.min => Priority.low,
        _ => Priority.defaultPriority,
      };

  AndroidNotificationChannel get channel => AndroidNotificationChannel(
        channelId,
        channelName,
        description: sub,
        importance: importance,
      );
}

class NotifCategories {
  NotifCategories._();

  static const wordOfDay = NotifCategory(
    id: 'word_of_day',
    label: 'Word of the day',
    sub: 'Each morning at your reminder time, with the day’s word and meaning',
    channelId: 'nwsb_word_of_day',
    channelName: 'Word of the day',
    importance: Importance.defaultImportance,
    defaultRoute: 'practice',
    legacyKind: 'routine',
  );
  static const streak = NotifCategory(
    id: 'streak',
    label: 'Streak reminder',
    sub: 'In the evening, only on days you have not practised yet',
    channelId: 'nwsb_streak',
    channelName: 'Streak reminders',
    importance: Importance.high,
    defaultRoute: 'progress',
    legacyKind: 'streak',
  );
  static const weekly = NotifCategory(
    id: 'weekly',
    label: 'Weekly summary',
    sub: 'Sunday evening: your words, minutes and streak for the week',
    channelId: 'nwsb_weekly',
    channelName: 'Weekly summary',
    importance: Importance.low,
    defaultRoute: 'progress',
  );
  static const reader = NotifCategory(
    id: 'reader',
    label: 'Reading reminders',
    sub: 'The “remind me” times you set in the Reader',
    channelId: 'nwsb_reader',
    channelName: 'Reading reminders',
    importance: Importance.high,
    defaultRoute: 'reader',
    legacyKind: 'reader',
  );
  static const dailyRewards = NotifCategory(
    id: 'daily_rewards',
    label: 'Daily spin & scratch',
    sub: 'When a new day’s spin and scratch card are ready',
    channelId: 'nwsb_daily_rewards',
    channelName: 'Daily spin & scratch',
    importance: Importance.defaultImportance,
    defaultRoute: 'rewards',
    group: 'Rewards',
  );
  static const rewards = NotifCategory(
    id: 'rewards',
    label: 'Coins & rewards',
    sub: 'Coins earned, a friend joining with your link, team and payout news',
    channelId: 'nwsb_rewards',
    channelName: 'Coins & rewards',
    importance: Importance.defaultImportance,
    defaultRoute: 'earn',
    group: 'Rewards',
  );
  static const gifts = NotifCategory(
    id: 'gifts',
    label: 'Gifts',
    sub: 'When a gift you sent is opened',
    channelId: 'nwsb_gifts',
    channelName: 'Gifts',
    importance: Importance.high,
    defaultRoute: 'gifts',
    group: 'Rewards',
  );
  static const requests = NotifCategory(
    id: 'requests',
    label: 'Word requests',
    sub: 'When a word you asked for is added',
    channelId: 'nwsb_requests',
    channelName: 'Word requests',
    importance: Importance.high,
    defaultRoute: 'requests',
    group: 'Content',
  );
  static const newContent = NotifCategory(
    id: 'new_content',
    label: 'New ebooks & words',
    sub: 'When new ebooks or words are published to the library',
    channelId: 'nwsb_new_content',
    channelName: 'New ebooks & words',
    importance: Importance.defaultImportance,
    defaultRoute: 'ebooks',
    group: 'Content',
  );
  static const subscription = NotifCategory(
    id: 'subscription',
    label: 'Subscription',
    sub: 'Renewed, expiring soon, payment problems and plan changes',
    channelId: 'nwsb_subscription',
    channelName: 'Subscription & billing',
    importance: Importance.high,
    defaultRoute: 'subscription',
    group: 'Account',
    legacyKind: 'subscription',
  );

  /// Channel id 'nowssb' is the one older server builds name, so pushes from
  /// them land here instead of Android's "Miscellaneous".
  static const inbox = NotifCategory(
    id: 'inbox',
    label: 'Messages from NowssB',
    sub: 'Messages the NowssB team sends to you',
    channelId: 'nowssb',
    channelName: 'Messages from NowssB',
    importance: Importance.high,
    defaultRoute: 'inbox',
    group: 'Account',
  );
  static const offers = NotifCategory(
    id: 'offers',
    label: 'Offers & news',
    sub: 'Announcements and offers from NowssB. Never during quiet hours',
    channelId: 'nwsb_offers',
    channelName: 'Offers & news',
    importance: Importance.low,
    defaultRoute: 'store',
    group: 'Account',
    promo: true,
    legacyKind: 'offers',
  );

  static const all = <NotifCategory>[
    wordOfDay,
    streak,
    weekly,
    reader,
    dailyRewards,
    rewards,
    gifts,
    requests,
    newContent,
    subscription,
    inbox,
    offers,
  ];

  static const groups = <String>['Your practice', 'Rewards', 'Content', 'Account'];

  static NotifCategory byId(String? id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return inbox;
  }

  /// A server `kind`/`type` (or an older NotifStore kind) → category. Same
  /// table as categoryFor() in functions/_lib/notify/push.js.
  static NotifCategory forKind(String? kind) {
    final k = (kind ?? '').toLowerCase();
    if (k.isEmpty) return inbox;
    for (final c in all) {
      if (c.id == k) return c;
    }
    if (k == 'gift' || k.startsWith('gift')) return gifts;
    if (k == 'request_done' || k == 'arrivals') return requests;
    if (k == 'plan' || k.startsWith('sub')) return subscription;
    if (k == 'reference' || k == 'earn' || k == 'payout' || k == 'economy' ||
        k == 'coins' || k == 'reward' || k == 'badge') {
      return rewards;
    }
    if (k == 'broadcast' || k == 'offer' || k == 'offers' || k == 'promo') {
      return offers;
    }
    if (k == 'routine') return wordOfDay;
    if (k == 'orders') return subscription;
    return inbox;
  }
}
