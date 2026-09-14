
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fashion practice uses website PRACTICE_VID via NwsbVideo', () {
    final src = File('lib/screens/fashion/sections_top.dart').readAsStringSync();
    expect(src, contains('09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4'));
    expect(src, contains('ClipPriority.feature'));
    expect(src, isNot(contains('player-liquid-splash.mp4')));
  });

  test('VideoPool enables mixWithOthers for concurrent muted loops', () {
    final src = File('lib/media/video_pool.dart').readAsStringSync();
    expect(src, contains('mixWithOthers: true'));
    expect(src, contains('maxLive = 24'));
  });

  test('GentleMarqueeText is continuous repeating marquee', () {
    final src = File('lib/widgets/home_parts.dart').readAsStringSync();
    expect(src, contains('_c.repeat()'));
    expect(src, isNot(contains('_c.repeat(reverse: true)')));
    expect(src, contains('borderRadius: BorderRadius.circular(20)'));
  });
}
