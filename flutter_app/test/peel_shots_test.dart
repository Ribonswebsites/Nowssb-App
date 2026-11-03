/// Corner peel (the Drop Studio entry's corner peel).
/// Run: flutter test test/peel_shots_test.dart --dart-define=RITUAL_OUT=/workspace/team-plan/shots/tm-build
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/concept/drop_v5.dart';

const _out = String.fromEnvironment('RITUAL_OUT', defaultValue: '/tmp/tm');

Future<void> _fonts() async {
  final dm = FontLoader('DM Sans');
  for (final f in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
    final file = File('assets/icons/DMSans-$f.ttf');
    if (file.existsSync()) dm.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await dm.load();
  ByteData f(String p) => ByteData.sublistView(File(p).readAsBytesSync());
  for (final fam in ['DM Sans', 'monospace']) {
    await (FontLoader(fam)..addFont(Future.value(f('assets/fonts/NotoSans-PIE.ttf')))).load();
  }
  await (FontLoader('CormorantGaramond')..addFont(Future.value(f('assets/fonts/CormorantGaramond-Variable.ttf')))).load();
  await (FontLoader('Anton')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Anton-Regular.ttf').readAsBytesSync())))).load();
  const mi = '/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(mi).existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File(mi).readAsBytesSync())))).load();
  }
}

void main() {
  setUpAll(_fonts);

  Future<void> pump(WidgetTester t, Widget w, double width, double scale, GlobalKey key) async {
    t.view.physicalSize = Size(width * 2, 3200 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(builder: (ctx) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: RepaintBoundary(key: key, child: ColoredBox(color: Colors.black, child: w)))),
          )),
    ));
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate().toList()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pump(const Duration(milliseconds: 200));
  }

  Future<void> save(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(_out).createSync(recursive: true);
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('corner peel loops on its own; a tap peels fully, then opens', (t) async {
    CornerPeel.debugLoopInTests = true;
    addTearDown(() => CornerPeel.debugLoopInTests = false);
    var opened = 0;
    await t.pumpWidget(MaterialApp(home: Center(child: SizedBox(width: 200, height: 260,
        child: CornerPeel(loop: const Duration(seconds: 2), onOpen: () => opened++, child: const ColoredBox(color: Colors.red))))));
    final st = t.state<CornerPeelState>(find.byType(CornerPeel));
    expect(st.peel, 0);
    await t.pump(const Duration(milliseconds: 500));
    expect(st.peel, greaterThan(.3), reason: 'auto peel lifts the corner');
    await t.pump(const Duration(milliseconds: 1000));
    expect(st.peel, lessThan(.05), reason: 'and settles back');
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(st.peel, greaterThan(.3), reason: 'it loops');
    await t.tap(find.byType(CornerPeel));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(st.peel, greaterThan(.6), reason: 'peeling past the loop');
    expect(opened, 0, reason: 'opens only after the full peel');
    await t.pump(const Duration(milliseconds: 260));
    await t.pump();
    expect(opened, 1);
    await t.pumpWidget(const SizedBox());
  });
}
