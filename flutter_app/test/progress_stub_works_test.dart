import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/progress/progress_screen.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(void Function(int) go) => NavScope(
      go: go,
      child: MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(c).push(MaterialPageRoute(
                    builder: (_) => const PracticeProgressScreen())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows clear text and both controls', (t) async {
    await t.pumpWidget(_host((_) {}));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Your progress lives on your Profile'), findsOneWidget);
    expect(find.text('Open my Profile'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('back arrow pops the page', (t) async {
    await t.pumpWidget(_host((_) {}));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.byType(PracticeProgressScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Android system back pops the page', (t) async {
    await t.pumpWidget(_host((_) {}));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(PracticeProgressScreen), findsNothing);
  });

  testWidgets('Open my Profile leaves the page and switches to tab 4', (t) async {
    final tabs = <int>[];
    await t.pumpWidget(_host(tabs.add));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Open my Profile'));
    await t.pumpAndSettle();
    expect(tabs, [4]);
    expect(find.byType(PracticeProgressScreen), findsNothing);
  });

  testWidgets('small screen + big text does not overflow', (t) async {
    t.view.physicalSize = const Size(320 * 2, 480 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: const MaterialApp(home: PracticeProgressScreen()),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
