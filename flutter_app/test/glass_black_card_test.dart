import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/glass_black_card.dart';
import 'package:nowssb/widgets/sections/section_config.dart';
import 'package:nowssb/widgets/sections/section_registry.dart';

void main() {
  testWidgets('GlassBlackCard renders title, child and tap', (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GlassBlackCard(
          title: 'Header',
          onTap: () => taps++,
          child: const Text('Body'),
        ),
      ),
    ));
    expect(find.text('Header'), findsOneWidget);
    await t.tap(find.text('Body'));
    expect(taps, 1);
  });

  test('glassCard round-trips and defaults off', () {
    final s = SectionStyle.fromJson({'glassCard': true, 'glassTitle': 'X', 'glassIntensity': 0.3, 'zz': 1});
    expect(s.glassCard, isTrue);
    expect(SectionStyle.fromJson(s.toJson()).glassIntensity, 0.3);
    expect(SectionStyle.fromJson({}).glassCard, isFalse);
  });

  testWidgets('registry wraps only when glassCard is true', (t) async {
    ensureSectionRegistry();
    final r = SectionRegistry.instance;
    final base = r.defaultConfigFor(SectionTypeId.cardRow, id: 'x');
    for (final on in [false, true]) {
      final cfg = base.copyWith(style: base.style.copyWith(glassCard: on));
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (c) => r.build(c, cfg))),
      ));
      expect(find.byType(GlassBlackCard), on ? findsOneWidget : findsNothing);
    }
  });
}
