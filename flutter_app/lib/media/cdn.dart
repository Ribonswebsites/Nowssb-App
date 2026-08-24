/// Where the same films also live on the network.
///
/// `assets/video/` is filled by `tools/flutter-assets.mjs` before a build and
/// is NOT committed (the website already has the only copy). A debug APK
/// built without that step, or a first frame before the bundle is unpacked,
/// would otherwise show posters forever. The pool tries the bundled file
/// first, then these origins — nowssb.com is the live site, GitHub Pages is
/// the same repository.
library;

class NwsbCdn {
  NwsbCdn._();

  static const origins = <String>[
    'https://nowssb.com/',
    'https://ribonswebsites.github.io/Nowssb-App/',
  ];

  static const workerMediaBase =
      'https://nowssb-api.ribonpatil2.workers.dev/media';

  static String mediaUrl(String key) => '$workerMediaBase/${key.replaceFirst(RegExp(r'^/+'), '')}';

  static String url(String assetPath) => '${origins.first}$assetPath';

  static Iterable<String> urls(String assetPath) sync* {
    final clean = assetPath.split('?').first;
    if (clean.startsWith('assets/video/')) {
      final file = clean.split('/').last;
      if (clean.startsWith('assets/video/time-')) {
        // Keep the established time-aware banner keys used by the dashboard.
        yield mediaUrl('home-banners/$file');
      } else if (clean == 'assets/video/hero-bg.mp4') {
        // The Fashion hero has its stable managed key.
        yield mediaUrl('hero/hero-bg.mp4');
      } else {
        // Every other background and section film shares the R2 video catalog.
        yield mediaUrl('video/$file');
      }
    }
    yield* origins.map((o) => '$o$assetPath');
  }
}
