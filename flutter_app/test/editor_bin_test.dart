/// The Deleted bin: delete → in the bin (what, where, when) → Restore puts
/// it back in its place → and the bin survives a restart / another device
/// (same server) and an unreachable server (this phone's copy).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/bin.dart';
import 'package:nowssb/admin/editor/bin_page.dart';
import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/placed_orbs.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, EditorController c) async {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
  await _settle(tester, 10);
  expect(tester.takeException(), isNull);
}

List<String> _liveIds(EditorController c) => [for (final s in c.sections) if (!s.entry.deleted) s.id];

/// A server that is down.
class _DownBin implements BinBackend {
  @override
  Stream<List<BinItem>> watch() => Stream.error(StateError('offline'));
  @override
  Future<void> put(BinItem item) async => throw StateError('offline');
  @override
  Future<void> remove(String id) async => throw StateError('offline');
}

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  late MemoryBin server;
  setUp(() {
    SharedPreferences.setMockInitialValues({kTouchHintSeen: true});
    server = MemoryBin();
    BinStore.instance = BinStore(server);
    VideoPool.instance.debugDropAll();
  });
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('delete a section → it is in the bin → Restore puts it back in its place', (tester) async {
    final c = EditorController();
    await _open(tester, c);
    final before = _liveIds(c);
    // A section in the middle, so "its place" means something.
    final id = before[2];
    final title = c.sections.firstWhere((s) => s.id == id).title;
    c.pickSection(id);
    await _settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('strip-delete')));
    await _settle(tester);
    expect(_liveIds(c), isNot(contains(id)));
    expect(find.textContaining('in the Bin'), findsOneWidget);

    // In the bin and on the server: what, where, when, how to put it back.
    final bin = BinStore.instance;
    expect(bin.items, hasLength(1));
    final item = bin.items.single;
    expect(item.kind, anyOf(BinKind.section, BinKind.banner));
    expect(item.label, title);
    expect(item.where, contains('after “'));
    expect(DateTime.now().millisecondsSinceEpoch - item.at, lessThan(60000));
    expect(item.data['entry'], isNotNull);
    expect(server.docs.keys, [item.id]);

    // Bin in the pill → the bin page lists it, with a big Restore.
    ScaffoldMessenger.of(tester.element(find.byType(UiEditorScreen))).clearSnackBars();
    await _settle(tester, 2);
    if (find.byKey(const ValueKey('editor-bin')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('editor-pill-handle')));
      await _settle(tester, 3);
    }
    await tester.tap(find.byKey(const ValueKey('editor-bin')));
    await _settle(tester, 6);
    expect(find.byKey(const ValueKey('bin-page')), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(find.textContaining('Deleted just now'), findsOneWidget);
    final restore = find.byKey(ValueKey('bin-restore-${item.id}'));
    expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
    await tester.tap(restore);
    await _settle(tester, 8);

    expect(find.byKey(const ValueKey('bin-page')), findsNothing, reason: 'back on the page');
    expect(_liveIds(c), before, reason: 'back exactly where it was');
    expect(bin.items, isEmpty);
    expect(server.docs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete then Undo also takes it out of the bin', (tester) async {
    final c = EditorController();
    await _open(tester, c);
    final id = _liveIds(c)[1];
    c.pickSection(id);
    await _settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('strip-delete')));
    await _settle(tester);
    expect(BinStore.instance.items, hasLength(1));
    await tester.tap(find.descendant(of: find.byType(SnackBar), matching: find.text('Undo')));
    await _settle(tester);
    expect(_liveIds(c), contains(id));
    expect(BinStore.instance.items, isEmpty);
  });

  testWidgets('an element: deleted, in the bin, restored', (tester) async {
    final c = EditorController();
    await _open(tester, c);
    final words = find.descendant(of: find.byType(EditorPreview), matching: find.textContaining('Ready for today'));
    await tester.tapAt(tester.getCenter(words));
    await _settle(tester, 3);
    final key = c.selectedSlot!;
    await tester.tap(find.byKey(const ValueKey('strip-delete')));
    await _settle(tester);
    expect(words, findsNothing);
    final item = BinStore.instance.items.single;
    expect(item.kind, BinKind.element);
    expect(item.label, contains('Ready for today'));
    expect(restoreFromBin(c, item), isTrue);
    await _settle(tester, 3);
    expect(c.overrideOf(key)?.style['removed'], isNull);
    expect(words, findsOneWidget);
    expect(BinStore.instance.items, isEmpty);
  });

  test('an orb: back on its section; on the last section when that one is gone', () {
    final c = EditorController()..pageId = 'p';
    final entries = [const SectionEntry(id: 'a'), const SectionEntry(id: 'b')];
    c.preview.reported['p'] = [for (final e in entries) SectionInfo(e.id, e.id, e)];
    const o = PlacedOrb(id: 'orb1', orb: 'working', x: 0.3, y: 40);
    expect(c.restoreOrb('a', o), isTrue);
    expect(c.orbById('a', 'orb1')?.x, 0.3);
    expect(c.restoreOrb('gone', const PlacedOrb(id: 'orb1', orb: 'working', x: 0.5, y: 10)), isTrue);
    expect(c.orbsIn('b'), hasLength(1), reason: 'the last section, under a fresh id');
    expect(c.orbsIn('b').single.id, isNot('orb1'));
  });

  test('a section whose spot is gone goes back at the end', () {
    final c = EditorController()..pageId = 'p';
    final entries = [const SectionEntry(id: 'a'), const SectionEntry(id: 'b')];
    c.preview.reported['p'] = [for (final e in entries) SectionInfo(e.id, e.id, e)];
    final e = SectionEntry(id: 'imageBanner~1', kind: 'imageBanner', props: templateStarter('imageBanner'));
    c.restoreSection(e, before: 'nope', after: 'gone');
    expect(c.entries.map((x) => x.id), ['a', 'b', 'imageBanner~1']);
    final e2 = SectionEntry(id: 'textBlock~1', kind: 'textBlock', props: templateStarter('textBlock'));
    c.restoreSection(e2, before: 'a');
    expect(c.entries.map((x) => x.id), ['a', 'textBlock~1', 'b', 'imageBanner~1'], reason: 'just after its neighbour');
  });

  test('the bin survives a restart and shows on another device (same server)', () async {
    SharedPreferences.setMockInitialValues({});
    final phone = BinStore(server);
    await phone.start();
    final item = BinItem(
      id: 'b1',
      kind: BinKind.banner,
      page: 'home.normal',
      layout: 'home.normal',
      label: 'Image banner · Spring',
      where: 'Home, after “Stories”',
      at: DateTime(2026, 10, 7, 12, 40).millisecondsSinceEpoch,
      data: const {'entry': {'id': 'imageBanner~1', 'kind': 'imageBanner'}, 'before': 'stories'},
    );
    await phone.add(item);
    phone.dispose();

    final tablet = BinStore(server);
    await tablet.start();
    await pumpEventQueue();
    expect(tablet.items.map((i) => i.id), ['b1']);
    final back = tablet.items.single;
    expect(back.label, item.label);
    expect(back.where, item.where);
    expect(back.at, item.at);
    expect(back.data['before'], 'stories');
    expect(jsonEncode(back.toJson()), jsonEncode(item.toJson()), reason: 'saved whole');
    await tablet.remove('b1');
    expect(server.docs, isEmpty);
    tablet.dispose();
  });

  test('with the server down it is kept on this phone, and survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final a = BinStore(_DownBin());
    await a.start();
    await a.add(BinItem(id: 'b2', kind: BinKind.section, page: 'p', layout: 'p', label: 'Stories', where: 'Home', at: 1));
    expect(a.items, hasLength(1));
    expect(a.syncError, isNotNull);
    a.dispose();
    final b = BinStore(_DownBin());
    await b.start();
    await pumpEventQueue();
    expect(b.items.map((i) => i.label), ['Stories']);
    b.dispose();
  });

  test('when it was deleted, in plain words', () {
    final now = DateTime(2026, 10, 7, 12, 40);
    expect(binWhen(now.subtract(const Duration(seconds: 20)).millisecondsSinceEpoch, now: now), startsWith('Deleted just now'));
    expect(binWhen(now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch, now: now), startsWith('Deleted 5 min ago'));
    expect(binWhen(now.subtract(const Duration(days: 3)).millisecondsSinceEpoch, now: now), contains('3 days ago · 4 Oct 2026'));
  });

  testWidgets('one strip, plain words under the icons, thumb-sized; no jargon in names', (tester) async {
    final c = EditorController();
    await _open(tester, c);
    c.pickSection(_liveIds(c).first);
    await _settle(tester, 2);
    final strip = find.byKey(const ValueKey('context-strip'));
    for (final t in ['Edit text', 'Style', 'Animate', 'Delete', 'Done']) {
      final w = find.descendant(of: strip, matching: find.text(t));
      expect(w, findsOneWidget, reason: '"$t" under its icon');
      final tool = find.ancestor(of: w, matching: find.byType(StripTool));
      final size = tester.getSize(tool.first);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$t is wide enough to hit');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$t is tall enough to hit');
    }
    c.unpick();
    for (final s in c.sections) {
      expect(s.title, isNot(matches(RegExp(r'\bHero\b|\bcurve\b', caseSensitive: false))),
          reason: '"${s.title}" in plain words');
    }
    expect(tester.takeException(), isNull);
  });
}
