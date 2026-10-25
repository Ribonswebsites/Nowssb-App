// Fashion home banner slot: every door opens its programme. (The Normal
// home keeps the original TrioRail; see home_normal_test.dart.)
// Set HOME_BANNER_SHOTS=<dir> to also write the two phone-size renders.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/programs/program_router.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/home_banner_slot.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await l.load();
}

const _g = '/usr/share/fonts/truetype/sand-box/google';

Widget _frame({required bool fashion, required Widget slot, double scale = 1, double width = 390}) {
  final bg = fashion ? NwsbColors.deep : NwsbColors.surface;
  final ink = fashion ? Colors.white : const Color(0xFF2A2D3A);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale), size: Size(width, 760)),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(fashion ? 16 : 20, 20, fashion ? 16 : 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                slot,
                const SizedBox(height: 22),
                Text('Your essentials',
                    style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _precache(WidgetTester t) async {
  await t.runAsync(() async {
    final ctx = t.element(find.byType(Scaffold));
    for (final d in [...homeDoors.map((d) => d.image), 'assets/banners/earn/hands-raise.png']) {
      await precacheImage(AssetImage(d), ctx);
    }
  });
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await _font('DM Sans', '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf');
    await _font('MaterialIcons', '/home/box/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf');
    await _font('CormorantGaramond', 'assets/fonts/CormorantGaramond-Variable.ttf');
  });

  for (final fashion in [true]) {
    final name = fashion ? 'fashion' : 'normal';
    testWidgets('$name slot: every door opens its programme', (t) async {
      t.view.physicalSize = const Size(390, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final opened = <(Programme, String?)>[];
      void rec(BuildContext _, Programme p, String? tab) => opened.add((p, tab));
      await t.pumpWidget(_frame(
        fashion: fashion,
        slot: FashionHomeBannerSlot(onOpen: rec),
      ));
      for (final d in homeDoors) {
        final f = find.byKey(ValueKey('$name-door-${d.label}'));
        await t.scrollUntilVisible(f, 80,
            scrollable: fashion
                ? find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first
                : find.byType(Scrollable).first);
        await t.tap(f);
        await t.pump();
      }
      expect(opened, [for (final d in homeDoors) (d.programme, d.tab)]);
      expect(t.takeException(), isNull);
    });

    testWidgets('$name slot: no overflow at 320 wide, text x1.3', (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_frame(
        fashion: fashion,
        scale: 1.3,
        width: 320,
        slot: const FashionHomeBannerSlot(),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('$name slot: phone render', (t) async {
      final dir = Platform.environment['HOME_BANNER_SHOTS'];
      for (final (w, scale, suffix) in [(390.0, 1.0, ''), (320.0, 1.3, '-320x1.3')]) {
        t.view.physicalSize = Size(w * 3, 560 * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
          key: key,
          child: _frame(
            fashion: fashion,
            scale: scale,
            width: w,
            slot: const FashionHomeBannerSlot(),
          ),
        ));
        await _precache(t);
        expect(t.takeException(), isNull);
        if (dir == null) continue;
        await t.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 3);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/home-banner-$name$suffix.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    });
  }
}
