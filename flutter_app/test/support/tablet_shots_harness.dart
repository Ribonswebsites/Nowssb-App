// Tablet sweep: every main page and every pushed route at 1280x800,
// 1024x768, 800x1280 and 390x844 (the phone, which must not change).
// Only runs with --dart-define=TABLET_SHOTS=<out dir>.
//   TABLET_ONLY=Home,PlayerScreen   only these pages
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/splash.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:nowssb/widgets/how_it_works_card.dart';
import 'package:nowssb/widgets/home_menu_drawer.dart';
import 'package:nowssb/screens/reader/reader_book.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/features/account/payout_details_page.dart';
import 'package:nowssb/features/account/complete_profile_page.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/draw/lucky_draw_screen.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/features/downloads/downloads_screen.dart';
import '../back_screens.g.dart';
import '../fake_video_platform.dart';
import 'home_render.dart';
import 'offline_google_fonts.dart';
import 'tablet_hook.dart';
import 'test_fonts.dart';

const _out = String.fromEnvironment('TABLET_SHOTS');
const _onlyArg = String.fromEnvironment('TABLET_ONLY');

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

final _key = GlobalKey();

/// Decodes on-screen pictures in parallel, with one short overall cap, so a
/// page full of art cannot stall the sweep.
Future<void> _precache(WidgetTester t) async {
  final imgs = [
    for (final e in find.byType(Image).evaluate())
      (e, (e.widget as Image).image),
    for (final e in find.byType(DecoratedBox).evaluate())
      if ((e.widget as DecoratedBox).decoration
          case BoxDecoration(image: DecorationImage(image: final p)))
        (e, p),
  ];
  await t.runAsync(() async {
    final jobs = <Future<void>>[];
    final seen = <Object>{};
    for (final (e, p) in imgs) {
      if (p is NetworkImage || (p is ResizeImage && p.imageProvider is NetworkImage)) continue;
      if (!seen.add(p)) continue;
      jobs.add(precacheImage(p, e).catchError((_) {}));
    }
    try {
      await Future.wait(jobs).timeout(const Duration(seconds: 4));
    } catch (_) {}
  });
}

Future<void> _shot(WidgetTester t, String name) async {
  await _precache(t);
  await t.pump(const Duration(milliseconds: 100));
  await _precache(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Pages from the generated list that are tabs (shot from the shell) or
/// not real routes of their own.
const _skipPages = {'NavShell', 'HomeFashion', 'HomeNormal', 'PracticeScreen', 'ProfileScreen', 'StoreScreen'};

final _errors = <String, Set<String>>{};

Future<GlobalKey<NavigatorState>> _app(WidgetTester t, Size s) async {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  final nav = GlobalKey<NavigatorState>();
  SplashGate.done.value = true;
  await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      navigatorObservers: appFrameObservers(),
      theme: NwsbTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (c, child) => RepaintBoundary(
          key: _key,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            wrapAppFrame(nav, child ?? const SizedBox()),
          ])),
      home: const NavShell()));
  await _settle(t, 15);
  final agree = find.text('I Agree · Continue');
  if (agree.evaluate().isNotEmpty) {
    await t.tap(agree.first, warnIfMissed: false);
    await _settle(t, 15);
  }
  // Today's quote pop-up and other once-a-day sheets: close them.
  for (var i = 0; i < 3; i++) {
    final nv = nav.currentState!;
    if (!nv.canPop()) break;
    nv.pop();
    await _settle(t, 6);
  }
  return nav;
}

