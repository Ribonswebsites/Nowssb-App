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
///
/// AND UNTIL IT DOES, THE PICTURE IS FETCHED. A phone has the network the
/// build sandbox does not, and the website has always drawn these straight
/// from Cloudinary — so a URL that is not in the bundle is loaded over the
/// network and cached on the device, which is exactly what the browser does
/// with the same address.
///
/// Three steps, in this order, and each is better than the next:
///
///   1. the bundle    — no network, no wait, works offline. Always preferred.
///   2. the network    — cached after the first look, so the second launch is
///                       as quick as the first was not.
///   3. the fallback   — the section's own clip poster or the dark plate,
///                       shown while the fetch is in flight and kept if it
///                       fails. Never a spinner: a section that flickers
///                       between grey boxes on every scroll is worse to read
///                       than one that is simply dark for a moment.
library;

import 'package:cached_network_image/cached_network_image.dart';
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

  /// True when [url] is something that can be fetched rather than opened.
  static bool _isRemote(String u) =>
      u.startsWith('http://') || u.startsWith('https://');

  Widget get _fallback =>
      fallback ?? const ColoredBox(color: Color(0xFF0A0F1C));

  @override
  Widget build(BuildContext context) {
    final path = resolve(url);

    if (path != null) {
      return Image.asset(
        path,
        fit: fit,
        alignment: alignment,
        // A picture that is in the map but missing on disk must not throw in
        // a scrolling list. Same reasoning as NwsbVideo's black rectangle.
        errorBuilder: (_, __, ___) => _fallback,
      );
    }

    if (_isRemote(url)) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
        // The fallback stands in while the fetch is in flight AND if it
        // fails, so a section reads the same in both cases and never shows
        // a broken picture or a spinner.
        placeholder: (_, __) => _fallback,
        errorWidget: (_, __, ___) => _fallback,
        // A section that is scrolled past before its picture arrives should
        // not repaint the whole list when it lands.
        fadeInDuration: const Duration(milliseconds: 220),
      );
    }

    return _fallback;
  }
}
