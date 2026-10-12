import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/home_menu_drawer.dart';

void main() {
  testWidgets('home menu drawer renders calm layout', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final out = Platform.environment['DRAWER_SHOT'];
    final fonts = Platform.environment['FLUTTER_ROOT_FONTS'];
    if (out != null && fonts != null) {
      await tester.runAsync(() async {
        Future<ByteData> f(String n) async =>
            ByteData.sublistView(File('$fonts/$n').readAsBytesSync());
        final r = FontLoader('Roboto')
          ..addFont(f('Roboto-Regular.ttf'))
          ..addFont(f('Roboto-Medium.ttf'))
          ..addFont(f('Roboto-Bold.ttf'));
        await r.load();
        await (FontLoader('MaterialIcons')
              ..addFont(f('MaterialIcons-Regular.otf')))
            .load();
      });
    }
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: key,
        child: HomeMenuDrawer(light: false, goTab: (_) {}),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    if (out != null) {
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  });
}
