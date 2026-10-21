import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/shared_sections.dart';
import 'package:nowssb/widgets/tv_frame.dart';
import 'package:nowssb/widgets/tv_split_header.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushed.add(route);
}

const _shots = '/workspace/specs/shots';

Future<void> _loadRoboto() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '/home/box/flutter'}/bin/cache/artifacts/material_fonts';
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf', 'Roboto-Medium.ttf']) {
    final file = File('$dir/$f');
    if (!file.existsSync()) return;
    final l = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await l.load();
  }
}

Future<void> _shot(WidgetTester t, Key key, String name) async {
  if (!Directory(_shots).existsSync()) return; // only on the box, not CI
  await t.runAsync(() async {
    final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final img = await ro.toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await _loadRoboto();
  });
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('each new Quick Access tile opens its program page', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final obs = _Obs();
    const shotKey = Key('qa-shot');
    await t.pumpWidget(MaterialApp(
      navigatorObservers: [obs],
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const Scaffold(
        backgroundColor: Color(0xFF0B0B10),
        body: SingleChildScrollView(
          child: RepaintBoundary(key: shotKey, child: QuickAccessSection()),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    await _shot(t, shotKey, 'home-quick-access.png');
    for (final label in ['Rewards', 'NowssB Earn', 'Gifts', 'Coupons']) {
      final before = obs.pushed.length;
      await t.tap(find.text(label));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(obs.pushed.length, greaterThan(before), reason: '$label did not open a page');
      expect(obs.pushed[before], isA<MaterialPageRoute<void>>());
      t.takeException(); // the program pages need Firebase; we only check routing
      obs.navigator!.popUntil((r) => r.isFirst);
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      t.takeException();
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('Home TV shows the NowssB / RESONANCE header on the left', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const shotKey = Key('tv-shot');
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const Scaffold(
        backgroundColor: Color(0xFF0B0B10),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: RepaintBoundary(
              key: shotKey,
              child: TvFrame(
                asset: 'assets/video/tv-split.mp4',
                frame: DeviceFrame.tvLandscape,
                showPoster: true,
                overlay: TvSplitHeader(),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('NowssB'), findsOneWidget);
    expect(find.text('RESONANCE'), findsOneWidget);
    expect(find.text('FREQUENCIES'), findsOneWidget);
    final box = t.getRect(find.text('NowssB'));
    final tv = t.getRect(find.byType(TvSplitHeader));
    expect(box.right <= tv.center.dx + 1, isTrue, reason: 'header must stay on the left half');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    await _shot(t, shotKey, 'home-tv-split.png');
  });

  testWidgets('TV header appears instantly with reduce motion', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox(width: 360, height: 200, child: TvSplitHeader()),
      ),
    ));
    final o = t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(o.opacity, 1);
    expect(o.duration, Duration.zero);
  });

  testWidgets('HomeHeader.sub shows back + title and pops', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: HomeHeader.sub(title: 'Rewards')))),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('NowssB'), findsNothing);
    await t.tap(find.byKey(const Key('home-header-back')));
    await t.pumpAndSettle();
    expect(find.text('go'), findsOneWidget);
  });
}
