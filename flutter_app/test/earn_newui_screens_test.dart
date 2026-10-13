// Renders phone-size PNGs of the new Earn page (flag on) with real Roboto +
// Material Icons. Skipped unless EARN_SCREENS_DIR is set, so CI stays fast.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/earn/newui/earn_downline_page.dart';
import 'package:nowssb/features/earn/newui/earn_newui_page.dart';
import 'package:nowssb/features/earn/newui/earn_view_data.dart';

final _out = Platform.environment['EARN_SCREENS_DIR'];
const _fonts = '/workspace/flutter/bin/cache/artifacts/material_fonts';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File('$_fonts/$f').readAsBytesSync())));
  }
  await l.load();
}

const _team = [
  EarnTeamMember(id: 'a', name: 'Asha', rank: 'Officer', words: 112),
  EarnTeamMember(id: 'b', name: 'Ben', rank: 'Assistant Officer', words: 40),
  EarnTeamMember(id: 'c', name: 'Chen', rank: 'Assistant Officer', words: 18),
  EarnTeamMember(id: 'd', name: 'Dana', level: 2, words: 6),
  EarnTeamMember(id: 'e', name: 'Eli', level: 2, words: 2),
];
const _ready = EarnViewData(
    load: EarnLoad.ready, signedIn: true, rank: 'Officer', metal: 'Silver', ratePct: 22, wordsSold: 240, team: _team, code: 'ASHA22');

void main() {
  final key = GlobalKey();

  Future<void> shot(WidgetTester t, String name, Widget page, {Future<void> Function()? then}) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        key: ValueKey(name),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
        builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: child!),
        home: page,
      ),
    ));
    await t.pump(const Duration(milliseconds: 50));
    if (then != null) await then();
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  setUpAll(() async {
    if (_out == null) return;
    await _font('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
    await _font('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  testWidgets('earn screens', (t) async {
    await shot(t, 'earn-1', const EarnNewUiPage(data: _ready));
    await shot(t, 'earn-2', const EarnNewUiPage(data: EarnViewData()));
    await shot(t, 'earn-3', const EarnNewUiPage(data: EarnViewData(load: EarnLoad.empty, signedIn: true)));
    await shot(t, 'earn-4', const EarnNewUiPage(data: EarnViewData(load: EarnLoad.error, signedIn: true)));
    await shot(t, 'earn-5', const EarnNewUiPage(data: EarnViewData(load: EarnLoad.offline, signedIn: true)));
    await shot(t, 'earn-6', Builder(builder: (c) => EarnNewUiPage(data: _ready, actions: EarnActions(onHelp: () => showEarnHowItWorks(c)))),
        then: () async {
      await t.tap(find.byKey(const Key('earn-help')));
      await t.pumpAndSettle();
    });
    await shot(t, 'earn-7', const EarnDownlinePage(data: _ready));
    await shot(t, 'earn-8', const EarnDownlinePage(data: _ready), then: () async {
      await t.tap(find.byKey(const Key('earn-node-a')));
      await t.pumpAndSettle();
    });
    addTearDown(t.view.reset);
  }, skip: _out == null);
}
