// A notification tapped before sign-in waits for the shell; when the shell
// attaches (from its initState) the route must not run inside that build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/features/notifications/notif_router.dart';
import 'package:nowssb/screens/store/request_words.dart';

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    NotifRouter.instance.attach(context, goTab: (t) => setState(() => tab = t), popToRoot: () {});
  }

  @override
  void dispose() {
    NotifRouter.instance.detach(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('tab $tab');
}

void main() {
  testWidgets('a pending tab route is applied after the shell is built', (tester) async {
    NotifRouter.instance.markReady();
    NotifRouter.instance.open('store');
    await tester.pumpWidget(const MaterialApp(home: _Shell()));
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(find.text('tab 3'), findsOneWidget);
  });

  testWidgets('a pending screen route is pushed after the shell is built', (tester) async {
    NotifRouter.instance.markReady();
    NotifRouter.instance.open('requests');
    await tester.pumpWidget(const MaterialApp(home: _Shell()));
    expect(tester.takeException(), isNull);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('tab 0', skipOffstage: false), findsOneWidget);
    expect(find.byType(RequestWordsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
