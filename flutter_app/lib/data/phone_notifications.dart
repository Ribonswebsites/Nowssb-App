/// Phone notifications — start-up, push wiring and the in-app banner.
///
/// The notification system itself lives in lib/features/notifications:
///   notif_categories.dart  one category + Android channel per kind
///   notif_prefs.dart       switches, quiet hours, reminder time, de-dup
///   notif_center.dart      the one place a notification is drawn
///   notif_scheduler.dart   local schedules (word of the day, streak, …)
///   notif_router.dart      where a tap goes
///   notif_watchers.dart    inbox + new-content watches
///
/// Nothing is posted at launch any more. Older builds posted two made-up
/// notifications back to back the moment the start animation ended (a daily
/// "words are ready"/"streak" line and a "50% off" offer no Play offer
/// backed), and a daily periodicallyShow that Android never delivered (no
/// ScheduledNotificationReceiver in the manifest) — so those two, together,
/// were the only notifications anyone ever saw.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_state.dart';
import '../features/notifications/notif_categories.dart';
import '../features/notifications/notif_center.dart';
import '../features/notifications/notif_prefs.dart';
import '../features/notifications/notif_router.dart';
import '../features/notifications/notif_scheduler.dart';
import '../features/notifications/notif_watchers.dart';
import 'firebase.dart';
import 'notifications.dart';
import 'remember_me.dart';

/// FCM background isolate entry (main.dart registers it).
@pragma('vm:entry-point')
Future<void> nwsbFcmBackground(RemoteMessage message) => nwsbNotifBackground(message);

class PhoneNotifications {
  PhoneNotifications._();
  static final PhoneNotifications instance = PhoneNotifications._();

  bool _started = false;
  bool _listening = false;
  String? _uid;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await NotifPrefs.instance.load();
    await NotifCenter.instance.init();

    // In-app events (Reader reminders, NotifStore.notify callers): the feed
    // keeps them, the banner shows them, the phone draws them once.
    NotifStore.onDelivered = (item) {
      if (FirebaseAuth.instance.currentUser != null) NotificationBanner.push(item);
      unawaited(NotifCenter.instance.present(NwsbNotice(
        category: NotifCategories.forKind(item.type),
        title: item.title,
        body: item.body,
        key: 'local:${item.type}:${item.at}',
      )));
    };

    if (!NwsbFirebase.ready || _listening) return;
    _listening = true;
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen(_onForegroundPush);
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => unawaited(_saveToken()));
      await NotifCenter.instance.bindPushTaps();
      AdminState.instance.addListener(_syncIdentity);
      FirebaseAuth.instance.authStateChanges().listen(_onAuth);
    } catch (e) {
      debugPrint('NowssB FCM: $e');
    }
  }

  void _onForegroundPush(RemoteMessage message) {
    if (FirebaseAuth.instance.currentUser == null) return;
    final n = NwsbNotice.fromRemote(message);
    if (n.category.id == NotifCategories.offers.id) {
      // Broadcasts have no inbox document: keep one in the feed (which also
      // draws it, through onDelivered).
      unawaited(NotifStore.instance.notify(type: 'offers', title: n.title, body: n.body));
      return;
    }
    // Everything else already has its inbox document (the feed shows it).
    unawaited(NotifCenter.instance.present(n));
  }

  Future<void> _onAuth(User? user) async {
    final signedIn = user != null && !user.isAnonymous;
    final was = _uid;
    _uid = signedIn ? user.uid : null;
    await _syncIdentity();
    if (signedIn) {
      await _saveToken();
      NotifWatchers.instance.bind(user.uid);
    } else {
      NotifWatchers.instance.bind(null);
      NotificationBanner.items.value = const [];
      await NotifScheduler.instance.cancelAll();
      // This phone's token stays registered under the account that just
      // signed out; retire it so that account's pushes stop coming here. A
      // fresh token is saved at the next sign-in.
      if (was != null) {
        try {
          await FirebaseMessaging.instance.deleteToken();
        } catch (_) {}
      }
    }
    NotifScheduler.instance.replanSoon();
  }

  Future<void> _syncIdentity() => NotifPrefs.instance.setIdentity(
        uid: _uid ?? '',
        admin: _uid != null && AdminState.instance.isAdmin,
      );

  /// Splash calls this once the start animation is done. Taps that opened
  /// the app are routed now; local schedules are planned. Nothing is posted.
  Future<void> announceAfterLaunch() async {
    await start();
    final remember = await RememberMe.read();
    if (!remember || FirebaseAuth.instance.currentUser == null) {
      NotificationBanner.items.value = const [];
    }
    NotifRouter.instance.markReady();
    NotifScheduler.instance.start();
    NotifWatchers.instance.startContent();
  }

  /// Called after a sign-in that just succeeded in this session.
  void armSession() {
    NotifRouter.instance.markReady();
    NotifScheduler.instance.start();
    unawaited(NotifScheduler.instance.refreshAccount());
  }

  String _country(SharedPreferences prefs) {
    for (final key in const ['nwsb.payoutCountry', 'country', 'ss_country']) {
      final saved = prefs.getString(key);
      if (saved != null && saved.isNotEmpty && saved != 'XX') return saved;
    }
    return PlatformDispatcher.instance.locale.countryCode ?? '';
  }

  /// pushSubs/{sha(token)} — only under the signed-in account (rules
  /// enforce it). notifFormat 2 tells the server this build reads
  /// data-only pushes (functions/_lib/notify/push.js).
  Future<void> _saveToken() async {
    if (!NwsbFirebase.ready) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final id = sha256.convert(utf8.encode(token)).toString().substring(0, 40);
      final prefs = await SharedPreferences.getInstance();
      await FirebaseFirestore.instance.collection('pushSubs').doc(id).set({
        'endpoint': 'fcm:$token',
        'fcmToken': token,
        'platform': 'android-native',
        'notifFormat': 2,
        'uid': uid,
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
///
/// Popups belong on the home tab, and only when nothing is pushed over it.
/// Agreement pages, store intros, and every other tab stay quiet.
class NotificationBanner {
  NotificationBanner._();
  static final items = ValueNotifier<List<NotifItem>>(const []);
  static final showPopups = ValueNotifier<bool>(true);

  static bool _onHome = true;
  static bool _routeRoot = true;

  static void setOnHome(bool value) {
    if (_onHome == value) return;
    _onHome = value;
    _publish();
  }

  static void setRouteRoot(bool value) {
    if (_routeRoot == value) return;
    _routeRoot = value;
    _publish();
  }

  static void _publish() {
    final next = _onHome && _routeRoot;
    if (showPopups.value != next) showPopups.value = next;
  }

  static void push(NotifItem item) {
    if (FirebaseAuth.instance.currentUser == null) return;
    items.value = [item, ...items.value].take(3).toList();
  }

  static void dismiss(NotifItem item) {
    items.value = items.value.where((e) => e != item).toList();
  }
}

/// Hides in-app banners as soon as a page is pushed over the shell.
class HomePopupRouteObserver extends NavigatorObserver {
  void _sync() {
    final nav = navigator;
    if (nav == null) return;
    NotificationBanner.setRouteRoot(!nav.canPop());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _sync();
}
