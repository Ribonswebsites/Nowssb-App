/// Local, OS-scheduled notifications: each on its own time, each its own
/// category and channel. Nothing here fires at launch.
///
///   word of the day   every day at the Daily Reminder time (Profile /
///                     Preferences), 7 days ahead, with that day's word
///   streak reminder   20:00 on a day you have not practised yet
///   daily spin        12:30 once a new server day's spin/scratch is ready
///   weekly summary    Sunday 19:00, your week's sessions/words/minutes
///   plan ending       3 days and 1 day before a plan that will not renew
///                     ends, and when it has ended
///   reader reminders  the exact "remind me" times set in the Reader
///
/// One-shot alarms (zonedSchedule, inexact while idle — no exact-alarm
/// permission), re-planned whenever the inputs change and whenever the app
/// goes to the background, so the content is current and a switch, quiet
/// hours or the reminder time take effect at once. [NotifPlanner.plan] is
/// pure and unit-tested.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../data/reader_store.dart';
import '../economy/economy_api.dart';
import 'notif_categories.dart';
import 'notif_center.dart';
import 'notif_prefs.dart';

class PlannedNotice {
  const PlannedNotice({
    required this.id,
    required this.category,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
    this.silent = false,
  });
  final int id;
  final NotifCategory category;
  final DateTime at;
  final String title;
  final String body;
  final String route;
  final bool silent;

  @override
  String toString() => '$id ${category.id} $at "$title"';
}

class PlanInput {
  const PlanInput({
    required this.now,
    required this.signedIn,
    required this.isOn,
    required this.quietOn,
    required this.quietFrom,
    required this.quietTo,
    required this.reminder,
    this.library = const [],
    this.practisedToday = false,
    this.streak = 0,
    this.hasHistory = false,
    this.sessionDates = const [],
    this.sessionWords = const [],
    this.sessionSeconds = const [],
    this.economyLive = false,
    this.claimedToday = false,
    this.planEnd,
    this.planRenews = true,
    this.planName = '',
    this.readerReminders = const [],
  });

  final DateTime now;
  final bool signedIn;
  final bool Function(NotifCategory) isOn;
  final bool quietOn;
  final int quietFrom;
  final int quietTo;
  final int reminder;
  final List<Word> library;
  final bool practisedToday;
  final int streak;
  final bool hasHistory;

  /// yyyy-mm-dd per practice session (+ the word and seconds, same order).
  final List<String> sessionDates;
  final List<String> sessionWords;
  final List<int> sessionSeconds;
  final bool economyLive;

  /// Today's (server day) spin or scratch was already used.
  final bool claimedToday;
  final DateTime? planEnd;
  final bool planRenews;
  final String planName;
  final List<({int at, String title})> readerReminders;
}

class NotifPlanner {
  NotifPlanner._();

  static const wordBase = 1000;
  static const streakBase = 1100;
  static const rewardsBase = 1200;
  static const planBase = 1300;
  static const weeklyId = 1400;
  static const readerBase = 1500;
  static const readerMax = 40;
  static const firstId = 1000;
  static const lastId = 1599;

  /// The older build's daily periodic reminder (periodicallyShow).
  static const legacyDailyId = 88001;

  static const streakMinute = 20 * 60;
  static const rewardsMinute = 12 * 60 + 30;
  static const weeklyMinute = 19 * 60;
  static const planMinute = 10 * 60;

