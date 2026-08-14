/// A picture that may or may not be in the bundle yet.
///
/// The Fashion home names 190 images that live on Cloudinary and 23 that are
/// in the repository. `tools/asset-manifest.mjs --download` fetches the
/// remote ones and `tools/flutter-assets.mjs` copies them into the bundle
/// with a stable, URL-derived name — but that download needs a network this
/// sandbox does not have, so the sections have to be written before the
/// pictures arrive.
///
/// This is the seam that makes that safe. A section names the URL exactly as
/// index.html does. If the file is in the bundle it is drawn; if it is not,
/// the section falls back to something deliberate — its own clip poster, or
/// the dark plate — and lays out identically either way.
///
/// WHEN THE DOWNLOAD RUNS, NOTHING HERE OR IN ANY SECTION CHANGES. The map
/// grows, and 190 fallbacks quietly become 190 pictures.
library;

import 'package:flutter/material.dart';

import 'media_map.dart';

class NwsbImage extends StatelessWidget {
  const NwsbImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallback,
  });

  /// The address as it is written in index.html — remote or `./assets/…`.
  /// Copied verbatim so the two files can be compared line for line.
  final String url;

  final BoxFit fit;
  final Alignment alignment;

  /// What to draw when the file is not in the bundle. A clip's poster is the
  /// honest choice where the section has one; otherwise the dark plate,
  /// which is what the page is wearing underneath anyway.
  final Widget? fallback;

  /// The bundled path for [url], or null if it has not been downloaded.
  static String? resolve(String url) {
    // Local already: `./assets/x` and `assets/x` are the same file.
    if (url.startsWith('./assets/')) return url.substring(2);
    if (url.startsWith('assets/')) return url;
    return kNowssbMedia[url];
  }

  /// True when this URL can actually be drawn today. Sections use it to
  /// decide between a picture and a fallback WITHOUT needing to know which
  /// of the two they are getting.
  static bool has(String url) => resolve(url) != null;

  @override
  Widget build(BuildContext context) {
    final path = resolve(url);
    if (path == null) {
      return fallback ?? const ColoredBox(color: Color(0xFF0A0F1C));
    }
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      // A picture that is in the map but missing on disk must not throw in a
      // scrolling list. Same reasoning as NwsbVideo's black rectangle.
      errorBuilder: (_, __, ___) =>
          fallback ?? const ColoredBox(color: Color(0xFF0A0F1C)),
    );
  }
}
