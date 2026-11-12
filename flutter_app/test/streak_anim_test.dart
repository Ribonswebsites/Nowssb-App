// Normal-home "YOUR STREAK" card: the circular disc / dotted ring / centre
// flame is replaced by a growing candle. Everything else on the card stays.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/concept/r27/anims.dart';
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

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(fontFamily: 'DM Sans'),
  home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 1400), disableAnimations: true),
    child: Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SingleChildScrollView(child: child),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    SharedPreferences.setMockInitialValues({});
    await PracticeProgress.instance.start();
  });

  setUp(() {
    PracticeProgress.instance.debugSetSessionsForTest({});
  });

  testWidgets(
    'streak card keeps its copy and uses the candle, not the disc flame',
    (t) async {
      await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
      await t.pump();
      expect(find.text('YOUR STREAK'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('days in a row'), findsOneWidget);
      expect(find.text('0 today · 0 sessions in all'), findsOneWidget);
      expect(find.text('Practice now'), findsOneWidget);
      expect(find.text('Exclusive offers'), findsOneWidget);
      expect(find.byType(R27StreakCandle), findsOneWidget);
      expect(find.byType(R27BreathFlame), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('candle follows the live streak (0 unlit, 4 days lit)', (
    t,
  ) async {
    await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
    await t.pump();
    expect(
      find.byWidgetPredicate((w) => w is R27StreakCandle && w.streak == 0),
      findsOneWidget,
    );

    PracticeProgress.instance.debugSetSessionsForTest(_days(4));
    await t.pump();
    expect(find.text('4'), findsOneWidget);
    expect(find.text('days in a row'), findsOneWidget);
    expect(find.text('1 today · 4 sessions in all'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is R27StreakCandle && w.streak == 4),
      findsOneWidget,
    );
    expect(find.byType(R27BreathFlame), findsNothing);
    expect(t.takeException(), isNull);
  });
}
