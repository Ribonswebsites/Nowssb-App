// Every pop-up goes away with a swipe (up or sideways), not by waiting.
// SWIPE_SHOTS=<dir> also writes mid-swipe frames as PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/notifications.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/widgets/notification_popup.dart';
import 'package:nowssb/widgets/swipe_away.dart';

NotifItem _n(String title, int m) => NotifItem(
    type: 'routine', title: title, body: 'Body of $title', at: 1000 + m, read: false);

final _shotKey = GlobalKey();
int _frame = 0;

Future<void> _shot(WidgetTester t, String name) async {
  final dir = Platform.environment['SWIPE_SHOTS'];
  if (dir == null) return;
  await t.pump();
  final ro = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$dir/${(_frame++).toString().padLeft(2, '0')}_$name.png');
    f.writeAsBytesSync(b!.buffer.asUint8List());
  });
}

class _Harness extends StatefulWidget {
  const _Harness({required this.items, this.progress, required this.log});
  final List<NotifItem> items;
  final ProgressItem? progress;
  final List<String> log;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late final items = [...widget.items];
  late ProgressItem? progress = widget.progress;
  bool shown = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: RepaintBoundary(
          key: _shotKey,
          child: Scaffold(
            backgroundColor: const Color(0xFF1B2A41),
            body: Stack(children: [
              if (shown && (items.isNotEmpty || progress != null))
                Positioned(
                  top: 40,
                  left: 12,
                  right: 12,
                  child: NotificationRow(
                    items: items,
                    progress: progress,
                    onOpen: (i) => widget.log.add('open ${i.title}'),
                    onDismiss: (i) => setState(() {
                      widget.log.add('dismiss ${i.title}');
                      items.remove(i);
                    }),
                    onDismissProgress: () => setState(() {
                      widget.log.add('dismiss progress');
                      progress = null;
                    }),
                    onViewAll: () => widget.log.add('view all'),
                    onClearAll: () => setState(() {
                      widget.log.add('clear all');
                      items.clear();
                    }),
                    onDismissAll: () => setState(() {
                      widget.log.add('dismiss row');
                      shown = false;
                    }),
                  ),
                ),
            ]),
          ),
        ),
      );
}

List<String> _haptics(WidgetTester t) {
  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
    if (c.method == 'HapticFeedback.vibrate') calls.add('${c.arguments}');
    return null;
  });
  return calls;
}

void main() {
  NotificationRow.networkThumbs = false;
  setUpAll(() async {
    final f = File('/usr/share/fonts/truetype/sand-box/google/Roboto/Roboto-VariableFont_wdth,wght.ttf');
    if (f.existsSync()) {
      await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
    }
  });

  testWidgets('swipe up on one card removes only that card, with haptic', (t) async {
    final h = _haptics(t);
    final log = <String>[];
    await t.pumpWidget(_Harness(items: [_n('First', 1), _n('Second', 2), _n('Third', 3)], log: log));
    await t.pumpAndSettle();
    final card = find.byKey(const ValueKey('n-routine|1001|First'));
    expect(card, findsOneWidget);
    final g = await t.startGesture(t.getCenter(card));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -30));
    await _shot(t, 'card_mid_swipe_up');
    await g.up();
    await t.pumpAndSettle();
    expect(log, ['dismiss First']);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(h, contains('HapticFeedbackType.lightImpact'));
    await _shot(t, 'card_gone_rest_remain');
  });

  testWidgets('single card goes away sideways', (t) async {
    final h = _haptics(t);
    final log = <String>[];
    await t.pumpWidget(_Harness(items: [_n('Only', 1)], log: log));
    await t.pumpAndSettle();
    final g = await t.startGesture(t.getCenter(find.text('Only')));
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(30, 0));
    }
    await _shot(t, 'single_mid_swipe_right');
    await g.up();
    await t.pumpAndSettle();
    expect(log, ['dismiss Only']);
    expect(h, isNotEmpty);
  });

  for (final dir in [const Offset(0, -120), const Offset(-200, 0), const Offset(200, 0)]) {
    testWidgets('header swipe $dir hides the whole row', (t) async {
      final log = <String>[];
      await t.pumpWidget(_Harness(items: [_n('A', 1), _n('B', 2)], log: log));
      await t.pumpAndSettle();
      await t.drag(find.byKey(const ValueKey('notif-row-header')), dir);
      await t.pumpAndSettle();
      expect(log, ['dismiss row']);
      expect(find.byType(NotificationRow), findsNothing);
    });
  }

  testWidgets('progress card swipes up away', (t) async {
    final log = <String>[];
    await t.pumpWidget(_Harness(
        items: [_n('A', 1)],
        progress: const ProgressItem(kind: ProgressKind.tasks, title: 'Downloading', done: 3, total: 10),
        log: log));
    await t.pumpAndSettle();
    await t.drag(find.byKey(ValueKey('progress-${ProgressKind.tasks}')), const Offset(0, -100));
    await t.pumpAndSettle();
    expect(log, ['dismiss progress']);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('View all and Clear all still work', (t) async {
    final log = <String>[];
    await t.pumpWidget(_Harness(items: [_n('A', 1), _n('B', 2)], log: log));
    await t.pumpAndSettle();
    await t.tap(find.text('View all'));
    await t.pumpAndSettle();
    await t.tap(find.text('Clear all'));
    await t.pumpAndSettle();
    expect(log, ['view all', 'clear all']);
  });

  testWidgets('SwipeAway: short drag springs back, tap still taps', (t) async {
    var gone = 0, taps = 0;
    await t.pumpWidget(MaterialApp(
        home: Center(
            child: SwipeAway(
                onDismissed: () => gone++,
                onTap: () => taps++,
                child: const SizedBox(width: 200, height: 60, key: ValueKey("box"), child: ColoredBox(color: Colors.red))))));
    await t.timedDrag(find.byKey(const ValueKey("box")), const Offset(0, -25), const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(gone, 0);
    await t.tap(find.byKey(const ValueKey("box")));
    expect(taps, 1);
    await t.fling(find.byKey(const ValueKey("box")), const Offset(-60, 0), 1200);
    await t.pumpAndSettle();
    expect(gone, 1);
  });

  testWidgets('snackbars swipe away sideways (app theme)', (t) async {
    await t.pumpWidget(MaterialApp(
        theme: ThemeData(snackBarTheme: const SnackBarThemeData(dismissDirection: DismissDirection.horizontal)),
        home: Scaffold(
            body: Builder(
                builder: (c) => TextButton(
                    onPressed: () => ScaffoldMessenger.of(c)
                        .showSnackBar(const SnackBar(content: Text('Saved'), duration: Duration(minutes: 1))),
                    child: const Text('go'))))));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.drag(find.text('Saved'), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });
}
