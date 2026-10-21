/// Progress empty state, in its own file so the PracticeProgress singleton
/// starts with no sessions (each test file runs in its own isolate).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/progress/progress_complete.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _bg = Positioned.fill(child: Image.asset('assets/video/subscription-bg-poster.webp', fit: BoxFit.cover));

void main() {
  setUpAll(_loadFonts);

  testWidgets('progress-home shot 7 (empty state)', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({kProgressGuideSeenKey: true});
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
        home: ProgressCompleteView(backdrop: _bg, onPractice: () {}),
      ),
    ));
    await t.runAsync(() => precacheImage((_bg.child as Image).image, key.currentContext!));
    await t.pumpAndSettle();
    expect(PracticeProgress.instance.totalSessions, 0);
    expect(find.text('Begin your first sit'), findsOneWidget);
    expect(t.takeException(), isNull);
    final dir = Directory('/workspace/screens');
    if (!dir.existsSync()) return;
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/progress-home-7.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/box/sdk/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
    if (n.startsWith('MaterialIcons')) icons.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await roboto.load();
  await icons.load();
}
