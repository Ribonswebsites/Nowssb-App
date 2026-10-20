import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/money.dart';

void main() {
  final fx = FxBook.instance;
  tearDown(() => fx.rates = const {'USD': 1});

  test('no hardcoded INR rate is built in', () {
    expect(fx.rates.containsKey('INR'), isFalse);
  });

  test('FX unloaded: non-IN locales never see the rupee sign', () {
    for (final loc in ['en_US', 'en_GB', 'de_DE', 'ja_JP']) {
      final s = fx.formatRupees(99, locale: loc);
      expect(s, isNot(contains('₹')), reason: loc);
      expect(s, FxBook.pricePending, reason: loc);
    }
  });

  test('FX unloaded: India locale shows rupees', () {
    expect(fx.formatRupees(99, locale: 'en_IN'), contains('₹'));
    expect(fx.formatRupees(99, locale: 'en_IN'), contains('99'));
  });

  test('FX loaded: converts to local currency', () {
    fx.rates = const {'USD': 1, 'INR': 90, 'EUR': 0.9};
    expect(fx.formatRupees(90, locale: 'en_US'), r'$1.00');
    final eur = fx.formatRupees(90, locale: 'de_DE');
    expect(eur, contains('€'));
    expect(eur, contains('0,90'));
    expect(fx.formatRupees(90, locale: 'en_IN'), contains('₹'));
  });

  test('formatCents still renders base USD for earnings when FX unloaded', () {
    expect(fx.formatCents(1234, locale: 'en_US'), r'$12.34');
    expect(fx.formatCents(1234, locale: 'en_IN'), contains('12.34'));
  });
}
