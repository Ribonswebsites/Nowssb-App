// Compact pop-up + per-category SVG badge. Set NOTIF_SHOTS=<dir> to also
// write one PNG per category (real Roboto, over a real app background).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/notifications.dart';
import 'package:nowssb/widgets/notification_popup.dart';
import 'support/test_fonts.dart';

const samples = <String, (String, String)>{
  'routine': ('Today’s word: Shanti', 'Peace that settles the mind. Two minutes to say it with intent.'),
  'streak': ('Keep your 12-day streak', 'You have not practised today. One word keeps it alive.'),
  'reader': ('Time to read', 'Pick up “The Sound of Calm” where you left off, page 42.'),
  'coins': ('40 coins are waiting', 'Collect them before midnight to keep your bonus.'),
  'rewards': ('Quest complete', 'You finished 5 sessions this week. Your reward is ready.'),
  'gifts': ('Anaya sent you a gift', 'Open your gift box to see what is inside.'),
  'spin': ('Your daily spin is ready', 'Spin the wheel for coins and coupons.'),
  'update': ('New in NowssB', 'The Rewards hub is here, with Free coins and Coinback.'),
  'offers': ('20% off Meaning Store', 'This weekend only, on every word print.'),
  'subscription': ('Your plan renews soon', 'NowssB Plus renews on 2 Nov. Manage it anytime.'),
  'orders': ('Order confirmed', 'Your Signature print #NW-2041 is being prepared.'),
  'support': ('Reply from support', 'We have looked into your question about the Reader.'),
};

void main() {
  test('every NotifStore kind has its own SVG, unknown falls back', () {
    final seen = <String>{};
    for (final k in NotifStore.allKinds) {
      final a = NotifCategoryBadge.assetFor(k);
      expect(a, isNot(NotifCategoryBadge.fallback), reason: k);
      expect(File(a).existsSync(), isTrue, reason: a);
      expect(seen.add(a), isTrue);
    }
    expect(NotifCategoryBadge.assetFor('nope'), NotifCategoryBadge.fallback);
    expect(File(NotifCategoryBadge.fallback).existsSync(), isTrue);
  });

  NotificationRow.networkThumbs = false;
  testWidgets('compact pop-up renders a badge per category', (t) async {
    final shots = Platform.environment['NOTIF_SHOTS'];
    ui.Image? bg;
    await t.runAsync(() async {
      await loadRoboto();
      final bgFile = File('assets/video/hero-bg-poster.webp');
      if (shots != null && bgFile.existsSync()) {
        final c = await ui.instantiateImageCodec(bgFile.readAsBytesSync());
        bg = (await c.getNextFrame()).image;
      }
    });
    t.view.physicalSize = const Size(1179, 640);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    expect(NotificationRow.cardHeight, lessThan(114));
    for (final e in samples.entries) {
      final key = GlobalKey();
      await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: RepaintBoundary(
          key: key,
          child: Stack(fit: StackFit.expand, children: [
            if (bg != null) RawImage(image: bg, fit: BoxFit.cover) else const ColoredBox(color: Color(0xFF2B2140)),
            Positioned(
              left: 12,
              right: 12,
              top: 40,
              child: NotificationRow(
                items: [
                  NotifItem(type: e.key, title: e.value.$1, body: e.value.$2, at: 1, read: false),
                  NotifItem(type: 'coins', title: 'x', body: 'y', at: 0, read: false),
                ],
                onOpen: (_) {},
                onDismiss: (_) {},
                onViewAll: () {},
                onClearAll: () {},
              ),
            ),
          ]),
        ),
      ));
      await t.pump();
      expect(find.byKey(ValueKey('notif-icon-${e.key}')), findsOneWidget);
      final svg = t.widget<SvgPicture>(find.byKey(ValueKey('notif-icon-${e.key}')));
      expect((svg.bytesLoader as SvgAssetLoader).assetName, NotifCategoryBadge.assetFor(e.key));
      if (shots != null) {
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await t.pump();
        await t.runAsync(() async {
          final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await ro.toImage(pixelRatio: 3);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/notif-popup-${e.key}.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }
  });
}