  /// The economy's day starts at midnight IST (config dayOffsetMinutes 330).
  static String serverDay(DateTime t) {
    final n = t.toUtc().add(const Duration(minutes: 330));
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  static String day(DateTime d) => HomeWidgetSync.day(d);

  static List<PlannedNotice> plan(PlanInput i) {
    if (!i.signedIn) return const [];
    final out = <PlannedNotice>[];
    final now = i.now;
    DateTime at(DateTime d, int minute) => DateTime(d.year, d.month, d.day, minute ~/ 60, minute % 60);
    DateTime unquiet(DateTime t) =>
        NotifPrefs.shiftOutOfQuiet(t, on: i.quietOn, from: i.quietFrom, to: i.quietTo);
    bool quiet(DateTime t) =>
        i.quietOn && NotifPrefs.quietContains(i.quietFrom, i.quietTo, t.hour * 60 + t.minute);
    final today = DateTime(now.year, now.month, now.day);

    // ── word of the day ──
    if (i.isOn(NotifCategories.wordOfDay) && i.library.isNotEmpty) {
      for (var d = 0; d < 7; d++) {
        final date = DateTime(today.year, today.month, today.day + d);
        final w = HomeWidgetSync.wordFor(date, i.library);
        if (w == null) continue;
        final when = unquiet(at(date, i.reminder));
        if (!when.isAfter(now)) continue;
        final line = HomeWidgetSync.lineFor(w);
        out.add(PlannedNotice(
          id: wordBase + d,
          category: NotifCategories.wordOfDay,
          at: when,
          title: 'Word of the day · ${w.word}',
          body: line.isEmpty ? 'Sit with today’s word for a few minutes.' : line,
          route: 'practice:${w.key}',
        ));
      }
    }

    // ── streak reminder ──
    if (i.isOn(NotifCategories.streak) && i.hasHistory) {
      // Before quiet hours start, never pushed past midnight.
      var minute = streakMinute;
      if (i.quietOn && NotifPrefs.quietContains(i.quietFrom, i.quietTo, minute)) {
        minute = (i.quietFrom - 30).clamp(12 * 60, 23 * 60);
      }
      for (var d = 0; d < 3; d++) {
        if (d == 0 && i.practisedToday) continue;
        final date = DateTime(today.year, today.month, today.day + d);
        final when = at(date, minute);
        if (!when.isAfter(now)) continue;
        // Day 0: today's streak (if any) is at stake. Day 1: still alive only
        // if today was practised. Later: it has lapsed.
        final alive = (d == 0 && i.streak > 0) || (d == 1 && i.practisedToday && i.streak > 0);
        out.add(PlannedNotice(
          id: streakBase + d,
          category: NotifCategories.streak,
          at: when,
          title: alive ? 'Your ${i.streak}-day streak ends at midnight' : 'Start a new streak today',
          body: alive
              ? 'One short practice before midnight keeps it going.'
              : 'A few minutes with one word is all it takes.',
          route: 'progress',
          silent: quiet(when),
        ));
      }
    }

    // ── daily spin & scratch ──
    if (i.isOn(NotifCategories.dailyRewards) && i.economyLive) {
      for (var d = 0; d < 3; d++) {
        final date = DateTime(today.year, today.month, today.day + d);
        final when = unquiet(at(date, rewardsMinute));
        if (!when.isAfter(now)) continue;
        if (i.claimedToday && serverDay(when) == serverDay(now)) continue;
        out.add(PlannedNotice(
          id: rewardsBase + d,
          category: NotifCategories.dailyRewards,
          at: when,
          title: 'Your daily spin is ready',
          body: 'Spin the wheel and scratch today’s card in Rewards.',
          route: 'rewards',
        ));
      }
    }

    // ── weekly summary ──
    if (i.isOn(NotifCategories.weekly) && i.hasHistory) {
      final toSunday = (DateTime.sunday - today.weekday) % 7;
      var sunday = DateTime(today.year, today.month, today.day + toSunday);
      var when = unquiet(at(sunday, weeklyMinute));
      if (!when.isAfter(now)) {
        sunday = DateTime(sunday.year, sunday.month, sunday.day + 7);
        when = unquiet(at(sunday, weeklyMinute));
      }
      final from = day(DateTime(sunday.year, sunday.month, sunday.day - 6));
      final to = day(sunday);
      var sessions = 0;
      var seconds = 0;
      final words = <String>{};
      for (var k = 0; k < i.sessionDates.length; k++) {
        final dt = i.sessionDates[k];
        if (dt.compareTo(from) < 0 || dt.compareTo(to) > 0) continue;
        sessions++;
        if (k < i.sessionWords.length && i.sessionWords[k].isNotEmpty) words.add(i.sessionWords[k]);
        if (k < i.sessionSeconds.length) seconds += i.sessionSeconds[k];
      }
      final minutes = (seconds / 60).round();
      out.add(PlannedNotice(
        id: weeklyId,
        category: NotifCategories.weekly,
        at: when,
        title: 'Your week in NowssB',
        body: sessions == 0
            ? 'No practice this week yet. A few minutes tonight starts a new streak.'
            : '$sessions session${sessions == 1 ? '' : 's'} · ${words.length} word${words.length == 1 ? '' : 's'}'
                '${minutes > 0 ? ' · $minutes min' : ''}. Streak: ${i.streak} day${i.streak == 1 ? '' : 's'}.',
        route: 'progress',
      ));
    }

    // ── plan ending (plans that will not renew on their own) ──
    final end = i.planEnd;
    if (i.isOn(NotifCategories.subscription) && end != null && end.isAfter(now) && !i.planRenews) {
      final plan = i.planName.isEmpty ? 'Your plan' : i.planName;
      final endDay = DateTime(end.year, end.month, end.day);
      final steps = <(int, String, String)>[
        (3, '$plan ends in 3 days', 'Renew to keep every word, meaning and ebook open.'),
        (1, '$plan ends tomorrow', 'Renew today so nothing locks.'),
      ];
      for (var k = 0; k < steps.length; k++) {
        final (days, title, body) = steps[k];
        final when = unquiet(at(DateTime(endDay.year, endDay.month, endDay.day - days), planMinute));
        if (!when.isAfter(now) || !when.isBefore(end)) continue;
        out.add(PlannedNotice(
            id: planBase + k, category: NotifCategories.subscription, at: when, title: title, body: body, route: 'subscription'));
      }
      out.add(PlannedNotice(
        id: planBase + 2,
        category: NotifCategories.subscription,
        at: unquiet(end.add(const Duration(minutes: 1))),
        title: '$plan has ended',
        body: 'Your words and progress are still here. Renew any time.',
        route: 'subscription',
      ));
    }

    // ── reader reminders (the person picked the time: kept, silent in quiet hours) ──
    if (i.isOn(NotifCategories.reader)) {
      final due = [...i.readerReminders]..sort((a, b) => a.at.compareTo(b.at));
      var k = 0;
      for (final r in due) {
        final when = DateTime.fromMillisecondsSinceEpoch(r.at);
        if (!when.isAfter(now) || k >= readerMax) continue;
        out.add(PlannedNotice(
          id: readerBase + k,
          category: NotifCategories.reader,
          at: when,
          title: 'Back to “${r.title}”',
          body: 'You asked to be reminded about this page.',
          route: 'reader',
          silent: quiet(when),
        ));
        k++;
      }
    }
    return spaced(out);
  }

  /// Two notifications never land together: anything within [gap] of the
  /// one before moves to just after it.
  static const gap = Duration(minutes: 3);
  static List<PlannedNotice> spaced(List<PlannedNotice> list) {
    final sorted = [...list]..sort((a, b) => a.at.compareTo(b.at));
    final out = <PlannedNotice>[];
    for (final p in sorted) {
      if (out.isNotEmpty && p.at.difference(out.last.at) < gap) {
        out.add(PlannedNotice(
          id: p.id,
          category: p.category,
          at: out.last.at.add(gap),
          title: p.title,
          body: p.body,
          route: p.route,
          silent: p.silent,
        ));
      } else {
        out.add(p);
      }
    }
    return out;
  }
}

class NotifScheduler with WidgetsBindingObserver {
  NotifScheduler._();
  static final NotifScheduler instance = NotifScheduler._();

