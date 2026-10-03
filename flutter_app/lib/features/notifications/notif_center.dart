/// The one place a NowssB phone notification is drawn.
///
/// Every source goes through [NotifCenter.present]: server pushes (FCM,
/// foreground and background), the inbox watch, and in-app events. It
/// applies, in order: signed in · category switch · promo-to-admin · quiet
/// hours (promos dropped, everything else silent) · de-duplication — then
/// draws on the category's own Android channel with a tap route.
///
/// Locally scheduled notifications (notif_scheduler.dart) are drawn by
/// Android at their time; they were checked against the same rules when
/// they were planned.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notif_categories.dart';
import 'notif_prefs.dart';
import 'notif_router.dart';

class NwsbNotice {
  const NwsbNotice({
    required this.category,
    required this.title,
    required this.body,
    this.route,
    this.key = '',
    bool? promo,
  }) : _promo = promo;

  final NotifCategory category;
  final String title;
  final String body;
  final String? route;

  /// Stable id for de-duplication (server nid, inbox doc id, schedule key).
  final String key;
  final bool? _promo;
  bool get promo => _promo ?? category.promo;

  String get effectiveRoute => (route == null || route!.isEmpty) ? category.defaultRoute : route!;

  /// From an FCM message: the new data-only format (data.nwsb == '1') or an
  /// older one (type/title/body/route in data, maybe a notification block).
  static NwsbNotice fromRemote(RemoteMessage m) {
    final d = m.data;
    final cat = d['nwsb'] == '1'
        ? NotifCategories.byId('${d['cat'] ?? ''}')
        : NotifCategories.forKind('${d['type'] ?? ''}');
    return NwsbNotice(
      category: cat,
      title: '${d['title'] ?? m.notification?.title ?? 'NowssB'}',
      body: '${d['body'] ?? m.notification?.body ?? ''}',
      route: '${d['route'] ?? ''}',
      key: '${d['nid'] ?? m.messageId ?? ''}',
      promo: d['promo'] == null ? null : d['promo'] == '1',
    );
  }

  String payload() => jsonEncode({'route': effectiveRoute, 'cat': category.id});
}

/// Why [NotifCenter.decide] said no (null = show).
enum NotifSkip { signedOut, switchedOff, adminPromo, quietPromo, duplicate, planned }

class NotifCenter {
  NotifCenter._();
  static final NotifCenter instance = NotifCenter._();

  static const kPlanned = 'nwsb_notif_planned';
  static const icon = '@drawable/ic_stat_nowssb';

  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get ready => _ready;
  String? _logoPath;

