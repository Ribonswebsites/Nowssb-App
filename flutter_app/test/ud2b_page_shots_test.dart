/// UD-2 screenshots of both homes at 390x844 with DM Sans loaded.
/// Needs DMSans-*.ttf / Anton-Regular.ttf copied into an asset folder so
/// google_fonts resolves them offline (not committed).
/// Run: flutter test test/ud2_home_shots_test.dart --dart-define=UD2_TAG=after
@Tags(['shots'])
@Skip('manual: needs DM Sans copied into assets/icons')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/features_page.dart';
import 'package:nowssb/screens/personal_coach.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';

import 'fake_video_platform.dart';

const _font = '/usr/share/fonts/truetype/sand-box/google/DM Sans/DMSans-VariableFont_opsz,wght.ttf';
const _tag = String.fromEnvironment('UD2_TAG', defaultValue: 'after');
const _out = String.fromEnvironment('UD2_OUT', defaultValue: '/workspace/team-plan/shots');
final _w = double.parse(const String.fromEnvironment('UD2_W', defaultValue: '390'));
final _scale = double.parse(const String.fromEnvironment('UD2_TS', defaultValue: '1.0'));

Future<void> _loadFonts() async {
  final bytes = File(_font).readAsBytesSync();
  final families = <String>{'DM Sans', 'Roboto', 'Outfit'};
  for (final f in ['DMSans', 'Outfit', 'Inter', 'Poppins', 'CormorantGaramond', 'PlayfairDisplay']) {
    for (final w in ['regular', 'italic', '100', '200', '300', '500', '600', '700', '800', '900']) {
      families.add('${f}_$w');
    }
  }
  final mi = File('/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync();
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(mi)))).load();
  for (final fam in families) {
    final l = FontLoader(fam)..addFont(Future.value(ByteData.sublistView(bytes)));
    await l.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await _loadFonts();
  });

  Future<void> shot(WidgetTester tester, Widget home, String name) async {
    final h = _w == 390 ? 844.0 : 640.0;
    tester.view.physicalSize = Size(_w * 2, h * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.library == 'image resource service') return; // missing art
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    final key = GlobalKey();
    final theme = NwsbTheme.dark;
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(_scale)),
          child: child!,
        ),
        home: NavScope(go: (_) {}, child: home),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.runAsync(() async {
      final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await ro.toImage(pixelRatio: 2.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  testWidgets('features', (t) async {
    await shot(t, const FeaturesPage(), 'ud2b-features-$_tag');
  });
  testWidgets('coach', (t) async {
    await shot(t, const PersonalCoachScreen(), 'ud2b-coach-$_tag');
  });
}
