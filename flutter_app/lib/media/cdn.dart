/// Canonical remote media paths shared by the WebView and Flutter builds.
library;

class NwsbCdn {
  NwsbCdn._();

  static const origins = <String>[
    'https://nowssb.com/',
    'https://ribonswebsites.github.io/Nowssb-App/',
  ];

  static const workerMediaBase =
      'https://nowssb-api.ribonpatil2.workers.dev/media';

  static String mediaUrl(String key) =>
      '$workerMediaBase/${key.replaceFirst(RegExp(r'^/+'), '')}';

  /// All video assets are shipped in the app bundle. Keep this resolver local
  /// so playback never waits on the worker or starts a private download pack.
  static String assetUrl(String assetPath) {
    final clean = assetPath.replaceFirst(RegExp(r'^\./'), '');
    return url(clean);
  }

  static String url(String assetPath) => '${origins.first}$assetPath';

  static Iterable<String> urls(String assetPath) sync* {
    final clean = assetPath.split('?').first.replaceFirst(RegExp(r'^\./'), '');
    if (clean.startsWith('assets/video/')) {
      yield* origins.map((o) => '$o$clean');
      return;
    }
    yield* origins.map((o) => '$o$clean');
  }
}
