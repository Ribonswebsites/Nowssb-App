/// Today's Quote pop-up: once per local day per account, manual open any
/// time, and the wave's poster painted on the very first frame.
@Timeout(Duration(seconds: 90))
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/quote_film.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/quotes_live.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

final _popup = find.byKey(const ValueKey('daily-quote-popup'));

final _poster = find.byWidgetPredicate((w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName == QuoteFilm.poster);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeVideoPlatform platform;

  setUpAll(() {
    platform = FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.instance.load();
    platform.reset();
    await QuoteFilm.debugReset();
  });

  tearDown(QuoteFilm.debugReset);

  late BuildContext ctx;

  Future<void> pumpHost(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox.expand());
      }),
    ));
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> close(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('daily-quote-close')));
    await settle(t);
    expect(_popup, findsNothing);
  }

  final day1 = DateTime(2026, 11, 17, 9);
  final day1Late = DateTime(2026, 11, 17, 23, 50);
  final day2 = DateTime(2026, 11, 18, 0, 5);

  testWidgets('shows once per local day, again the next day', (t) async {
    await pumpHost(t);

    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    await settle(t);
    expect(_popup, findsOneWidget);
    await close(t);

    // Re-opening the app / home the same day: nothing.
    showDailyQuoteIfNeeded(ctx, now: day1Late, uid: 'u1');
    await settle(t);
    expect(_popup, findsNothing);

    // Next calendar day: once again.
    showDailyQuoteIfNeeded(ctx, now: day2, uid: 'u1');
    await settle(t);
    expect(_popup, findsOneWidget);
    await close(t);
  });

  testWidgets('the day is claimed before the card opens (app killed while open)',
      (t) async {
    await pumpHost(t);
    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    await settle(t);
    expect(_popup, findsOneWidget);
    // Not closed — as if the app were swiped away now.
    final p = await SharedPreferences.getInstance();
    expect(p.getString(dailyQuoteShownKey('u1')), '2026-11-17');
    expect(await dailyQuoteDue(now: day1Late, uid: 'u1'), isFalse);
    await close(t);
  });

  testWidgets('two shells asking at once open a single card', (t) async {
    await pumpHost(t);
    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    await settle(t);
    expect(_popup, findsOneWidget);
    await close(t);
  });

  testWidgets('each account has its own day mark', (t) async {
    await pumpHost(t);
    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    await settle(t);
    await close(t);
    expect(await dailyQuoteDue(now: day1, uid: 'u1'), isFalse);
    expect(await dailyQuoteDue(now: day1, uid: 'u2'), isTrue);
  });

  testWidgets('opening it by hand works any time', (t) async {
    await pumpHost(t);
    showDailyQuoteIfNeeded(ctx, now: day1, uid: 'u1');
    await settle(t);
    await close(t);

    showTodayQuote(ctx, now: day1Late);
    await settle(t);
    expect(_popup, findsOneWidget);
    await t.tap(find.byKey(const ValueKey('daily-quote-x')));
    await settle(t);
    expect(_popup, findsNothing);
  });

  testWidgets('poster is on screen at the first frame, before any video',
      (t) async {
    await pumpHost(t);
    showTodayQuote(ctx, now: day1);
    await t.pump(); // route pushed
    await t.pump(); // first frame of the card
    expect(_popup, findsOneWidget);
    expect(_poster, findsOneWidget);
    // The poster stays underneath once the film is up: no blank gap.
    await settle(t);
    expect(QuoteFilm.controller.value, isNotNull);
    expect(_poster, findsOneWidget);
    await close(t);
    await t.pump(const Duration(milliseconds: 50));
    expect(QuoteFilm.controller.value, isNull,
        reason: 'the decoder is given back once the card closes');
  });

  testWidgets('warmDailyQuote opens the film before the card on a due day',
      (t) async {
    await pumpHost(t);
    await warmDailyQuote(ctx);
    await settle(t);
    expect(QuoteFilm.controller.value, isNotNull);
    expect(QuoteFilm.controller.value!.value.isInitialized, isTrue);
    QuoteFilm.release();
    await settle(t);
  });

  testWidgets('no typo, no italic serif', (t) async {
    await pumpHost(t);
    showTodayQuote(ctx, now: day1);
    await settle(t);
    expect(find.textContaining('Quate'), findsNothing);
    expect(find.text("TODAY'S QUOTE"), findsOneWidget);
    expect(find.text('Open Quotes'), findsOneWidget);
    for (final e in find.descendant(of: _popup, matching: find.byType(Text)).evaluate()) {
      final s = (e.widget as Text).style;
      expect(s?.fontStyle == FontStyle.italic, isFalse);
      if (s?.fontFamily != null) expect(s!.fontFamily, 'DM Sans');
    }
    await close(t);
  });
}
