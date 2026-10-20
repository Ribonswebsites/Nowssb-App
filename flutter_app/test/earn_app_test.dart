import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/earn/app/earn_app.dart';
import 'package:nowssb/features/earn/app/earn_data.dart';
import 'package:nowssb/features/earn/app/earn_ui.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _summary = <String, dynamic>{
  'enabled': true,
  'standing': {'title': 'Officer', 'metal': 'Silver', 'ratePct': 22},
  'ranks': [{'title': 'Officer', 'metal': 'Silver', 'minWords': 100, 'ratePct': 22}, {'title': 'Executive Officer I', 'metal': 'Gold', 'minWords': 500, 'ratePct': 30}],
  'balances': {'lifetimeINR': 1250, 'pendingINR': 250, 'availableINR': 1000},
  'words': 240,
  'targets': [
    {'words': 100, 'coins': 300, 'coupon': 'rare'}, {'words': 500, 'coins': 1000, 'coupon': 'epic'}, {'words': 1000}, {'words': 2000}, {'words': 3000},
  ],
  'team': [
    {'uid': 'a', 'name': 'Asha', 'rank': 'Officer', 'words': 112, 'level': 1},
    {'uid': 'b', 'name': 'Ben', 'words': 40, 'level': 1},
    {'uid': 'c', 'name': 'Chen', 'words': 6, 'level': 2},
  ],
  'invites': [{'id': 'i1', 'rank': 'Officer', 'fromName': 'Ravi'}],
};

final _shots = Platform.environment['EARN_SCREENS_DIR'];
final _key = GlobalKey();

Widget _app(Widget w) => RepaintBoundary(
      key: _key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: _shots == null ? null : 'Roboto', brightness: Brightness.dark),
        home: w,
      ),
    );

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots == null) return;
  await t.runAsync(() async {
    final ctx = _key.currentContext!;
    for (final p in kEarnPhotos) {
      await precacheImage(AssetImage(p), ctx);
    }
  });
  await t.pump(const Duration(milliseconds: 400));
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File('/workspace/flutter/bin/cache/artifacts/material_fonts/$f').readAsBytesSync())));
  }
  await l.load();
}

void main() {
  earnNoVideo = true;
  setUpAll(() async {
    if (_shots != null) {
      await _font('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
      await _font('MaterialIcons', ['MaterialIcons-Regular.otf']);
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'earn.guide.seen': true});
    earnLoader = () async => EarnData.fromSummary(_summary);
  });

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  test('zero rate never shows 0%', () {
    final d = EarnData.fromSummary({'standing': {'title': 'Assistant Officer', 'ratePct': 0}, 'words': 0, 'targets': [{'words': 100}]});
    expect(d.ratePct, 0);
    expect(d.next!.words, 100);
  });

  test('summary maps honestly', () {
    final d = EarnData.fromSummary(_summary);
    expect(d.rank, 'Officer');
    expect(d.next!.words, 500);
    expect(d.progress, closeTo(140 / 400, 1e-9));
    expect(d.nextRank!.title, 'Executive Officer I');
    expect(d.currency, 'INR');
    expect(d.earned, 1250);
    expect(d.direct.length, 2);
    expect(d.second.length, 1);
    expect(EarnData.fromSummary(const {}).targets, isEmpty);
    expect(EarnData.fromError(EconomyException('x', code: 'offline')).load, EarnLoad.offline);
    expect(EarnData.fromError(EconomyException('x', code: 'unauthenticated')).load, EarnLoad.signedOut);
  });

  testWidgets('home, tabs, pop-ups', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const EarnApp()));
    await t.pump();
    expect(find.text('Officer'), findsWidgets);
    expect(find.textContaining('260 more words to reach 500.'), findsOneWidget);
    expect(find.textContaining('Next rank: Executive Officer I'), findsOneWidget);
    expect(find.textContaining('22%'), findsWidgets);
    await _shot(t, 'earn-1');
    await t.tap(find.byKey(const Key('earn-tab-1')));
    await t.pump();
    expect(find.byKey(const Key('earn-target-500')), findsOneWidget);
    await _shot(t, 'earn-2');
    await t.tap(find.byKey(const Key('earn-target-500')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Sell 260 more words'), findsOneWidget);
    await _shot(t, 'earn-3');
    await t.tap(find.text('Close'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('earn-tab-2')));
    await t.pump();
    expect(find.text('2 direct · 1 level 2'), findsOneWidget);
    await _shot(t, 'earn-4');
    await t.tap(find.byKey(const Key('earn-member-a')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Words sold: 112'), findsOneWidget);
    await _shot(t, 'earn-6');
    await t.tap(find.text('Close'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('earn-tab-3')));
    await t.pump();
    expect(find.byKey(const Key('earn-task-share')), findsOneWidget);
    await _shot(t, 'earn-5');
  });

  testWidgets('first-use guide shows once and steps through', (t) async {
    await phone(t);
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_app(const EarnApp()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Join as an agent'), findsOneWidget);
    await _shot(t, 'earn-7');
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Sell words and plans'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('earn.guide.seen'), isTrue);
  });

  testWidgets('payout entry is country-aware and honest', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const EarnPayoutPage()));
    await t.pump();
    expect(find.textContaining('global payout provider'), findsOneWidget);
    await t.tap(find.byKey(const Key('earn-country')));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Germany').last);
    await t.pump(const Duration(milliseconds: 400));
    await _shot(t, 'earn-8');
    await t.tap(find.text('Continue'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Payouts for Germany open when'), findsOneWidget);
    await _shot(t, 'earn-9');
  });

  testWidgets('invite pop-up and states', (t) async {
    await phone(t);
    earnLoader = () async => const EarnData(load: EarnLoad.offline);
    await t.pumpWidget(_app(const EarnApp()));
    await t.pump();
    expect(find.byKey(const Key('earn-offline')), findsOneWidget);
    await _shot(t, 'earn-10');
    earnLoader = () async => const EarnData(load: EarnLoad.error, message: 'Boom');
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.text('Boom'), findsOneWidget);
    earnLoader = () async => EarnData.fromSummary({..._summary, 'team': <dynamic>[]});
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.tap(find.byKey(const Key('earn-tab-2')));
    await t.pump();
    expect(find.byKey(const Key('earn-team-empty')), findsOneWidget);
    await _shot(t, 'earn-11');
  });
}
