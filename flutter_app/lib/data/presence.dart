/// "Last seen" for the admin console (People, Dashboard "online now").
///
/// On app open, on every return to the foreground and every 4 minutes
/// while the app stays open, the signed-in person's `users/{uid}` gets a
/// merge of:
///   lastSeen      milliseconds, the number the web studio already reads
///   lastSeenAt    the server's own clock (the rules accept only that)
///   lastPlatform  'android' | 'ios'
///   lastApp       'flutter'
///   lastBuild     this build number (NWSB_BUILD_NUMBER)
///   lastOs        the OS version string
/// and, once per launch, a profile mirror the console searches without the
/// server key: email, displayName, photoURL, phone, providers,
/// authCreatedAt. None of these are privileged fields, so it cannot collide
/// with plan or block fields. One `activity` row per launch (`open`, or
/// `signup` for a brand-new account) — the rules accept only that shape.
///
/// Daily sign-in history for the Admin app ("who signed in today", a
/// person's sign-in days): on each launch, each return to the app and at most
/// every 30 minutes while open, `presenceDays/{day}/people/{uid}` and
/// `users/{uid}/days/{day}` get {first, last (server clock), opens, platform,
/// build, os}. The day is India time (UTC+5:30), the console's day.
/// A brand-new account also tells the admins (lib/admin/admin_alert_client).
/// Never throws.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_alert_client.dart';
import '../app_update.dart';
import 'firebase.dart';

class Presence with WidgetsBindingObserver {
  Presence._();
  static final Presence instance = Presence._();

  static const _gap = Duration(minutes: 4);
  DateTime? _last;
  String? _lastUid;
  String? _mirrored;
  bool _started = false;
  bool _foreground = true;
  StreamSubscription<User?>? _sub;
  Timer? _beat;

  void start() {
    if (_started || !NwsbFirebase.ready) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) => ping());
    _beat = Timer.periodic(const Duration(minutes: 4, seconds: 5), (_) {
      if (_foreground) ping();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final was = _foreground;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !was) _openPending = true;
    if (_foreground) ping();
  }

  bool _openPending = true;
  DateTime? _dayAt;
  String? _dayKey;

  /// India-time day key, the same one the admin server uses.
  static String dayKey(DateTime t) =>
      t.toUtc().add(const Duration(minutes: 330)).toIso8601String().substring(0, 10);

  Future<void> _daily(User u, DateTime now) async {
    final day = dayKey(now);
    final open = _openPending;
    if (!open && _dayKey == day && _dayAt != null && now.difference(_dayAt!) < const Duration(minutes: 30)) return;
    _openPending = false;
    _dayKey = day;
    _dayAt = now;
    try {
      final p = await SharedPreferences.getInstance();
      final mark = '${u.uid}|$day';
      final firstToday = p.getString('nwsb_presence_day') != mark;
      final os = Platform.operatingSystemVersion;
      final base = <String, dynamic>{
        'uid': u.uid,
        'day': day,
        'last': FieldValue.serverTimestamp(),
        if (firstToday) 'first': FieldValue.serverTimestamp(),
        if (open || firstToday) 'opens': FieldValue.increment(1),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'build': NwsbAppUpdate.currentBuild,
        'os': os.length > 80 ? os.substring(0, 80) : os,
      };
      final db = FirebaseFirestore.instance;
      final b = db.batch();
      b.set(db.doc('users/${u.uid}/days/$day'), base, SetOptions(merge: true));
      b.set(db.doc('presenceDays/$day/people/${u.uid}'), {
        ...base,
        if ((u.email ?? '').isNotEmpty) 'email': u.email,
        if ((u.displayName ?? '').isNotEmpty) 'name': u.displayName,
      }, SetOptions(merge: true));
      await b.commit();
      if (firstToday) await p.setString('nwsb_presence_day', mark);
    } catch (e) {
      debugPrint('NowssB daily presence: $e');
    }
  }

  Future<void> ping() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final now = DateTime.now();
    if (!u.isAnonymous) unawaited(_daily(u, now));
    if (_lastUid == u.uid && _last != null && now.difference(_last!) < _gap) return;
    _last = now;
    _lastUid = u.uid;
    final data = <String, dynamic>{
      'lastSeen': now.millisecondsSinceEpoch,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'lastPlatform': Platform.isIOS ? 'ios' : 'android',
      'lastApp': 'flutter',
      'lastBuild': NwsbAppUpdate.currentBuild,
      'lastOs': Platform.operatingSystemVersion.length > 80 ? Platform.operatingSystemVersion.substring(0, 80) : Platform.operatingSystemVersion,
    };
    final firstThisLaunch = _mirrored != u.uid;
    if (firstThisLaunch) {
      final created = u.metadata.creationTime;
      data.addAll({
        if ((u.email ?? '').isNotEmpty) 'email': u.email,
        if ((u.displayName ?? '').isNotEmpty) 'displayName': u.displayName,
        if ((u.photoURL ?? '').isNotEmpty) 'photoURL': u.photoURL,
        if ((u.phoneNumber ?? '').isNotEmpty) 'phone': u.phoneNumber,
        'providers': [for (final p in u.providerData) p.providerId],
        if (created != null) 'authCreatedAt': created.millisecondsSinceEpoch,
      });
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(data, SetOptions(merge: true));
      if (firstThisLaunch) {
        _mirrored = u.uid;
        final created = u.metadata.creationTime;
        final isNew = created != null && now.difference(created) < const Duration(minutes: 10);
        final signedIn = u.metadata.lastSignInTime;
        final fresh = signedIn != null && now.difference(signedIn) < const Duration(minutes: 10);
        final type = isNew ? 'signup' : (fresh ? 'login' : 'open');
        if (isNew && !u.isAnonymous) tellAdmins('signup');
        await FirebaseFirestore.instance.collection('activity').add({
          'type': type,
          'uid': u.uid,
          'at': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'ios' : 'android',
          'build': NwsbAppUpdate.currentBuild,
          'app': 'flutter',
          'summary': {'signup': 'New account', 'login': 'Signed in', 'open': 'Opened the app'}[type],
        });
      }
    } catch (e) {
      debugPrint('NowssB presence: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _beat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
