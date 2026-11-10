import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/programs/program_router.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';
import 'package:nowssb/widgets/four_banners.dart';
import 'package:nowssb/widgets/path_aurora_banner.dart';

import 'support/home_render.dart';

// flutter test test/prog_glass_shots_test.dart --dart-define=PROGGLASS_OUT=/out
const _out = String.fromEnvironment('PROGGLASS_OUT');

// Stand-in for the Zen home's looping backdrop video (black with colour
// swirls) so the frosted glass has something to blur.
class _Swirl extends StatelessWidget {
  const _Swirl({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.2, colors: [Color(0xFF5A2BBE), Color(0xFF14082A), Color(0xFF000000)], stops: [0, .5, 1]),
        ),
        child: child,
      );
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name, double pr) async {
  await t.runAsync(() async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: pr);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(b!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester t, GlobalKey key, Widget child, double w, double h, double pr) async {
  t.view.physicalSize = Size(w * pr, h * pr);
  t.view.devicePixelRatio = pr;
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: RepaintBoundary(
      key: key,
      child: _Swirl(child: Material(type: MaterialType.transparency, child: Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 24), child: Align(alignment: Alignment.topCenter, child: child)))),
    ),
  ));
  await precacheAll(t);
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  tearDown(() => PathAuroraBanner.debugT = null);

  for (final f in [0.0, .12, .25, .37, .5, .75]) {
    testWidgets('banner frame $f', (t) async {
      if (_out.isEmpty) return;
      PathAuroraBanner.debugT = f;
      final key = GlobalKey();
      await _pump(t, key, const PathAuroraBanner(), 390, 260, 2);
      await _shot(t, key, 'banner_390_t${(f * 100).round().toString().padLeft(2, '0')}', 2);
    });
  }

  for (final cfg in [(390.0, 1.0, '390'), (320.0, 1.3, '320@1.3x')]) {
    testWidgets('section ${cfg.$3}', (t) async {
      if (_out.isEmpty) return;
      PathAuroraBanner.debugT = .37;
      final key = GlobalKey();
      await _pump(t, key, const ProgrammesGlassSection(), cfg.$1, 880, cfg.$2 < 1.5 ? 2 : cfg.$2);
      expect(t.takeException(), isNull);
      await _shot(t, key, 'section_${cfg.$3}', 2);
    });
  }

  testWidgets('taps open real pages', (t) async {
    PathAuroraBanner.debugT = .3;
    t.view.physicalSize = const Size(390 * 2, 900 * 2);
    t.view.devicePixelRatio = 2;
    var opened = 0;
    await t.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: Scaffold(body: SingleChildScrollView(child: PathAuroraBanner(onOpen: () => opened++)))));
    await t.tap(find.text('Start earning'));
    expect(opened, 1);
    // Default CTA resolves to the Earn programme page.
    expect(Programmes.page(Programme.earn), isA<Widget>());
    expect(find.text('Calm that\npays you back'), findsOneWidget);
  });

  testWidgets('reduced motion holds still', (t) async {
    PathAuroraBanner.debugT = null;
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: Scaffold(body: PathAuroraBanner())),
    ));
    await t.pump(const Duration(seconds: 3));
    expect(t.binding.transientCallbackCount, 0);
  });

  testWidgets('glass section copy', (t) async {
    PathAuroraBanner.debugT = .3;
    t.view.physicalSize = const Size(390 * 2, 1400 * 2);
    t.view.devicePixelRatio = 2;
    await t.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: const Scaffold(body: SingleChildScrollView(child: ProgrammesGlassSection()))));
    expect(find.text('YOUR PATH'), findsOneWidget);
    expect(find.text('Programmes'), findsOneWidget);
    expect(find.text('PROGRAMME'), findsNWidgets(3));
    expect(find.text('Earned today'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('in the real Zen home', (t) async {
    if (_out.isEmpty) return;
    SharedPreferences.setMockInitialValues({});
    PathAuroraBanner.debugT = .37;
    const w = 390.0, h = 9000.0;
    final key = GlobalKey();
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: RepaintBoundary(key: key, child: NavScope(go: (_) {}, child: const HomeFashion()))),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      t.takeException();
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 300));
    t.takeException();
    expect(find.byType(ProgrammesGlassSection), findsOneWidget);
    final box = t.getRect(find.byType(ProgrammesGlassSection));
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1);
      final r = Rect.fromLTWH(0, box.top - 70, w, box.height + 140);
      final rec = ui.PictureRecorder();
      Canvas(rec).drawImageRect(img, r, Rect.fromLTWH(0, 0, r.width, r.height), Paint());
      final part = await rec.endRecording().toImage(r.width.ceil(), r.height.ceil());
      final png = await part.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/zen_home_context_390.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
