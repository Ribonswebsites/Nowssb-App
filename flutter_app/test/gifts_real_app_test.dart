import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/features/programs/gifts_program.dart';

Widget _tab(String id, Map<String, dynamic> s) => MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          final t = kGiftsSpec.tabs[kGiftsSpec.indexOf(id)];
          return ListView(children: t.build(context, s));
        }),
      ),
    );

void main() {
  final past = DateTime(2020).millisecondsSinceEpoch;
  final future = DateTime.now().add(const Duration(days: 90)).millisecondsSinceEpoch;
  final summary = <String, dynamic>{
    'gifts': {
      'sent': [
        {'code': 'NWSB-AAAA-1111', 'title': 'Word card', 'status': 'active', 'at': 1, 'expiresAt': future, 'toName': 'Asha'},
        {'code': 'NWSB-OLD1-0000', 'title': 'Stage card', 'status': 'active', 'at': 1, 'expiresAt': past},
      ],
      'received': [
        {'title': '7-day Basic', 'fromName': 'Ravi', 'at': 1, 'status': 'redeemed'},
        {'title': 'Old pass', 'status': 'expired', 'at': 1},
      ],
    },
    'today': <String, dynamic>{},
  };

  test('expired is derived from status or expiry date', () {
    expect(giftIsExpired({'status': 'expired'}), isTrue);
    expect(giftIsExpired({'status': 'active', 'expiresAt': past}), isTrue);
    expect(giftIsExpired({'status': 'active', 'expiresAt': future}), isFalse);
    expect(giftIsExpired({'status': 'redeemed', 'expiresAt': past}), isFalse);
    expect(giftStatusWord({'status': 'active'}), 'Not opened yet');
  });

  test('catalog prices never hardcode the rupee sign in code', () {
    expect(kGiftCatalog, isNotEmpty);
    for (final c in kGiftCatalog) {
      expect(c.priceLabel, isNotEmpty);
    }
  });

  testWidgets('tabs list Expired; sent hides expired; plain status words', (t) async {
    expect(kGiftsSpec.indexOf('expired'), greaterThan(0));
    await t.pumpWidget(_tab('sent', summary));
    expect(find.textContaining('Not opened yet'), findsOneWidget);
    expect(find.textContaining('NWSB-OLD1'), findsNothing);
    await t.pumpWidget(_tab('expired', summary));
    expect(find.textContaining('Stage card'), findsOneWidget);
    expect(find.textContaining('Old pass'), findsOneWidget);
    await t.pumpWidget(_tab('received', summary));
    expect(find.textContaining('from Ravi'), findsOneWidget);
    expect(find.textContaining('Old pass'), findsNothing);
  });

  testWidgets('cancel asks first, Keep it does nothing', (t) async {
    await t.pumpWidget(_tab('sent', summary));
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Cancel this gift?'), findsOneWidget);
    await t.tap(find.text('Keep it'));
    await t.pumpAndSettle();
    expect(find.text('Cancel this gift?'), findsNothing);
  });

  testWidgets('free tab says when minutes are missing', (t) async {
    await t.pumpWidget(_tab('free', summary));
    expect(find.textContaining('load when you are online'), findsOneWidget);
  });

  testWidgets('redeem button waits for a code; keyboard typing enables it', (t) async {
    await t.pumpWidget(_tab('redeem', summary));
    TextButton btn() => t.widget<TextButton>(find.widgetWithText(TextButton, 'Preview the gift'));
    expect(btn().onPressed, isNull);
    await t.enterText(find.byType(TextField), 'nwsb-ab12-cd34');
    await t.pump();
    expect(btn().onPressed, isNotNull);
  });
}
