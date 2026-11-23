// My progress in the CliniQ layout: shots at 390x844 (and 360, tablet).
// flutter test test/myprogress_shots_test.dart --dart-define=MYPROGRESS_SHOTS=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/features/progress/my_progress_kit.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
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

const _out = String.fromEnvironment('MYPROGRESS_SHOTS');
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

Future<void> _app(WidgetTester t, Widget home, {double w = 390, double h = 844, bool dark = true}) async {
  t.view.physicalSize = Size(w, h);
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
  });

  testWidgets('my progress shots', (t) async {
    if (_out.isEmpty) return;
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await DailyTasks.publish();
      await DailyCheckIn.instance.load();
    });
    ProgressCenter.instance.reset();
    ProgressRoutes.goTab = (_, __) {};
    EconomyMirror.instance.summary = const {};
    PracticeProgress.instance.debugSetSessionsForTest({});
    ProgressSources.instance.sync();
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _app(t, const TodayProgressScreen());
    await _shot(t, '00_warmup');
    FlutterError.onError = warm;
    File('$_out/00_warmup.png').deleteSync();

    Future<void> page(String name, {double w = 390, double h = 844}) async {
      await t.pumpWidget(const SizedBox());
      await _app(t, const TodayProgressScreen(), w: w, h: h);
      await _settle(t, 6);
      await _shot(t, '${name}_1_top');
      final s = t.state<ScrollableState>(find.byType(Scrollable).hitTestable().first);
      if (s.position.maxScrollExtent > 0) {
        s.position.jumpTo((s.position.maxScrollExtent / 2).roundToDouble());
        await _settle(t, 4);
        await _shot(t, '${name}_2_middle');
        s.position.jumpTo(s.position.maxScrollExtent);
        await _settle(t, 4);
        await _shot(t, '${name}_3_end');
      }
    }

    // New account: empty states, real zeros.
    await page('after_01_new_user_390');
    await page('after_02_new_user_360', w: 360, h: 800);

    // Some practice (test sessions on real library words) to show the data.
    final lib = ContentStore.instance.library;
    final now = DateTime.now();
    final s = <String, Map<String, dynamic>>{};
    void add(int daysAgo, int hour, int minute, int i, int secs) {
      if (lib.length <= i) return;
      final d = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
      final k = dayKey(d);
      s['${k}_${lib[i].word}'] = {'date': k, 'word': lib[i].word, 'completedAt': d.toIso8601String(), 'durationSec': secs};
    }
    add(0, 7, 15, 0, 240);
    add(0, 7, 40, 1, 180);
    add(1, 9, 5, 2, 300);
    add(1, 21, 30, 3, 200);
    add(2, 6, 50, 4, 260);
    add(3, 18, 10, 5, 220);
    add(30, 8, 20, 6, 210);
    PracticeProgress.instance.debugSetSessionsForTest(s);
    await t.runAsync(() => DailyCheckIn.instance.checkIn());
    ProgressSources.instance.sync();
    await page('after_03_with_practice_390');

    // Pick yesterday on the strip.
    await t.pumpWidget(const SizedBox());
    await _app(t, const TodayProgressScreen());
    final y = DateTime(now.year, now.month, now.day - 1);
    final f = find.byKey(ValueKey('today-day-${dayKey(y)}'));
    await t.ensureVisible(f);
    await _settle(t, 3);
    await t.tap(f);
    await _settle(t, 4);
    await _shot(t, 'after_04_yesterday_picked');
    // Details sheet.
    final sc = t.state<ScrollableState>(find.byType(Scrollable).hitTestable().first);
    sc.position.jumpTo(0);
    await _settle(t, 3);
    await t.tap(find.byKey(const ValueKey('today-details')));
    await _settle(t, 6);
    await _shot(t, 'after_05_word_details_sheet');
    await t.tapAt(const Offset(195, 40));
    await _settle(t, 6);
    expect(find.byKey(const ValueKey('mp-sheet')), findsNothing);
    // Swipe-able month switcher: back one month.
    await t.tap(find.byKey(const ValueKey('mp-month-prev')));
    await _settle(t, 4);
    await t.ensureVisible(find.byKey(const ValueKey('mp-month-label')));
    await _settle(t, 3);
    await _shot(t, 'after_06_previous_month');

    // Tablet.
    await page('after_07_tablet_1024', w: 1024, h: 1366);
  });
}
