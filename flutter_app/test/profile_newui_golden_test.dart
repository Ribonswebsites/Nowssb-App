import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/profile/milestones.dart';
import 'package:nowssb/pages/profile/new_profile_page.dart';
import 'package:nowssb/pages/profile/profile_data.dart';

class _Src implements ProfileSource {
  _Src(this.fn);
  final Future<ProfileData> Function() fn;
  @override
  Future<ProfileData> load() => fn();
}

const _full = ProfileData(name: 'Ribon', signedIn: true, streak: 4, minutes: 72, sessions: 12, level: 3, week: [true, true, true, true, false, false, false]);

Future<void> _shot(WidgetTester t, ProfileSource s, String name) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: NewProfilePage(source: s, animate: false, backdrop: const ColoredBox(color: Colors.black), onNavigate: (_, __) {})));
  await t.pump();
  await t.pump();
  await expectLater(find.byType(NewProfilePage), matchesGoldenFile('goldens/profile_newui_$name.png'));
}

void main() {
  test('milestones are earned only from real numbers', () {
    final m = milestonesFor(_full);
    expect(m.where((x) => x.earned).map((x) => x.id), ['first', 'streak3', 'min60']);
    expect(milestonesFor(const ProfileData(name: 'x')).any((x) => x.earned), isFalse);
  });

  testWidgets('milestone badges render earned/locked', (t) async {
    await t.pumpWidget(MaterialApp(home: NewProfilePage(source: _Src(() async => _full), animate: false, backdrop: const ColoredBox(color: Colors.black), onNavigate: (_, __) {})));
    await t.pump();
    await t.scrollUntilVisible(find.byKey(const Key('profile-milestones')), 100);
    expect(find.byKey(const Key('milestone-streak3-on')), findsOneWidget);
    expect(find.byKey(const Key('milestone-streak7-off')), findsOneWidget);
    expect(find.textContaining('3 of 5'), findsOneWidget);
  });

  testWidgets('reduce-motion: page renders and settles with no running animation', (t) async {
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: NewProfilePage(source: _Src(() async => _full), backdrop: const ColoredBox(color: Colors.black), onNavigate: (_, __) {})),
    ));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profile-hero')), findsOneWidget);
  });

  testWidgets('golden: ready', (t) => _shot(t, _Src(() async => _full), 'ready'));
  testWidgets('golden: empty', (t) => _shot(t, _Src(() async => const ProfileData(name: 'New friend')), 'empty'));
  testWidgets('golden: error', (t) => _shot(t, _Src(() async => throw Exception('x')), 'error'));
  testWidgets('golden: offline', (t) => _shot(t, _Src(() async => throw const ProfileOffline()), 'offline'));
}
