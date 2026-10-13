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
];

Widget _app(StoreLoader l, {StoreOpen? onOpen}) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: NewStorePage(loader: l, onOpen: onOpen, background: const ColoredBox(color: Colors.black))),
    );

void main() {
  testWidgets('loading then ready, item tap opens', (t) async {
    final c = Completer<List<StoreRail>>();
    StoreItem? opened;
    await t.pumpWidget(_app(() => c.future, onOpen: (_, i) => opened = i));
    expect(find.byKey(const Key('store_loading')), findsOneWidget);
    c.complete(_rails);
    await t.pump();
    expect(find.text('Calm'), findsOneWidget);
    expect(find.textContaining(r'$1.99'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget); // single card: last -> Open pill
    expect(find.bySemanticsLabel(RegExp('Open Words')), findsOneWidget);
    await t.ensureVisible(find.text('Open'));
    await t.pump();
    await t.tap(find.text('Open'));
    expect(opened?.id, 'a');
  });

  testWidgets('dept tile opens dept', (t) async {
    StoreDept? d;
    await t.pumpWidget(_app(() async => _rails, onOpen: (x, _) => d = x));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('dept_ebooks')));
    expect(d, StoreDept.ebooks);
  });

  testWidgets('empty', (t) async {
    await t.pumpWidget(_app(() async => []));
    await t.pump();
    expect(find.byKey(const Key('store_empty')), findsOneWidget);
  });

  testWidgets('error then retry', (t) async {
    var n = 0;
    await t.pumpWidget(_app(() async {
      if (n++ == 0) throw StateError('x');
      return _rails;
    }));
    await t.pump();
    expect(find.byKey(const Key('store_error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.text('Calm'), findsOneWidget);
  });

  testWidgets('offline', (t) async {
    await t.pumpWidget(_app(() async => throw const SocketException('no')));
    await t.pump();
    expect(find.byKey(const Key('store_offline')), findsOneWidget);
  });
}
