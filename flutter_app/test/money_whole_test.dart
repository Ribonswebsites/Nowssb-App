import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/money.dart';

void main() {
  final fx = FxBook.instance;

  test('whole rupees drop the decimals; real paise stay', () {
    expect(fx.formatPrice(99, locale: 'en_IN', whole: true), '₹99');
    expect(fx.formatPrice(299, locale: 'en_IN', whole: true), '₹299');
    expect(fx.formatPrice(99.5, locale: 'en_IN', whole: true), '₹99.50');
    expect(fx.formatPrice(100000, locale: 'en_IN', whole: true), '₹1,00,000');
  });

  test('the shared default is unchanged (decimals kept)', () {
    expect(fx.formatPrice(99, locale: 'en_IN'), '₹99.00');
  });

  test('a Play label loses only an all-zero minor part', () {
    expect(FxBook.wholeLabel('₹99.00'), '₹99');
    expect(FxBook.wholeLabel('₹99.50'), '₹99.50');
    expect(FxBook.wholeLabel('₹1,00,000.00'), '₹1,00,000');
    expect(FxBook.wholeLabel('₹1,00,000'), '₹1,00,000');
    expect(FxBook.wholeLabel('1.234,00 €'), '1.234 €');
    expect(FxBook.wholeLabel('US\$1.00'), 'US\$1');
  });
}
