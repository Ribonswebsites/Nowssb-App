/// Phone notifications + the in-app banner.
///
/// Alerts post through `flutter_local_notifications` only after someone is
/// signed in. The shade uses the NowssB logo and the hands-up still as the
/// big picture. Copy follows the phone's local time and country.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';
import 'notifications.dart';

const _channelId = 'nowssb_alerts';

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
  channelDescription: 'Practice, offers and account updates',
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
  bool _listening = false;
  bool _armed = false;
  int _seq = 1;
  String? _picturePath;
  String? _logoPath;

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
          description: 'Practice, offers and account updates',
          importance: Importance.max,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      await _ensureArt();
      _ready = true;
    } catch (e) {
      debugPrint('NowssB notifications init: $e');
    }

    NotifStore.onDelivered = (item) {
      unawaited(show(item));
      if (FirebaseAuth.instance.currentUser != null) {
        NotificationBanner.push(item);
      }
    };

    if (NwsbFirebase.ready && !_listening) {
      _listening = true;
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        FirebaseMessaging.onMessage.listen((message) {
          if (FirebaseAuth.instance.currentUser == null) return;
          final n = message.notification;
          final type = message.data['type']?.toString() ?? 'subscription';
          unawaited(NotifStore.instance.notify(
            type: NotifStore.allKinds.contains(type) ? type : 'subscription',
            title: n?.title ?? message.data['title']?.toString() ?? 'NowssB',
            body: n?.body ?? message.data['body']?.toString() ?? '',
          ));
        });
        await _saveToken();
        FirebaseAuth.instance.authStateChanges().listen((user) {
          unawaited(_saveToken());
          unawaited(_scheduleDaily(user != null));
          if (user == null) {
            NotificationBanner.items.value = const [];
            return;
          }
          if (_armed) unawaited(deliverForUser(user));
        });
      } catch (e) {
        debugPrint('NowssB FCM: $e');
      }
    }
  }

  /// Splash calls this. Signed-out phones, and remembered-off restores, get nothing.
  Future<void> announceAfterLaunch() async {
    await start();
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('nwsb.rememberMe') ?? true;
    final user = FirebaseAuth.instance.currentUser;
    if (!remember || user == null) {
      await _scheduleDaily(false);
      NotificationBanner.items.value = const [];
      return;
    }
    _armed = true;
    await _scheduleDaily(true);
    await deliverForUser(user);
  }

  /// Called after a sign-in that just succeeded in this session.
  void armSession() {
    _armed = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) unawaited(deliverForUser(user));
  }

  /// One set per local day, written for this account's clock and country.
  Future<void> deliverForUser(User user) async {
    await start();
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dayKey =
        '${user.uid}-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (prefs.getString('nwsb_notif_day') == dayKey) return;
    await prefs.setString('nwsb_notif_day', dayKey);

    final country = _country(prefs);
    final where = country.isEmpty ? '' : ' · $country';
    final rawName = (user.displayName ?? '').trim();
    final first = rawName.isEmpty ? '' : rawName.split(RegExp(r'\s+')).first;
    final who = first.isEmpty ? 'there' : first;
    final hour = now.hour;

    if (hour < 17) {
      final part = hour < 12 ? 'morning' : 'afternoon';
      await NotifStore.instance.notify(
        type: 'routine',
        title: 'Your daily words are ready',
        body:
            'Good $part, $who. Sit with one word. A few minutes keeps the day$where.',
      );
    } else {
      await NotifStore.instance.notify(
        type: 'streak',
        title: 'Streak is waiting',
        body:
            'Practice once before midnight, $who, so today still counts$where.',
      );
    }
    await NotifStore.instance.notify(
      type: 'offers',
      title: 'Today’s offer · 50% off',
      body:
          'Subscription is half price today on this account$where. It ends at midnight, local time.',
    );
  }

  Future<void> show(NotifItem item) async {
    if (!_ready) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    if (!NotifStore.instance.isKindOn(item.type)) return;
    try {
      await _ensureArt();
      await _plugin.show(
        _seq++,
        item.title,
        item.body,
        NotificationDetails(android: _richDetails(item.title, item.body)),
        payload: item.type,
      );
    } catch (e) {
      debugPrint('NowssB notification show: $e');
    }
  }

  AndroidNotificationDetails _richDetails(String title, String body) {
    final logo = _logoPath;
    final picture = _picturePath;
    final logoBitmap =
        logo == null ? null : FilePathAndroidBitmap(logo);
    return AndroidNotificationDetails(
      _channelId,
      'NowssB',
      channelDescription: 'Practice, offers and account updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_stat_nowssb',
      largeIcon: logoBitmap,
      styleInformation: picture == null
          ? null
          : BigPictureStyleInformation(
              FilePathAndroidBitmap(picture),
              largeIcon: logoBitmap,
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: false,
            ),
      playSound: true,
      enableVibration: true,
    );
  }

  Future<void> _ensureArt() async {
    if (_picturePath != null && _logoPath != null) return;
    final dir = await getApplicationSupportDirectory();
    final picture = File('${dir.path}/nwsb_notif_hands.png');
    final logo = File('${dir.path}/nwsb_notif_logo.png');
    if (!await picture.exists() || await picture.length() < 1000) {
      final data = await rootBundle.load('assets/notifications/hands-offer.png');
      await picture.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    if (!await logo.exists() || await logo.length() < 500) {
      final data = await rootBundle.load('assets/notifications/logo.png');
      await logo.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    _picturePath = picture.path;
    _logoPath = logo.path;
  }

  String _country(SharedPreferences prefs) {
    for (final key in const ['nwsb.payoutCountry', 'country', 'ss_country']) {
      final saved = prefs.getString(key);
      if (saved != null && saved.isNotEmpty && saved != 'XX') return saved;
    }
    return PlatformDispatcher.instance.locale.countryCode ?? '';
  }

  Future<void> _scheduleDaily(bool signedIn) async {
    if (!_ready) return;
    try {
      if (!signedIn) {
        await _plugin.cancel(88001);
        return;
      }
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
      final prefs = await SharedPreferences.getInstance();
      await FirebaseFirestore.instance.collection('pushSubs').doc(id).set({
        'endpoint': 'fcm:$token',
        'fcmToken': token,
        'platform': 'android-native',
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'country': _country(prefs),
        'tzOffsetMin': DateTime.now().timeZoneOffset.inMinutes,
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
    if (FirebaseAuth.instance.currentUser == null) return;
    items.value = [item, ...items.value].take(3).toList();
  }

  static void dismiss(NotifItem item) {
    items.value = items.value.where((e) => e != item).toList();
  }
}
