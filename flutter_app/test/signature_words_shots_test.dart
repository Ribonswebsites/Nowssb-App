// Phone-size review renders of the rebuilt Signature Words page (flag on).
// Opt-in: SIG_SHOTS=1 flutter test test/signature_words_shots_test.dart --update-goldens
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/signature_words/signature_models.dart';
import 'package:nowssb/pages/signature_words/signature_words_page.dart';

class _Src implements SignatureSource {
  _Src(this.fn);
  final Future<List<SignatureWord>> Function() fn;
  @override
  Future<List<SignatureWord>> load() => fn();
}

final _skip = Platform.environment['SIG_SHOTS'] != '1';

Future<void> _fonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    if (n.startsWith('MaterialIcons')) icons.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await roboto.load();
  await icons.load();
}

Future<void> _shot(WidgetTester t, SignatureSource src, String name, [Future<void> Function()? act]) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
    home: RepaintBoundary(key: const Key('shot'), child: SignatureWordsPage(source: src, reduceEffects: true)),
  ));
  await t.pumpAndSettle();
  if (act != null) {
    await act();
    await t.pumpAndSettle();
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
}

void main() {
  setUpAll(_fonts);
  const demo = DemoSignatureSource();
  testWidgets('1 grid', (t) => _shot(t, demo, 'signature-1'), skip: _skip);
  testWidgets('2 detail', (t) => _shot(t, demo, 'signature-2', () => t.tap(find.byKey(const ValueKey('sig-card-aum')))), skip: _skip);
  testWidgets('3 help', (t) => _shot(t, demo, 'signature-3', () => t.tap(find.byKey(const Key('sig-help')))), skip: _skip);
  testWidgets('4 rarity', (t) => _shot(t, demo, 'signature-4', () async {
        await t.tap(find.byKey(const ValueKey('sig-card-lumen')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('sig-rarity-info')));
      }), skip: _skip);
  testWidgets('5 collection', (t) => _shot(t, demo, 'signature-5', () => t.tap(find.byKey(const Key('sig-owned')))), skip: _skip);
  testWidgets('6 empty', (t) => _shot(t, _Src(() async => []), 'signature-6'), skip: _skip);
  testWidgets('7 error', (t) => _shot(t, _Src(() async => throw StateError('x')), 'signature-7'), skip: _skip);
  testWidgets('8 offline', (t) => _shot(t, _Src(() async => throw const OfflineException()), 'signature-8'), skip: _skip);
}
