library;

import 'package:flutter/material.dart';

import 'cdn.dart';

/// Shared NowssB image seam. It accepts the current bundled-asset form and the
/// August 15 URL/fallback form so the exact baseline section widgets can be
/// carried forward without losing current media behavior.
class NwsbImage extends StatelessWidget {
  const NwsbImage(
    [this.asset], {
    super.key,
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
    if (_isLocal) {
      return Image.asset(
        _localPath,
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
