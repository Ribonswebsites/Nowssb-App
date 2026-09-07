import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/playback_session.dart';

void main() {
  test('NIOSH safeSeconds: 85 dB is 8 hours', () {
    expect(PlaybackSession.safeSeconds(85), 8 * 3600);
  });

  test('NIOSH safeSeconds: every +3 dB halves', () {
    expect(PlaybackSession.safeSeconds(88), 4 * 3600);
    expect(PlaybackSession.safeSeconds(91), 2 * 3600);
    expect(PlaybackSession.safeSeconds(100), closeTo(15 * 60, 1));
  });

  test('below 85 dB is unlimited', () {
    expect(PlaybackSession.safeSeconds(55).isInfinite, isTrue);
    expect(PlaybackSession.safeSeconds(84.9).isInfinite, isTrue);
  });
}
