import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/partner/partner_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _summary = <String, dynamic>{
  'title': 'Bloom',
  'confirmed': 420,
  'pending': 60,
  'confirmDays': 30,
  'tracks': {'word': 300, 'plan': 120},
  'recent': [
    {'kind': 'word', 'points': 20, 'confirmed': true},
    {'kind': 'subscription', 'points': 60, 'confirmed': false},
  ],
  'levels': [
    {
      'level': 1,
      'title': 'Seed',
      'points': 100,
      'reached': true,
      'claimed': true,
      'coins': 50
    },
    {
      'level': 2,
      'title': 'Bloom',
      'points': 400,
      'reached': true,
      'claimed': false,
      'coins': 150,
      'giftbox': 'silver'
    },
    {
      'level': 3,
      'title': 'Radiant',
      'points': 1200,
      'reached': false,
      'earlyHours': 24,
      'pass': {'days': 7, 'tier': 'Plus'},
    },
  ],
  'config': {
    'reference': {
      'friendDiscount': {'wordPct': 10, 'wordFirstN': 3, 'subscriptionPct': 20},
    },
  },
};

final _board = <String, dynamic>{
  'period': 'October',
  'rows': [
    {'name': 'Asha', 'points': 2400},
    {'name': 'Lukas', 'points': 1800},
    {'name': 'You', 'points': 420, 'me': true},
  ],
};

int claims = 0;
String? shared;

void _fake({Object? error, bool empty = false}) {
  PartnerData.summary = () async {
    if (error != null) throw error;
    return empty ? <String, dynamic>{'levels': []} : _summary;
  };
  PartnerData.board = () async => _board;
  PartnerData.claim = (l) async {
    claims++;
    return {'ok': true};
  };
  PartnerData.link =
      (k, t) async => {'url': 'https://nowssb.com/r/ab12?k=$k', 'title': t};
  PartnerData.money = (c) => '€${(c / 100 * .92).toStringAsFixed(2)}';
  PartnerData.share = (t) async => shared = t;
}

