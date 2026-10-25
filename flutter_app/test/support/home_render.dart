// Shared helpers for tests that lay out or render a whole home page:
// real fonts when the box has them, a path_provider stub (google_fonts reads
// its cache from there), and image precaching so renders show pictures.
//
// Set HOME_FONT_CACHE=<dir> to a folder of google_fonts cache files
// ('<Family>_<variant>_<hash>.ttf') to render the Google fonts offline.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final l = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await l.load();
}

const _g = '/usr/share/fonts/truetype/sand-box/google';

/// The google_fonts cache to render with: HOME_FONT_CACHE, else
/// ~/.cache/nowssb-test-fonts. Null when neither exists.
final String? homeFontCache = () {
  final env = Platform.environment['HOME_FONT_CACHE'];
  final home = Platform.environment['HOME'];
  for (final d in [env, if (home != null) '$home/.cache/nowssb-test-fonts']) {
    if (d != null && d.isNotEmpty && Directory(d).existsSync()) return d;
  }
  return null;
}();

/// Layout checks that depend on real glyph widths (overflow at a given
/// phone size) are skipped without the real fonts: the test font's square
/// glyphs are far wider than DM Sans and would report false overflows.
final bool homeFontsReady = homeFontCache != null;

/// Call from setUpAll.
Future<void> setUpHomeRender() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cache = homeFontCache;
  final dir = cache ?? Directory.systemTemp.createTempSync('home_render').path;
  // With a cache the files load from 'disk'; without one google_fonts
  // behaves as in every other widget test here.
  if (cache != null) GoogleFonts.config.allowRuntimeFetching = true;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => dir,
  );
  await _font('DM Sans', '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf');
  await _font('MaterialIcons',
      '/home/box/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf');
  await _font(
      'CormorantGaramond', 'assets/fonts/CormorantGaramond-Variable.ttf');
  await _font('Anton', '$_g/Anton/Anton-Regular.ttf');
  // google_fonts names each face '<Family>_<variant>'; register the cached
  // files under those names so first-frame text is not tofu.
  if (cache != null) {
    for (final f in Directory(cache).listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      final m =
          RegExp(r'^(.+?)_([0-9a-z]+)_[0-9a-f]{64}\.ttf$').firstMatch(name);
      if (m != null) await _font('${m[1]}_${m[2]}', f.path);
    }
  }
}

/// Decodes every on-screen picture so a render shows it.
Future<void> precacheAll(WidgetTester t) async {
  final imgs = [
    for (final e in find.byType(Image).evaluate())
      (e, (e.widget as Image).image),
    for (final e in find.byType(DecoratedBox).evaluate())
      if ((e.widget as DecoratedBox).decoration
          case BoxDecoration(image: DecorationImage(image: final p)))
        (e, p),
  ];
  await t.runAsync(() async {
    try {
      await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 10));
    } catch (_) {}
    for (final (e, p) in imgs) {
      if (p is NetworkImage ||
          (p is ResizeImage && p.imageProvider is NetworkImage)) continue;
      try {
        await precacheImage(p, e).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  });
}
