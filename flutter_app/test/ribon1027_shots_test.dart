// Ribon Oct 27 checks: each changed surface renders with the real fonts at
// 320/360/390/412 and 320@1.3 with no overflow, ellipsis or mid-word break.
// Set RIBON_SHOTS=<dir> to also write <name>-{390,320-1.3x}.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/concept/ritual_card.dart';
import 'package:nowssb/widgets/concept/stillwater.dart';
import 'package:nowssb/widgets/enter_curve_stage.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = String.fromEnvironment('RIBON_SHOTS');

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

/// No overflow (exceptions), no ellipsis, no single word wrapped mid-word.
void expectCleanText(WidgetTester t, String label) {
  expect(t.takeException(), isNull, reason: 'exception/overflow: $label');
  for (final e in find.byType(RichText).evaluate()) {
    final rp = e.renderObject as RenderParagraph?;
    if (rp == null || !rp.attached || !rp.hasSize) continue;
    final s = rp.text.toPlainText().trim();
    if (s.isEmpty) continue;
    expect(rp.didExceedMaxLines, isFalse, reason: 'ellipsis/clip "$s" at $label');
    expect(s.contains('…') || s.contains('...'), isFalse, reason: 'ellipsis text "$s" at $label');
    final full = rp.text.toPlainText();
    for (final m in RegExp(r'[^\s\u00B7·—-]{2,}').allMatches(full)) {
      final tops = rp
          .getBoxesForSelection(TextSelection(baseOffset: m.start, extentOffset: m.end), boxHeightStyle: ui.BoxHeightStyle.max)
          .map((b) => b.top.round())
          .toSet();
      expect(tops.length, 1, reason: 'mid-word break "${m[0]}" in "$s" at $label');
    }
  }
}

class ShotSpec {
  const ShotSpec(this.name, this.build, {this.scrollShots = 0, this.scrollTo});
  final String name;
  final Widget Function() build;
  /// Extra shots further down the page (600 logical px apart).
  final int scrollShots;
  /// Scroll until this is on screen before the first shot.
  final Finder Function()? scrollTo;
}

Widget _light(Widget child) => Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      body: ListView(padding: const EdgeInsets.only(top: 18), children: [child]),
    );

Widget _ritual(RitualTime t) => _light(RitualCard(
    time: t, debugPhase: .5, completed: 0, total: 8, sessionCount: 9, streak: 0,
    onBegin: () {}, onSeeProgress: () {}));

final specs = <ShotSpec>[
  ShotSpec('item4-ritual-morning-meditation', () => _ritual(RitualTime.morning)),
  ShotSpec('item6-ritual-evening-meditation', () => _ritual(RitualTime.evening)),
  ShotSpec('item6-enter-curve-candle', () => _light(const AspectRatio(aspectRatio: 16 / 10, child: EnterCurveStage(embedded: true)))),
  ShotSpec('item6-drop-studio-meditation', () => const DropStudioScreen(), scrollShots: 1),
];

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await _font('Anton', 'assets/fonts/Anton-Regular.ttf');
    await _font('NotoSansPIE', 'assets/fonts/NotoSans-PIE.ttf');
    if (_shots.isNotEmpty) Directory(_shots).createSync(recursive: true);
  });
  setUp(() => Stillwater.debugPhase = .42);
  tearDown(() => Stillwater.debugPhase = null);

  for (final spec in specs) {
    for (final (w, s) in [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
      testWidgets('${spec.name} clean at ${w.round()}@$s', (t) async {
        t.view.physicalSize = Size(w * 2, 844 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await t.runAsync(() async {
          await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
          await Settings.instance.load();
          await CartBag.instance.load();
        });
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('en', 'IN'),
            theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s), disableAnimations: true), child: child!),
            home: NavScope(go: (_) {}, child: spec.build()),
          ),
        ));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        if (spec.scrollTo != null) {
          final f = spec.scrollTo!();
          for (var i = 0; i < 60 && f.hitTestable().evaluate().isEmpty; i++) {
            await t.drag(find.byType(Scrollable).first, const Offset(0, -200), warnIfMissed: false);
            await t.pump(const Duration(milliseconds: 120));
          }
          if (f.evaluate().isNotEmpty) {
            await t.ensureVisible(f.first);
            await t.pump(const Duration(milliseconds: 300));
          }
        }
        expectCleanText(t, '${spec.name} ${w.round()}@$s');
        final tag = s == 1 ? '${w.round()}' : '${w.round()}-${s}x';
        Future<void> shot(String suffix) async {
          if (_shots.isEmpty || !(w == 390 && s == 1 || w == 320 && s == 1.3)) return;
          final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await t.runAsync(() => ro.toImage(pixelRatio: 2));
          final data = await t.runAsync(() async => img!.toByteData(format: ui.ImageByteFormat.png));
          File('$_shots/${spec.name}-$tag$suffix-1027.png').writeAsBytesSync(data!.buffer.asUint8List());
        }

        await shot('');
        for (var k = 1; k <= spec.scrollShots; k++) {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -600), warnIfMissed: false);
          for (var i = 0; i < 4; i++) {
            await t.pump(const Duration(milliseconds: 150));
          }
          expectCleanText(t, '${spec.name} ${w.round()}@$s scroll $k');
          await shot('-down$k');
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 5));
      });
    }
  }
}
