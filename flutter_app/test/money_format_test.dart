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
}
