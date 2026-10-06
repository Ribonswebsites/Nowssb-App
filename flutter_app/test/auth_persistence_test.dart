// Login must survive leaving the app: a user FirebaseAuth restores at cold
// start goes straight to the app, and a stale "Remember me = off" written by
// older builds on sign-out no longer signs everyone out on every launch.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/remember_me.dart';
import 'package:nowssb/screens/auth_gate.dart';
import 'package:nowssb/widgets/login_stage.dart';

class _RestoredUser implements User {
  @override
  String get uid => 'restored-uid';
  @override
  bool get isAnonymous => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _home = Key('home');

Widget _gate(Stream<User?> states, List<String> signedIn) => MaterialApp(
      home: AuthGate(
        authStates: states,
        onSignedIn: signedIn.add,
        child: const Scaffold(key: _home, body: Text('Home')),
      ),
    );

void main() {
  group('Remember me', () {
    test('the "off" older builds wrote on sign-out is dropped once', () async {
      // What a pre-3-Oct sign-out from Settings left behind.
      SharedPreferences.setMockInitialValues({RememberMe.key: false});
      final prefs = await SharedPreferences.getInstance();
      expect(await RememberMe.read(prefs), isTrue);
      expect(await RememberMe.read(prefs), isTrue);
      expect(prefs.getBool(RememberMe.key), isNull);
    });

    test('a choice made on the sign-in screen is kept', () async {
      SharedPreferences.setMockInitialValues({RememberMe.key: false});
      final prefs = await SharedPreferences.getInstance();
      await RememberMe.write(false, prefs);
      expect(await RememberMe.read(prefs), isFalse);
      await RememberMe.write(true, prefs);
      expect(await RememberMe.read(prefs), isTrue);
    });

    test('cold start does not sign out a stale "off" (no Firebase needed)', () async {
      SharedPreferences.setMockInitialValues({RememberMe.key: false});
      await AuthGate.forgetUnremembered();
      final prefs = await SharedPreferences.getInstance();
      expect(await RememberMe.read(prefs), isTrue);
    });
  });

  group('AuthGate', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('a restored signed-in user goes to home, not login', (tester) async {
      // Single-subscription on purpose: a gate that re-subscribes on rebuild
      // throws "Stream has already been listened to".
      final auth = StreamController<User?>();
      final signedIn = <String>[];
      await tester.pumpWidget(_gate(auth.stream, signedIn));
      // Before FirebaseAuth answers: neither login nor home.
      expect(find.byType(LoginStage), findsNothing);
      expect(find.byKey(_home), findsNothing);

      auth.add(_RestoredUser());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_home), findsOneWidget);
      expect(find.byType(LoginStage), findsNothing);
      expect(signedIn, ['restored-uid']);

      // The gate rebuilding (Remember-me load etc.) keeps the user at home.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(_home), findsOneWidget);
      await auth.close();
    });

    testWidgets('no restored user shows the login screen', (tester) async {
      final auth = StreamController<User?>();
      await tester.pumpWidget(_gate(auth.stream, <String>[]));
      auth.add(null);
      await tester.pump();
      await tester.pump();
      expect(find.byType(LoginStage), findsOneWidget);
      expect(find.byKey(_home), findsNothing);
      await auth.close();
    });
  });
}
