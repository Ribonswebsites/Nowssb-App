import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/verify_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

const _out = String.fromEnvironment('CONNECT_SHOTS');

void main() {
  setUpAll(loadRoboto);
  final key = GlobalKey();
  for (final c in [('none', null, null), ('pending', null, true), ('gold', 'gold', null)]) {
    testWidgets('verify status ${c.$1}', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(390, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (ctx, child) => RepaintBoundary(key: key, child: child),
        home: VerifyScreen(debugTier: c.$2 ?? (c.$3 == null ? '' : null), debugRequestedAt: c.$3 == true ? DateTime(2026, 11, 4) : null),
      ));
      await t.pump();
      final status = t.widget<Text>(find.byKey(const Key('verify-status'))).data!;
      switch (c.$1) {
        case 'none':
          expect(status, 'Not verified yet');
          expect(find.text('Request verification'), findsOneWidget);
        case 'pending':
          expect(status, startsWith('Pending review'));
          expect(find.text('Request sent'), findsOneWidget);
        case 'gold':
          expect(status, 'Approved · Gold badge');
          expect(find.byKey(const Key('verify-request')), findsNothing);
      }
      if (_out.isEmpty) return;
      final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final img = await ro.toImage(pixelRatio: 1);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/verify_${c.$1}.png')..createSync(recursive: true)..writeAsBytesSync(b!.buffer.asUint8List());
      });
    });
  }
}
