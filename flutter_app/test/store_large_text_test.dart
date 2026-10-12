/// UI-9: large-text / small-screen pass on the four sub stores.
///
/// Pumps each page on a 320×568 phone at text scale 1.3 and 2.0, scrolls the
/// whole page (slivers only build what is on screen) and fails on any
/// RenderFlex overflow or other layout error.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store/ebooks_store.dart';
import 'package:nowssb/screens/store/meaning_store.dart';
import 'package:nowssb/screens/store/signature_store.dart';
import 'package:nowssb/screens/store/word_atelier.dart';

import 'fake_video_platform.dart';

const String? _dumpTo = String.fromEnvironment('UI9_DUMP') == ''
    ? null
    : String.fromEnvironment('UI9_DUMP');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({
    'nwsb_terms_hub': '1',
    'nwsb_terms_word': '1',
    'nwsb_terms_signature': '1',
    'nwsb_terms_meaning': '1',
    'nwsb_terms_ebooks': '1',
  });

  setUpAll(() async {
    await _loadRoboto();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  final pages = <String, Widget Function()>{
    'Word Atelier': () => const WordAtelierScreen(),
    'Signature Store': () => const SignatureStoreScreen(),
    'Meaning Store': () => const MeaningStoreScreen(),
    'eBooks Store': () => const EbooksStoreScreen(),
  };

  for (final scale in [1.0, 1.3, 2.0]) {
    pages.forEach((name, build) {
      testWidgets('$name: no overflow at 320x568, textScaler $scale',
          (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 568 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        final prev = FlutterError.onError;
        FlutterError.onError = (details) {
          // Layout only: overflow / constraint errors from the rendering
          // library. (Image decode noise from the asset stand-in is not a
          // layout problem.)
          final layout = details.library == 'rendering library' ||
              details.exceptionAsString().contains('overflowed');
          if (!layout) return;
          final full = details.toString();
          final m = RegExp(r'lib/[\w/]+\.dart:\d+:\d+').firstMatch(full);
          final line = '${details.exceptionAsString().split('\n').first} '
              '@ ${m?.group(0) ?? '?'}';
          errors.add(line);
          if (_dumpTo != null) {
            File(_dumpTo!).writeAsStringSync('==== $name@$scale $line\n$full\n',
                mode: FileMode.append);
          }
          // ignore: avoid_print
          print('OVERFLOW[$name@$scale] $line');
        };
        addTearDown(() => FlutterError.onError = prev);

        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: DefaultAssetBundle(bundle: _FallbackBundle(), child: build()),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Walk the page top to bottom so every sliver child lays out.
        // The page's own vertical scroll (PageShell's CustomScrollView), not
        // a horizontal rail or a sheet.
        final scrollable = find
            .byWidgetPredicate((w) =>
                w is Scrollable && w.axisDirection == AxisDirection.down)
            .first;
        final state = tester.state<ScrollableState>(scrollable);
        // Meaning Store pre-caches its art (real async I/O) before it shows
        // the rows; let that finish.
        for (var i = 0; i < 20 && state.position.maxScrollExtent < 2000; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        var guard = 0;
        while (guard++ < 200) {
          final pos = state.position;
          if (pos.pixels >= pos.maxScrollExtent - 1) break;
          pos.jumpTo((pos.pixels + 400).clamp(0, pos.maxScrollExtent));
          await tester.pump(const Duration(milliseconds: 50));
          void visit(RenderObject o) {
            if (o is RenderParagraph && o.didExceedMaxLines) {
              final t = o.text.toPlainText();
              final fs = (o.text.style?.fontSize ?? 14);
              // ignore: avoid_print
              print('CLIP[$name@$scale] fs=$fs w=${o.size.width.round()} "$t"');
            }
            o.visitChildren(visit);
          }
          tester.binding.renderViews.first.visitChildren(visit);
        }

        FlutterError.onError = prev;
        // The walk really covered a long page, top to bottom.
        expect(state.position.maxScrollExtent, greaterThan(2000));
        expect(state.position.pixels,
            closeTo(state.position.maxScrollExtent, 1));
        // ignore: avoid_print
        print('UI9[$name@$scale] scrolled ${state.position.pixels.round()}px');
        expect(errors.toSet().toList(), isEmpty, reason: '$name @ $scale');
      });
    });
  }
}

/// Media folders are fetched at build time (gitignored), so a clean clone has
/// no images. Serve a transparent 1×1 PNG for any missing image so the debug
/// "missing asset" box does not pose as a layout overflow.
class _FallbackBundle extends CachingAssetBundle {
  static final _png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00,
    0x00, 0x05, 0x00, 0x01, 0x7A, 0x5E, 0xAB, 0x3F, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      if (RegExp(r'\.(png|jpe?g|webp|gif)$', caseSensitive: false)
          .hasMatch(key)) {
        return ByteData.sublistView(_png);
      }
      rethrow;
    }
  }
}

/// The default test font draws every glyph 1em wide (~1.7× real text), which
/// flags overflows no phone would show. Load the SDK's Roboto (the Android
/// default the app renders with) so widths are realistic. Falls back to the
/// test font if the SDK fonts are not on disk.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('Roboto-') && name.endsWith('.ttf') &&
        !name.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
}
