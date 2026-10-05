import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:nowssb/widgets/app_thinking_loader.dart';

void main() {
  test('orbStateFromStyle reads a known OrbState and ignores random/empty', () {
    expect(orbStateFromStyle({'orb': 'solving'}), OrbState.solving);
    expect(orbStateFromStyle({'orb': 'shaping'}), OrbState.shaping);
    expect(orbStateFromStyle({'orb': 'random'}), isNull);
    expect(orbStateFromStyle({'orb': ''}), isNull);
    expect(orbStateFromStyle(null), isNull);
    expect(orbStateFromStyle({'orb': 'notReal'}), isNull);
  });

  test('thinkingAnimFromStyle prefers lottie kind+asset over orb', () {
    final a = thinkingAnimFromStyle({
      'kind': 'lottie',
      'asset': 'assets/anim/thinking/assistant_gem_gold.json',
      'orb': 'solving',
    });
    expect(a, isNotNull);
    expect(a!.isLottie, isTrue);
    expect(a.asset, 'assets/anim/thinking/assistant_gem_gold.json');
    expect(a.orb, isNull);
  });

  test('thinkingAnimFromStyle falls back to OrbState', () {
    final a = thinkingAnimFromStyle({'kind': 'orb', 'orb': 'listening'});
    expect(a, isNotNull);
    expect(a!.isOrb, isTrue);
    expect(a.orb, OrbState.listening);
  });
}
