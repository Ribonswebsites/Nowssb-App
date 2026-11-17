// Normal-home "YOUR STREAK" card: the candle is replaced by the written
// Devanagari श letter. Everything else on the card stays.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/concept/r27/anims.dart';
import 'package:nowssb/widgets/concept/r27/streak_marks.dart';
import 'package:nowssb/widgets/concept/r27/streak_marks2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';

Map<String, Map<String, dynamic>> _days(int n) {
  final now = DateTime.now();
  final out = <String, Map<String, dynamic>>{};
  for (var i = 0; i < n; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final ymd =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_Om'] = {
      'date': ymd,
      'word': 'Om',
      'completedAt': d.toIso8601String(),
      'durationSec': 300,
    };
  }
  return out;
}

Widget _app(Widget child, {bool animate = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(fontFamily: 'DM Sans'),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 1400),
      disableAnimations: !animate,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SingleChildScrollView(child: child),
    ),
  ),
);

List<String> _haptics(WidgetTester t) {
  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (c) async {
      if (c.method == 'HapticFeedback.vibrate') calls.add('${c.arguments}');
      return null;
    },
  );
  return calls;
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    SharedPreferences.setMockInitialValues({});
    await PracticeProgress.instance.start();
  });

  setUp(() {
    PracticeProgress.instance.debugSetSessionsForTest({});
  });

  tearDown(() async {
    if (!Settings.instance.fashionPlus) {
      await Settings.instance.setFashionPlus(true);
    }
  });

  testWidgets(
    'streak card keeps its copy and uses the written letter, not the candle',
    (t) async {
      await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
      await t.pump();
      expect(find.text('YOUR STREAK'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('days in a row'), findsOneWidget);
      expect(find.text('0 today · 0 sessions in all'), findsOneWidget);
      expect(find.text('Practice now'), findsOneWidget);
      expect(find.text('Exclusive offers'), findsOneWidget);
      expect(find.byType(StreakSilkRibbons), findsOneWidget);
      expect(find.byType(R27StreakCandle), findsNothing);
      expect(find.byType(R27BreathFlame), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('letter follows the live streak (0 pale gold, 5 days richer)', (
    t,
  ) async {
    await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
    await t.pump();
    expect(
      find.byWidgetPredicate((w) => w is StreakSilkRibbons && w.streak == 0),
      findsOneWidget,
    );

    PracticeProgress.instance.debugSetSessionsForTest(_days(5));
    await t.pump();
    expect(find.text('5'), findsOneWidget);
    expect(find.text('days in a row'), findsOneWidget);
    expect(find.text('1 today · 5 sessions in all'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is StreakSilkRibbons && w.streak == 5),
      findsOneWidget,
    );
    expect(find.byType(R27StreakCandle), findsNothing);
    expect(find.byType(R27BreathFlame), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('Still motion freezes a finished letter and never buzzes', (
    t,
  ) async {
    final h = _haptics(t);
    await Settings.instance.setFashionPlus(false);
    PracticeProgress.instance.debugSetSessionsForTest(_days(5));
    await t.pumpWidget(
      _app(V4Streak(onPractice: () {}, onOffers: () {}), animate: true),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 2400));
    expect(
      find.byWidgetPredicate((w) => w is StreakSilkRibbons && w.streak == 5),
      findsOneWidget,
    );
    expect(find.byType(R27StreakCandle), findsNothing);
    expect(h, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('the letter itself does not trigger haptics while it writes', (
    t,
  ) async {
    final h = _haptics(t);
    PracticeProgress.instance.debugSetSessionsForTest(_days(5));
    await t.pumpWidget(
      _app(V4Streak(onPractice: () {}, onOffers: () {}), animate: true),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 2400));
    expect(find.byType(StreakSilkRibbons), findsOneWidget);
    expect(h, isEmpty);
    expect(t.takeException(), isNull);
  });
}
