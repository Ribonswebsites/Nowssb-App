/// Phone notifications + the in-app banner.
///
/// The inbox ([NotifStore]) used to be the only place a notification existed,
/// so nothing ever reached the shade. This posts the same item through
/// `flutter_local_notifications` 17.2 (high-importance channel, so Android
/// draws a heads-up) and asks Firebase Messaging for a token the existing
/// `/api/push` sender already understands (`fcm:<token>` on `pushSubs`).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';
import 'notifications.dart';

const _channelId = 'nowssb_alerts';

/// Foreground FCM does not draw a shade notification on Android. Background
/// isolates do. Both paths land in the same channel.
@pragma('vm:entry-point')
Future<void> nwsbFcmBackground(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@drawable/ic_stat_nowssb');
  await plugin.initialize(const InitializationSettings(android: android));
  final n = message.notification;
  final title = n?.title ?? message.data['title']?.toString() ?? 'NowssB';
  final body = n?.body ?? message.data['body']?.toString() ?? '';
  await plugin.show(
    title.hashCode ^ DateTime.now().millisecondsSinceEpoch,
    title,
    body,
    const NotificationDetails(android: _androidDetails),
    payload: message.data['type']?.toString(),
  );
}

const _androidDetails = AndroidNotificationDetails(
  _channelId,
  'NowssB',
  channelDescription: 'Practice, gifts, orders and account updates',
  importance: Importance.max,
  priority: Priority.high,
  icon: '@drawable/ic_stat_nowssb',
  playSound: true,
  enableVibration: true,
);

class PhoneNotifications {
  PhoneNotifications._();
  static final PhoneNotifications instance = PhoneNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _seq = 1;

  Future<void> start() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@drawable/ic_stat_nowssb');
      await _plugin.initialize(
        const InitializationSettings(android: android),
      );
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'NowssB',
          description: 'Practice, gifts, orders and account updates',
          importance: Importance.max,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('NowssB notifications init: $e');
    }

    NotifStore.onDelivered = (item) {
      unawaited(show(item));
      NotificationBanner.push(item);
    };

    if (NwsbFirebase.ready) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        FirebaseMessaging.onMessage.listen((message) {
          final n = message.notification;
          final type = message.data['type']?.toString() ?? 'support';
          unawaited(NotifStore.instance.notify(
            type: NotifStore.allKinds.contains(type) ? type : 'support',
            title: n?.title ?? message.data['title']?.toString() ?? 'NowssB',
            body: n?.body ?? message.data['body']?.toString() ?? '',
          ));
        });
        await _saveToken();
        FirebaseAuth.instance.authStateChanges().listen((_) {
          unawaited(_saveToken());
        });
      } catch (e) {
        debugPrint('NowssB FCM: $e');
      }
    }

    await _scheduleDaily();
  }

  /// First open after this build, and any later open with an empty inbox,
  /// puts something on the phone and in the banner. Permission is already
  /// requested by [start].
  Future<void> announceAfterLaunch() async {
    await start();
    final prefs = await SharedPreferences.getInstance();
    final welcomed = prefs.getBool('nwsb_phone_welcomed') == true;
    if (!welcomed || NotifStore.instance.feed.isEmpty) {
      await prefs.setBool('nwsb_phone_welcomed', true);
      await prefs.setInt('nwsb_phone_last_shown', DateTime.now().millisecondsSinceEpoch);
      await NotifStore.instance.notify(
        type: 'routine',
        title: 'Your daily words are ready',
        body: 'Open NowssB and sit with one word. A few minutes keeps the day.',
      );
      await NotifStore.instance.notify(
        type: 'streak',
        title: 'Streak is waiting',
        body: 'Practice once today so the streak does not drop.',
      );
      await NotifStore.instance.notify(
        type: 'offers',
        title: 'Notifications are on',
        body: 'Gifts, orders and practice reminders will show on this phone.',
      );
      return;
    }
    final last = prefs.getInt('nwsb_phone_last_shown') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 12).inMilliseconds) return;
    await prefs.setInt('nwsb_phone_last_shown', now);
    await show(NotifStore.instance.feed.first);
    NotificationBanner.push(NotifStore.instance.feed.first);
  }

  Future<void> show(NotifItem item) async {
    if (!_ready) return;
    if (!NotifStore.instance.isKindOn(item.type)) return;
    try {
      await _plugin.show(
        _seq++,
        item.title,
        item.body,
        const NotificationDetails(android: _androidDetails),
        payload: item.type,
      );
    } catch (e) {
      debugPrint('NowssB notification show: $e');
    }
  }

  Future<void> _scheduleDaily() async {
    if (!_ready) return;
    try {
      await _plugin.periodicallyShow(
        88001,
        'NowssB',
        'Your daily words are ready.',
        RepeatInterval.daily,
        const NotificationDetails(android: _androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'routine',
      );
    } catch (e) {
      debugPrint('NowssB daily reminder: $e');
    }
  }

  Future<void> _saveToken() async {
    if (!NwsbFirebase.ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final id = sha256.convert(utf8.encode(token)).toString().substring(0, 40);
      await FirebaseFirestore.instance.collection('pushSubs').doc(id).set({
        'endpoint': 'fcm:$token',
        'fcmToken': token,
        'platform': 'android-native',
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NowssB push token: $e');
    }
  }
}

/// In-app banner. The host mounts once under MaterialApp.
class NotificationBanner {
  NotificationBanner._();
  static final items = ValueNotifier<List<NotifItem>>(const []);

  static void push(NotifItem item) {
    items.value = [item, ...items.value].take(3).toList();
  }

  static void dismiss(NotifItem item) {
    items.value = items.value.where((e) => e != item).toList();
  }
}
