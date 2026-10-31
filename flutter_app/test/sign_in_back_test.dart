import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/screens/nwsb_sign_in_sheet.dart';

import 'fake_video_platform.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(FakeVideoPlatform.new);

  testWidgets('Android back on the sign-in page: Sign Up → Log In → closes',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () async => result = await NwsbSignInPage.open(c),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final toggle = find.textContaining("Don't have an account?");
    await tester.ensureVisible(toggle);
    await tester.tap(toggle, warnIfMissed: false);
    await tester.pump();
    expect(find.textContaining('Already have an account?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining("Don't have an account?"), findsOneWidget,
        reason: 'back closed the page from Sign Up instead of returning to Log In');

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('open'), findsOneWidget);
    expect(result, isNot(true));
  });
}
