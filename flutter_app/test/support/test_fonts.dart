// Real fonts for layout tests, found the same way on every machine.
//
// Overflow and wrap checks only mean something with real glyph widths; the
// default test font's square glyphs are far wider than DM Sans. These tests
// used to load fonts from one dev box's /usr/share/fonts and ~/flutter, so on
// CI they silently fell back to the square font and reported false overflows.
// Fonts now come from the repo (test/fonts, assets/fonts) and from the Flutter
// SDK that is running the test.
import 'dart:io';

import 'package:flutter/services.dart';

/// The first existing file of [paths], loaded as [family]. Returns false
/// when none exists.
Future<bool> loadTestFont(String family, List<String?> paths) async {
  for (final p in paths) {
    if (p == null) continue;
    final f = File(p);
    if (!f.existsSync()) continue;
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync()))))
        .load();
    return true;
  }
  return false;
}

/// The running Flutter SDK's bundled material fonts folder
/// (bin/cache/artifacts/material_fonts), or null.
final String? sdkMaterialFonts = () {
  final roots = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final r?) '$r/bin/cache/artifacts',
  ];
  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<platform>/.
  var d = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    roots.add(d.path);
    d = d.parent;
  }
  for (final r in roots) {
    final m = Directory('$r/material_fonts');
    if (m.existsSync()) return m.path;
  }
  return null;
}();

String? sdkFont(String file) =>
    sdkMaterialFonts == null ? null : '$sdkMaterialFonts/$file';

Future<void> loadDmSans() => loadTestFont('DM Sans', [
      'test/fonts/DMSans.ttf',
      '/usr/share/fonts/truetype/sand-box/google/DM Sans/DMSans-VariableFont_opsz,wght.ttf',
    ]);

Future<void> loadAnton() => loadTestFont('Anton', [
      'test/fonts/Anton.ttf',
      'assets/fonts/Anton-Regular.ttf',
    ]);

Future<void> loadMaterialIcons() =>
    loadTestFont('MaterialIcons', [sdkFont('MaterialIcons-Regular.otf')]);

/// Roboto from the SDK's static faces, every weight under one family.
Future<void> loadRoboto() async {
  final dir = sdkMaterialFonts;
  if (dir == null) return;
  final l = FontLoader('Roboto');
  for (final f in Directory(dir).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf')) {
      l.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await l.load();
}
