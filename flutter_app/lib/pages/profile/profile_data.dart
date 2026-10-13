/// Profile data for the new page. A thin read over the existing sources of
/// truth (SharedPreferences name, Firebase user, PracticeProgress) — no new
/// storage. Swap to Bug Hunter's shared data layer when it lands.
library;

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';
import '../../data/practice_progress.dart';

class ProfileData {
  const ProfileData({
    required this.name,
    this.avatarUrl,
    this.signedIn = false,
    this.streak = 0,
    this.minutes = 0,
    this.sessions = 0,
    this.level = 1,
    this.week = const [],
  });
  final String name;
  final String? avatarUrl;
  final bool signedIn;
  final int streak;
  final int minutes;
  final int sessions;
  final int level;
  /// Mon..Sun done flags for this week.
  final List<bool> week;

  /// Nothing practiced yet: show the empty state.
  bool get isEmpty => sessions == 0;
}

class ProfileOffline implements Exception {
  const ProfileOffline();
}

abstract class ProfileSource {
  Future<ProfileData> load();
}

class LiveProfileSource implements ProfileSource {
  const LiveProfileSource();

  @override
  Future<ProfileData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    final p = PracticeProgress.instance;
    await p.start();
    final saved = prefs.getString('nowssb_name')?.trim();
    final account = user?.displayName?.trim();
    final data = ProfileData(
      name: saved?.isNotEmpty == true ? saved! : (account?.isNotEmpty == true ? account! : 'Practitioner'),
      avatarUrl: user?.photoURL,
      signedIn: user != null,
      streak: p.streak,
      minutes: p.totalMinutes,
      sessions: p.totalSessions,
      level: p.level,
      week: [for (final d in p.thisWeekDays) d.done],
    );
    // Local data still shows offline; we only raise offline for a signed-in
    // account with nothing cached, so the page can say why it is empty.
    if (user != null && data.isEmpty && !await _online()) throw const ProfileOffline();
    return data;
  }

  static Future<bool> _online() async {
    try {
      final r = await InternetAddress.lookup('nowssb.com').timeout(const Duration(seconds: 3));
      return r.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
