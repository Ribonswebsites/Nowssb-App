/// Phone-size PNG renders of the newui Progress page (flag on, reduced motion).
/// Writes /workspace/screens/progress-1..4.png when the folder exists.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/progress/newui/progress_new_screen.dart';

ProgressView _view({int sessions = 12}) => ProgressView(
      streak: 4,
      totalSessions: sessions,
      totalMinutes: sessions == 0 ? 0 : 96,
      uniqueWords: sessions == 0 ? 0 : 7,
      todaySessions: sessions == 0 ? 0 : 1,
      weekPercent: sessions == 0 ? 0 : 57,
      week: [
        for (var i = 0; i < 7; i++)
          (date: '2026-10-${7 + i}', done: sessions > 0 && i >= 2 && i <= 6 && i != 4, isToday: i == 6, isFuture: false),
      ],
      recent: sessions == 0 ? const [] : const ['Calm', 'Focus', 'Gratitude'],
    );

void main() {
  setUpAll(_loadFonts);

  final cases = <(int, ProgressLoad, ProgressView?)>[
    (1, ProgressLoad.ready, _view()),
    (2, ProgressLoad.ready, _view(sessions: 0)),
    (3, ProgressLoad.error, null),
    (4, ProgressLoad.offline, _view()),
  ];
  for (final (n, load, view) in cases) {
    testWidgets('progress shot $n ($load)', (t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: true), child: child!),
          home: ProgressNewScreen(load: load, view: view, onBack: () {}, onRetry: () {}, onStart: () {}),
        ),
      ));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      final dir = Directory('/workspace/screens');
      if (!dir.existsSync()) return;
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 3.0);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/progress-$n.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
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
