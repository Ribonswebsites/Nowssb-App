import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/features/gifts/gift_unwrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Gift unwrap: closed, mid-unwrap, revealed', (tester) async {
    await tester.runAsync(_loadRoboto);
    await tester.binding.setSurfaceSize(const Size(412, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: ColoredBox(color: Colors.black, child: Center(child: RepaintBoundary(key: ValueKey('shot'), child: ColoredBox(color: Colors.black, child: SizedBox(width: 412, height: 240,
        child: GiftUnwrapReveal(child: Center(child: Text('Your gift card', style: TextStyle(color: Colors.white, fontSize: 20))))))))),
    ));
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('gift_unwrap_closed.png'));
    await tester.tap(find.byType(GiftUnwrapReveal));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('gift_unwrap_mid.png'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Your gift card'), findsOneWidget);
  });
}

Future<void> _loadRoboto() async {
  final dir = Directory('/home/box/flutter/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  final icons = File('/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
  }
}