void tabletShots(List<String> sizes) {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'nowssb_name': 'Ribon'});
  setUpAll(() async {
    if (_out.isEmpty) return;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    await loadRoboto();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await ContentStore.instance.start();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });
  tearDownAll(() {
    if (_out.isEmpty) return;
    final b = StringBuffer();
    for (final e in _errors.entries) {
      if (e.value.isEmpty) continue;
      b.writeln('== ${e.key}');
      for (final x in e.value) {
        b.writeln('  $x');
      }
    }
    File('$_out/errors_${sizes.join('_')}.txt').writeAsStringSync(b.toString());
  });

  final only = _onlyArg.isEmpty ? null : _onlyArg.split(',').toSet();
  bool want(String n) => only == null || only.contains(n);

  for (final spec in sizes) {
    final p = spec.split('x');
    final size = Size(double.parse(p[0]), double.parse(p[1]));
    final tag = spec;

    Future<void> run(WidgetTester t, String name, Future<void> Function(GlobalKey<NavigatorState> nav) body) async {
      addTearDown(t.view.reset);
      final prev = FlutterError.onError;
      final errs = _errors.putIfAbsent('$tag $name', () => <String>{});
      FlutterError.onError = (d) => errs.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = prev);
      final nav = await _app(t, size);
      await body(nav);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 5));
    }

    const tabs = {'Home': 0, 'Practice': 1, 'Library': 2, 'Store': 3, 'Profile': 4};
    for (final skin in ['normal', 'zen']) {
      for (final e in tabs.entries) {
        if (skin == 'zen' && e.key != 'Home') continue;
        final name = e.key == 'Home' ? '${skin}home' : e.key;
        if (!want(name)) continue;
        testWidgets('$tag $name', (t) async {
          await run(t, name, (nav) async {
            await Settings.instance.setFashionHome(skin == 'zen');
            await _settle(t, 6);
            NavScope.goTo(nav.currentState!.overlay!.context, e.value);
            await _settle(t, 12);
            await _shot(t, '$tag/$name');
          });
        }, skip: _out.isEmpty);
      }
    }

    final pages = <String, Widget Function()>{
      for (final e in btScreens.entries)
        if (!_skipPages.contains(e.key)) e.key: e.value,
      'PracticePlayerScreen': () => PracticePlayerScreen(
          words: ContentStore.instance.library.take(6).toList(), title: 'Morning Ritual', showIntro: false),
      'WordDetail': () => WordDetail(word: ContentStore.instance.library.first),
      'ReaderBookScreen': () => const ReaderBookScreen(kind: ReaderKind.ebook),
      'TodayProgressScreen': () => const TodayProgressScreen(),
      'SoundCategoryScreen': () => const SoundCategoryScreen(category: 'Healing'),
      'PayoutDetailsPage': () => const PayoutDetailsPage(),
      'EarnTabsPage': () => const EarnTabsPage(initialTab: 'earn'),
      'LuckyDrawScreen': () => const LuckyDrawScreen(),
      'RecentActivityScreen': () => const RecentActivityScreen(),
      'DownloadsScreen': () => const DownloadsScreen(),
      'YourDetailsPage': () => const YourDetailsPage(uid: 'tablet-shots'),
    };
    for (final e in pages.entries) {
      if (!want(e.key)) continue;
      testWidgets('$tag ${e.key}', (t) async {
        await run(t, e.key, (nav) async {
          await Settings.instance.setFashionHome(false);
          nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => e.value()));
          await _settle(t, 18);
          await _shot(t, '$tag/${e.key}');
        });
      }, skip: _out.isEmpty);
    }

    if (want('MenuDrawer')) {
      testWidgets('$tag MenuDrawer', (t) async {
        await run(t, 'MenuDrawer', (nav) async {
          final ctx = nav.currentState!.overlay!.context;
          unawaited(showHomeMenuDrawer(ctx, goTab: (i) => NavScope.goTo(ctx, i)));
          await _settle(t, 10);
          await _shot(t, '$tag/MenuDrawer');
        });
      }, skip: _out.isEmpty);
    }

    if (want('PlayerQueue')) {
      testWidgets('$tag PlayerQueue', (t) async {
        await run(t, 'PlayerQueue', (nav) async {
          nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(
              words: ContentStore.instance.library.take(6).toList(), title: 'Morning Ritual', showIntro: false)));
          await _settle(t, 18);
          // Swipe up on the player's next-up card opens the queue.
          final up = find.text('UP NEXT');
          if (up.evaluate().isNotEmpty) {
            try {
              await t.ensureVisible(up.first);
              await _settle(t, 4);
            } catch (_) {}
            await t.fling(up.first, const Offset(0, -300), 1500, warnIfMissed: false);
            await _settle(t, 10);
          }
          await _shot(t, '$tag/PlayerQueue');
        });
      }, skip: _out.isEmpty);
    }

    if (want('HowItWorks')) {
      testWidgets('$tag HowItWorks', (t) async {
        await run(t, 'HowItWorks', (nav) async {
          showHowItWorks(nav.currentState!.overlay!.context);
          await _settle(t, 10);
          await _shot(t, '$tag/HowItWorks');
        });
      }, skip: _out.isEmpty);
    }
  }
}
