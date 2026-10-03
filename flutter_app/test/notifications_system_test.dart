import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/features/notifications/notif_categories.dart';
import 'package:nowssb/features/notifications/notif_center.dart';
import 'package:nowssb/features/notifications/notif_prefs.dart';
import 'package:nowssb/features/notifications/notif_router.dart';
import 'package:nowssb/features/notifications/notif_scheduler.dart';
import 'package:nowssb/features/notifications/notif_watchers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Word _w(String word, {String meaning = ''}) => Word(
      key: word.toLowerCase(),
      word: word,
      deva: '',
      translit: '',
      phonetic: '',
      parts: const [],
      audioMale: '',
      audioFemale: '',
      organ: '',
      origin: 'Sanskrit',
      benefit: '',
      meaning: meaning,
      mouthPos: '',
      resonance: '',
      mistake: '',
      tip: '',
      categories: const [],
      gender: 'both',
      time: 'any',
      price: 0,
      img: '',
    );

PlanInput _input({
  required DateTime now,
  bool signedIn = true,
  Set<String> off = const {},
  bool practisedToday = false,
  int streak = 3,
  bool hasHistory = true,
  bool economyLive = true,
  bool claimedToday = false,
  DateTime? planEnd,
  bool planRenews = true,
  List<({int at, String title})> reader = const [],
  List<String> dates = const [],
}) =>
    PlanInput(
      now: now,
      signedIn: signedIn,
      isOn: (c) => !off.contains(c.id),
      quietOn: true,
      quietFrom: 22 * 60 + 30,
      quietTo: 7 * 60,
      reminder: 7 * 60,
      library: [_w('Ananda', meaning: 'Bliss'), _w('Shanti', meaning: 'Peace')],
      practisedToday: practisedToday,
      streak: streak,
      hasHistory: hasHistory,
      sessionDates: dates,
      sessionWords: [for (final _ in dates) 'ananda'],
      sessionSeconds: [for (final _ in dates) 300],
      economyLive: economyLive,
      claimedToday: claimedToday,
      planEnd: planEnd,
      planRenews: planRenews,
      planName: 'Frequency',
      readerReminders: reader,
    );

