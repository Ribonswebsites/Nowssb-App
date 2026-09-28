/// "Last seen" for the admin Users view (coming next) and the web studio.
///
/// On app open and on every return to the foreground — at most once every
/// ten minutes — the signed-in person's `users/{uid}` gets a merge of:
///   lastSeen      milliseconds, the number the web studio already reads
///   lastSeenAt    the server's own clock (the rules accept only that)
///   lastPlatform  'android' | 'ios'
///   lastApp       'flutter'
/// Nothing else is written, so it cannot collide with profile or plan
/// fields. Never throws.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'firebase.dart';

class Presence with WidgetsBindingObserver {
  Presence._();
  static final Presence instance = Presence._();

  static const _gap = Duration(minutes: 10);
  DateTime? _last;
  String? _lastUid;
  bool _started = false;
  StreamSubscription<User?>? _sub;

  void start() {
    if (_started || !NwsbFirebase.ready) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) => ping());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ping();
  }

  Future<void> ping() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final now = DateTime.now();
    if (_lastUid == u.uid && _last != null && now.difference(_last!) < _gap) return;
    _last = now;
    _lastUid = u.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'lastSeen': now.millisecondsSinceEpoch,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'lastPlatform': Platform.isIOS ? 'ios' : 'android',
        'lastApp': 'flutter',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NowssB presence: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
