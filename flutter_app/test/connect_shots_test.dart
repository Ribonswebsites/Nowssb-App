import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';
import 'support/test_fonts.dart';

// flutter test test/connect_shots_test.dart --dart-define=CONNECT_SHOTS=/out
const _out = String.fromEnvironment('CONNECT_SHOTS');

Map<String, dynamic> _p(String id, String text, int minsAgo, {bool mine = false, String image = ''}) =>
    {'id': id, 'text': text, 'mine': mine, 'image': image, 'at': DateTime.now().subtract(Duration(minutes: minsAgo)).millisecondsSinceEpoch};

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
  });
  final key = GlobalKey();
  for (final cfg in [(320.0, 1.3, '320@1.3x'), (390.0, 1.0, '390')]) {
    for (final empty in [false, true]) {
      testWidgets('connect shot ${cfg.$3} empty=$empty', (t) async {
        if (_out.isEmpty) return;
        SharedPreferences.setMockInitialValues({});
        NormalLoop.debugT = .4;
        addTearDown(() => NormalLoop.debugT = null);
        final h = empty ? 1000.0 : 2000.0;
        t.view.physicalSize = Size(cfg.$1 * cfg.$2, h * cfg.$2);
        t.view.devicePixelRatio = cfg.$2;
        addTearDown(t.view.reset);
        ConnectScreen.debugImage = (_) => Image.asset('assets/banners/course-bubble.jpg', fit: BoxFit.cover);
        addTearDown(() => ConnectScreen.debugImage = null);
        EconomyApi.debugHandler = (name, data) async => {
              'day': '20261102', 'today': '20261102', 'readOnly': false,
              'word': 'TEJAS', 'meaning': 'Inner radiance — the warm, steady light of a clear mind.',
              'postsLeft': empty ? 3 : 2, 'days': ['20261101', '20261031', '20261030'],
              'posts': empty
                  ? []
                  : [
                      _p('a', 'Sat with the bowl for ten minutes before work. The hum stayed with me all morning.', 6),
                      _p('q', encodeQuote('Silence is a source of great strength.', 'Lao Tzu'), 34),
                      _p('b', 'Evening light after practice.', 95, image: 'connect/x/1730000000000.jpg'),
                      _p('c', 'Lit a lamp and breathed slowly. Small, but it helped.', 180, mine: true),
                    ],
            };
        addTearDown(() => EconomyApi.debugHandler = null);
        await t.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (c, child) => RepaintBoundary(key: key, child: child),
          home: const ConnectScreen(),
        ));
        for (var i = 0; i < 15; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final img = await ro.toImage(pixelRatio: cfg.$2);
          final b = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/connect_${cfg.$3}${empty ? '_empty' : ''}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(b!.buffer.asUint8List());
        });
      });
    }
  }
}
