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

Map<String, dynamic> _p(String id, String text, String feeling, int felt, {bool me = false, bool mine = false, String image = ''}) =>
    {'id': id, 'text': text, 'feeling': feeling, 'felt': felt, 'feltByMe': me, 'mine': mine, 'image': image, 'at': DateTime(2026, 11, 2, 9 + felt % 8, 12).millisecondsSinceEpoch};

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
  });
  final key = GlobalKey();
  for (final cfg in [(320.0, 1.3, '320@1.3x'), (390.0, 1.0, '390')]) {
    for (final guide in [false, true]) {
      testWidgets('connect shot ${cfg.$3} guide=$guide', (t) async {
        if (_out.isEmpty) return;
        SharedPreferences.setMockInitialValues({if (!guide) 'nwsb_connect_board_guide_v1': true});
        NormalLoop.debugT = .4;
        addTearDown(() => NormalLoop.debugT = null);
        final h = guide ? 780.0 : 1700.0;
        t.view.physicalSize = Size(cfg.$1 * cfg.$2, h * cfg.$2);
        t.view.devicePixelRatio = cfg.$2;
        addTearDown(t.view.reset);
        ConnectScreen.debugImage = (_) => const DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3D9A4), Color(0xFFB7C6E6)], begin: Alignment.topLeft, end: Alignment.bottomRight)));
        addTearDown(() => ConnectScreen.debugImage = null);
        EconomyApi.debugHandler = (name, data) async => {
              'day': '20261102', 'today': '20261102', 'readOnly': false,
              'word': 'TEJAS', 'meaning': 'Inner radiance — the warm, steady light of a clear mind.',
              'postsLeft': 2, 'days': ['20261101', '20261031', '20261030'],
              'posts': [
                _p('a', 'Felt it on the morning walk. The sun on my face and nothing to prove.', 'warm', 12, me: true),
                _p('b', 'Hard week. Reading this word helped me sit a little straighter.', 'tender', 7, image: 'connect/x/1.jpg'),
                _p('c', 'Lit a lamp before work today.', 'calm', 3, mine: true),
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
          File('$_out/connect_${cfg.$3}${guide ? '_guide' : ''}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(b!.buffer.asUint8List());
        });
      });
    }
  }
}
