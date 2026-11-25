// Ribon's tablet fixes (Nov 25): the client's 11" Android tablet in
// portrait (800x1280 logical, nav rail) and landscape (1280x800, sidebar),
// plus the sizes he asked to be checked (1600x2560, 2560x1600) and a phone
// (412x915) that must keep its own layout.
//
//   * Normal home is the full home on a tablet (not one banner and a void).
//   * Pages keep a readable centre column; the player is a full dashboard.
//   * Login: the film at its own shape beside the form, never behind it.
//   * Earn data is kept in memory: a revisit draws at once, no refetch.
//   * Admin accounts never get a coin pop-up; no in-app notification row.
//
// Screenshots: --dart-define=TABLET_FIX_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/admin/admin_state.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/live_cache.dart';
import 'package:nowssb/data/notifications.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/economy/reward_overlay.dart';
import 'package:nowssb/features/programs/program_kit.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/quotes_live.dart';
import 'package:nowssb/screens/splash.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/shell/tablet_frame.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:nowssb/widgets/login_stage.dart';
import 'package:nowssb/widgets/notification_popup.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('TABLET_FIX_SHOTS');
final _shotKey = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _precache(WidgetTester t) async {
  final imgs = [
    for (final e in find.byType(Image).evaluate()) (e, (e.widget as Image).image),
  ];
  await t.runAsync(() async {
    final jobs = <Future<void>>[];
    for (final (e, p) in imgs) {
      if (p is NetworkImage) continue;
      jobs.add(precacheImage(p, e).catchError((_) {}));
    }
    try {
      await Future.wait(jobs).timeout(const Duration(seconds: 4));
    } catch (_) {}
  });
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  await _precache(t);
  await _precache(t);
  final ro = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Layout errors (overflow and the like) raised while [body] runs. Network
/// pictures that cannot load in a test are not layout errors.
Future<List<String>> _errorsDuring(Future<void> Function() body) async {
  final errs = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    final s = d.exceptionAsString().split('\n').first;
    if (s.contains('HttpException') || s.contains('NetworkImage') || s.contains('Unable to load asset')) return;
    errs.add(s);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = prev;
  }
  return errs;
}

Future<GlobalKey<NavigatorState>> _app(WidgetTester t, Size s) async {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final nav = GlobalKey<NavigatorState>();
  SplashGate.done.value = true;
  await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      navigatorObservers: [TabletShellGate.observer],
      theme: NwsbTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (c, child) => RepaintBoundary(
          key: _shotKey,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            TabletFrame(navigatorKey: nav, child: child ?? const SizedBox()),
          ])),
      home: const NavShell()));
  await _settle(t, 15);
  final agree = find.text('I Agree · Continue');
  if (agree.evaluate().isNotEmpty) {
    await t.tap(agree.first, warnIfMissed: false);
    await _settle(t, 12);
  }
  for (var i = 0; i < 3 && nav.currentState!.canPop(); i++) {
    nav.currentState!.pop();
    await _settle(t, 4);
  }
  return nav;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(minutes: 5));
}

