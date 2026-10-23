import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/daily_quotes.dart';
import 'package:nowssb/widgets/buddha_gyro_stage.dart';

void main() {
  test('every quote has its emphasis word inside the text', () {
    for (final q in kDailyQuotes) {
      if (q.emphasis != null) {
        expect(q.text.toLowerCase(), contains(q.emphasis!.toLowerCase()));
      }
    }
    expect(kDailyQuotes.length, greaterThanOrEqualTo(25));
  });

  test('rotation: deterministic, new each day, covers the list', () {
    final start = DateTime(2026, 10, 1);
    final seen = <int>{};
    int? prev;
    for (var i = 0; i < kDailyQuotes.length; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      final idx = quoteIndexFor(d);
      expect(idx, quoteIndexFor(DateTime(d.year, d.month, d.day, 23, 59)));
      expect(idx, isNot(prev));
      prev = idx;
      seen.add(idx);
    }
    expect(seen.length, kDailyQuotes.length);
  });

  test('week list is today first then the previous six days', () {
    final w = weekQuotes(DateTime(2026, 10, 23, 18));
    expect(w.length, 7);
    expect(w.first.day, DateTime(2026, 10, 23));
    expect(w.last.day, DateTime(2026, 10, 17));
    final o = weekQuotes(DateTime(2026, 10, 23),
        override: (d) => d.day == 23 ? 'Pinned' : '');
    expect(o.first.quote.text, 'Pinned');
  });

  testWidgets('quotes section renders the Daily Quote card without overflow', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BuddhaGyroStage(now: DateTime(2026, 10, 23, 18, 41)),
        ),
      ),
    ));
    await t.pump();
    expect(find.byType(DailyQuoteCard), findsOneWidget);
    expect(find.textContaining('TODAY'), findsOneWidget);
    await t.drag(find.byType(PageView), const Offset(-400, 0));
    await t.pump(const Duration(milliseconds: 600)); await t.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('YESTERDAY'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