void main() {
  group('the planner', () {
    // Saturday 3 Oct 2026, 09:00 local.
    final now = DateTime(2026, 10, 3, 9);

    test('nothing at all when signed out', () {
      expect(NotifPlanner.plan(_input(now: now, signedIn: false)), isEmpty);
    });

    test('never two notifications at the same moment', () {
      final plan = NotifPlanner.plan(_input(
        now: now,
        planEnd: DateTime(2026, 10, 9, 18),
        planRenews: false,
        reader: [(at: now.add(const Duration(hours: 2)).millisecondsSinceEpoch, title: 'Om')],
      ));
      expect(plan.length, greaterThan(10));
      final times = plan.map((p) => p.at.millisecondsSinceEpoch).toList();
      expect(times.toSet().length, times.length, reason: plan.join('\n'));
      final ids = plan.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final p in plan) {
        expect(p.at.isAfter(now), isTrue, reason: '$p');
        expect(p.id, inInclusiveRange(NotifPlanner.firstId, NotifPlanner.lastId));
      }
    });

    test('word of the day: 7 days ahead at the reminder time, skips today once past it', () {
      final words = NotifPlanner.plan(_input(now: now)).where((p) => p.category.id == 'word_of_day').toList();
      expect(words.length, 6); // 07:00 today has passed
      expect(words.first.at, DateTime(2026, 10, 4, 7));
      expect(words.first.title, startsWith('Word of the day · '));
      expect(words.first.route, startsWith('practice:'));
    });

    test('streak: only on days not yet practised, and before quiet hours', () {
      var s = NotifPlanner.plan(_input(now: now)).where((p) => p.category.id == 'streak').toList();
      expect(s.first.at, DateTime(2026, 10, 3, 20));
      expect(s.first.title, 'Your 3-day streak ends at midnight');
      s = NotifPlanner.plan(_input(now: now, practisedToday: true)).where((p) => p.category.id == 'streak').toList();
      expect(s.first.at, DateTime(2026, 10, 4, 20));
      expect(NotifPlanner.plan(_input(now: now, hasHistory: false)).where((p) => p.category.id == 'streak'), isEmpty);
    });

    test('daily spin: not again on a server day already claimed', () {
      final open = NotifPlanner.plan(_input(now: now)).where((p) => p.category.id == 'daily_rewards').toList();
      expect(open.first.at, DateTime(2026, 10, 3, 12, 30));
      final used = NotifPlanner.plan(_input(now: now, claimedToday: true)).where((p) => p.category.id == 'daily_rewards').toList();
      expect(used.first.at.day, 4);
      expect(NotifPlanner.plan(_input(now: now, economyLive: false)).where((p) => p.category.id == 'daily_rewards'), isEmpty);
    });

    test('weekly summary is Sunday evening with the week\'s numbers', () {
      final w = NotifPlanner.plan(_input(now: now, dates: ['2026-09-28', '2026-10-01', '2026-09-20']))
          .singleWhere((p) => p.category.id == 'weekly');
      expect(w.at, DateTime(2026, 10, 4, 19));
      expect(w.body, startsWith('2 sessions · 1 word · 10 min'));
    });

    test('plan ending only when it will not renew', () {
      final end = DateTime(2026, 10, 9, 18);
      expect(NotifPlanner.plan(_input(now: now, planEnd: end)).where((p) => p.category.id == 'subscription'), isEmpty);
      final p = NotifPlanner.plan(_input(now: now, planEnd: end, planRenews: false))
          .where((p) => p.category.id == 'subscription')
          .toList();
      expect(p.map((e) => e.title), ['Frequency ends in 3 days', 'Frequency ends tomorrow', 'Frequency has ended']);
      expect(p[0].at, DateTime(2026, 10, 6, 10));
    });

    test('a switched-off category is not planned', () {
      final plan = NotifPlanner.plan(_input(now: now, off: {'word_of_day', 'weekly'}));
      expect(plan.where((p) => p.category.id == 'word_of_day' || p.category.id == 'weekly'), isEmpty);
      expect(plan.where((p) => p.category.id == 'streak'), isNotEmpty);
    });

    test('reader reminders keep their exact time', () {
      final at = DateTime(2026, 10, 3, 23, 15);
      final r = NotifPlanner.plan(_input(now: now, reader: [(at: at.millisecondsSinceEpoch, title: 'Om')]))
          .singleWhere((p) => p.category.id == 'reader');
      expect(r.at, at);
      expect(r.silent, isTrue); // inside quiet hours
    });

    test('two plans for the same minute are spaced apart', () {
      final at = DateTime(2026, 10, 4, 20);
      final a = PlannedNotice(id: 1, category: NotifCategories.streak, at: at, title: 'a', body: '', route: '');
      final b = PlannedNotice(id: 2, category: NotifCategories.reader, at: at, title: 'b', body: '', route: '');
      final s = NotifPlanner.spaced([a, b]);
      expect(s[1].at.difference(s[0].at), NotifPlanner.gap);
    });

    test('server day rolls over at midnight IST', () {
      expect(NotifPlanner.serverDay(DateTime.utc(2026, 10, 3, 18, 29)), '20261003');
      expect(NotifPlanner.serverDay(DateTime.utc(2026, 10, 3, 18, 31)), '20261004');
    });
  });

  group('quiet hours', () {
    test('a window across midnight', () {
      expect(NotifPrefs.quietContains(22 * 60, 7 * 60, 23 * 60), isTrue);
      expect(NotifPrefs.quietContains(22 * 60, 7 * 60, 6 * 60 + 59), isTrue);
      expect(NotifPrefs.quietContains(22 * 60, 7 * 60, 7 * 60), isFalse);
      expect(NotifPrefs.quietContains(9 * 60, 9 * 60, 9 * 60), isFalse);
    });
    test('a time inside moves to the end', () {
      final t = NotifPrefs.shiftOutOfQuiet(DateTime(2026, 10, 3, 23), on: true, from: 22 * 60, to: 7 * 60);
      expect(t, DateTime(2026, 10, 4, 7));
      final u = NotifPrefs.shiftOutOfQuiet(DateTime(2026, 10, 3, 5), on: true, from: 22 * 60, to: 7 * 60);
      expect(u, DateTime(2026, 10, 3, 7));
    });
  });

  group('the rules at draw time', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<NotifPrefs> prefs({bool admin = false, String uid = 'u1'}) async {
      final p = NotifPrefs.instance;
      await p.load(fresh: true);
      await p.setIdentity(uid: uid, admin: admin);
      await p.setQuiet(on: true, from: 22 * 60, to: 7 * 60);
      return p;
    }

    NwsbNotice n(NotifCategory c, {String key = 'k1', String title = 'T', String body = 'B'}) =>
        NwsbNotice(category: c, title: title, body: body, key: key);

    test('the same notification is shown once', () async {
      final p = await prefs();
      final noon = DateTime(2026, 10, 3, 12);
      expect(await NotifCenter.decide(n(NotifCategories.gifts), p, now: noon), isNull);
      expect(await NotifCenter.decide(n(NotifCategories.gifts), p, now: noon), NotifSkip.duplicate);
      // Same text through another path (push vs inbox watch) within minutes.
      expect(await NotifCenter.decide(n(NotifCategories.gifts, key: 'other'), p, now: noon.add(const Duration(minutes: 2))),
          NotifSkip.duplicate);
      expect(await NotifCenter.decide(n(NotifCategories.gifts, key: 'k2', body: 'new'), p, now: noon), isNull);
    });

    test('promos skip admins and quiet hours; switches and sign-out stop everything', () async {
      var p = await prefs(admin: true);
      final noon = DateTime(2026, 10, 3, 12);
      expect(await NotifCenter.decide(n(NotifCategories.offers), p, now: noon), NotifSkip.adminPromo);
      p = await prefs();
      expect(await NotifCenter.decide(n(NotifCategories.offers, key: 'q'), p, now: DateTime(2026, 10, 3, 23)), NotifSkip.quietPromo);
      expect(await NotifCenter.decide(n(NotifCategories.gifts, key: 'q2'), p, now: DateTime(2026, 10, 3, 23)), isNull);
      await p.setOn(NotifCategories.rewards, false);
      expect(await NotifCenter.decide(n(NotifCategories.rewards, key: 'r'), p, now: noon), NotifSkip.switchedOff);
      p = await prefs(uid: '');
      expect(await NotifCenter.decide(n(NotifCategories.inbox, key: 'x'), p, now: noon), NotifSkip.signedOut);
    });

    test('a switch turned off on the older settings page counts too', () async {
      SharedPreferences.setMockInitialValues({'nwsb_notif_off': '["streak"]'});
      final p = NotifPrefs.instance;
      await p.load(fresh: true);
      expect(p.isOn(NotifCategories.streak), isFalse);
      await p.setOn(NotifCategories.streak, true);
      expect(p.isOn(NotifCategories.streak), isTrue);
    });

    test('the Profile reminder time is the word-of-the-day time', () async {
      SharedPreferences.setMockInitialValues({'nowssb_reminder': '08:45'});
      final p = NotifPrefs.instance;
      await p.load(fresh: true);
      expect(p.reminder, 8 * 60 + 45);
    });
  });

  group('categories and routes', () {
    test('every category has its own channel', () {
      final ids = NotifCategories.all.map((c) => c.channelId).toList();
      expect(ids.toSet().length, ids.length);
      expect(NotifCategories.all.where((c) => c.promo).map((c) => c.id), ['offers']);
    });

    test('server kinds map like functions/_lib/notify/push.js', () {
      expect(NotifCategories.forKind('gift').id, 'gifts');
      expect(NotifCategories.forKind('request_done').id, 'requests');
      expect(NotifCategories.forKind('plan').id, 'subscription');
      expect(NotifCategories.forKind('earn').id, 'rewards');
      expect(NotifCategories.forKind('reference').id, 'rewards');
      expect(NotifCategories.forKind('broadcast').id, 'offers');
      expect(NotifCategories.forKind('admin').id, 'inbox');
      expect(NotifCategories.forKind('routine').id, 'word_of_day');
    });

    test('tab routes and screen routes', () {
      expect(NotifRouter.tabFor('store'), 3);
      expect(NotifRouter.tabFor('library'), 2);
      expect(NotifRouter.tabFor('gifts'), isNull);
      for (final c in NotifCategories.all) {
        final r = c.defaultRoute;
        expect(NotifRouter.tabFor(r) != null || NotifRouter.screenFor(r) != null || r == 'practice', isTrue, reason: r);
      }
    });

    test('inbox rows route to the word that was added', () {
      expect(NotifWatchers.routeForInbox({'kind': 'request_done', 'wordKey': 'om'}), 'word:om');
      expect(NotifWatchers.routeForInbox({'kind': 'gift'}), 'gifts');
      expect(NotifWatchers.routeForInbox({'kind': 'admin', 'route': 'store'}), 'store');
    });

    test('new content is only what was not known', () {
      expect(NotifWatchers.fresh(['a', 'b', 'c'], {'a', 'c'}), ['b']);
    });
  });
}
