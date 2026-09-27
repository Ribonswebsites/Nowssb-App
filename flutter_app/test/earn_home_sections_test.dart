import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/features/earn/earn_home_sections.dart';
import 'package:nowssb/screens/nwsb_sign_in_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home earn sections render signed out', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              EarnUmbrellaSection(),
              YourRewardsSection(),
              GiftsHomeSection(),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NowssB Earn'), findsWidgets);
    expect(find.text('Agents, codes, commission'), findsOneWidget);
    expect(find.text('Become an agent'), findsOneWidget);
    expect(find.text('NowssB Rewards'), findsWidgets);
    expect(find.text('NowssB Gifts'), findsWidgets);
    expect(find.text('Sign in to see your rewards'), findsOneWidget);
    expect(find.text('Networking'), findsNothing);
    expect(find.text('Circle'), findsNothing);
  });

  testWidgets('Sign-in shows a real error when Firebase is not ready', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NwsbSignInPage()));
    await tester.pump();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Firebase is not ready in this build.'), findsOneWidget);
  });
}
