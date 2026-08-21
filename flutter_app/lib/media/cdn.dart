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

  static String url(String assetPath) => '${origins.first}$assetPath';

  static Iterable<String> urls(String assetPath) =>
      origins.map((o) => '$o$assetPath');
}
