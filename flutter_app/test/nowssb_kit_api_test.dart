import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 340, child: w))));

void main() {
  testWidgets('NTicketCard shows CTA by default and hides it when ctaLabel is null', (t) async {
    await t.pumpWidget(_host(const NTicketCard(title: 'Flat 40% off', label: 'Words')));
    expect(find.text('View products >'), findsOneWidget);
    await t.pumpWidget(_host(const NTicketCard(title: 'Flat 40% off', ctaLabel: null)));
    expect(find.byKey(const Key('nticket-cta')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('NTicketCard expired state shows the Expired pill', (t) async {
    await t.pumpWidget(_host(const NTicketCard(title: 'Off', expired: true)));
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('MeditationCard accepts a custom circle widget', (t) async {
    await t.pumpWidget(_host(const MeditationCard(title: 'T', circle: Icon(Icons.spa, key: Key('custom-circle')), blur: 0)));
    expect(find.byKey(const Key('custom-circle')), findsOneWidget);
  });

  testWidgets('MeditationCard Skip calls onSkip (and onSecondary as fallback)', (t) async {
    var skips = 0, legacy = 0;
    await t.pumpWidget(_host(MeditationCard(title: 'T', blur: 0, onSkip: () => skips++)));
    await t.tap(find.byKey(const Key('meditation-skip')));
    expect(skips, 1);
    await t.pumpWidget(_host(MeditationCard(title: 'T', blur: 0, onSecondary: () => legacy++)));
    await t.tap(find.byKey(const Key('meditation-skip')));
    expect(legacy, 1);
  });

  testWidgets('NCardCarousel renders cards', (t) async {
    await t.pumpWidget(_host(const NCardCarousel(height: 420, items: [NCarouselItem(title: 'A'), NCarouselItem(title: 'B')])));
    expect(find.text('A'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
