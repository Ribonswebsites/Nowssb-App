/// tm-build: hero carousel, per-user words, ref-style sections.
/// Run: flutter test test/tm_build_shots_test.dart --dart-define=RITUAL_OUT=/tmp/tm
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/today_ritual.dart';
import 'package:nowssb/screens/normal/calm_hero.dart';
import 'package:nowssb/widgets/concept/ref_sections.dart';

const _out = String.fromEnvironment('RITUAL_OUT', defaultValue: '/tmp/tm');

Word _w(String w) => Word.from({'word': w, 'phonetic': w.toLowerCase(), 'benefit': 'Calm and steady'})!;

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

  test('hero words: owned first, then saved, then routine; routine is the fallback', () {
    final lib = [_w('PITTA'), _w('SOMA'), _w('OJAS'), _w('PRANA')];
    final routine = [lib[0], lib[1]];
    expect(personalHeroWords(library: lib, routine: routine).map((w) => w.word), ['PITTA', 'SOMA']);
    expect(
        personalHeroWords(library: lib, routine: routine, ownedTitles: ['Ojas — word card'], saved: {'prana'}).map((w) => w.word),
        ['OJAS', 'PRANA', 'PITTA', 'SOMA']);
  });

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

  for (final (width, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('ref sections $width', (t) async {
      final key = GlobalKey();
      await pump(t, const RefHomeSections(), width, scale, key);
      expect(t.takeException(), isNull);
      await save(t, key, 'ref-sections-${width.toInt()}');
    });

    testWidgets('hero cards $width', (t) async {
      final key = GlobalKey();
      var begun = 0;
      final data = HeroData(
          title: 'Morning ritual', partLabel: 'Morning', words: [_w('PITTA'), _w('SOMA'), _w('OJAS')],
          done: 1, total: 3, streak: 3, sessions: 5, onBegin: () => begun++);
      await pump(t, SizedBox(height: 520, child: MixedHero(data: data)), width, scale, key);
      final pv = find.byType(PageView);
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 400));
        expect(t.takeException(), isNull, reason: 'card $i');
        await save(t, key, 'hero-${width.toInt()}-card$i');
        if (find.byKey(const ValueKey('hero-depth')).hitTestable().evaluate().isNotEmpty) {
          await t.timedDrag(find.byKey(const ValueKey('hero-depth')), const Offset(0, -120), const Duration(milliseconds: 600));
          await t.pump(const Duration(milliseconds: 400));
          await save(t, key, 'hero-${width.toInt()}-card$i-scrolled');
        }
        final c = t.widget<PageView>(pv).controller!;
        c.jumpToPage(c.initialPage + i + 1);
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(begun, 0);
    });
  }
}
