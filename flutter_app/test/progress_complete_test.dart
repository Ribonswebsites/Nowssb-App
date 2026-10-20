/// Progress page: tabs, sub-pages, pop-ups, first-use guide and screenshots.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/progress/progress_complete.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Video can't play in tests: a still frame (poster) of the original video.
final _bg = Positioned.fill(child: Image.asset('assets/video/subscription-bg-poster.webp', fit: BoxFit.cover));

String _d(int back) {
  final n = DateTime.now();
  final d = DateTime(n.year, n.month, n.day - back);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, Object> _seed({bool guideSeen = true}) {
  final sessions = <String, Object>{};
  const words = ['Calm', 'Focus', 'Gratitude', 'Calm'];
  for (var i = 0; i < 4; i++) {
    sessions['${_d(i)}_${words[i]}'] = {'date': _d(i), 'word': words[i], 'completedAt': '${_d(i)}T07:30:00', 'source': 'native-player', 'durationSec': 600};
  }
  return {'nwsb_native_sessions': jsonEncode(sessions), if (guideSeen) kProgressGuideSeenKey: true};
}

var practiced = 0;
Widget _app() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      home: ProgressCompleteView(backdrop: _bg, onPractice: () => practiced++),
    );

Future<void> _phone(WidgetTester t) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3.0;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('overview shows real data and every tab works', (t) async {
    await _phone(t);
    SharedPreferences.setMockInitialValues(_seed());
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    final p = PracticeProgress.instance;
    expect(p.totalSessions, 4);
    expect(find.text('4'), findsWidgets); // streak + sessions
    expect(find.byKey(const ValueKey('progress-guide')), findsNothing);
    await t.tap(find.byKey(const ValueKey('progress-tab-1')));
    await t.pumpAndSettle();
    expect(find.text('Focus'), findsOneWidget);
    await t.tap(find.text('Focus'));
    await t.pumpAndSettle();
    expect(find.text('Length: 10m'), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('progress-tab-2')));
    await t.pumpAndSettle();
    expect(find.text('First sit'), findsOneWidget);
    await t.tap(find.text('Three calm days'));
    await t.pumpAndSettle();
    expect(find.text('Reached. Well done.'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('progress-tab-0')));
    await t.pumpAndSettle();
    await t.tap(find.text('YOUR NUMBERS'));
    await t.pumpAndSettle();
    expect(find.text('MOST PRACTICED'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget); // Calm twice
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(find.text('4 day streak'), findsOneWidget);
    expect(find.text('LAST 28 DAYS'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    final todayIdx = (DateTime.now().weekday + 6) % 7;
    await t.tap(find.byKey(ValueKey('progress-day-$todayIdx')));
    await t.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    await t.tapAt(const Offset(20, 20));
    await t.pumpAndSettle();
    await t.tap(find.text('Practice'));
    expect(practiced, 1);
  });

  testWidgets('first-use guide shows once, steps through and is remembered', (t) async {
    await _phone(t);
    SharedPreferences.setMockInitialValues(_seed(guideSeen: false));
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-guide')), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-guide')), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool(kProgressGuideSeenKey), isTrue);
    await t.tap(find.byTooltip('Show guide'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-guide')), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-guide')), findsNothing);
  });

  // Screenshots: 1 overview, 2 history, 3 milestones, 4 streak, 5 stats, 6 guide, 7 empty.
  for (final n in [1, 2, 3, 4, 5, 6, 7]) {
    testWidgets('progress-complete shot $n', (t) async {
      await _phone(t);
      SharedPreferences.setMockInitialValues(_seed(guideSeen: n != 6));
      if (n == 7) await PracticeProgress.instance.clearAll();
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(key: key, child: _app()));
      await t.runAsync(() => precacheImage((_bg.child as Image).image, key.currentContext!));
      await t.pumpAndSettle();
      if (n == 2) await t.tap(find.byKey(const ValueKey('progress-tab-1')));
      if (n == 3) await t.tap(find.byKey(const ValueKey('progress-tab-2')));
      if (n == 4) await t.tap(find.text('Details'));
      if (n == 5) await t.tap(find.text('YOUR NUMBERS'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final dir = Directory('/workspace/screens');
      if (!dir.existsSync()) return;
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 3.0);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/progress-complete-$n.png').writeAsBytesSync(bytes!.buffer.asUint8List());
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
