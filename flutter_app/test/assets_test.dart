/// Every asset the code names is actually in the bundle.
///
/// A wrong asset path does not throw — Image.asset falls back to its
/// errorBuilder and NwsbVideo falls back to a black rectangle. That is the
/// right behaviour at runtime and it is exactly why a typo can ship: the app
/// keeps working and simply shows nothing, which looks like a design
/// decision until someone notices the picture is missing.
///
/// So the paths are checked against the filesystem instead. This walks the
/// Dart source for asset strings and asserts each one exists, which is
/// cheaper and more complete than remembering to check by hand.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every asset path named in lib/ exists on disk', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'run this from flutter_app/');

    // 'assets/…' inside a single- or double-quoted Dart string.
    final re = RegExp(r'''['"](assets/[A-Za-z0-9_\-./]+\.[A-Za-z0-9]+)['"]''');

    final missing = <String>[];
    final seen = <String>{};

    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in re.allMatches(src)) {
        final path = m.group(1)!;
        if (!seen.add(path)) continue;
        if (!File(path).existsSync()) {
          missing.add('$path  (${f.path})');
        }
      }
    }

    expect(seen, isNotEmpty, reason: 'no asset paths found — check the regex');
    expect(missing, isEmpty,
        reason: 'these are named in the code and are not in the bundle:\n'
            '  ${missing.join('\n  ')}\n'
            'Run `node tools/flutter-assets.mjs` from the repository root.');

    // ignore: avoid_print
    print('${seen.length} asset paths, all present');
  });

  test('every clip has the poster NwsbVideo will look for', () {
    // NwsbVideo derives the poster from the clip: X.mp4 -> X-poster.webp.
    // A clip without one shows black for as long as it is waiting for a
    // decoder, which with a ceiling of four is most of the time.
    final dir = Directory('assets/video');
    if (!dir.existsSync()) return;

    final missing = <String>[];
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.mp4')) continue;
      final poster = f.path.replaceAll(RegExp(r'\.mp4$'), '-poster.webp');
      if (!File(poster).existsSync()) missing.add(poster);
    }

    expect(missing, isEmpty,
        reason: 'clips without a poster:\n  ${missing.join('\n  ')}');
  });
}
