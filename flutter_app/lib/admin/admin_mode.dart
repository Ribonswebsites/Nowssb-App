/// Which app an admin is in: the NowssB Admin app (its own shell, see
/// admin_app.dart) or the member app. Same APK, same sign-in.
///
/// * An admin launches straight into Admin; the last choice is remembered.
/// * "Open user app" (Admin app bar) switches to the member app; the gold
///   "Admin" pill over the member app, App Settings → Admin and a long-press
///   on the Edit button switch back.
/// * While the server's answer for this account loads, the last answer this
///   phone saw is used; a never-seen account gets a short neutral splash, so
///   an admin never sees the member app flash first.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firebase.dart';
import '../data/notifications.dart';
import 'admin_app.dart';
import 'admin_state.dart';

enum AppSide { admin, member }

class AdminMode extends ChangeNotifier {
  AdminMode._();
  static final AdminMode instance = AdminMode._();

  static const _k = 'nwsb_admin_side';
  AppSide _side = AppSide.admin;
  AppSide get side => _side;

  /// True when the Admin app is what is on screen.
  bool get inAdmin => _side == AppSide.admin && AdminState.instance.isAdmin;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _side = p.getString(_k) == 'member' ? AppSide.member : AppSide.admin;
    } catch (_) {}
  }

  Future<void> set(AppSide side) async {
    if (side == _side) return;
    _side = side;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, side == AppSide.member ? 'member' : 'admin');
    } catch (_) {}
  }
}

/// Switch the whole app to the Admin side (from anywhere in the member app).
void openAdminApp(BuildContext context) {
  if (!AdminState.instance.isAdmin) return;
  final nav = Navigator.of(context, rootNavigator: true);
  nav.popUntil((r) => r.isFirst);
  unawaited(AdminMode.instance.set(AppSide.admin));
}

/// Switch to the member app (from the Admin app).
void openMemberApp(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  nav.popUntil((r) => r.isFirst);
  unawaited(AdminMode.instance.set(AppSide.member));
}

/// Sits where the member app's shell is mounted (main.dart, inside the
/// sign-in gate). Shows the Admin app for an admin on the Admin side, the
/// member app otherwise.
class AdminAppGate extends StatefulWidget {
  const AdminAppGate({super.key, required this.child});
  final Widget child;

  @override
  State<AdminAppGate> createState() => _AdminAppGateState();
}

class _AdminAppGateState extends State<AdminAppGate> {
  Timer? _giveUp;
  bool _waitedOut = false;

  @override
  void initState() {
    super.initState();
    AdminState.instance.addListener(_changed);
    AdminMode.instance.addListener(_changed);
    _arm();
  }

  void _arm() {
    _giveUp?.cancel();
    _waitedOut = false;
    // Offline and never checked: do not hold anyone longer than this.
    _giveUp = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _waitedOut = true);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    AdminState.instance.removeListener(_changed);
    AdminMode.instance.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AdminState.instance;
    final m = AdminMode.instance;
    User? user;
    try {
      user = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    } catch (_) {}
    final bool admin;
    if (user == null || user.isAnonymous) {
      admin = false;
    } else if (a.resolved) {
      admin = a.isAdmin;
    } else {
      final cached = a.cachedFor(user.uid);
      if (cached == null && !_waitedOut) return const _NeutralSplash();
      admin = cached == true;
    }
    if (admin && m.side == AppSide.admin) {
      return const AdminApp();
    }
    return widget.child;
  }
}

/// Plain dark screen with the mark, shown only while a never-seen account's
/// admin status loads (a second or two, at most four).
class _NeutralSplash extends StatelessWidget {
  const _NeutralSplash();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF05070D),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFFE8D5A3)),
          ),
        ),
      );
}

/// On an admin's phone: no member promos or nudges (today's offer, daily
/// words, streak, broadcast promos) and no daily repeat reminder.
class AdminPromoGuard {
  AdminPromoGuard._();
  static bool _started = false;

  static void start() {
    if (_started) return;
    _started = true;
    NotifStore.mute = AdminState.instance.mutes;
    AdminState.instance.addListener(apply);
    // phone_notifications schedules the repeat right after each sign-in;
    // cancel again once that has run.
    if (NwsbFirebase.ready) {
      FirebaseAuth.instance.authStateChanges().listen((_) {
        Future.delayed(const Duration(seconds: 4), apply);
      });
    }
  }

  /// Cancels the member daily repeat (id 88001 in phone_notifications.dart).
  /// Safe to call any time.
  static Future<void> apply() async {
    if (!AdminState.instance.mutes('routine')) return;
    try {
      await FlutterLocalNotificationsPlugin().cancel(88001);
    } catch (_) {}
  }
}
