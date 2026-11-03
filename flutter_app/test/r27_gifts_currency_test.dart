import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/widgets/concept/r27/data.dart';
import 'package:nowssb/widgets/concept/r27/sections.dart';

void main() {
  test('Gifts line uses the local currency, never a hard-coded rupee', () {
    const d = R27Gifts(cards: [R27Gift('a', 'A', 99)], sent: 0, received: 0);
    final line = r27GiftsLine(d, 99)!;
    expect(line, contains(FxBook.instance.formatPrice(99, whole: true)));
    if (FxBook.instance.codeFor() != 'INR') {
      expect(line, isNot(contains('₹')));
    }
    expect(line, isNot(contains('INR')));
  });
}
