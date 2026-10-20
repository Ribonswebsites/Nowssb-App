import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/nowssb_ui/tickets.dart';
import 'package:nowssb/widgets/n_motion.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/screens/normal/horizontal_routine_cards.dart';

void main() {
  testWidgets('every NCardCarousel card acts when tapped, and the rail snaps', (t) async {
    final hits = <int>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NCardCarousel(
          height: 300,
          cardWidth: 200,
          items: [
            for (var i = 0; i < 4; i++)
              NCarouselItem(title: 'Card $i', onCta: () => hits.add(i)),
          ],
        ),
      ),
    ));
    await t.pump();
    final list = t.widget<ListView>(find.byType(ListView));
    expect(list.physics, isA<SnapRailPhysics>());
    for (var i = 0; i < 4; i++) {
      final card = find.text('Card $i');
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      await t.tap(card, warnIfMissed: false);
      await t.pump();
    }
    expect(hits, [0, 1, 2, 3]);
  });

  testWidgets('showNDialog opens, closes on barrier tap; reduce motion is instant', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => showNDialog<void>(context: c, builder: (_) => const AlertDialog(title: Text('Hi'))),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Hi'), findsOneWidget);
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(find.text('Hi'), findsNothing);

    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (c) => TextButton(
            onPressed: () => showNSheet<void>(context: c, builder: (_) => const Text('Sheet')),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump();
    expect(find.text('Sheet'), findsOneWidget);
  });

  testWidgets('Home routine cards open the Library tab instead of nothing', (t) async {
    final tabs = <int>[];
    await t.pumpWidget(MaterialApp(
      home: NavScope(
        go: tabs.add,
        child: Builder(
          builder: (c) => TextButton(
            onPressed: () => openRoutineCard(c, 'Meditation'),
            child: const Text('card'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('card'));
    await t.pump();
    expect(tabs, [2]);
  });
}
