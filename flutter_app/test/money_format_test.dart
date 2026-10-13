import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/money.dart';

void main() {
  final fx = FxBook.instance;
  setUp(() => fx.rates = const {'USD': 1, 'INR': 80, 'EUR': 0.9, 'JPY': 150});

  test('server rupees shown in the viewer currency, from the rate table', () {
    expect(fx.formatRupees(80, locale: 'en_US'), r'$1.00');
    expect(fx.formatRupees(400, locale: 'en_IN'), contains('400'));
    expect(fx.formatRupees(400, locale: 'en_IN'), contains('₹'));
    final de = fx.formatRupees(80, locale: 'de_DE');
    expect(de, contains('0,90'));
    expect(de, contains('€'));
    expect(fx.formatRupees(80, locale: 'ja_JP'), contains('150'));
    expect(fx.formatRupees(80, locale: 'ja_JP'), isNot(contains('.')));
  });

  test('no ₹ for non-Indian locales', () {
    for (final l in ['en_US', 'de_DE', 'en_GB', 'ja_JP']) {
      expect(fx.formatRupees(499, locale: l), isNot(contains('₹')), reason: l);
    }
  });

  test('a currency with no rate falls back to USD, never invents a rate', () {
    expect(fx.formatCents(250, locale: 'en_GB'), contains('2.50'));
    expect(fx.formatCents(250, locale: 'en_GB'), contains(r'$'));
  });

  test('niceRound gives clean steps by magnitude', () {
    expect(FxBook.niceRound(5.98), 6);
    expect(FxBook.niceRound(0.18), 0.2);
    expect(FxBook.niceRound(0.012), 0.01);
    expect(FxBook.niceRound(3.2), 3);
    expect(FxBook.niceRound(47.3), 47);
    expect(FxBook.niceRound(73), 75);
    expect(FxBook.niceRound(312), 310);
    expect(FxBook.niceRound(7480), 7500);
    expect(FxBook.niceRound(0.3, wholeOnly: true), 1);
  });

  test('fixed rule amounts read as clean local figures', () {
    expect(fx.formatNice(BaseAmounts.underChip, locale: 'en_US'), r'$6'); // 499/80 = 6.24
    expect(fx.formatNice(BaseAmounts.minPaidLine, locale: 'en_US'), r'$0.20'); // 0.1875
    expect(fx.formatNice(BaseAmounts.coinExampleCoins / BaseAmounts.coinsPerUnit, locale: 'de_DE'), allOf(contains('1'), contains('€'), isNot(contains(','))));  // 100/80*0.9 = 1.125 → 1
    expect(fx.formatNice(BaseAmounts.underChip, locale: 'ja_JP'), contains('935')); // 935.6 → 935 (step 5)
    expect(fx.formatNice(BaseAmounts.underChip, locale: 'en_GB'), r'$6'); // no GBP rate here → USD, no invented rate
  });

  test('user copy in the payout/earn screens has no UPI, INR, rupee or India-only text', () {
    final bad = RegExp(r"'[^'\n]*(\bUPI\b|\bINR\b|₹|(?<![A-Za-z])[Rr]upee|\bPAN\b|\bTDS\b|Outside India)[^'\n]*'");
    for (final f in [
      'lib/features/earn/earnings_screen.dart',
      'lib/features/programs/earn_program.dart',
      'lib/features/earn/nowssb_one.dart',
      'lib/features/earn/earn_loyalty.dart',
      'lib/widgets/sections/category_tiles_section.dart',
    ]) {
      final hits = File(f).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//') && bad.hasMatch(l)).toList();
      expect(hits, isEmpty, reason: f);
    }
  });
}