const _fonts = '/workspace/flutter/bin/cache/artifacts/material_fonts';
bool _fontsLoaded = false;
Future<void> _loadFonts() async {
  if (_fontsLoaded || !Directory(_fonts).existsSync()) return;
  _fontsLoaded = true;
  final loader = FontLoader('Roboto');
  for (final f in Directory(_fonts).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') &&
        n.endsWith('.ttf') &&
        !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  await (FontLoader('MaterialIcons')
        ..addFont(File('$_fonts/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView)))
      .load();
}

const _shots = bool.fromEnvironment('PARTNER_SHOTS');

Widget _app({bool guide = false, String? tab}) => RepaintBoundary(
      key: const ValueKey('shot'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
        builder: (c, child) => Stack(
          children: [
            // Stand-in for the app's original background video (its poster frame).
            const Positioned.fill(
              child: Image(
                  image:
                      AssetImage('assets/video/fashion-plus-bg-6-poster.webp'),
                  fit: BoxFit.cover),
            ),
            child!,
          ],
        ),
        home: PartnerHome(showGuide: guide, initialTab: tab),
      ),
    );

Future<void> _shot(WidgetTester t, String name) async {
  if (!_shots) return;
  final ro =
      t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('/workspace/screens').createSync(recursive: true);
    File('/workspace/screens/$name.png')
        .writeAsBytesSync(b!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(w);
  if (_shots) {
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
  }
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (_shots) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({kGuideKey: true});
    claims = 0;
    shared = null;
    _fake();
  });

  testWidgets('hub shows points and cards', (t) async {
    await _pump(t, _app());
    expect(find.byKey(const Key('partner.points')), findsOneWidget);
    expect(find.text('420 points'), findsOneWidget);
    await _shot(t, 'partner-v4-1');
  });

  testWidgets('first-use guide shows once, steps through, then stays hidden',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(t, _app(guide: true));
    expect(find.byKey(const Key('partner.guide')), findsOneWidget);
    await _shot(t, 'partner-v4-2');
    await t.tap(find.byKey(const Key('partner.guide.next')));
    await t.pumpAndSettle();
    expect(find.text('They save, you grow'), findsOneWidget);
    await t.tap(find.byKey(const Key('partner.guide.next')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.guide.next')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.guide')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(kGuideKey), isTrue);
    await t.pumpWidget(const SizedBox());
    await _pump(t, _app(guide: true));
    expect(find.byKey(const Key('partner.guide')), findsNothing);
  });

  testWidgets('help button replays the guide; skip closes it', (t) async {
    await _pump(t, _app());
    await t.tap(find.byKey(const Key('partner.help')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.guide')), findsOneWidget);
    await t.tap(find.byKey(const Key('partner.guide.skip')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.guide')), findsNothing);
  });

  testWidgets('targets tab and level sub-page', (t) async {
    await _pump(t, _app());
    await t.ensureVisible(find.byKey(const Key('partner.tab.targets')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.tab.targets')));
    await t.pumpAndSettle();
    await _shot(t, 'partner-v4-3');
    await t.tap(find.byKey(const Key('partner.level.3')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.level')), findsOneWidget);
    expect(find.text('420 / 1200 points'), findsOneWidget);
    await _shot(t, 'partner-v4-4');
  });

  testWidgets('perks: claim asks to confirm, then claims', (t) async {
    await _pump(t, _app());
    await t.ensureVisible(find.byKey(const Key('partner.tab.perks')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.tab.perks')));
    await t.pumpAndSettle();
    await _shot(t, 'partner-v4-11');
    await t.ensureVisible(find.byKey(const Key('partner.claim.2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.claim.2')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.confirm')), findsOneWidget);
    await _shot(t, 'partner-v4-5');
    await t.tap(find.text('Claim').last);
    await t.pumpAndSettle();
    expect(claims, 1);
  });

  testWidgets('refer tab: link tools make a link and open share sheet',
      (t) async {
    await _pump(t, _app());
    await t.ensureVisible(find.byKey(const Key('partner.tab.refer')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.tab.refer')));
    await t.pumpAndSettle();
    await _shot(t, 'partner-v4-6');
    await t.scrollUntilVisible(find.byKey(const Key('partner.r.tools')), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('partner.list')),
                matching: find.byType(Scrollable))
            .first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.r.tools')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.links')), findsOneWidget);
    await t.tap(find.byKey(const Key('partner.kind.word')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('partner.linkField')), 'Serenity');
    await t.tap(find.byKey(const Key('partner.make')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.share')), findsOneWidget);
    await _shot(t, 'partner-v4-7');
    await t.tap(find.byKey(const Key('partner.shareNow')));
    await t.pumpAndSettle();
    expect(shared, contains('https://nowssb.com/r/ab12?k=word'));
  });

  testWidgets('buyer discount sub-page shows local currency', (t) async {
    await _pump(t, _app(tab: 'discount'));
    await t.scrollUntilVisible(find.byKey(const Key('partner.r.discount')), 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('partner.list')),
                matching: find.byType(Scrollable))
            .first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.r.discount')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.discount')), findsOneWidget);
    expect(find.textContaining('€'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
    await _shot(t, 'partner-v4-8');
  });

  testWidgets('activity and rules sub-pages, leaderboard tab', (t) async {
    await _pump(t, _app());
    await t.tap(find.byKey(const Key('partner.q.activity')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.activity')), findsOneWidget);
    await t.tap(find.byKey(const Key('home-header-back')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.rulesBtn')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.rules')), findsOneWidget);
    await t.tap(find.byKey(const Key('home-header-back')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('partner.tab.board')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('partner.tab.board')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.tab.board')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.board')), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    await _shot(t, 'partner-v4-9');
  });

  testWidgets(
      'Luxe layout: perks rail, spotlight cards open sub-pages and tabs',
      (t) async {
    await _pump(t, _app());
    expect(find.text('SPOTLIGHT PICKS'), findsOneWidget);
    await t.tap(find.byKey(const Key('partner.rail.1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.spot.perk')), findsOneWidget);
    await t.tap(find.byKey(const Key('partner.perkRail.0')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.level')), findsOneWidget);
    await t.tap(find.byKey(const Key('home-header-back')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.spot.perk')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.confirm')), findsOneWidget);
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('partner.tab.refer')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.tab.refer')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.spot.links')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.links')), findsOneWidget);
    await t.tap(find.byKey(const Key('home-header-back')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('partner.spot.discount')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner.page.discount')), findsOneWidget);
  });

  testWidgets('loading, empty, error and offline states', (t) async {
    PartnerData.summary =
        () => Future.delayed(const Duration(seconds: 1), () => _summary);
    await t.pumpWidget(_app());
    await t.pump();
    expect(find.byKey(const Key('partner.loading')), findsOneWidget);
    await t.pumpAndSettle();

    _fake(empty: true);
    await t.pumpWidget(const SizedBox());
    await _pump(t, _app());
    expect(find.byKey(const Key('partner.empty')), findsOneWidget);

    _fake(error: Exception('boom'));
    await t.pumpWidget(const SizedBox());
    await _pump(t, _app());
    expect(find.byKey(const Key('partner.error')), findsOneWidget);

    _fake(error: const SocketException('no route'));
    await t.pumpWidget(const SizedBox());
    await _pump(t, _app());
    expect(find.byKey(const Key('partner.offline')), findsOneWidget);
    await _shot(t, 'partner-v4-10');
  });
}
