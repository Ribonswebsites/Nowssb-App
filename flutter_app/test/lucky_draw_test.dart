// Lucky draw + winners. Set DRAW_SHOTS=<dir> to write draw-*.png renders.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/draw/draw_models.dart';
import 'package:nowssb/features/draw/draw_repository.dart';
import 'package:nowssb/features/draw/lucky_draw_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Map<String, dynamic> _statusJson({bool entered = false, Map<String, dynamic>? result}) => {
      'drawId': 'd-2026-10-31',
      'odds': {'text': 'About 1 in 150 entries wins', 'numerator': 1, 'denominator': 150},
      'closesAt': '2026-10-31T18:29:00Z',
      'resultsAt': '2026-10-31T18:30:00Z',
      'entered': entered,
      'open': true,
      'result': result,
      'prizes': [
        {'id': 'g1', 'kind': 'gift', 'title': 'Headphone gift box', 'detail': 'Delivered to your address'},
        {'id': 'c1', 'kind': 'coupon', 'title': '20% off coupon', 'detail': 'Covers part of a price'},
      ],
    };

class FakeRepo implements DrawRepository {
  FakeRepo({this.statusJson, this.fail = false, this.winnersJson = const {'winners': []}});
  Map<String, dynamic>? statusJson;
  bool fail;
  Map<String, dynamic> winnersJson;
  final entered = <String>[];
  final reviews = <String>[];
  Completer<void>? gate;

  @override
  Future<DrawStatus> status() async {
    if (gate != null) await gate!.future;
    if (fail) throw EconomyException('You look offline. Nothing was lost — try again.');
    return DrawStatus.fromJson(statusJson!);
  }

  @override
  Future<DrawStatus> enter(String drawId) async {
    entered.add(drawId);
    return DrawStatus.fromJson(_statusJson(entered: true));
  }

  @override
  Future<WinnersPage> winners({String? cursor, int limit = 20}) async => WinnersPage.fromJson(winnersJson);

  @override
  Future<void> submitReview({required String claimId, required String text, int? stars}) async =>
      reviews.add('$claimId|$text|$stars');
}

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester t, String name) async {
  final dir = Platform.environment['DRAW_SHOTS'];
  if (dir == null) return;
  final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  final img = await t.runAsync(() => ro.toImage(pixelRatio: 2));
  final bytes = await t.runAsync(() => img!.toByteData(format: ui.ImageByteFormat.png));
  File('$dir/draw-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(780, 1688);
  t.view.devicePixelRatio = 2;
  await t.pumpWidget(RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'DM Sans', useMaterial3: true), home: w)));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  testWidgets('shows server odds, free entry, enters once', (t) async {
    final repo = FakeRepo(statusJson: _statusJson());
    await _pump(t, LuckyDrawScreen(repository: repo));
    expect(find.text('About 1 in 150 entries wins'), findsOneWidget);
    expect(find.textContaining('Free to enter'), findsOneWidget);
    expect(find.text('Prizes have no cash value.'), findsOneWidget);
    await _shot(t, 'open');
    await t.tap(find.text('Enter free'));
    await t.pump();
    expect(repo.entered, ['d-2026-10-31']);
    expect(find.byKey(const Key('draw-entered')), findsOneWidget);
    expect(find.text('Enter free'), findsNothing);
    await _shot(t, 'entered');
  });

  testWidgets('odds hidden when server sends none', (t) async {
    final j = _statusJson()..remove('odds');
    await _pump(t, LuckyDrawScreen(repository: FakeRepo(statusJson: j)));
    expect(find.byKey(const Key('draw-odds')), findsNothing);
  });

  testWidgets('win result from server, review goes to server', (t) async {
    final repo = FakeRepo(
        statusJson: _statusJson(entered: true, result: {
      'won': true,
      'claimId': 'cl1',
      'prize': {'id': 'c1', 'kind': 'coupon', 'title': '20% off coupon'}
    }));
    await _pump(t, LuckyDrawScreen(repository: repo));
    expect(find.byKey(const Key('draw-won')), findsOneWidget);
    await _shot(t, 'won');
    await t.tap(find.text('Write a review'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('5 stars'));
    await t.enterText(find.byType(TextField), 'Loved it');
    await t.tap(find.text('Send review'));
    await t.pump();
    expect(repo.reviews, ['cl1|Loved it|5']);
    await _shot(t, 'review');
  });

  testWidgets('lost result', (t) async {
    await _pump(
        t, LuckyDrawScreen(repository: FakeRepo(statusJson: _statusJson(entered: true, result: {'won': false}))));
    expect(find.byKey(const Key('draw-lost')), findsOneWidget);
  });

  testWidgets('loading then error with retry', (t) async {
    final repo = FakeRepo(fail: true)..gate = Completer();
    await _pump(t, LuckyDrawScreen(repository: repo));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.gate!.complete();
    await t.pump();
    await t.pump();
    expect(find.text('Try again'), findsOneWidget);
    await _shot(t, 'error');
  });

  testWidgets('rules sheet', (t) async {
    await _pump(t, LuckyDrawScreen(repository: FakeRepo(statusJson: _statusJson())));
    await t.tap(find.text('Official rules'));
    await t.pumpAndSettle();
    expect(find.textContaining('No purchase and no coins'), findsOneWidget);
    expect(find.textContaining('no cash value'), findsWidgets);
    await _shot(t, 'rules');
  });

  testWidgets('winners empty state has no made-up names', (t) async {
    await _pump(t, LuckyDrawWinnersScreen(repository: FakeRepo()));
    expect(find.textContaining('No winners yet'), findsOneWidget);
    await _shot(t, 'winners-empty');
  });

  testWidgets('winners list shows server winners and reviews', (t) async {
    await _pump(
        t,
        LuckyDrawWinnersScreen(
            repository: FakeRepo(winnersJson: {
          'winners': [
            {
              'id': 'w1',
              'displayName': 'Asha K.',
              'prizeTitle': '20% off coupon',
              'wonAt': '2026-10-30T18:30:00Z',
              'review': {'text': 'Used it the same day.', 'stars': 5}
            },
            {'id': 'w2', 'displayName': 'Dev R.', 'prizeTitle': 'Headphone gift box', 'wonAt': '2026-10-29T18:30:00Z'},
          ],
          'nextCursor': null,
        })));
    expect(find.text('Asha K.'), findsOneWidget);
    expect(find.text('“Used it the same day.”'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
    await _shot(t, 'winners');
  });
}