const _sizes = {
  'tablet-portrait': Size(800, 1280),
  'tablet-landscape': Size(1280, 800),
  'big-portrait': Size(1600, 2560),
  'big-landscape': Size(2560, 1600),
  'phone': Size(412, 915),
};

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'nowssb_name': 'Ribon'});
  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    await loadRoboto();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await ContentStore.instance.start();
    ContentStore.recordedWordsOnly = true;
    ContentStore.instance.debugRecompute();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });

  // Loads every font the pages use once, so the first real shot does not
  // catch them half-loaded.
  testWidgets('warm up', (t) async {
    await _errorsDuring(() async {
      await _app(t, const Size(800, 1280));
      await _settle(t, 10);
    });
    await _end(t);
  });

  for (final e in _sizes.entries) {
    final tag = e.key;
    final size = e.value;
    final phone = size.shortestSide < 600;
    final landscape = size.width > size.height;

    testWidgets('$tag: homes, Store and Earn lay out in a sensible column', (t) async {
      late GlobalKey<NavigatorState> nav;
      final errs = await _errorsDuring(() async {
        nav = await _app(t, size);
        for (final zen in [false, true]) {
          await Settings.instance.setFashionHome(zen);
          NavScope.goTo(nav.currentState!.overlay!.context, 0);
          await _settle(t, 10);
          if (!zen) expect(find.byType(HomeNormal), findsOneWidget);
          await _shot(t, '$tag/${zen ? 'zen' : 'normal'}-home');
        }
        await Settings.instance.setFashionHome(false);
        for (final tab in const {'store': 3, 'library': 2, 'profile': 4}.entries) {
          NavScope.goTo(nav.currentState!.overlay!.context, tab.value);
          await _settle(t, 10);
          if (!phone) {
            final w = t.getSize(find.byKey(const ValueKey('tablet-centre'))).width;
            expect(w, lessThanOrEqualTo(TabletBp.page + 0.5), reason: '${tab.key} column');
          }
          await _shot(t, '$tag/${tab.key}');
        }
        nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const EarnTabsPage(initialTab: 'overview')));
        await _settle(t, 16);
        if (!phone) {
          expect(t.getSize(find.byKey(const ValueKey('tablet-centre'))).width, lessThanOrEqualTo(TabletBp.page + 0.5));
        }
        await _shot(t, '$tag/earn');
      });
      expect(errs.where((s) => s.contains('overflowed')), isEmpty);
      await _end(t);
    });

    testWidgets('$tag: player', (t) async {
      final errs = await _errorsDuring(() async {
        final nav = await _app(t, size);
        nav.currentState!.push(MaterialPageRoute<void>(
            builder: (_) => PracticePlayerScreen(
                words: ContentStore.instance.library.take(6).toList(), title: 'Morning Ritual', showIntro: false)));
        await _settle(t, 18);
        if (phone) {
          expect(find.byKey(const ValueKey('player-tablet-landscape')), findsNothing);
          expect(find.byKey(const ValueKey('player-tablet-portrait')), findsNothing);
        } else {
          expect(find.byKey(ValueKey(landscape ? 'player-tablet-landscape' : 'player-tablet-portrait')), findsOneWidget);
          expect(find.byKey(const ValueKey('player-tablet-queue')), findsOneWidget);
          // The dashboard uses the panel's whole width (no reading cap).
          final w = t.getSize(find.byKey(const ValueKey('tablet-centre'))).width;
          expect(w, greaterThan(TabletBp.page - 40));
        }
        await _shot(t, '$tag/player');
      });
      expect(errs.where((s) => s.contains('overflowed')), isEmpty);
      await _end(t);
    });

    testWidgets('$tag: login', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final id = TextEditingController();
      final secret = TextEditingController();
      Widget login() => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NwsbTheme.light,
          home: RepaintBoundary(
            key: _shotKey,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: LoginStage(
                id: id,
                secret: secret,
                busy: false,
                obscure: true,
                remember: true,
                createAccount: false,
                codeSent: false,
                onSubmit: () {},
                onGoogle: () {},
                onApple: () {},
                onForgot: () {},
                onToggleCreate: () {},
                onToggleObscure: () {},
                onToggleRemember: () {},
                onExplore: () {},
              ),
            ),
          ),
        );
      // Fonts load on first use: draw once, let them land, then measure.
      await _errorsDuring(() async {
        await t.pumpWidget(login());
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
        await t.pumpWidget(const SizedBox());
      });
      final errs = await _errorsDuring(() async {
        await t.pumpWidget(login());
        await _settle(t, 8);
        if (phone) {
          expect(find.byKey(const ValueKey('login-tablet')), findsNothing);
        } else {
          final film = t.getRect(find.byKey(const ValueKey('login-tablet-film')));
          final form = t.getRect(find.byKey(const ValueKey('login-tablet-form')));
          // Side by side: the form never sits over the film (her face).
          expect(film.right, lessThanOrEqualTo(form.left));
          expect(film.width / film.height, closeTo(624 / 1456, 0.01));
          expect(film.bottom, lessThanOrEqualTo(size.height));
        }
        await _shot(t, '$tag/login');
      });
      // The phone login is the unchanged phone layout (its fit depends on
      // the fonts the test has); the tablet layout must always fit.
      if (!phone) expect(errs.where((s) => s.contains('overflowed')), isEmpty);
      await t.pumpWidget(const SizedBox());
      id.dispose();
      secret.dispose();
    });
  }

  testWidgets('tablet portrait to landscape keeps the page and its state', (t) async {
    final errs = await _errorsDuring(() async {
      final nav = await _app(t, const Size(800, 1280));
      NavScope.goTo(nav.currentState!.overlay!.context, 3);
      await _settle(t, 8);
      final shell = t.state(find.byType(NavShell));
      t.view.physicalSize = const Size(1280, 800);
      await _settle(t, 8);
      expect(t.state(find.byType(NavShell)), same(shell));
      expect(TabletShellGate.tab.value, 3);
      expect(find.byType(TabletSidebar), findsOneWidget);
    });
    expect(errs.where((s) => s.contains('overflowed')), isEmpty);
    await _end(t);
  });

  group('Earn stays loaded', () {
    tearDown(() {
      EconomyApi.debugHandler = null;
      ServerViewCache.debugClear();
    });

    testWidgets('a revisit draws from memory and does not refetch', (t) async {
      var calls = 0;
      EconomyApi.debugHandler = (name, data) async {
        calls++;
        return {'value': 'answer $calls'};
      };
      Widget page() => MaterialApp(
            home: Scaffold(
              body: ServerView(
                action: 'earnSummary',
                builder: (c, r, _) => Text('${r['value']}', textDirection: TextDirection.ltr),
              ),
            ),
          );
      await t.pumpWidget(page());
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('answer 1'), findsOneWidget);
      expect(calls, 1);
      // Leave and come back (another page, then back).
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(page());
      // First frame of the revisit: the answer, no loader, no new request.
      expect(find.text('answer 1'), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      expect(calls, 1);
    });

    test('a live query is opened once and replays its last value', () async {
      var opened = 0;
      Stream<int> open() {
        opened++;
        return Stream<int>.fromIterable([7]);
      }

      final a = await LiveCache.of('t:x', open).first;
      final b = await LiveCache.of('t:x', open).first;
      expect(a, 7);
      expect(b, 7);
      expect(opened, 1);
      expect(LiveCache.latest<int>('t:x'), 7);
    });
  });

  group('pop-ups', () {
    tearDown(() {
      AdminState.instance.debugSetAdmin(false);
      RewardOverlay.debugPlayInTests = false;
      RewardOverlay.debugReset();
    });

    testWidgets('an admin account never gets a coin pop-up', (t) async {
      RewardOverlay.debugPlayInTests = true;
      RewardOverlay.debugReset();
      await t.pumpWidget(MaterialApp(navigatorKey: RewardOverlay.navigatorKey, home: const Scaffold()));
      AdminState.instance.debugSetAdmin(true);
      await RewardOverlay.coins(25, from: 0, to: 25);
      await RewardOverlay.reveal(title: 'You won', items: const [
        {'type': 'coins', 'coins': 25, 'label': '25 coins'},
      ]);
      await t.pump(const Duration(milliseconds: 300));
      expect(RewardOverlay.navigatorKey.currentState!.canPop(), isFalse);
      expect(find.textContaining('25'), findsNothing);

      // A member still gets it (the gate is the admin account, nothing else).
      AdminState.instance.debugSetAdmin(false);
      RewardOverlay.reveal(title: 'You won', items: const [
        {'type': 'coins', 'coins': 25, 'label': '25 coins'},
      ]);
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 500));
      expect(RewardOverlay.navigatorKey.currentState!.canPop(), isTrue);
      RewardOverlay.navigatorKey.currentState!.pop();
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('no in-app notification pop-up row, ever', (t) async {
      SplashGate.done.value = true;
      DailyQuoteGate.done.value = true;
      await NotifStore.instance.load();
      await t.pumpWidget(const MaterialApp(home: NotificationPopupHost(child: Scaffold(body: Text('page')))));
      await NotifStore.instance.notify(type: 'offers', title: 'Big offer', body: 'Today only');
      await t.pump(const Duration(milliseconds: 300));
      expect(NotifStore.instance.feed.where((e) => e.title == 'Big offer'), isNotEmpty);
      expect(find.byKey(const ValueKey('nwsb-notif-row')), findsNothing);
      expect(find.text('Big offer'), findsNothing);
      expect(find.text('page'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 7));
    });
  });
}
