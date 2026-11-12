/// Where each of the five daily goals reads its count, and where each one
/// goes when tapped.
///
///  * Daily tasks     — [DailyTasks.items]: the account's own list, ticked on
///                      the Daily tasks page (SharedPreferences per account+day).
///  * Today's practice — [PracticeProgress.todaySessions]: words finished in
///                      the player today, of [PracticeProgress.dailyPracticeGoal].
///  * Daily coins     — the server's today doc (`earnCaps/<IST day>`):
///                      login coins + today's free scratch card, of 2.
///  * Quest           — a quest claimed today: a `quest:` row in the server's
///                      recent coin ledger dated today (IST), or a claim made
///                      in this session.
///  * Daily check-in  — [DailyCheckIn]: checked in on this phone today, or the
///                      server already has today's login.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/practice_progress.dart';
import '../../screens/daily_tasks.dart';
import '../../shell/nav_shell.dart';
import '../coins/coins_screen.dart';
import '../economy/economy_api.dart';
import 'progress_center.dart';
import 'quests_screen.dart';

/// The server's day starts at midnight IST (config dayOffsetMinutes 330).
const _istOffset = Duration(minutes: 330);

DateTime _istNow([DateTime? now]) => (now ?? DateTime.now()).toUtc().add(_istOffset);

