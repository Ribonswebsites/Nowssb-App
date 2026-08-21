/// Pictures the same way [NwsbVideo] does films: bundled first, then the
/// same path on nowssb.com / GitHub Pages.
///
/// Frames, the logo disc, intro paintings and posters live in this
/// repository once, under `assets/`. A debug APK that skipped
/// `tools/flutter-assets.mjs` would otherwise show empty bezels and a blank
/// mark — the same hole that made the films sit still.
library;

import 'package:flutter/material.dart';

import 'cdn.dart';

class NwsbImage extends StatelessWidget {
  const NwsbImage(
    this.asset, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.error,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => Image.network(
        NwsbCdn.url(asset),
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) =>
            error ?? const ColoredBox(color: Colors.black),
      ),
    );
  }
}
