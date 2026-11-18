// Referral capture through sign-up: codes from the Play install referrer,
// a tapped link or typing; attached to the account exactly once by the
// server, never credited by the app.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/account/referral_capture.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing', () {
    test('codes are upper-cased letters and digits, 4–20 long', () {
      expect(normalizeReferralCode(' ab12-cd34 '), 'AB12CD34');
      expect(normalizeReferralCode('ab1'), isNull);
      expect(normalizeReferralCode('A' * 21), isNull);
      expect(normalizeReferralCode(null), isNull);
    });

    test('share links: nowssb.com/w/<item>?r=CODE and nowssb://ref', () {
      final a = referralFromUri(Uri.parse('https://nowssb.com/w/sahasrara?r=ab12cd34'));
      expect(a?.code, 'AB12CD34');
      expect(a?.item, 'sahasrara');
      expect(referralFromUri(Uri.parse('https://www.nowssb.com/w/app?ref=ZZ99YY88'))?.code, 'ZZ99YY88');
      expect(referralFromUri(Uri.parse('nowssb://ref?r=QW12ER34'))?.code, 'QW12ER34');
      expect(referralFromUri(Uri.parse('nowssb://ref/QW12ER34'))?.code, 'QW12ER34');
      // Other hosts and links without a code are ignored.
      expect(referralFromUri(Uri.parse('https://evil.example/w/app?r=AB12CD34')), isNull);
      expect(referralFromUri(Uri.parse('https://nowssb.com/w/app')), isNull);
      expect(referralFromUri(Uri.parse('nowssb://widget/home')), isNull);
    });

    test('Play install referrer string from the share page', () {
      const raw = 'utm_source=nowssb_ref&utm_medium=link&nwsb_ref=AB12CD34&nwsb_item=app';
      expect(referralFromInstallReferrer(raw)?.code, 'AB12CD34');
      // Still URL-encoded once (some Play versions).
      expect(referralFromInstallReferrer(Uri.encodeComponent(raw))?.code, 'AB12CD34');
      // Organic installs carry Play's default referrer: nothing to attach.
      expect(referralFromInstallReferrer('utm_source=google-play&utm_medium=organic'), isNull);
      expect(referralFromInstallReferrer(''), isNull);
      expect(referralFromInstallReferrer('nwsb_ref=AB12CD34')?.item, 'app');
    });
  });

  group('capture and attach', () {
    late List<(String, Map<String, dynamic>)> calls;
    late Map<String, dynamic> Function(String, Map<String, dynamic>) answer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ReferralCapture.instance.debugReset();
      await PendingCoins.instance.debugReset();
      PendingCoins.debugIgnoreGates = true;
      PendingCoins.debugAutoShow = () => false;
      calls = [];
      answer = (_, __) => {'attached': true, 'welcomeOffer': {'coins': 100}};
      EconomyApi.debugHandler = (name, data) async {
        calls.add((name, data));
        final r = answer(name, data);
        if (r['throw'] != null) throw EconomyException('${r['throw']}', code: '${r['code'] ?? 'failed-precondition'}');
        return r;
      };
      ReferralCapture.debugLinks = const Stream<Uri>.empty();
      ReferralCapture.debugInstallReferrer = () async => null;
    });

    tearDown(() {
      EconomyApi.debugHandler = null;
      ReferralCapture.debugLinks = null;
      ReferralCapture.debugInstallReferrer = null;
      PendingCoins.debugAutoShow = null;
      PendingCoins.debugIgnoreGates = false;
    });

    test('install referrer is read once and waits for sign-up', () async {
      var reads = 0;
      ReferralCapture.debugInstallReferrer = () async {
        reads++;
        return 'utm_source=nowssb_ref&nwsb_ref=AB12CD34&nwsb_item=app';
      };
      await ReferralCapture.instance.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(ReferralCapture.instance.pending?.code, 'AB12CD34');
      expect(ReferralCapture.instance.pending?.source, 'install');
      // A later launch does not read Play again.
      await ReferralCapture.instance.debugReset();
      await ReferralCapture.instance.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(reads, 1);
      // ...but the waiting code survived the restart.
      expect(ReferralCapture.instance.pending?.code, 'AB12CD34');
      expect(calls, isEmpty, reason: 'nothing is sent before someone signs in');
    });

    test('a tapped link replaces a waiting install code', () async {
      final links = StreamController<Uri>();
      ReferralCapture.debugLinks = links.stream;
      ReferralCapture.debugInstallReferrer = () async => 'nwsb_ref=OLDC0DE1';
      await ReferralCapture.instance.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      links.add(Uri.parse('https://nowssb.com/w/app?r=NEWC0DE2'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ReferralCapture.instance.pending?.code, 'NEWC0DE2');
      expect(ReferralCapture.instance.pending?.source, 'link');
      await links.close();
    });

    test('sign-in attaches once with source and install id; coins are only offered', () async {
      ReferralCapture.debugInstallReferrer = () async => 'nwsb_ref=AB12CD34';
      await ReferralCapture.instance.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(ReferralCapture.instance.pending?.code, 'AB12CD34');
      final out = await ReferralCapture.instance.onSignedIn('u1');
      expect(out?.attached, isTrue);
      expect(out?.welcomeCoins, 100);
      final attach = calls.where((c) => c.$1 == 'attachReferral').single.$2;
      expect(attach['code'], 'AB12CD34');
      expect(attach['source'], 'install');
      expect('${attach['installId']}', isNotEmpty);
      // Offered as a Collect card, not credited: no reportAction call yet.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls.where((c) => c.$1 == 'reportAction'), isEmpty);
      expect(PendingCoins.instance.items.map((e) => e.action), contains('referral_welcome'));
      expect(ReferralCapture.instance.pending, isNull);

      // Exactly once: a second code for this account never reaches the server.
      final again = await ReferralCapture.instance.attach('u1', 'ZZ99YY88');
      expect(again.attached, isFalse);
      expect(again.message, contains('can’t be changed'));
      expect(calls.where((c) => c.$1 == 'attachReferral').length, 1);
      expect(await ReferralCapture.instance.attachedCode('u1'), 'AB12CD34');
    });

    test('server refusals (own link, same phone) are shown and the code is dropped', () async {
      answer = (_, __) => {'throw': 'That is your own link. Share it with a friend instead.'};
      ReferralCapture.debugInstallReferrer = () async => 'nwsb_ref=MYOWN123';
      await ReferralCapture.instance.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final out = await ReferralCapture.instance.onSignedIn('u2');
      expect(out?.attached, isFalse);
      expect(out?.message, contains('own link'));
      expect(ReferralCapture.instance.pending, isNull);
      expect(await ReferralCapture.instance.attachedCode('u2'), isEmpty);
    });

    test('offline keeps the code waiting for the next try', () async {
      answer = (_, __) => {'throw': 'You look offline.', 'code': 'offline'};
      await ReferralCapture.instance.start();
      await ReferralCapture.instance.captureUri(Uri.parse('nowssb://ref?r=AB12CD34'));
      final out = await ReferralCapture.instance.onSignedIn('u3');
      expect(out?.keep, isTrue);
      expect(ReferralCapture.instance.pending?.code, 'AB12CD34');
    });

    test('an older server that credits the welcome set is described honestly', () async {
      answer = (_, __) => {
            'attached': true,
            'welcome': [
              {'type': 'coins', 'coins': 100, 'label': '100 coins'},
            ],
          };
      final out = await ReferralCapture.instance.attach('u4', 'AB12CD34');
      expect(out.attached, isTrue);
      expect(out.welcomeCoins, 0);
      expect(out.message, contains('100 coins'));
    });
  });
}
