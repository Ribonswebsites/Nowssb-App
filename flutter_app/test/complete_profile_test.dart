// Complete your profile after sign-up: validation, the friend's code from a
// link, saving to the account, and the gate in front of the app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/account/complete_profile_page.dart';
import 'package:nowssb/features/account/countries.dart';
import 'package:nowssb/features/account/profile_details.dart';
import 'package:nowssb/features/account/referral_capture.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/media/video_pool.dart';

void main() {
  group('validation', () {
    test('name', () {
      expect(validateName('A'), isNotNull);
      expect(validateName('Ana Ray'), isNull);
      expect(validateName('Ana 2'), isNotNull);
    });
    test('phone with country code', () {
      final india = countryByCode('IN');
      final us = countryByCode('US');
      expect(validatePhone('9876543210', india), isNull);
      expect(validatePhone('1234567890', india), isNotNull);
      expect(validatePhone('98765', india), isNotNull);
      expect(validatePhone('4155550123', us), isNull);
      expect(validatePhone('14155550123', us), isNotNull);
      expect(validatePhone('612345678', countryByCode('FR')), isNull);
      expect(validatePhone('612345678', null), isNotNull);
    });
    test('date of birth is optional, 13+', () {
      final now = DateTime(2026, 11, 18);
      expect(validateDob(null, now: now), isNull);
      expect(validateDob(DateTime(2000, 1, 1), now: now), isNull);
      expect(validateDob(DateTime(2015, 1, 1), now: now), isNotNull);
      expect(validateDob(DateTime(2027, 1, 1), now: now), isNotNull);
    });
    test('referral input', () {
      expect(validateReferralInput(''), isNull);
      expect(validateReferralInput('AB12CD34'), isNull);
      expect(validateReferralInput('AB'), isNotNull);
    });
    test('E.164 split and missing details', () {
      expect(splitE164('+919876543210'), ('IN', '9876543210'));
      expect(splitE164('+14155550123', preferCountry: 'CA'), ('CA', '4155550123'));
      expect(splitE164('+447700900123'), ('GB', '7700900123'));
      final d = ProfileDetails.fromUserDoc({'displayName': 'Ana', 'phone': '+919876543210'});
      expect(d.phoneCountry, 'IN');
      expect(d.missing, isTrue, reason: 'no country yet');
      expect(ProfileDetails.fromUserDoc({'displayName': 'Ana', 'phone': '+919876543210', 'country': 'IN'}).missing, isFalse);
      expect(ProfileDetails.fromUserDoc({'profileCompletedAt': 1}).missing, isFalse);
    });
  });

  group('page', () {
    late List<(String, Map<String, dynamic>)> calls;
    late List<Map<String, dynamic>> saved;

    setUp(() async {
      VideoPool.debugDeadlines = false; // the page's film backdrop
      SharedPreferences.setMockInitialValues({});
      await ReferralCapture.instance.debugReset();
      await PendingCoins.instance.debugReset();
      PendingCoins.debugIgnoreGates = true;
      PendingCoins.debugAutoShow = () => false;
      ReferralCapture.debugLinks = const Stream<Uri>.empty();
      ReferralCapture.debugInstallReferrer = () async => 'nwsb_ref=AB12CD34&nwsb_item=app';
      calls = [];
      saved = [];
      EconomyApi.debugHandler = (name, data) async {
        calls.add((name, data));
        return {'attached': true};
      };
      ProfileDetailsStore.debugSave = (uid, data) async => saved.add({'uid': uid, ...data});
    });

    tearDown(() {
      EconomyApi.debugHandler = null;
      ProfileDetailsStore.debugSave = null;
      ProfileDetailsStore.debugLoad = null;
      ReferralCapture.debugLinks = null;
      ReferralCapture.debugInstallReferrer = null;
      PendingCoins.debugAutoShow = null;
      PendingCoins.debugIgnoreGates = false;
    });

    Future<void> pumpPage(WidgetTester tester, {VoidCallback? onDone}) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: CompleteProfilePage(
          uid: 'u1',
          initial: const ProfileDetails(country: 'IN', phoneCountry: 'IN'),
          onDone: onDone,
          onSkip: () {},
        ),
      ));
      await tester.pump();
    }

    testWidgets('the friend’s code from the link is prefilled', (tester) async {
      await tester.runAsync(() async {
        await ReferralCapture.instance.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await pumpPage(tester);
      expect(find.text('AB12CD34'), findsOneWidget);
      expect(find.byKey(const Key('profile-ref-from-link')), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Save checks the fields, then saves and attaches once', (tester) async {
      await tester.runAsync(() async {
        await ReferralCapture.instance.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      var done = 0;
      await pumpPage(tester, onDone: () => done++);
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pump();
      expect(find.text('Enter your name (at least 2 letters).'), findsOneWidget);
      expect(find.text('Enter your phone number.'), findsOneWidget);
      expect(saved, isEmpty);

      await tester.enterText(find.byKey(const Key('profile-name')), 'Ana Ray');
      await tester.enterText(find.byKey(const Key('profile-phone')), '98765 43210');
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('profile-save')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(saved.single['displayName'], 'Ana Ray');
      expect(saved.single['phone'], '+919876543210');
      expect(saved.single['country'], 'IN');
      expect(saved.single['dob'], isNull);
      final attach = calls.where((c) => c.$1 == 'attachReferral').single.$2;
      expect(attach['code'], 'AB12CD34');
      expect(attach['source'], 'install');
      expect(done, 1);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('gate shows the page for missing details, and not when complete', (tester) async {
      ProfileDetailsStore.debugLoad = (uid) async => uid == 'new' ? {'displayName': 'Ana'} : {'profileCompletedAt': 1};
      ReferralCapture.debugInstallReferrer = () async => null;
      await tester.pumpWidget(const MaterialApp(home: ProfileSetupGate(uid: 'old', child: Text('HOME'))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('HOME'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: ProfileSetupGate(key: Key('g2'), uid: 'new', child: Text('HOME'))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('Complete your profile'), findsOneWidget);
      // Not now lets the app through and is remembered for three days.
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('profile-skip')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(find.text('HOME'), findsOneWidget);
      expect(await tester.runAsync(() => ProfileDetailsStore.instance.snoozed('new')), isTrue);
    });
  });
}
