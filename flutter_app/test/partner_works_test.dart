import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/features/economy/partner_screen.dart';
import 'package:nowssb/features/programs/partner_program.dart';

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('purchase kinds read in plain words', () {
    expect(partnerKindLabel('subscription'), 'Plan');
    expect(partnerKindLabel('giftcard'), 'Gift card');
    expect(partnerKindLabel('word'), 'Word');
    expect(partnerKindLabel(''), 'Purchase');
  });

  test('pending line never says 0 days', () {
    expect(partnerPendingLine(0, 30), 'Nothing waiting to be confirmed');
    expect(partnerPendingLine(1, 30), '1 point waiting 30 days for the refund window');
    expect(partnerPendingLine(5, 0), '5 points waiting for the refund window');
  });

  test('no fake 0% buyer discount', () {
    expect(partnerDiscountReady(const {}), isFalse);
    expect(partnerDiscountReady(const {'wordPct': 10}), isTrue);
  });

  testWidgets('every Partner button and tab opens without a crash', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: PartnerScreen()));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Your Partner points'), findsOneWidget);
    for (final b in ['My progress and perks', 'Word Track', 'Plan Track', 'Buyer discount']) {
      await t.tap(find.text(b).first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull, reason: b);
    }
    for (final tab in ['Perks', 'Leaderboard', 'Rules']) {
      final f = find.text(tab);
      if (f.evaluate().isEmpty) continue;
      await t.ensureVisible(f.last);
      await t.tap(f.last, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull, reason: tab);
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
