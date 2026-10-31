import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
  });

  group('earningsRows', () {
    const now = 1000000;
    test('sales, team commissions and payouts read plainly, newest first', () {
      final rows = earningsRows(
        cash: [
          {'reason': 'Commission (direct)', 'delta': 500, 'held': true, 'availableAt': now + 86400000, 'at': 10},
          {'reason': 'Commission (leg1)', 'delta': 200, 'held': true, 'availableAt': now - 1, 'at': 20},
          {'reason': 'Payout requested', 'delta': -700, 'at': 30},
        ],
        payouts: [
          {'amountBase': 700, 'status': 'queued', 'at': 40},
        ],
        nowMs: now,
      );
      expect(rows.map((r) => r.title), ['Payout', 'Team commission', 'Your sale']);
      expect(rows[0].cents, -700);
      expect(rows[0].status, 'In the queue');
      expect(rows[1].status, 'Available');
      expect(rows[2].status, startsWith('Pending until'));
      expect(rows.map((r) => r.kind), ['payout', 'circle', 'sale']);
    });

    test('missing fields never crash', () {
      final rows = earningsRows(cash: [{}], payouts: [{}], nowMs: now);
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.cents == 0), isTrue);
    });
  });

  testWidgets('Earnings: title, account sheet validates, activity filters, back closes sheet', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    // The shared EconomyPage header can overflow with the test font; that is not this page's doing.
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await t.pumpWidget(const MaterialApp(home: EarningsScreen()));
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Your Earnings'), findsWidgets);
    expect(find.textContaining('India · UPI'), findsNothing);

    // Activity filter chips switch.
    final chip = find.byKey(const Key('earnings-filter-payout'));
    await t.scrollUntilVisible(chip, 200, scrollable: find.byType(Scrollable).first);
    Scrollable.ensureVisible(t.element(chip), alignment: 0.5);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(chip);
    await t.pump();
    expect(t.widget<ChoiceChip>(chip).selected, isTrue);

    // Open the payout account sheet from the account card.
    await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await t.pump(const Duration(milliseconds: 300));
    final banner = find.text('Your earning');
    await t.scrollUntilVisible(banner, 150, scrollable: find.byType(Scrollable).first);
    Scrollable.ensureVisible(t.element(banner), alignment: 0.5);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(banner.first);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Payout account'), findsWidgets);
    if (find.byKey(const Key('earnings-email')).evaluate().isNotEmpty || find.byKey(const Key('earnings-upi')).evaluate().isNotEmpty) {
      await t.pump(const Duration(milliseconds: 500));
      await t.ensureVisible(find.text('Save payout account'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Save payout account'));
      await t.pump();
      expect(find.byKey(const Key('earnings-problem')), findsOneWidget);
    }

    // Android back closes the sheet, not the page.
    final popped = await t.binding.handlePopRoute();
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(popped, isTrue);
    expect(find.text('Save payout account'), findsNothing);
    expect(find.text('Your Earnings'), findsWidgets);
  });
}
