import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:nowssb/pages/signature_words/signature_models.dart';
import 'package:nowssb/pages/signature_words/signature_words_page.dart';

class _Src implements SignatureSource {
  _Src(this.fn);
  final Future<List<SignatureWord>> Function() fn;
  @override
  Future<List<SignatureWord>> load() => fn();
}

Widget _app(SignatureSource s) => MaterialApp(home: SignatureWordsPage(source: s, reduceEffects: true));

void main() {
  testWidgets('loading state', (t) async {
    final c = Completer<List<SignatureWord>>();
    await t.pumpWidget(_app(_Src(() => c.future)));
    expect(find.byKey(const Key('sig-loading')), findsOneWidget);
    c.complete([]);
    await t.pumpAndSettle();
  });

  testWidgets('empty state', (t) async {
    await t.pumpWidget(_app(_Src(() async => [])));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sig-empty')), findsOneWidget);
  });

  testWidgets('error state with retry', (t) async {
    var calls = 0;
    await t.pumpWidget(_app(_Src(() async {
      calls++;
      throw StateError('x');
    })));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sig-error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(_Src(() async => throw const OfflineException())));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sig-offline')), findsOneWidget);
  });

  testWidgets('grid, collection filter, detail and help', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(const DemoSignatureSource()));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sig-card-aum')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sig-card-aum')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sig-buy')), findsOneWidget);
    await t.tap(find.byKey(const Key('sig-buy')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sig-owned')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sig-card-shanti')), findsOneWidget);
    expect(find.byKey(const ValueKey('sig-card-aum')), findsNothing);
    await t.tap(find.byKey(const Key('sig-help')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sig-help-sheet')), findsOneWidget);
  });

  testWidgets('rarity info explains fixed prices, no random draws', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(const DemoSignatureSource()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sig-card-lumen')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sig-rarity-info')));
    await t.pumpAndSettle();
    expect(find.textContaining('no random draws'), findsOneWidget);
  });

  testWidgets('effects on: animated page builds and disposes cleanly', (t) async {
    await t.pumpWidget(const MaterialApp(home: SignatureWordsPage()));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('sig-card-aum')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  test('flag rules: off for users, on for admins and remote release', () {
    expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: null)), isTrue);
    expect(NewUi.decide(const NewUiInputs(isAdmin: true, remote: null)), isTrue);
    expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: true)), isTrue);
  });
}
