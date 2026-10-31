import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/programs/coupons_program.dart';

void main() {
  test('discount line hides a missing cap and date, no rupee text', () {
    final l = discountLine({'scope': 'any', 'capINR': 0});
    expect(l, 'Works on anything');
    expect(l.contains('₹'), isFalse);
    expect(l.contains('INR'), isFalse);
    expect(discountLine({'scope': 'words'}), 'Works on words');
  });

  test('claim note is plain words for every server answer', () {
    expect(couponClaimNote({'label': '10% off'}), '10% off is on your account.');
    expect(couponClaimNote({}), 'Your coupon is on your account.');
    expect(couponClaimNote({'win': false}), 'No win this time.');
    expect(couponClaimNote({'win': false, 'winPct': 20}), 'No win this time (20% chance).');
    expect(couponClaimNote({'already': true}), 'This code is already on your account.');
    expect(couponClaimNote({'locked': true}), 'This code needs one more step.');
    expect(couponClaimNote({'locked': true, 'label': 'Stage', 'how': 'Finish a streak'}), 'Stage: Finish a streak');
  });
}
