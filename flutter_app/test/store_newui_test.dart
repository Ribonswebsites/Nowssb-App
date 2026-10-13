import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/store/newui/store_feed.dart';
import 'package:nowssb/screens/store/newui/store_page.dart';

const _rails = [
  StoreRail(title: 'Words to own', dept: StoreDept.words, items: [
    StoreItem(id: 'a', title: 'Calm', subtitle: 'Peace', priceMinor: 199, dept: StoreDept.words),
  ]),
  StoreRail(title: 'New meanings', dept: StoreDept.meanings, items: [
    StoreItem(id: 'm', title: 'Earth', subtitle: 'Elements', priceMinor: 59, dept: StoreDept.meanings),
  ]),
];

const _bg = ColoredBox(color: Colors.black);

Widget _app(Widget page) => MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      child: MaterialApp(home: page),
    );

void main() {
  setUp(() {
    // Under test there is no live FX doc, so prices fall back to USD base
    // formatting; the label never comes from a hardcoded currency.
  });

  testWidgets('hub: loading then ready, dept card and ticket open', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final c = Completer<List<StoreRail>>();
    final opened = <Object?>[];
    await t.pumpWidget(_app(NewStorePage(loader: () => c.future, background: _bg, onOpen: (d, i) => opened.add(i ?? d))));
    expect(find.byKey(const Key('store_loading')), findsOneWidget);
    c.complete(_rails);
    await t.pump();
    expect(find.bySemanticsLabel(RegExp('Open Word Atelier')), findsOneWidget);
    await t.tap(find.text('Word Atelier'));
    expect(opened.last, StoreDept.words);
    await t.tap(find.text('Next').first);
    await t.pump();
    final ticket = find.byKey(const ValueKey('ticket_a'));
    await t.ensureVisible(ticket);
    await t.pump();
    expect(find.textContaining('Calm ·'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
    await t.tap(ticket);
    expect((opened.last as StoreItem?)?.id, 'a');
  });

  testWidgets('hub shortcuts reach Get Verified and Plans', (t) async {
    final hit = <String>[];
    await t.pumpWidget(_app(NewStorePage(loader: () async => _rails, background: _bg, onOpen: (_, __) {}, shortcuts: [
      StoreShortcut('Get Verified', Icons.verified_outlined, (_) => hit.add('v')),
      StoreShortcut('Subscription Plans', Icons.workspace_premium_outlined, (_) => hit.add('p')),
    ])));
    await t.pump();
    for (final l in ['Word Atelier', 'Meanings', 'Signature', 'Ebooks']) {
      expect(find.text(l), findsWidgets, reason: l);
      if (l != 'Ebooks') {
        await t.tap(find.descendant(of: find.byKey(ValueKey('dept_${{'Word Atelier': 'words', 'Meanings': 'meanings', 'Signature': 'signature'}[l]}')), matching: find.text('Next')));
        await t.pumpAndSettle();
      }
    }
    await t.ensureVisible(find.text('Get Verified'));
    await t.tap(find.text('Get Verified'));
    await t.tap(find.text('Subscription Plans'));
    expect(hit, ['v', 'p']);
  });

  testWidgets('words page shows only words with carousel and tickets', (t) async {
    StoreItem? opened;
    await t.pumpWidget(_app(StoreDeptPage(dept: StoreDept.words, loader: () async => _rails, background: _bg, onOpen: (_, i) => opened = i)));
    await t.pump();
    expect(find.text('Calm'), findsOneWidget);
    expect(find.textContaining('Earth'), findsNothing);
    await t.tap(find.text('Open'));
    expect(opened?.id, 'a');
  });

  testWidgets('meanings page empty when no meanings', (t) async {
    await t.pumpWidget(_app(StoreDeptPage(dept: StoreDept.meanings, loader: () async => [_rails.first], background: _bg)));
    await t.pump();
    expect(find.byKey(const Key('store_empty')), findsOneWidget);
  });

  testWidgets('empty', (t) async {
    await t.pumpWidget(_app(NewStorePage(loader: () async => [], background: _bg)));
    await t.pump();
    expect(find.byKey(const Key('store_empty')), findsOneWidget);
  });

  testWidgets('error then retry', (t) async {
    var n = 0;
    await t.pumpWidget(_app(NewStorePage(background: _bg, loader: () async {
      if (n++ == 0) throw StateError('x');
      return _rails;
    })));
    await t.pump();
    expect(find.byKey(const Key('store_error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.text('Word Atelier'), findsOneWidget);
  });

  testWidgets('offline', (t) async {
    await t.pumpWidget(_app(NewStorePage(background: _bg, loader: () async => throw const SocketException('no'))));
    await t.pump();
    expect(find.byKey(const Key('store_offline')), findsOneWidget);
  });
}