  bool _started = false;
  Timer? _debounce;
  StreamSubscription<User?>? _auth;
  ({DateTime? end, bool renews, String name}) _plan = (end: null, renews: true, name: '');
  bool _claimedToday = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    for (final l in <Listenable>[
      PracticeProgress.instance,
      ContentStore.instance,
      ReaderStore.instance,
      NotifPrefs.instance,
      EconomyMirror.instance,
    ]) {
      l.addListener(replanSoon);
    }
    if (NwsbFirebase.ready) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((_) => unawaited(refreshAccount()));
    }
    unawaited(PracticeProgress.instance.start());
    replanSoon();
  }

  void stop() {
    _auth?.cancel();
    _auth = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app: the Profile reminder time may have changed, a
    // practice may have happened — plan with what is true now.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      // refreshAccount re-reads today's spin/scratch and the plan end, then re-plans.
      unawaited(NotifPrefs.instance.load(fresh: true).then((_) => refreshAccount()));
    }
  }

  void replanSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => unawaited(replan()));
  }

  static const _tiers = {'resonance': 'Resonance', 'frequency': 'Frequency', 'frequencyX': 'Frequency X'};

  /// Plan end + today's spin/scratch use, read from Firestore.
  Future<void> refreshAccount() async {
    final user = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    if (user == null || user.isAnonymous) {
      _plan = (end: null, renews: true, name: '');
      _claimedToday = false;
      replanSoon();
      return;
    }
    try {
      final u = (await FirebaseFirestore.instance.doc('users/${user.uid}').get()).data() ?? {};
      final end = DateTime.tryParse('${u['subscriptionEndDate'] ?? ''}')?.toLocal();
      final active = u['isPro'] == true && end != null && end.isAfter(DateTime.now());
      final renews = u['subscriptionSource'] == 'play' && u['subscriptionAutoRenew'] != false;
      _plan = (end: active ? end : null, renews: renews, name: _tiers['${u['tier'] ?? ''}'] ?? '');
    } catch (_) {}
    try {
      final caps = (await FirebaseFirestore.instance
                  .doc('users/${user.uid}/earnCaps/${NotifPlanner.serverDay(DateTime.now())}')
                  .get())
              .data() ??
          {};
      final counts = caps['counts'];
      _claimedToday = caps['scratch'] == true || (counts is Map && (counts['spin'] is num) && (counts['spin'] as num) > 0);
    } catch (_) {}
    replanSoon();
  }

  Future<List<({int at, String title})>> _readerReminders() async {
    final list = ReaderStore.instance.reminders;
    if (list.isNotEmpty) return [for (final r in list) (at: r.at, title: r.title)];
    // The Reader loads lazily; its reminders are on the phone regardless.
    try {
      final p = await SharedPreferences.getInstance();
      final raw = jsonDecode(p.getString('nwsb_reader_reminders') ?? '[]');
      if (raw is List) {
        return [
          for (final m in raw.whereType<Map>())
            if (m['at'] is num && '${m['title'] ?? ''}'.isNotEmpty) (at: (m['at'] as num).toInt(), title: '${m['title']}'),
        ];
      }
    } catch (_) {}
    return const [];
  }

  PlanInput _input(DateTime now, List<({int at, String title})> reader) {
    final prefs = NotifPrefs.instance;
    final p = PracticeProgress.instance;
    final sessions = p.sessionsSnapshot;
    final user = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    final eco = EconomyMirror.instance;
    return PlanInput(
      now: now,
      signedIn: user != null && !user.isAnonymous,
      isOn: prefs.isOn,
      quietOn: prefs.quietOn,
      quietFrom: prefs.quietFrom,
      quietTo: prefs.quietTo,
      reminder: prefs.reminder,
      library: ContentStore.instance.library,
      practisedToday: p.todaySessions > 0,
      streak: p.streak,
      hasHistory: p.totalSessions > 0,
      sessionDates: [for (final s in sessions) '${s['date'] ?? ''}'],
      sessionWords: [for (final s in sessions) '${s['word'] ?? ''}'],
      sessionSeconds: [for (final s in sessions) (s['durationSec'] is num) ? (s['durationSec'] as num).round() : 0],
      economyLive: eco.live && eco.summary.isNotEmpty,
      claimedToday: _claimedToday || eco.scratchToday,
      planEnd: _plan.end,
      planRenews: _plan.renews,
      planName: _plan.name,
      readerReminders: reader,
    );
  }

  bool _running = false;
  bool _again = false;
  String? _applied;

  Future<void> replan() async {
    final center = NotifCenter.instance;
    if (!center.ready || !NotifPrefs.instance.loaded) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final now = DateTime.now();
      final planned = NotifPlanner.plan(_input(now, await _readerReminders()));
      // Same plan as the one already with Android: leave it alone.
      final sig = planned.map((n) => '${n.id}@${n.at.millisecondsSinceEpoch}:${n.title}|${n.body}|${n.silent}').join('\n');
      if (sig == _applied) return;
      final plugin = center.plugin;
      // Clear what this planner owns (and the older build's daily repeat).
      final pending = await plugin.pendingNotificationRequests();
      for (final r in pending) {
        if ((r.id >= NotifPlanner.firstId && r.id <= NotifPlanner.lastId) || r.id == NotifPlanner.legacyDailyId) {
          await plugin.cancel(r.id);
        }
      }
      final ledger = <String, int>{};
      for (final n in planned) {
        await plugin.zonedSchedule(
          n.id,
          n.title,
          n.body,
          tz.TZDateTime.from(n.at, tz.UTC),
          NotificationDetails(android: NotifCenter.details(n.category, n.title, n.body, silent: n.silent)),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({'route': n.route, 'cat': n.category.id}),
        );
        ledger[NotifPrefs.textKey(n.title, n.body)] = n.at.millisecondsSinceEpoch;
      }
      await NotifCenter.recordPlanned(ledger);
      _applied = sig;
    } catch (e) {
      debugPrint('NowssB schedule: $e');
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        replanSoon();
      }
    }
  }

  /// Signed out: nothing local stays armed.
  Future<void> cancelAll() async {
    _applied = null;
    try {
      final plugin = NotifCenter.instance.plugin;
      for (final r in await plugin.pendingNotificationRequests()) {
        if ((r.id >= NotifPlanner.firstId && r.id <= NotifPlanner.lastId) || r.id == NotifPlanner.legacyDailyId) {
          await plugin.cancel(r.id);
        }
      }
    } catch (_) {}
  }
}
