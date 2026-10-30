/// Test-only: serve google_fonts from test/fonts instead of the network.
///
/// google_fonts looks in the app-support folder for `<Family>_<variant>_<hash>.ttf`
/// before fetching, and does not re-check the hash for files found there. So
/// this seeds that folder (a temp dir behind a mocked path_provider) with the
/// local font for every variant of the listed families. App code is untouched.
library;

import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// google_fonts family name -> file under test/fonts.
const _families = {
  'Oswald': 'Oswald.ttf',
  'Anton': 'Anton.ttf',
  'DMSans': 'DMSans.ttf',
  'LibreBaskerville': 'LibreBaskerville.ttf',
};

Future<String> setUpOfflineGoogleFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final dir = Directory.systemTemp.createTempSync('gf_offline');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => dir.path,
  );
  // Isolate.resolvePackageUri is unsupported under flutter test, so read the
  // package location from the package config instead.
  final cfg = File('.dart_tool/package_config.json');
  if (!cfg.existsSync()) return dir.path;
  final pkgs = (jsonDecode(cfg.readAsStringSync()) as Map)['packages'] as List;
  final gf = pkgs.cast<Map>().firstWhere((p) => p['name'] == 'google_fonts',
      orElse: () => const {});
  if (gf['rootUri'] == null) return dir.path;
  var rootUri = gf['rootUri'] as String;
  if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
  final root = cfg.absolute.uri.resolve(rootUri);
  final parts = root.resolve('lib/src/google_fonts_parts/part_a.g.dart');
  final variant = RegExp(
      r"fontWeight: FontWeight\.w(\d00),\s*fontStyle: FontStyle\.(normal|italic),\s*\): GoogleFontsFile\(\s*'([0-9a-f]{64})'");
  for (final f in File.fromUri(parts).parent.listSync().whereType<File>()) {
    final src = f.readAsStringSync();
    for (final block in src.split('static TextStyle ')) {
      final fam = RegExp(r"fontFamily: '([A-Za-z0-9]+)'").firstMatch(block)?[1];
      final local = _families[fam];
      if (fam == null || local == null) continue;
      final bytes = File('test/fonts/$local').readAsBytesSync();
      for (final m in variant.allMatches(block)) {
        final w = m[1]!;
        final italic = m[2] == 'italic';
        // GoogleFontsVariant.toString: '' for 400, then 'regular'/'italic'.
        final v = w == '400' ? (italic ? 'italic' : 'regular') : '$w${italic ? 'italic' : ''}';
        File('${dir.path}/${fam}_${v}_${m[3]}.ttf').writeAsBytesSync(bytes);
      }
    }
  }
  return dir.path;
}
