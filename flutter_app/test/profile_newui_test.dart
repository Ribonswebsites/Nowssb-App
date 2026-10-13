import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/profile/new_profile_page.dart';
import 'package:nowssb/pages/profile/profile_data.dart';
import 'package:nowssb/pages/profile/profile_flag.dart';

class _Src implements ProfileSource {
  _Src(this.fn);
  final Future<ProfileData> Function() fn;
  int calls = 0;
  @override
  Future<ProfileData> load() {
    calls++;
    return fn();
  }
}

const _full = ProfileData(name: 'Ribon', signedIn: true, streak: 5, minutes: 42, sessions: 9, level: 3, week: [true, true, false, false, false, false, false]);

Widget _app(ProfileSource s, {ProfileNav? nav}) => MaterialApp(
      home: NewProfilePage(source: s, animate: false, onNavigate: nav ?? (_, __) {}),
    );

void main() {
  test('flag: off for users by default, on for admins, remote can enable', () {
    expect(resolveNewUiProfile(isAdmin: false), isFalse);
    expect(resolveNewUiProfile(isAdmin: false, remote: false), isFalse);
    expect(resolveNewUiProfile(isAdmin: false, remote: true), isTrue);
    expect(resolveNewUiProfile(isAdmin: true, remote: false), isTrue);
  });

  testWidgets('flag gate shows legacy when off and new UI when on', (t) async {
    ProfileFlag.debugOverride = false;
    await t.pumpWidget(MaterialApp(home: ProfileFlagGate(newUi: (_) => const Text('new'), legacy: (_) => const Text('old'))));
    expect(find.text('old'), findsOneWidget);
    ProfileFlag.debugOverride = true;
    await t.pumpWidget(MaterialApp(home: ProfileFlagGate(key: UniqueKey(), newUi: (_) => const Text('new'), legacy: (_) => const Text('old'))));
    expect(find.text('new'), findsOneWidget);
    ProfileFlag.debugOverride = null;
  });

  testWidgets('loading then ready with stats', (t) async {
    await t.pumpWidget(_app(_Src(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return _full;
    })));
    expect(find.byKey(const Key('profile-loading')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 60));
    await t.pump();
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.text('Ribon'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('empty state', (t) async {
    await t.pumpWidget(_app(_Src(() async => const ProfileData(name: 'New'))));
    await t.pump();
    expect(find.byKey(const Key('profile-empty')), findsOneWidget);
    expect(find.byKey(const Key('stat-streak')), findsNothing);
  });

  testWidgets('error state retries', (t) async {
    var fail = true;
    final s = _Src(() async {
      if (fail) throw Exception('boom');
      return _full;
    });
    await t.pumpWidget(_app(s));
    await t.pump();
    expect(find.byKey(const Key('profile-error')), findsOneWidget);
    fail = false;
    await t.tap(find.byKey(const Key('profile-retry')));
    await t.pump();
    await t.pump();
    expect(find.byKey(const Key('profile-ready')), findsOneWidget);
    expect(s.calls, 2);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(_Src(() async => throw const ProfileOffline())));
    await t.pump();
    expect(find.byKey(const Key('profile-offline')), findsOneWidget);
  });

  testWidgets('main flow: links navigate', (t) async {
    final went = <String>[];
    await t.pumpWidget(_app(_Src(() async => _full), nav: (_, x) => went.add(x)));
    await t.pump();
    await t.tap(find.byKey(const Key('profile-settings')));
    await t.tap(find.byKey(const Key('profile-link-progress')));
    await t.scrollUntilVisible(find.byKey(const Key('profile-link-subscription')), 100);
    await t.tap(find.byKey(const Key('profile-link-subscription')));
    expect(went, ['settings', 'progress', 'subscription']);
  });
}
