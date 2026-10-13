import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/template_more.dart';

void main() {
  test('sample prices follow the locale, not one country', () {
    expect(samplePrice(199, locale: 'en_US'), r'$199');
    expect(samplePrice(199, locale: 'en_IN'), contains('199'));
    expect(samplePrice(199, locale: 'de_DE'), contains('€'));
    expect(samplePrice(5, locale: 'xx_bogus'), contains('5'));
  });

  test('our editor templates carry no hard-coded rupee prices', () {
    final src = File('lib/admin/layout/template_more.dart').readAsStringSync();
    expect(src.contains('\u20b9'), isFalse);
    expect(RegExp(r'\binr\(').hasMatch(src), isFalse);
    expect(moreStarter('couponStub')['amount'], isA<String>());
  });
}
