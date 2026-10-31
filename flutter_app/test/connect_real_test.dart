import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _home({List<Map<String, dynamic>> people = const [], List<Map<String, dynamic>> posts = const [], bool me = true}) => {
      'me': me ? {'uid': 'me1', 'name': 'Ribon', 'focus': 'Wellness', 'bio': '', 'theme': 'neu', 'banner': '', 'avatar': ''} : null,
      'people': people,
      'posts': posts,
      'following': <String>[],
      'followingCount': 0,
      'followerCount': 3,
    };

// Tests have no network: ignore failed network images, nothing else.
void _quietImages() {
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exception is NetworkImageLoadException || '${d.exception}'.contains('HTTP request failed')) return;
    prev?.call(d);
  };
  addTearDown(() => FlutterError.onError = prev);
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => EconomyApi.debugHandler = null);

  testWidgets('no profile yet shows setup, never sample people', (t) async {
    EconomyApi.debugHandler = (name, data) async => _home(me: false);
    _quietImages();
    await t.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const MaterialApp(home: ConnectScreen()));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Kavya'), findsNothing);
    expect(find.textContaining('kavya.frequency'), findsNothing);
    await _close(t);
  });

  testWidgets('empty community shows honest empty states and real counts', (t) async {
    final calls = <String>[];
    EconomyApi.debugHandler = (name, data) async {
      calls.add(name);
      return _home();
    };
    _quietImages();
    await t.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const MaterialApp(home: ConnectScreen()));
    await t.pump(const Duration(milliseconds: 50));
    expect(calls, contains('connectHome'));
    expect(find.textContaining('No one else has joined Connect yet'), findsOneWidget);
    await t.tap(find.text('PROFILE'));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('3'), findsOneWidget); // followers from the server
    expect(find.text('You haven’t posted yet.'), findsOneWidget);
    await _close(t);
  });

  testWidgets('follow, real post and a real message go to the server', (t) async {
    final calls = <String, Map<String, dynamic>>{};
    EconomyApi.debugHandler = (name, data) async {
      calls[name] = data;
      switch (name) {
        case 'connectFollow':
          return {'following': true};
        case 'connectThread':
          return {'chatId': 'a_b', 'messages': <Map<String, dynamic>>[]};
        case 'connectSend':
          return {'chatId': 'a_b', 'message': {'id': 'm1', 'mine': true, 'text': data['text'], 'at': 1}};
        default:
          return _home(
            people: [
              {'uid': 'u2', 'name': 'Asha Rao', 'username': 'asha.rao.u2', 'focus': 'Beginner', 'bio': '', 'avatar': ''},
            ],
            posts: [
              {'id': 'p1', 'authorUid': 'u2', 'authorName': 'Asha Rao', 'text': 'First session today', 'image': '', 'likes': 2, 'liked': false},
            ],
          );
      }
    };
    _quietImages();
    await t.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const MaterialApp(home: ConnectScreen()));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Asha Rao'), findsOneWidget);
    await t.tap(find.text('Follow').first);
    await t.pump(const Duration(milliseconds: 50));
    expect(calls['connectFollow'], {'targetUid': 'u2', 'follow': true});
    expect(find.text('Following'), findsOneWidget);

    await t.tap(find.text('CONNECT'));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('First session today'), findsOneWidget);
    await t.tap(find.text('Message').first);
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Say hello to Asha Rao.'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing); // no fake calls
    expect(find.text('Rate ★'), findsNothing);
    await t.enterText(find.byKey(const Key('connect-message')), 'Hi Asha');
    await t.tap(find.byKey(const Key('connect-send')));
    await t.pump(const Duration(milliseconds: 50));
    expect(calls['connectSend'], {'toUid': 'u2', 'text': 'Hi Asha'});
    expect(find.text('Hi Asha'), findsOneWidget);
    await _close(t);
  });
}