  /// Foreground set-up: plugin, channels, permission, tap handling.
  Future<void> init({bool requestPermission = true}) async {
    if (_ready) return;
    try {
      await plugin.initialize(
        const InitializationSettings(android: AndroidInitializationSettings(icon)),
        onDidReceiveNotificationResponse: (r) => _onTap(r.payload),
      );
      await ensureChannels(plugin);
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (requestPermission) await android?.requestNotificationsPermission();
      _ready = true;
      await _ensureLogo();
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _onTap(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('NowssB notifications init: $e');
    }
  }

  static Future<void> ensureChannels(FlutterLocalNotificationsPlugin plugin) async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final c in NotifCategories.all) {
      await android.createNotificationChannel(c.channel);
    }
    // The single catch-all channel of older builds ("NowssB": practice,
    // offers and account in one) — replaced by the per-category ones.
    try {
      await android.deleteNotificationChannel('nowssb_alerts');
    } catch (_) {}
  }

  void _onTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    String? route;
    try {
      final v = jsonDecode(payload);
      if (v is Map) {
        route = '${v['route'] ?? ''}';
        if (route.isEmpty) route = NotifCategories.byId('${v['cat'] ?? ''}').defaultRoute;
      }
    } catch (_) {
      // Older payloads were the bare kind ('routine', 'streak', …).
      route = NotifCategories.forKind(payload).defaultRoute;
    }
    NotifRouter.instance.open(route);
  }

  /// Taps on pushes Android drew itself (older-format messages).
  Future<void> bindPushTaps() async {
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((m) => NotifRouter.instance.open(NwsbNotice.fromRemote(m).effectiveRoute));
      final first = await FirebaseMessaging.instance.getInitialMessage();
      if (first != null) NotifRouter.instance.open(NwsbNotice.fromRemote(first).effectiveRoute);
    } catch (e) {
      debugPrint('NowssB push taps: $e');
    }
  }

  /// The rules, without side effects except the de-dup ledger.
  static Future<NotifSkip?> decide(NwsbNotice n, NotifPrefs prefs, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    if (prefs.uid.isEmpty) return NotifSkip.signedOut;
    if (!prefs.isOn(n.category)) return NotifSkip.switchedOff;
    if (n.promo && prefs.isAdmin) return NotifSkip.adminPromo;
    if (n.promo && prefs.inQuiet(t)) return NotifSkip.quietPromo;
    if (await _wasPlanned(n, t)) return NotifSkip.planned;
    final fresh = await prefs.claim(key: n.key, title: n.title, body: n.body, now: t);
    return fresh ? null : NotifSkip.duplicate;
  }

  /// Draws [n] if the rules allow. Works in the FCM background isolate too
  /// ([background]: the plugin is set up on the spot).
  Future<bool> present(NwsbNotice n, {bool background = false}) async {
    final prefs = NotifPrefs.instance;
    await prefs.load(fresh: true);
    final skip = await decide(n, prefs);
    if (skip != null) return false;
    if (background && !_ready) {
      try {
        await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings(icon)));
        await ensureChannels(plugin);
      } catch (_) {}
    } else if (!_ready) {
      return false;
    }
    try {
      await plugin.show(
        idFor(n),
        n.title,
        n.body,
        NotificationDetails(android: details(n.category, n.title, n.body, silent: prefs.inQuiet(DateTime.now()), logoPath: _logoPath ?? await _existingLogo())),
        payload: n.payload(),
      );
      return true;
    } catch (e) {
      debugPrint('NowssB notification show: $e');
      return false;
    }
  }

  /// Same key → same Android id, so a repeat replaces rather than stacks.
  static int idFor(NwsbNotice n) {
    final k = n.key.isNotEmpty ? n.key : '${n.category.id}|${n.title}|${n.body}';
    final h = int.parse(NotifPrefs.textKey(k, ''), radix: 16);
    return 0x10000 + (h % 0x3fff0000);
  }

  static AndroidNotificationDetails details(NotifCategory c, String title, String body,
      {bool silent = false, String? logoPath}) {
    final logo = logoPath == null ? null : FilePathAndroidBitmap(logoPath);
    return AndroidNotificationDetails(
      c.channelId,
      c.channelName,
      channelDescription: c.sub,
      importance: c.importance,
      priority: c.priority,
      icon: icon,
      largeIcon: logo,
      color: const Color(0xFFE8D5A3),
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      category: switch (c.id) {
        'streak' || 'word_of_day' || 'reader' || 'daily_rewards' => AndroidNotificationCategory.reminder,
        'inbox' => AndroidNotificationCategory.message,
        'offers' => AndroidNotificationCategory.promo,
        'subscription' => AndroidNotificationCategory.status,
        _ => AndroidNotificationCategory.social,
      },
      groupKey: 'nowssb.${c.id}',
      silent: silent,
    );
  }

  /// Local notifications planned with the OS. If one of them has already
  /// been drawn by Android, the same text arriving in-app (e.g. a Reader
  /// reminder the app's own timer also noticed) is not drawn again.
  static Future<void> recordPlanned(Map<String, int> textKeyToAt) async {
    final p = await SharedPreferences.getInstance();
    // Keep the last two days of already-fired ones: they are the ones an
    // in-app copy could still duplicate.
    final keep = <String, int>{};
    final floor = DateTime.now().subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
    try {
      final old = jsonDecode(p.getString(kPlanned) ?? '{}');
      if (old is Map) {
        old.forEach((k, v) {
          if (v is num && v.toInt() >= floor && v.toInt() <= DateTime.now().millisecondsSinceEpoch) keep['$k'] = v.toInt();
        });
      }
    } catch (_) {}
    await p.setString(kPlanned, jsonEncode({...keep, ...textKeyToAt}));
  }

  static Future<bool> _wasPlanned(NwsbNotice n, DateTime now) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = jsonDecode(p.getString(kPlanned) ?? '{}');
      if (raw is! Map) return false;
      final at = raw[NotifPrefs.textKey(n.title, n.body)];
      return at is num && at.toInt() <= now.millisecondsSinceEpoch + 60000;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureLogo() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logo = File('${dir.path}/nwsb_notif_logo.png');
      if (!await logo.exists() || await logo.length() < 500) {
        final data = await rootBundle.load('assets/notifications/logo.png');
        await logo.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      _logoPath = logo.path;
    } catch (_) {}
  }

  static Future<String?> _existingLogo() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logo = File('${dir.path}/nwsb_notif_logo.png');
      return await logo.exists() ? logo.path : null;
    } catch (_) {
      return null;
    }
  }
}

/// FCM background isolate (registered in main.dart through
/// phone_notifications.dart). A message that carries a notification block
/// was already drawn by Android — drawing it again here was the second copy
/// of every push; only the de-dup ledger is updated for it.
@pragma('vm:entry-point')
Future<void> nwsbNotifBackground(RemoteMessage message) async {
  final n = NwsbNotice.fromRemote(message);
  if (message.notification != null) {
    await NotifPrefs.instance.remember(
        n.key.isEmpty ? 'fcm:${message.messageId}' : n.key, n.title, n.body, DateTime.now().millisecondsSinceEpoch);
    return;
  }
  await NotifCenter.instance.present(n, background: true);
}
