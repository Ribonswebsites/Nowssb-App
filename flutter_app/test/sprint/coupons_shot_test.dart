import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/widgets/coupon_ticket_shape.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Coupon ticket renders (perforation, stub, foil)', (tester) async {
    await tester.runAsync(_loadRoboto);
    await tester.binding.setSurfaceSize(const Size(412, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const Scaffold(backgroundColor: Colors.black, body: RepaintBoundary(key: ValueKey('shot'), child: Padding(
        padding: EdgeInsets.all(20),
        child: CouponTicket(
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('ALREADY SCRATCHED TODAY', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.6, fontSize: 11, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('You won 20% off', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          ]),
          stub: Icon(Icons.local_activity, color: Color(0xFFE4C56A), size: 36),
        ),
      ))),
    ));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 1600));
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('coupon_ticket.png'));
    await tester.pump(const Duration(seconds: 5));
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
