/// Full control of a picture: drag inside a picked picture moves it in its
/// frame, pinch zooms in and out freely, eight big handles move each side
/// and corner of the frame; saved as data and drawn the same outside the
/// editor. And photos keep the top (a person's head) when a banner crops.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/image_frame.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/admin/template/ui_overrides.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);
const _pic = 'test.frame.pic';

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A published picture 200×100 at (100, 100).
Widget _published() => Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        Positioned(
          left: 100,
          top: 100,
          child: Builder(
            builder: (context) => slotChrome(context, _pic, SlotType.image, '',
                const SizedBox(width: 200, height: 100, child: ColoredBox(key: ValueKey('pixels'), color: Colors.orange))),
          ),
        ),
        const Positioned(left: 0, top: 260, child: SizedBox(key: ValueKey('below'), width: 10, height: 10)),
      ]),
    );

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({kTouchHintSeen: true});
    VideoPool.instance.debugDropAll();
  });
  tearDown(VideoPool.instance.debugDropAll);

  test('the framing keys read back, clamped; nothing set → no frame', () {
    expect(framingOf(const {}), isNull);
    expect(framingOf(const {'imgZoom': 1.0}), isNull);
    final f = framingOf(const {'imgZoom': 0.1, 'imgX': 0.2, 'frameL': 0.5, 'frameB': -5})!;
    expect(f.zoom, ImageFraming.kMinZoom, reason: 'zoomed out, but not to nothing');
    expect(f.x, 0.2);
    expect(f.frameIn(const Size(200, 100)), rectMoreOrLessEquals(const Rect.fromLTRB(-100, 0, 200, 10)));
  });

  testWidgets('saved crop, offset, zoom and frame → the published app draws them the same', (tester) async {
    addTearDown(() => UiOverrides.instance.removeLocal(_pic));
    final c = EditorController()..pageId = 'test.frame';
    addTearDown(c.dispose);
    c.patchStyle(_pic, SlotType.image, '',
        {'imgZoom': 0.5, 'imgX': 0.25, 'imgY': -0.1, 'frameL': 0.5, 'frameB': 1.0});
    // Through the same JSON the server keeps.
    final saved = jsonDecode(jsonEncode(c.preview.draftOverrides[_pic]!.toJson())) as Map<String, dynamic>;
    expect((saved['style'] as Map).keys, containsAll(['imgZoom', 'imgX', 'imgY', 'frameL', 'frameB']));
    expect((saved['style'] as Map).containsKey('frameT'), isFalse, reason: 'zero edges are not saved');
    UiOverrides.instance.applyLocal(UiOverride.from(saved)!);

    await tester.pumpWidget(_published());
    expect(find.byType(EditorPreviewScope), findsNothing);
    final r = tester.renderObject<RenderImageFrame>(find.byType(ImageFrame));
    expect(r.size, const Size(200, 100), reason: 'the page around it does not move');
    expect(tester.getTopLeft(find.byKey(const ValueKey('below'))).dy, 260);
    expect(r.frame, const Rect.fromLTRB(-100, 0, 200, 200), reason: 'left side out by half, bottom by one');
    // The picture fills the frame (300×200), drawn at half size, centred
    // then moved a quarter right and a tenth up.
    final px = find.byKey(const ValueKey('pixels'));
    expect(tester.getRect(px), rectMoreOrLessEquals(Rect.fromCenter(center: const Offset(100 + 50 + 75, 100 + 100 - 20), width: 150, height: 100)));
    // A tap in the frame but outside the old box still lands on it.
    expect(tester.hitTestOnBinding(const Offset(350, 150)).path.any((e) => e.target == r), isFalse);
  });

  testWidgets('photos keep the top when a wide banner crops them (no cut-off heads)', (tester) async {
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr, child: NetPicture(url: 'assets/none.png')));
    final img = tester.widget<Image>(find.byType(Image));
    expect(img.fit, BoxFit.cover);
    expect((img.alignment as Alignment).y, lessThan(-0.4));
    expect(img.alignment, kPhotoAlignment);
  });

  testWidgets('in the editor: drag pans, pinch zooms out and in, handles resize the frame', (tester) async {
    tester.view.physicalSize = _screen * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
    await _settle(tester, 10);

    // A picture banner near the top.
    c.insertTemplate('imageBanner', 1);
    await _settle(tester, 10);
    PreviewSlot? pic;
    Rect? rect;
    for (final s in c.preview.slots.values) {
      if (s.type != SlotType.image || !s.slotKey.contains('imageBanner')) continue;
      final b = s.box.currentContext?.findRenderObject() as RenderBox?;
      if (b == null || !b.attached || !b.hasSize) continue;
      final r = b.localToGlobal(Offset.zero) & b.size;
      if (r.width >= 120 && r.height >= 70 && r.left >= 0 && r.right <= 412) {
        pic = s;
        rect = r;
        break;
      }
    }
    expect(pic, isNotNull, reason: 'the home page has a picture');
    c.selectIn(null, pic!.slotKey, pic.type, pic.defaultValue);
    await _settle(tester, 3);
    expect(find.byKey(const ValueKey('picture-frame')), findsOneWidget);
    expect(find.byKey(const ValueKey('frame-handle-1-1')), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('frame-handle-1-1'))).width, greaterThanOrEqualTo(24));
    Map<String, dynamic> st() => c.overrideOf(pic!.slotKey)?.style ?? const {};

    // Drag inside: the picture moves, the page does not scroll.
    final at = rect!;
    final g = await tester.startGesture(at.center);
    for (var i = 0; i < 10; i++) {
      await g.moveBy(Offset(at.width / 40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await _settle(tester, 2);
    expect((st()['imgX'] as num).toDouble(), closeTo(0.25, 0.08));

    // Pinch out of it: smaller than it was (zoom out), then far in.
    Future<void> pinch(double from, double to) async {
      final a = await tester.startGesture(at.center - Offset(from, 0));
      final b = await tester.startGesture(at.center + Offset(from, 0));
      await tester.pump(const Duration(milliseconds: 16));
      for (var i = 1; i <= 10; i++) {
        final d = (to - from) / 10;
        await a.moveBy(Offset(-d, 0));
        await b.moveBy(Offset(d, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await _settle(tester, 2);
    }

    await pinch(50, 20);
    final out = (st()['imgZoom'] as num).toDouble();
    expect(out, lessThan(0.75), reason: 'zoomed out below its own size');
    await pinch(20, 60);
    expect((st()['imgZoom'] as num).toDouble(), greaterThan(out));

    // The bottom-right handle: the frame grows right and down.
    final h = tester.getCenter(find.byKey(const ValueKey('frame-handle-1-1')));
    final hg = await tester.startGesture(h + const Offset(-6, -6));
    for (var i = 0; i < 10; i++) {
      await hg.moveBy(const Offset(3, 4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await hg.up();
    await _settle(tester, 2);
    expect((st()['frameR'] as num).toDouble(), greaterThan(0.05));
    expect((st()['frameB'] as num).toDouble(), greaterThan(0.05));
    expect(st()['frameL'], isNull);
    final frame = tester.getRect(find.byKey(const ValueKey('picture-frame')));
    expect(frame.right, greaterThan(at.right + 15));
    // The left side handle: in (smaller).
    final l = tester.getCenter(find.byKey(const ValueKey('frame-handle--1-0')));
    final lg = await tester.startGesture(l);
    for (var i = 0; i < 10; i++) {
      await lg.moveBy(const Offset(3, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await lg.up();
    await _settle(tester, 2);
    expect((st()['frameL'] as num).toDouble(), lessThan(0));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
