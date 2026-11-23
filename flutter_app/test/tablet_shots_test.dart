// Tablet sweep: every main page and every pushed route at 1280x800,
// 1024x768, 800x1280 and 390x844 (the phone, which must not change).
// Only runs with --dart-define=TABLET_SHOTS=<out dir>; see
// test/support/tablet_shots_harness.dart. test/tablet_shots/ has one file
// per size so the sizes run side by side (flutter test -j 4).
import 'support/tablet_shots_harness.dart';

const _sizes = String.fromEnvironment('TABLET_SIZES', defaultValue: '1280x800,1024x768,800x1280,390x844');

void main() => tabletShots(_sizes.split(','));
