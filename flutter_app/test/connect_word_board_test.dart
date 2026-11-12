import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

Map<String, dynamic> _day({List<Map<String, dynamic>> posts = const [], bool readOnly = false, int left = 3, List<String> days = const []}) => {
      'day': readOnly ? '20261101' : '20261102',
      'today': '20261102',
      'readOnly': readOnly,
      'word': 'TEJAS',
      'meaning': 'Inner radiance, the warm light of a clear mind.',
      'posts': posts,
      'postsLeft': left,
      'days': days,
    };

Map<String, dynamic> _post(String id, String text, {bool mine = false, String image = ''}) =>
    {'id': id, 'text': text, 'mine': mine, 'image': image, 'at': 0};

Future<void> _open(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await t.binding.setSurfaceSize(const Size(390, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(const MaterialApp(home: ConnectScreen()));
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  // Connect now sits on the app film (AppBackdrop), like the Sound Library.
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    NormalLoop.debugT = .35;
    ConnectScreen.debugImage = (_) => const ColoredBox(color: Color(0xFFCCD3E0));
  });
  tearDown(() {
    EconomyApi.debugHandler = null;
    ConnectScreen.debugPickImage = null;
    ConnectScreen.debugImage = null;
    NormalLoop.debugT = null;
  });

  test('no Instagram-style Connect left in the source', () {
    final src = File('lib/features/social/connect_screen.dart').readAsStringSync();
    for (final bad in ['connectFollow', 'connectSend', 'connectInbox', 'connectSaveProfile', 'connectHome', 'Reels', 'Stories', 'followers', 'felt this', 'feltByMe', 'fontStyle: FontStyle.italic']) {
      expect(src.contains(bad), isFalse, reason: bad);
    }
  });

  test('images are compressed to about 1 MB JPEG', () {
    final big = img.Image(width: 3000, height: 2000);
    for (var y = 0; y < 2000; y++) {
      for (var x = 0; x < 3000; x++) {
        big.setPixelRgb(x, y, (x * 7 + y * 3) % 256, (x * y) % 256, (y * 11) % 256);
      }
    }
    final raw = Uint8List.fromList(img.encodePng(big));
    final out = compressBoardImage(raw)!;
    expect(out.lengthInBytes, lessThanOrEqualTo(kBoardMaxImageBytes));
    final back = img.decodeJpg(out)!;
    expect(back.width, lessThanOrEqualTo(1280));
    expect(compressBoardImage(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('quotes round-trip through the stored text; times read like a real app', () {
    final q = BoardPost.from({'id': 'q', 'text': encodeQuote('Be still and know', 'Psalm 46'), 'image': ''});
    expect(q.kind, PostKind.quote);
    expect(q.body, 'Be still and know');
    expect(q.by, 'Psalm 46');
    expect(BoardPost.from({'id': 't', 'text': 'Just a thought'}).kind, PostKind.thought);
    expect(BoardPost.from({'id': 'i', 'text': '', 'image': 'connect/u/1.jpg'}).kind, PostKind.image);
    final now = DateTime(2026, 11, 4, 12);
    expect(boardAgo(now.subtract(const Duration(seconds: 20)).millisecondsSinceEpoch, now: now), 'just now');
    expect(boardAgo(now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch, now: now), '12 min ago');
    expect(boardAgo(now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch, now: now), '3 h ago');
    expect(boardAgo(DateTime(2026, 11, 3, 20).millisecondsSinceEpoch, now: now), 'Yesterday');
    expect(boardAgo(DateTime(2026, 11, 1, 9).millisecondsSinceEpoch, now: now), 'Nov 1');
  });

  testWidgets('empty board shows an honest empty state', (t) async {
    EconomyApi.debugHandler = (name, data) async => _day();
    await _open(t);
    expect(find.text('NowssB Connect'), findsOneWidget);
    expect(find.text('Post to the board'), findsOneWidget);
    expect(find.textContaining('No posts yet today'), findsOneWidget);
    expect(find.text('3 of 3 left today'), findsOneWidget);
  });

  testWidgets('post a thought', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardPost') return {'post': _post('n1', data['text'] as String, mine: true, image: data['image'] as String), 'postsLeft': 2};
      return _day();
    };
    await _open(t);
    await t.enterText(find.byType(TextField), 'Warm, like sun on my chest');
    await t.pump();
    await t.tap(find.bySemanticsLabel('Post'));
    await t.pump(const Duration(milliseconds: 600));
    expect(calls['boardPost'], {'text': 'Warm, like sun on my chest', 'image': ''});
    expect(find.text('Warm, like sun on my chest'), findsOneWidget);
    expect(find.text('2 of 3 left today'), findsOneWidget);
  });

  testWidgets('post a quote with who said it', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardPost') return {'post': _post('n2', data['text'] as String, mine: true), 'postsLeft': 2};
      return _day();
    };
    await _open(t);
    await t.tap(find.bySemanticsLabel('Quote'));
    await t.pump();
    await t.enterText(find.byType(TextField).first, 'Silence is a source of great strength');
    await t.enterText(find.byType(TextField).last, 'Lao Tzu');
    await t.pump();
    await t.tap(find.bySemanticsLabel('Post'));
    await t.pump(const Duration(milliseconds: 600));
    expect(calls['boardPost']!['text'], '“Silence is a source of great strength” — Lao Tzu');
    expect(find.text('“Silence is a source of great strength”'), findsOneWidget);
    expect(find.text('— Lao Tzu'), findsOneWidget);
  });

  testWidgets('post an image', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardPost') return {'post': _post('n3', data['text'] as String, mine: true, image: data['image'] as String), 'postsLeft': 2};
      return _day();
    };
    ConnectScreen.debugPickImage = () async => 'connect/me1/1730000000000.jpg';
    await _open(t);
    await t.tap(find.bySemanticsLabel('Image'));
    await t.pump();
    expect(find.bySemanticsLabel('Post'), findsOneWidget);
    await t.tap(find.text('Choose an image'));
    await t.pump();
    await t.tap(find.bySemanticsLabel('Post'));
    await t.pump(const Duration(milliseconds: 600));
    expect(calls['boardPost']!['image'], 'connect/me1/1730000000000.jpg');
  });

  testWidgets('filter, hide and report go to the server; no Delete until boardDelete ships', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardReport') return {'hidden': true};
      if (name == 'boardDelete') return {'deleted': true};
      return _day(posts: [_post('a', 'Light and open'), _post('b', 'Odd one'), _post('c', encodeQuote('Be here now', '')), _post('m', 'Mine', mine: true)]);
    };
    await _open(t);
    await t.tap(find.bySemanticsLabel('Quotes'));
    await t.pump();
    expect(find.text('Light and open'), findsNothing);
    expect(find.text('“Be here now”'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('All'));
    await t.pump();
    await t.tap(find.byTooltip('Hide or report').at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Report'));
    await t.pumpAndSettle();
    expect(calls['boardReport']!['postId'], 'b');
    expect(find.text('Odd one'), findsNothing);
    await t.tap(find.byTooltip('Hide or report').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Hide this'));
    await t.pumpAndSettle();
    expect(calls['boardReport'], {'day': '20261102', 'postId': 'a', 'hideOnly': true});
    // boardDelete isn't deployed yet: your own post shows no dead Delete.
    expect(find.byTooltip('Delete'), findsNothing);
    expect(calls.containsKey('boardDelete'), isFalse);
  });

  testWidgets('an earlier day is read-only', (t) async {
    EconomyApi.debugHandler = (name, data) async => data['day'] == '20261101'
        ? _day(readOnly: true, posts: [_post('y', 'Yesterday felt heavy')], left: 0)
        : _day(days: ['20261101']);
    await _open(t);
    await t.tap(find.bySemanticsLabel('Nov 1'));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Yesterday felt heavy'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('read it, but not post'), findsOneWidget);
  });
}
