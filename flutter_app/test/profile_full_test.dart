import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/profile_parts/edit_profile.dart';
import 'package:nowssb/screens/profile_parts/profile_guide.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first-use guide steps through and is remembered', (t) async {
    var done = false;
    await t.pumpWidget(MaterialApp(home: ProfileGuide(onDone: () => done = true)));
    expect(find.text('Your profile'), findsOneWidget);
    await t.tap(find.byKey(const Key('guide-next')));
    await t.pump();
    expect(find.text('Progress & streak'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('guide-next')));
      await t.pumpAndSettle();
    }
    expect(done, isTrue);
    expect(await ProfileGuide.shouldShow(), isFalse);
    await ProfileGuide.reset();
    expect(await ProfileGuide.shouldShow(), isTrue);
  });

  testWidgets('guide Skip finishes immediately', (t) async {
    var done = false;
    await t.pumpWidget(MaterialApp(home: ProfileGuide(onDone: () => done = true)));
    await t.tap(find.byKey(const Key('guide-skip')));
    await t.pumpAndSettle();
    expect(done, isTrue);
  });

  testWidgets('edit profile validates and returns name and motto', (t) async {
    EditProfileResult? res;
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => TextButton(
      onPressed: () async => res = await Navigator.of(c).push<EditProfileResult>(MaterialPageRoute(builder: (_) => const EditProfileScreen(name: 'Ribon', motto: '', avatar: ColoredBox(color: Colors.grey)))),
      child: const Text('open')))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('edit-name')), 'R');
    await t.tap(find.byKey(const Key('edit-save')));
    await t.pump();
    expect(find.text('Name needs at least 2 letters'), findsOneWidget);
    await t.enterText(find.byKey(const Key('edit-name')), 'Ribon P');
    await t.enterText(find.byKey(const Key('edit-motto')), 'Breathe.');
    await t.tap(find.byKey(const Key('edit-save')));
    await t.pumpAndSettle();
    expect(res?.name, 'Ribon P');
    expect(res?.motto, 'Breathe.');
  });
}
