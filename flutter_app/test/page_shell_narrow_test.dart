import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/page_shell.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'fake_video_platform.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VideoPlayerPlatform.instance = FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  for (final size in const [Size(320, 640), Size(390, 800)]) {
    testWidgets('PageShell header with back, actions and Stores fits at ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.3)),
          child: PageShell(
            eyebrow: 'Checkout',
            title: 'NowssB Store',
            subtitle: 'Your bag',
            film: '',
            onBack: () {},
            onStorePicker: () {},
            actions: [
              TextButton(onPressed: () {}, child: const Text('Reset')),
            ],
            slivers: const [SliverToBoxAdapter(child: SizedBox(height: 10))],
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      expect(find.text('Stores'), findsOneWidget);
      expect(find.text('NowssB Store'), findsOneWidget);
    });
  }
}
