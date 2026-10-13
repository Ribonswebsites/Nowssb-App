// Renders phone-size PNGs of the newui_partner page to /workspace/screens
// when PARTNER_SHOTS=1. Skipped in CI.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/partner/partner_home_page.dart';
import 'package:nowssb/pages/partner/partner_models.dart';

class _Repo implements PartnerRepository {
  _Repo(this.run);
  final Future<PartnerData> Function() run;
  @override
  Future<PartnerData> load() => run();
}

const _full = PartnerData(
  points: 1240,
  perk: 'Silver',
  tier: 'Silver partner',
  toNextTier: 6,
  targets: [
    PartnerTarget(label: 'Basic subscriptions', goal: 50, done: 32, reward: 'Coins + coupon pack'),
    PartnerTarget(label: 'Higher subscriptions', goal: 30, done: 11, reward: 'Gift + early access'),
    PartnerTarget(label: 'Top subscriptions', goal: 15, done: 3, reward: 'Partner mark'),
  ],
  leaders: [PartnerLeader('Ava', 4200), PartnerLeader('Kenji', 3810), PartnerLeader('Lucía', 2990)],
  referralLink: 'https://nowssb.app/r/ribon',
  buyerDiscountUsdCents: 500,
);

const _empty = PartnerData(
  points: 0,
  perk: '',
  tier: 'Starter',
  toNextTier: 0,
  targets: [
    PartnerTarget(label: 'Basic subscriptions', goal: 50, done: 0, reward: 'Coins + coupon pack'),
    PartnerTarget(label: 'Higher subscriptions', goal: 30, done: 0, reward: 'Gift + early access'),
    PartnerTarget(label: 'Top subscriptions', goal: 15, done: 0, reward: 'Partner mark'),
  ],
  leaders: [],
  referralLink: '',
  buyerDiscountUsdCents: 0,
);

/// Poster frame of the app's default background video (Settings index 1).
const _poster = AssetImage('assets/video/fashion-plus-bg-6-poster.webp');

const _fonts = '/workspace/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  final loader = FontLoader('Roboto');
  for (final f in Directory(_fonts).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  await (FontLoader('MaterialIcons')
        ..addFont(File('$_fonts/MaterialIcons-Regular.otf').readAsBytes().then(ByteData.sublistView)))
      .load();
}

Future<void> _shot(WidgetTester t, String name) async {
  final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 3);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('/workspace/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _app(PartnerRepository r) => RepaintBoundary(
      key: const ValueKey('shot'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
        home: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: MediaQuery(
            data:
                const MediaQueryData(size: Size(390, 844), disableAnimations: true, padding: EdgeInsets.only(top: 47)),
            child: PartnerHomePage(
              repository: r,
              countryCode: 'DE',
              onOpenEarnings: () {},
              background: const Image(image: _poster, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );

void main() {
  final on = Platform.environment['PARTNER_SHOTS'] == '1';

  Future<void> render(WidgetTester t, PartnerRepository r, String name, {double scrollTo = 0, int swipe = 0}) async {
    await t.runAsync(_loadFonts);
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_app(r));
    await t.runAsync(() async {
      for (final e in t.allElements.toList()) {
        if (e.widget is Image) await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pumpAndSettle();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    if (scrollTo > 0) {
      await t.drag(find.byKey(const Key('partner-hub')), Offset(0, -scrollTo));
      await t.pumpAndSettle();
    }
    for (var i = 0; i < swipe; i++) {
      await t.drag(find.byType(PageView), const Offset(-300, 0));
      await t.pumpAndSettle();
    }
    await _shot(t, name);
  }

  testWidgets('1 hub top', (t) => render(t, _Repo(() async => _full), 'partner-1'), skip: !on);
  testWidgets('2 hub scrolled', (t) => render(t, _Repo(() async => _full), 'partner-2', scrollTo: 440), skip: !on);
  testWidgets('3 payout card', (t) => render(t, _Repo(() async => _full), 'partner-3', swipe: 2), skip: !on);
  testWidgets('4 empty', (t) => render(t, _Repo(() async => _empty), 'partner-4'), skip: !on);
  testWidgets('5 error', (t) => render(t, _Repo(() async => throw StateError('x')), 'partner-5'), skip: !on);
  testWidgets('6 offline', (t) => render(t, _Repo(() async => throw const PartnerOfflineException()), 'partner-6'),
      skip: !on);
}
