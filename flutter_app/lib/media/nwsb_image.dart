import 'package:flutter/material.dart';

import 'cdn.dart';
import 'media_assets.dart';

/// Shared NowssB image seam for restored local artwork and uncatalogued runtime media.
class NwsbImage extends StatelessWidget {
  const NwsbImage({
    super.key,
    this.asset,
    this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.error,
    this.fallback,
  });

  final String? asset;
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? error;
  final Widget? fallback;

  String get _source => url ?? asset ?? '';
  Widget get _fallback => fallback ?? error ?? const ColoredBox(color: Colors.black);
  bool get _isLocal => _source.startsWith('./assets/') || _source.startsWith('assets/');
  String get _localPath => _source.startsWith('./') ? _source.substring(2) : _source;
  @override
  Widget build(BuildContext context) {
    if (_source.isEmpty) return _fallback;
    final localPath = _isLocal ? _localPath : nowssbImageAsset(_source);
    if (localPath != null) {
      return Image.asset(
        localPath,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => _fallback,
      );
    }
    final networkUrl = _source.startsWith('http://') || _source.startsWith('https://')
        ? _source
        : NwsbCdn.url(_source);
    return Image.network(
      networkUrl,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _fallback,
    );
  }
}
