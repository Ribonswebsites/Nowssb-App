// Phone screenshots of the new Profile page with real fonts.
// Run: PROFILE_SHOTS=/workspace/screens flutter test test/profile_screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/profile/new_profile_page.dart';
import 'package:nowssb/pages/profile/profile_data.dart';

final _out = Platform.environment['PROFILE_SHOTS'];
// Stand-in for the app's original background video: its first frame,
// extracted with `ffmpeg -i assets/video/fashion-plus-bg-6.mp4 -frames:v 1`.
final _bgPath = Platform.environment['PROFILE_BG'] ?? '/tmp/profile_bg_frame.png';
ui.Image? _bgFrame;
Widget _bg() => _bgFrame != null ? RawImage(image: _bgFrame, fit: BoxFit.cover) : const ColoredBox(color: Colors.black);
Future<void> _decodeBg(WidgetTester t) async {
  if (_bgFrame != null || !File(_bgPath).existsSync()) return;
  await t.runAsync(() async {
    final codec = await ui.instantiateImageCodec(File(_bgPath).readAsBytesSync());
    _bgFrame = (await codec.getNextFrame()).image;
  });
}
const _fonts = '/workspace/flutter/bin/cache/artifacts/material_fonts';

class _Src implements ProfileSource {
  _Src(this.fn);
  final Future<ProfileData> Function() fn;
  @override
  Future<ProfileData> load() => fn();
}

const _full = ProfileData(name: 'Ribon Patil', signedIn: true, streak: 4, minutes: 72, sessions: 12, level: 3, week: [true, true, true, true, false, false, false]);

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File('$_fonts/$f').readAsBytesSync())));
  }
  await l.load();
}

Future<void> _shot(WidgetTester t, ProfileSource s, String file, {double scroll = 0}) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await _decodeBg(t);
  final key = GlobalKey();
  await t.pumpWidget(RepaintBoundary(
    key: key,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      home: NewProfilePage(source: s, animate: false, onNavigate: (_, __) {}, backdrop: _bg()),
    ),
  ));
    await t.pump();
  await t.pump();
  if (scroll > 0) {
    await t.drag(find.byType(ListView), Offset(0, -scroll));
    await t.pumpAndSettle();
  }
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$file').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (_out == null) return;
    await _font('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Light.ttf']);
    await _font('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });
  final skip = _out == null;
  testWidgets('ready', (t) => _shot(t, _Src(() async => _full), 'profile-1.png'), skip: skip);
  testWidgets('empty', (t) => _shot(t, _Src(() async => const ProfileData(name: 'New friend')), 'profile-2.png'), skip: skip);
  testWidgets('error', (t) => _shot(t, _Src(() async => throw Exception('x')), 'profile-3.png'), skip: skip);
  testWidgets('offline', (t) => _shot(t, _Src(() async => throw const ProfileOffline()), 'profile-4.png'), skip: skip);
  testWidgets('milestones', (t) => _shot(t, _Src(() async => _full), 'profile-5.png', scroll: 420), skip: skip);
}