String istDayKey([DateTime? now]) {
  final n = _istNow(now);
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

/// Epoch ms of today's midnight IST.
int istDayStartMs([DateTime? now]) {
  final n = _istNow(now);
  return DateTime.utc(n.year, n.month, n.day).subtract(_istOffset).millisecondsSinceEpoch;
}

/// True when the server's recent coin ledger has a quest claim from today.
bool questClaimedToday(Map<String, dynamic> summary, {DateTime? now}) {
  final start = istDayStartMs(now);
  for (final r in (summary['recentCoins'] as List? ?? const [])) {
    if (r is! Map) continue;
    final reason = '${r['reason'] ?? ''}';
    final at = (r['at'] as num?)?.toInt() ?? 0;
    if (reason.startsWith('quest') && at >= start) return true;
  }
  return false;
}

bool _todayFlag(String name) {
  final m = EconomyMirror.instance;
  if (name == 'login' && m.loginToday) return true;
  if (name == 'scratch' && m.scratchToday) return true;
  final t = m.summary['today'];
  return t is Map && t[name] == true && '${t['day'] ?? istDayKey()}' == istDayKey();
}

/// The day's check-in. Works signed out (kept on this phone); signed in it
/// also claims the server's daily login coins.
class DailyCheckIn extends ChangeNotifier {
  DailyCheckIn._();
  static final instance = DailyCheckIn._();

  /// Tests: stands in for the server's claimDailyLogin.
  static Future<int> Function()? debugClaim;

  String _loadedFor = '';
  bool _done = false;

  static String get _who {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'local';
    } catch (_) {
      return 'local';
    }
  }

  String get _key => 'nwsb_checkin_${_who}_${istDayKey()}';

  bool get doneToday => (_loadedFor == _key && _done) || _todayFlag('login');

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final k = _key;
      final v = p.getBool(k) ?? false;
      if (k != _loadedFor || v != _done) {
        _loadedFor = k;
        _done = v;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Checks in for today. Returns the login coins the server paid (0 when
  /// signed out or already paid). Throws the server's error after the local
  /// check-in is kept, so the caller can say why no coins came.
  Future<int> checkIn() async {
    await load();
    if (!_done) {
      _loadedFor = _key;
      _done = true;
      try {
        final p = await SharedPreferences.getInstance();
        await p.setBool(_key, true);
      } catch (_) {}
      notifyListeners();
    }
    ProgressSources.instance.sync();
    final m = EconomyMirror.instance;
    final claim = debugClaim ?? (m.uid != null && !m.loginToday ? EconomyApi.claimToday : null);
    if (claim == null) return 0;
    final coins = await claim();
    ProgressSources.instance.sync();
    return coins;
  }

  @visibleForTesting
  void debugReset() {
    _loadedFor = '';
    _done = false;
  }
}

/// Keeps [ProgressCenter] in step with the real stores.
class ProgressSources {
  ProgressSources._();
  static final instance = ProgressSources._();

  ProgressCenter center = ProgressCenter.instance;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    for (final l in _sources) {
      l.addListener(sync);
    }
    sync();
    refresh();
  }

  List<Listenable> get _sources => [DailyTasks.items, PracticeProgress.instance, EconomyMirror.instance, DailyCheckIn.instance];

  /// Re-reads the stores that live on disk (tasks, practice, check-in).
  Future<void> refresh() async {
    try {
      await DailyTasks.publish();
    } catch (_) {}
    try {
      await PracticeProgress.instance.start();
    } catch (_) {}
    await DailyCheckIn.instance.load();
    sync();
  }

  void sync() {
    final c = center;
    final tasks = DailyTasks.items.value;
    c.sync(ProgressKind.tasks, tasks.where((t) => t.done).length, tasks.length);
    c.sync(ProgressKind.routine, PracticeProgress.instance.todaySessions, PracticeProgress.dailyPracticeGoal);
    c.sync(ProgressKind.coins, (_todayFlag('login') ? 1 : 0) + (_todayFlag('scratch') ? 1 : 0), 2);
    final quest = questClaimedToday(EconomyMirror.instance.summary) || (c.itemOf(ProgressKind.quest)?.complete ?? false);
    c.sync(ProgressKind.quest, quest ? 1 : 0, 1, key: quest ? 'today' : null);
    c.sync(ProgressKind.checkin, DailyCheckIn.instance.doneToday ? 1 : 0, 1);
  }

  /// The server already paid today's login coins.
  static bool get serverLoginToday => _todayFlag('login');

  /// Coins need an account; signed out there is nothing to claim.
  static bool get signedIn => EconomyMirror.instance.uid != null;

  /// One line on what to do next for [item].
  static String nextStep(ProgressItem item) {
    if (item.complete) {
      return switch (item.kind) {
        ProgressKind.tasks => 'All tasks ticked off today',
        ProgressKind.routine => 'Practice done for today',
        ProgressKind.coins => 'Both daily coins collected',
        ProgressKind.quest => 'A quest claimed today',
        ProgressKind.checkin => 'Checked in · see you tomorrow',
      };
    }
    final left = item.total - item.done;
    switch (item.kind) {
      case ProgressKind.tasks:
        final open = DailyTasks.items.value.where((t) => !t.done).toList();
        return open.isEmpty ? 'Add a task for today' : 'Tick off \u201c${open.first.title}\u201d';
      case ProgressKind.routine:
        return 'Finish $left more word${left == 1 ? '' : 's'} in the player';
      case ProgressKind.coins:
        if (!signedIn) return 'Sign in to collect daily coins';
        if (!_todayFlag('login')) return 'Check in to collect your login coins';
        return 'Scratch today\u2019s free card';
      case ProgressKind.quest:
        return 'Claim a finished quest';
      case ProgressKind.checkin:
        return 'One tap to check in for today';
    }
  }

  static String actionLabel(ProgressKind k) => switch (k) {
        ProgressKind.tasks => 'Open tasks',
        ProgressKind.routine => 'Practise now',
        ProgressKind.coins => 'Open coins',
        ProgressKind.quest => 'Open quests',
        ProgressKind.checkin => 'Check in',
      };
}

/// Where each goal goes. Tests may swap [goTab].
abstract final class ProgressRoutes {
  /// 1 = the Practice tab. Defaults to the shell's tab switch.
  static void Function(BuildContext context, int tab) goTab = NavScope.goTo;

  static Widget? pageFor(ProgressKind k) => switch (k) {
        ProgressKind.tasks => const DailyTasksPage(),
        ProgressKind.coins => const CoinsScreen(),
        ProgressKind.quest => const QuestsScreen(),
        ProgressKind.routine || ProgressKind.checkin => null,
      };

  /// Opens [kind]'s place. When called from a pop-up route, the pop-up
  /// closes first so the page opens on the app, not under the sheet.
  static Future<void> open(BuildContext context, ProgressKind kind) async {
    final nav = Navigator.of(context);
    final inPopup = ModalRoute.of(context) is PopupRoute;
    switch (kind) {
      case ProgressKind.checkin:
        await checkIn(context);
      case ProgressKind.routine:
        if (inPopup) nav.pop();
        goTab(nav.context, 1);
      default:
        final page = pageFor(kind)!;
        if (inPopup) nav.pop();
        unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => page)));
    }
  }

  /// Today's free scratch card: draw it on the server, then reveal it.
  static Future<void> scratchToday(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    String text;
    try {
      final r = await EconomyApi.call('dailyScratch');
      final id = r['id'];
      var label = '${r['label'] ?? ''}';
      if (id is String && id.isNotEmpty) {
        final rr = await EconomyApi.call('revealScratch', {'id': id});
        label = '${rr['label'] ?? label}';
      }
      text = r['already'] == true ? 'Today’s card is already scratched' : label.isEmpty ? 'Card scratched' : 'You got $label';
    } on EconomyException catch (e) {
      text = e.message;
    } catch (_) {
      text = 'That did not go through. Try again.';
    }
    ProgressSources.instance.sync();
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  static Future<void> checkIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final was = DailyCheckIn.instance.doneToday;
    String text;
    try {
      final coins = await DailyCheckIn.instance.checkIn();
      text = was
          ? 'Already checked in today'
          : coins > 0
              ? 'Checked in · +$coins coins'
              : 'Checked in for today';
    } on EconomyException catch (e) {
      text = 'Checked in for today. ${e.message}';
    } catch (_) {
      text = 'Checked in for today';
    }
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }
}
