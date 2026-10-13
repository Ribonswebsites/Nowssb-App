/// BD-8c: calm (brief B) goldens for the store sub pages.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:nowssb/widgets/page_shell.dart';

import 'fake_video_platform.dart';

void main() {
  // These cover the legacy Store screens; the rebuilt ones have store_newui_test.
  setUpAll(() async {
    await NewUi.setDebugOverride('store', false);
    await NewUi.setDebugOverride('signature', false);
  });
  tearDownAll(NewUi.resetForTest);

  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'nwsb_terms_hub': '1',
    'nwsb_terms_word': '1',
    'nwsb_terms_meaning': '1',
    'nwsb_terms_signature': '1',
    'nwsb_terms_ebooks': '1',
    'nwsb_terms_subscription': '1',
  });

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.createTempSync('bd8').path);
    await _loadFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  void Function() restore = () {};
  Future<List<String>> pump(
      WidgetTester tester, Widget home, Size size, double scale) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.library == 'rendering library' ||
          d.exceptionAsString().contains('overflowed')) {
        final m = RegExp(r'lib/[\w/]+\.dart:\d+:\d+').firstMatch(d.toString());
        errors
            .add('${d.exceptionAsString().split('\n').first} @ ${m?.group(0)}');
      }
    };
    restore = () => FlutterError.onError = prev;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: child!),
      home: home,
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Decode the poster images for real so the golden shows them.
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump(const Duration(milliseconds: 200));
    return errors;
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 300,
        scrollable: find
            .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
            .first);
    await tester.pump(const Duration(milliseconds: 200));
  }

  final pages = <String, Widget Function()>{
    'atelier': () => const WordAtelierScreen(),
    'meanings': () => const MeaningStoreScreen(),
    'signature': () => const SignatureStoreScreen(),
    'ebooks': () => const EbooksStoreScreen(),
    'plans': () => const SubscriptionScreen(),
  };
  for (final w in [320.0, 390.0]) {
    for (final k in [1.0, 1.3, 2.0]) {
      testWidgets('store sub header: no clipped title/subtitle @${w}px x$k',
          (tester) async {
        await pump(tester, const WordAtelierScreen(), Size(w, 844), k);
        restore();
        final clipped = <String>[];
        var seen = 0;
        final header = find.byType(PageShell);
        for (final e in find
            .descendant(of: header, matching: find.text('NowssB Store'))
            .evaluate()
            .followedBy(find
                .byWidgetPredicate((w) =>
                    w is Text && w.data == 'The Word Atelier' && w.maxLines == 2)
                .evaluate())) {
          seen++;
          final ro = e.renderObject;
          if (ro is RenderParagraph && ro.didExceedMaxLines) {
            clipped.add(ro.text.toPlainText());
          }
          // A mid-word break shows up as a 3+ line title.
          if (ro is RenderParagraph) {
            final lines = ro.getBoxesForSelection(TextSelection(
                    baseOffset: 0, extentOffset: ro.text.toPlainText().length))
                .map((b) => b.top.round())
                .toSet()
                .length;
            if (lines > 2) clipped.add('${ro.text.toPlainText()} x$lines');
          }
        }
        expect(seen, 2);
        expect(clipped, isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 11));
      });
    }
  }
  pages.forEach((name, build) {
    testWidgets('store sub $name golden 390x844', (tester) async {
      await pump(tester, build(), const Size(390, 844), 1.0);
      // Meaning Store pre-caches its art (real async I/O) first.
      for (var i = 0;
          i < 40 &&
              find
                  .textContaining('Loading', findRichText: true)
                  .evaluate()
                  .isNotEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump(const Duration(milliseconds: 200));
      // Plans shows its research-proposal terms sheet first; agree to it.
      final agree = find.textContaining('I Agree', findRichText: true);
      if (agree.evaluate().isNotEmpty) {
        await tester.tap(agree.first);
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      restore();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/store-sub-$name.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  });
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/box/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') &&
        n.endsWith('.ttf') &&
        !n.contains('Italic')) {
      roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
    if (n.startsWith('MaterialIcons')) {
      icons.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await roboto.load();
  await icons.load();
}
