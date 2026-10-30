import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/screens/poster/poster_kit.dart';

void main() {
  test('a word bought on this phone reads as Owned at once (no re-buy)', () {
    final e = Entitlements.instance;
    e.debugSet(uid: 'u1', owned: {});
    expect(priceOrNull('word:calm', 99), isNotNull);
    e.markPaid(['word:calm', 'meaning:calm']);
    expect(e.ownsItem('word:calm'), isTrue);
    expect(e.ownsOrIncluded('word:calm', price: 99), isTrue);
    expect(e.ownsOrIncluded('meaning:calm', price: 99), isTrue);
    expect(priceOrNull('word:calm', 99), isNull);
    expect(ownedLabel('word:calm'), 'Owned');
    e.debugSet(uid: null, owned: {});
    expect(e.ownsItem('word:calm'), isFalse);
  });
}
