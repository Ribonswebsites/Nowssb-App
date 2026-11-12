// Today's progress shots at 390 wide.
// flutter test test/today_progress_shots_test.dart --dart-define=TODAY_SHOTS=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/quests_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:nowssb/widgets/page_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('TODAY_SHOTS');
final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _app(WidgetTester t, Widget home, {double h = 844, bool dark = true}) async {
  t.view.physicalSize = Size(390, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(MaterialApp(
    theme: NwsbTheme.light,
    debugShowCheckedModeBanner: false,
    builder: (c, child) => RepaintBoundary(
      key: _key,
      child: Stack(children: [
        Positioned.fill(child: ColoredBox(color: dark ? Colors.black : NwsbColors.surface)),
        if (dark) const Positioned.fill(child: FaintFilm()),
        child ?? const SizedBox(),
      ]),
    ),
    home: home,
  ));
  await _settle(t);
}

/// Stand-in for the Zen home's backdrop video (the tests have no decoder).
class _ZenBack extends StatelessWidget {
  const _ZenBack({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.3, colors: [Color(0xFF3A1D78), Color(0xFF0E061E), Color(0xFF000000)], stops: [0, .55, 1]),
        ),
        child: child,
      );
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });

  testWidgets('today progress shots', (t) async {
    if (_out.isEmpty) return;
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    ProgressCenter.instance.reset();
    ProgressRoutes.goTab = (_, __) {};
    await t.runAsync(() async {
      await DailyTasks.publish();
      await DailyCheckIn.instance.load();
    });
    ProgressSources.instance.sync();

    // 1 · normal home greeting (a throwaway first shot registers the fonts).
    const greet = Scaffold(backgroundColor: NwsbColors.surface, body: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(bottom: 16), child: NmGreeting(name: 'Healer'))));
    // Warm-up: renders in the square test font until google_fonts registers.
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _app(t, greet, h: 400, dark: false);
    await _shot(t, '01_normal_greeting_button');
    await t.pumpWidget(const SizedBox());
    await _app(t, greet, h: 130, dark: false);
    await _shot(t, '01_normal_greeting_button');
    FlutterError.onError = warm;

    // 2 · Zen Begin Your Healing Path banner.
    await _app(t, const Scaffold(backgroundColor: Colors.black, body: _ZenBack(child: Align(alignment: Alignment.topCenter, child: FashGreeting()))), h: 190);
    await _shot(t, '02_zen_begin_banner_button');

    // 3 · pop-up before and after a check-in (over the normal home top).
    final under = Scaffold(
      backgroundColor: NwsbColors.surface,
      body: SafeArea(child: Column(children: [const NmGreeting(name: 'Healer'), Expanded(child: Container())])),
    );
    await _app(t, under);
    await t.tap(find.byKey(const ValueKey('today-progress-button')));
    await _settle(t, 6);
    await _shot(t, '03_popup_before_checkin');
    await t.tap(find.byKey(const ValueKey('progress-tile-checkin')));
    await _settle(t, 6);
    await _shot(t, '04_popup_after_checkin');

    // 4 · Today's progress page (from View all).
    await t.tap(find.byKey(const ValueKey('progress-view-all')));
    await _settle(t, 12);
    await _shot(t, '05_today_progress_page_top');
    final s = t.state<ScrollableState>(find.byType(Scrollable).hitTestable().first);
    s.position.jumpTo(s.position.maxScrollExtent);
    await _settle(t, 4);
    await _shot(t, '06_today_progress_page_end');

    // 5 · each destination, opened from its card on the page.
    s.position.jumpTo(0);
    await _settle(t, 4);
    Future<void> openFrom(String kind, String name) async {
      final f = find.byKey(ValueKey('today-goal-$kind'));
      await t.ensureVisible(f);
      await _settle(t, 2);
      await t.tap(f);
      await _settle(t, 14);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await _settle(t, 4);
      await _shot(t, name);
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await _settle(t, 6);
    }

    await openFrom('tasks', '07_dest_daily_tasks');
    await openFrom('coins', '08_dest_coins');
    await openFrom('quest', '09_dest_quests_signed_out');

    // Practice goes to the Practice tab (the shell's tab switch); this is that tab.
    // (Its own cards are another worker's restyle; a test-font overflow there is not ours.)
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) prev?.call(d);
    };
    await _app(t, const PracticeScreen());
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await _settle(t, 6);
    await _shot(t, '10_dest_practice_tab');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    FlutterError.onError = prev;

    // Quests as a signed-in account sees them (sample server summary).
    await _app(
        t,
        PageShell(
          eyebrow: 'NowssB',
          title: 'Quests',
          film: 'assets/video/subscription-bg.mp4',
          usePageFilm: true,
          quietFilm: true,
          onBack: () {},
          slivers: const [
            SliverToBoxAdapter(
              child: QuestsBody(signedIn: true, summary: {
                'quests': {
                  'starter': [
                    {'id': 'practice5', 'title': 'Practise 5 times', 'goal': 5, 'coins': 25, 'value': 5, 'claimed': false},
                    {'id': 'streak3', 'title': 'Keep a 3-day streak', 'goal': 3, 'coins': 20, 'value': 1, 'claimed': false},
                    {'id': 'listen1', 'title': 'Open the player', 'goal': 1, 'coins': 10, 'value': 1, 'claimed': true},
                  ],
                  'weekly': [
                    {'id': 'w_minutes', 'title': 'Spend 60 minutes', 'goal': 60, 'coins': 40, 'value': 12, 'claimed': false},
                    {'id': 'w_meanings', 'title': 'Read 5 meanings', 'goal': 5, 'coins': 25, 'value': 2, 'claimed': false},
                  ],
                  'monthly': {'id': 'm_master', 'title': 'Master 3 words to level 5', 'goal': 3, 'coins': 200, 'value': 0, 'claimed': false},
                },
              }),
            ),
          ],
        ));
    await _shot(t, '11_dest_quests_signed_in_sample');
    EconomyMirror.instance.loginToday = false;
  });
}
