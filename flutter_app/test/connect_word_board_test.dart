import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Map<String, dynamic> _post(String id, String text, {String feeling = '', int felt = 0, bool feltByMe = false, bool mine = false, String image = ''}) =>
    {'id': id, 'text': text, 'feeling': feeling, 'felt': felt, 'feltByMe': feltByMe, 'mine': mine, 'image': image, 'at': 0};

Future<void> _open(WidgetTester t, {bool guideSeen = true}) async {
  SharedPreferences.setMockInitialValues({if (guideSeen) 'nwsb_connect_board_guide_v1': true});
  await t.binding.setSurfaceSize(const Size(390, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(const MaterialApp(home: ConnectScreen()));
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
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
    for (final bad in ['connectFollow', 'connectSend', 'connectInbox', 'connectSaveProfile', 'connectHome', 'Reels', 'fontStyle: FontStyle.italic']) {
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

  testWidgets('empty board shows the word and an honest empty state', (t) async {
    EconomyApi.debugHandler = (name, data) async => _day();
    await _open(t);
    expect(find.text('NowssB Connect'), findsOneWidget);
    expect(find.text('TODAY’S WORD'), findsOneWidget);
    expect(find.textContaining('No thoughts yet today'), findsOneWidget);
    expect(find.textContaining('3 of 3 left today'), findsOneWidget);
  });

  testWidgets('share a thought with a feeling and an image', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardPost') return {'post': _post('n1', data['text'] as String, feeling: data['feeling'] as String, mine: true, image: data['image'] as String), 'postsLeft': 2};
      return _day();
    };
    ConnectScreen.debugPickImage = () async => 'connect/me1/1730000000000.jpg';
    await _open(t);
    await t.enterText(find.byType(TextField), 'Warm, like sun on my chest');
    await t.tap(find.bySemanticsLabel(RegExp(r'^calm$')));
    await t.tap(find.bySemanticsLabel(RegExp('Add an image')));
    await t.pump();
    await t.tap(find.text('Share'));
    await t.pump(const Duration(milliseconds: 600));
    expect(calls['boardPost']!['text'], 'Warm, like sun on my chest');
    expect(calls['boardPost']!['feeling'], 'calm');
    expect(calls['boardPost']!['image'], 'connect/me1/1730000000000.jpg');
    expect(find.text('Warm, like sun on my chest'), findsOneWidget);
    expect(find.text('feels calm'), findsOneWidget);
    expect(find.textContaining('2 of 3 left today'), findsOneWidget);
  });

  testWidgets('felt this, hide and report go to the server', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      if (name == 'boardFelt') return {'felt': 3, 'feltByMe': true};
      if (name == 'boardReport') return {'hidden': true};
      return _day(posts: [_post('a', 'Light and open', felt: 2), _post('b', 'Odd one')]);
    };
    await _open(t);
    expect(find.bySemanticsLabel(RegExp('2 felt this')), findsOneWidget);
    await t.tap(find.text('2 felt this'));
    await t.pumpAndSettle();
    expect(calls['boardFelt'], {'day': '20261102', 'postId': 'a', 'on': true});
    expect(find.bySemanticsLabel(RegExp('3 felt this')), findsOneWidget);
    await t.tap(find.byTooltip('Hide or report').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Report'));
    await t.pumpAndSettle();
    expect(calls['boardReport']!['postId'], 'b');
    expect(find.text('Odd one'), findsNothing);
  });

  testWidgets('yesterday is read-only', (t) async {
    EconomyApi.debugHandler = (name, data) async => data['day'] == '20261101'
        ? _day(readOnly: true, posts: [_post('y', 'Yesterday felt heavy', felt: 4)], left: 0)
        : _day(days: ['20261101']);
    await _open(t);
    await t.tap(find.bySemanticsLabel(RegExp('Nov 1')));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Yesterday felt heavy'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('read it, but not post'), findsOneWidget);
  });

  testWidgets('guide shows once, reopens from ?', (t) async {
    EconomyApi.debugHandler = (name, data) async => _day();
    await _open(t, guideSeen: false);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('One word a day'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.text('One word a day'), findsNothing);
    await t.tap(find.bySemanticsLabel(RegExp('How Connect works')));
    await t.pumpAndSettle();
    expect(find.text('One word a day'), findsOneWidget);
  });
}
