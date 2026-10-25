// Normal home, essentials → footer (calm kit): every main tap reports the
// right action, nothing overflows at 320 wide × 1.3 text, and (with
// HOME_NORMAL_SHOTS=<dir>) a full-length 390-wide render is written.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/normal/calm/calm_sections.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:nowssb/widgets/home_banner_slot.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await l.load();
}

const _g = '/usr/share/fonts/truetype/sand-box/google';
final _now = DateTime(2026, 10, 25, 8, 30);

List<Widget> _sections(void Function(String) act) => [
      const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 4), child: NormalHomeBannerSlot()),
      CalmEssentials(onAct: act),
      CalmRoutines(onAct: act, now: _now),
      CalmToday(onAct: act),
      CalmPractice(onAct: act),
      CalmWhereToBegin(onAct: act),
      CalmHelp(onAct: act),
      CalmCategories(onAct: act),
      CalmSpotlight(onAct: act),
      CalmEnter(onAct: act),
      CalmStories(onAct: act),
      CalmQuote(onAct: act, now: _now),
      CalmEarn(onAct: act),
      CalmReader(onAct: act),
      CalmTrending(onAct: act),
      CalmMyRoutines(onAct: act),
      CalmConnectNotes(onAct: act),
      CalmFeed(onAct: act),
      CalmQuick(onAct: act),
      CalmTrendShop(onAct: act),
      CalmEdition(onAct: act),
      CalmEbooks(onAct: act),
      CalmConnectChips(onAct: act),
      CalmHealing(onAct: act),
      CalmFashionSwitch(onAct: act),
      CalmFooter(onAct: act),
    ];

Widget _app(Widget body, {double scale = 1, double width = 390, double height = 800}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale), size: Size(width, height)),
        child: Scaffold(backgroundColor: NwsbColors.surface, body: body),
      ),
    );

/// (finder key, expected action) — one per section's main taps.
const _taps = <(String, String)>[
  ('calm:tasks', 'tasks'),
  ('calm:library-today', 'library-today'),
  ('calm:routine', 'routine'),
  ('calm:daypart', 'daypart'),
  ('calm:grid:practice', 'grid:practice'),
  ('calm:grid:subscription', 'grid:subscription'),
  ('calm:grid:quotes', 'grid:quotes'),
  ('calm:today', 'today'),
  ('calm:streak', 'streak'),
  ('calm:streak-store', 'streak-store'),
  ('calm:practice', 'practice'),
  ('calm:flip:MEDITATION', 'flip'),
  ('calm:main:Sound Library:2', 'main:Sound Library:2'),
  ('calm:main:My Progress:4', 'main:My Progress:4'),
  ('calm:wayaround', 'wayaround'),
  ('calm:support', 'support'),
  ('calm:coach', 'coach'),
  ('calm:cta:coupons', 'cta:coupons'),
  ('calm:cta:store', 'cta:store'),
  ('calm:hype:coupons', 'hype:coupons'),
  ('calm:enter:player', 'enter:player'),
  ('calm:enter:reader', 'enter:reader'),
  ('calm:stories:PRANA', 'stories'),
  ('calm:quotes', 'quotes'),
  ('calm:raredrop', 'raredrop'),
  ('calm:tier:0', 'earn'),
  ('calm:earn-join', 'earn'),
  ('calm:reader', 'reader'),
  ('calm:rewards', 'rewards'),
  ('calm:gift-send', 'gift-send'),
  ('calm:trending', 'trending'),
  ('calm:routines:Morning', 'routines'),
  ('calm:connect', 'connect'),
  ('calm:feed:reels', 'connect'),
  ('calm:reference', 'reference'),
  ('calm:cart', 'cart'),
  ('calm:wishlist', 'wishlist'),
  ('calm:orders', 'orders'),
  ('calm:trendshop', 'trendshop'),
  ('calm:subscribe', 'subscribe'),
  ('calm:partner', 'partner'),
  ('calm:ebooks', 'ebooks'),
  ('calm:connectban:Reels', 'connect'),
  ('calm:healing', 'healing'),
  ('calm:healing-f', 'healing-f'),
  ('calm:healing-m', 'healing-m'),
  ('calm:fashion', 'fashion'),
  ('calm:footer:about', 'footer:about'),
  ('calm:footer:profile', 'footer:profile'),
];

void main() {
  setUpAll(() async {
    await _font('DM Sans', '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf');
    await _font('MaterialIcons', '/home/box/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf');
    await _font('CormorantGaramond', 'assets/fonts/CormorantGaramond-Variable.ttf');
  });

  testWidgets('calm normal home: every main tap reports its action', (t) async {
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final got = <String>[];
    await t.pumpWidget(_app(ListView(children: _sections(got.add))));
    await t.pump();
    for (final (key, want) in _taps) {
      final f = find.byKey(ValueKey(key), skipOffstage: false).first;
      await t.ensureVisible(f);
      await t.pump();
      got.clear();
      await t.tap(f, warnIfMissed: false);
      await t.pump();
      expect(got, [want], reason: key);
    }
  });

  testWidgets('calm normal home: no overflow at 320 wide × 1.3', (t) async {
    t.view.physicalSize = const Size(320, 9000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _sections((_) {}))),
        scale: 1.3, width: 320, height: 9000));
    await t.pump();
    expect(t.takeException(), isNull);
    // No label may be cut short with an ellipsis at this size.
    final cut = <String>[];
    for (final e in find.byType(RichText, skipOffstage: false).evaluate()) {
      final r = e.renderObject! as RenderParagraph;
      if (r.overflow == TextOverflow.ellipsis && r.didExceedMaxLines) cut.add(r.text.toPlainText());
    }
    expect(cut, isEmpty, reason: 'ellipsised at 320 × 1.3: $cut');
  });

  final dir = Platform.environment['HOME_NORMAL_SHOTS'];
  for (final (w, s, name) in [(390.0, 1.0, 'home-normal-full'), (320.0, 1.3, 'home-normal-320x1.3')]) {
    testWidgets('render $name', (t) async {
      final key = GlobalKey();
      t.view.physicalSize = Size(w, 12000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(
        SingleChildScrollView(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: NwsbColors.surface,
              padding: const EdgeInsets.only(top: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _sections((_) {})),
            ),
          ),
        ),
        scale: s,
        width: w,
        height: 12000,
      ));
      await t.runAsync(() async {
        final ctx = t.element(find.byType(Scaffold));
        for (final d in homeDoors.map((d) => d.image)) {
          await precacheImage(AssetImage(d), ctx);
        }
      });
      await t.pump();
      expect(t.takeException(), isNull);
      if (dir == null) return;
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }, skip: dir == null && name.contains('320'));
  }
}
