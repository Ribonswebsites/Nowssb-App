import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/gifts/spin_wheel.dart';

// Daily Spin: exactly one free spin a day, no paid extra spins.
void main() {
  Map<String, dynamic> summary(int spins, {Map<String, dynamic>? spin}) => {
        'config': {'spin': spin ?? {'freePerDay': 1, 'paidPerDay': 0}},
        'today': {'spins': spins},
      };

  tearDown(() => EconomyMirror.instance.summary = const {});

  test('the free spin is open until it is used today', () {
    EconomyMirror.instance.summary = summary(0);
    final now = SpinNow.read();
    expect(now.next, 'free');
    expect(now.freeLeft, 1);
  });

  test('after the free spin: come back tomorrow, never a paid spin', () {
    EconomyMirror.instance.summary = summary(1);
    expect(SpinNow.read().next, 'limit');
  });

  test('an old server config with paid spins still never offers one', () {
    EconomyMirror.instance.summary = summary(1, spin: {'freePerDay': 1, 'paidPerDay': 40, 'costCoins': 15});
    expect(SpinNow.read().next, 'limit');
  });

  test('no summary yet: one free spin', () {
    EconomyMirror.instance.summary = const {};
    expect(SpinNow.read().next, 'free');
  });
}
