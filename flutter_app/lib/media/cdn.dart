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

  /// Maps a repository asset path to its verified R2 object. The launch
  /// animation is intentionally the one local-only exception.
  static String assetUrl(String assetPath) {
    final clean = assetPath.replaceFirst(RegExp(r'^\./'), '');
    if (clean == 'assets/video/start-animation.mp4' ||
        clean == 'assets/video/start-animation-poster.webp') {
      return url(clean);
    }
    return mediaUrl('media/repo/$clean');
  }

  static String url(String assetPath) => '${origins.first}$assetPath';

  static Iterable<String> urls(String assetPath) sync* {
    final clean = assetPath.split('?').first.replaceFirst(RegExp(r'^\./'), '');
    if (clean.startsWith('assets/video/')) {
      final file = clean.split('/').last;
      if (file == 'start-animation.mp4' || file == 'start-animation-poster.webp') {
        yield* origins.map((o) => '$o$clean');
        return;
      }
      yield assetUrl(clean);
    }
    yield* origins.map((o) => '$o$clean');
  }
}
