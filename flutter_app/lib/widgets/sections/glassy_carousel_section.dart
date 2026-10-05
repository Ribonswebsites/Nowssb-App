/// Glassy 3D carousel row — UI-1.
///
/// Centre card bigger and in focus; side cards smaller, faded, and tilted
/// (rotateY) on a frosted glass panel. Reads [SectionConfig] for
/// [SectionTypeId.glassyCarousel]. Admin fills [SectionMediaItem] image/video
/// URLs; empty slots show black/gold placeholders (no stock photos).
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../../admin/layout/app_pages.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import 'section_config.dart';

/// Reusable glassy coverflow carousel driven by [SectionConfig].
class GlassyCarouselSection extends StatefulWidget {
  const GlassyCarouselSection({super.key, required this.config});

  final SectionConfig config;

  @override
  State<GlassyCarouselSection> createState() => _GlassyCarouselSectionState();
}

class _GlassyCarouselSectionState extends State<GlassyCarouselSection> {
  late PageController _page;
  Timer? _autoplay;
  var _index = 0;
  var _fraction = 0.58;
  var _autoplayArmed = false;

  SectionConfig get _c => widget.config;

  List<SectionMediaItem> get _items {
    final raw = _c.items;
    final cap = _c.behavior.itemCount;
    if (raw.isEmpty) {
      // Placeholder slots so the section still shows while admin fills it.
      return List<SectionMediaItem>.generate(
        3,
        (i) => SectionMediaItem(id: '_ph.$i', title: 'Add media', subtitle: 'Admin fillable'),
      );
    }
    if (cap != null && cap > 0 && cap < raw.length) return raw.sublist(0, cap);
    return raw;
  }

  bool get _loop => _c.behavior.loop && _items.length > 1;

  /// Large virtual count so PageView can loop without a jump.
  int get _pageCount => _loop ? _items.length * 1000 : _items.length;

  int get _startPage {
    final n = _items.length;
    if (n == 0) return 0;
    final start = _c.behavior.startIndex.clamp(0, n - 1);
    if (!_loop) return start;
    return (n * 500) + start;
  }

  bool _reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _index = _c.behavior.startIndex.clamp(0, math.max(_items.length - 1, 0));
    _page = PageController(viewportFraction: _fraction, initialPage: _startPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoplayArmed) {
      _autoplayArmed = true;
      _syncAutoplay();
    }
  }

  @override
  void didUpdateWidget(GlassyCarouselSection old) {
    super.didUpdateWidget(old);
    if (old.config.behavior.startIndex != _c.behavior.startIndex ||
        old.config.behavior.loop != _c.behavior.loop ||
        old.config.items.length != _c.items.length ||
        old.config.behavior.itemCount != _c.behavior.itemCount) {
      _reseedController();
    }
    _syncAutoplay();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _scheduleFraction(double fraction) {
    final f = fraction.clamp(0.35, 0.85);
    if ((f - _fraction).abs() < 0.02) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (f - _fraction).abs() < 0.02) return;
      final resume = _page.hasClients
          ? (_page.page ?? _page.initialPage.toDouble())
          : _startPage.toDouble();
      final old = _page;
      _fraction = f;
      _page = PageController(viewportFraction: f, initialPage: resume.round());
      old.dispose();
      setState(() {
        _index = resume.round() % math.max(_items.length, 1);
      });
      _syncAutoplay();
    });
  }

  void _reseedController() {
    final old = _page;
    _page = PageController(viewportFraction: _fraction, initialPage: _startPage);
    old.dispose();
    _index = _c.behavior.startIndex.clamp(0, math.max(_items.length - 1, 0));
  }

  void _syncAutoplay() {
    _autoplay?.cancel();
    _autoplay = null;
    if (!mounted) return;
    if (!_c.behavior.autoplay || _items.length < 2) return;
    if (_reduceMotion(context)) return;
    final ms = _c.behavior.autoplayMs.clamp(1200, 60000);
    _autoplay = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted || !_page.hasClients) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      final next = (_page.page ?? _page.initialPage.toDouble()).round() + 1;
      if (!_loop && next >= _items.length) return;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onCta(SectionMediaItem item) {
    final link = item.ctaLink?.trim() ?? '';
    if (link.isNotEmpty) {
      openRoute(context, link);
      return;
    }
    final label = item.ctaLabel?.trim() ?? '';
    if (label.isNotEmpty) NwsbLinks.cta(context, label);
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.enabled) return const SizedBox.shrink();

    final layout = _c.layout;
    final radius = layout.radius ?? 20;
    final spacing = layout.spacing ?? 12;
    final pad = layout.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    final sectionH = layout.height ?? 220;
    final cardW = layout.cardWidth ?? 160;
    final cardH = layout.cardHeight ??
        (layout.aspect != null && layout.aspect! > 0
            ? cardW / layout.aspect!
            : 200.0);
    final glass = _c.style.glass;
    final glow = _c.style.glowColor != null
        ? Color(_c.style.glowColor!)
        : NwsbColors.gold;
    final accent = _c.style.accent != null
        ? Color(_c.style.accent!)
        : NwsbColors.goldLight;
    final reduce = _reduceMotion(context);

    final wrapperW = layout.wrapperWidth;
    final wrapperH = layout.wrapperHeight ?? sectionH;

    Widget carousel = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // Side cards peek; spacing is absorbed into the fraction gap.
        final frac = ((cardW + spacing) / maxW).clamp(0.38, 0.72);
        _scheduleFraction(frac);
        final items = _items;
        final n = items.length;
        if (n == 0) return SizedBox(height: cardH);

        return SizedBox(
          height: cardH + 8,
          child: PageView.builder(
            controller: _page,
            itemCount: _pageCount,
            padEnds: true,
            onPageChanged: (i) {
              setState(() => _index = i % n);
            },
            itemBuilder: (context, i) {
              final item = items[i % n];
              return AnimatedBuilder(
                animation: _page,
                builder: (context, child) {
                  double page = i.toDouble();
                  if (_page.hasClients && _page.position.haveDimensions) {
                    page = _page.page ?? i.toDouble();
                  } else {
                    page = _page.initialPage.toDouble();
                  }
                  final d = i - page;
                  return _coverflowCard(
                    distance: d,
                    reduceMotion: reduce,
                    glow: glow,
                    child: child!,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: _GlassyCard(
                    item: item,
                    width: cardW,
                    height: cardH,
                    radius: radius,
                    accent: accent,
                    focused: (i % n) == _index,
                    onCta: () => _onCta(item),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    Widget body = Padding(
      padding: pad,
      child: carousel,
    );

    if (glass) {
      body = _GlassPanel(
        radius: radius + 6,
        width: wrapperW,
        height: wrapperH,
        child: body,
      );
    } else {
      body = SizedBox(
        width: wrapperW,
        height: wrapperH,
        child: body,
      );
    }

    return body;
  }

  /// Coverflow: rotateY + scale + opacity by distance from centre.
  Widget _coverflowCard({
    required double distance,
    required bool reduceMotion,
    required Color glow,
    required Widget child,
  }) {
    final a = distance.abs().clamp(0.0, 1.5);
    final t = (a / 1.5).clamp(0.0, 1.0);
    final scale = 1.0 - 0.18 * t;
    final opacity = (1.0 - 0.45 * t).clamp(0.35, 1.0);
    final focused = a < 0.35;

    Widget card = child;
    if (!reduceMotion) {
      card = Transform(
        alignment: distance < 0 ? Alignment.centerRight : Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(-distance.clamp(-1.2, 1.2) * 0.72)
          ..scaleByDouble(scale, scale, 1, 1),
        child: card,
      );
    } else {
      card = Transform.scale(scale: scale, child: card);
    }

    card = Opacity(opacity: opacity, child: card);

    if (focused) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: card,
      );
    }
    return card;
  }
}

// ─── Glass panel under the row ──────────────────────────────────────────────

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.radius,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final double? width;
  final double? height;

  static const _fill = Color(0x14FFFFFF);
  static const _line = Color(0x28FFFFFF);

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? double.infinity,
          minHeight: height ?? 0,
          maxHeight: height ?? double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 14),
                  blurRadius: 36,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: r,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _fill,
                    borderRadius: r,
                    border: Border.all(color: _line),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x22FFFFFF),
                        Color(0x08FFFFFF),
                      ],
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single card ────────────────────────────────────────────────────────────

class _GlassyCard extends StatelessWidget {
  const _GlassyCard({
    required this.item,
    required this.width,
    required this.height,
    required this.radius,
    required this.accent,
    required this.focused,
    required this.onCta,
  });

  final SectionMediaItem item;
  final double width;
  final double height;
  final double radius;
  final Color accent;
  final bool focused;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final hasCta = (item.ctaLabel?.trim().isNotEmpty ?? false) ||
        (item.ctaLink?.trim().isNotEmpty ?? false);
    final title = item.title?.trim();
    final subtitle = item.subtitle?.trim();
    final textH = (title != null || subtitle != null) ? 64.0 : 0.0;
    final mediaH = math.max(height - textH, height * 0.62);

    final fit = item.fit == SectionMediaFit.contain ? BoxFit.contain : BoxFit.cover;
    final align = Alignment(item.focalX, item.focalY);

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(
                color: const Color(0xCC0A0A12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: mediaH,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _CardMedia(
                            item: item,
                            fit: fit,
                            alignment: align,
                            zoom: item.zoom,
                          ),
                          if (hasCta && focused)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 10,
                              child: Center(
                                child: _CtaChip(
                                  label: item.ctaLabel?.trim().isNotEmpty == true
                                      ? item.ctaLabel!.trim()
                                      : 'Open',
                                  accent: accent,
                                  onTap: onCta,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (textH > 0)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (title != null)
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: accent.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaChip extends StatelessWidget {
  const _CtaChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xCC0A0A0E),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: 16, color: accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Media (image / video / placeholder) ────────────────────────────────────

class _CardMedia extends StatelessWidget {
  const _CardMedia({
    required this.item,
    required this.fit,
    required this.alignment,
    required this.zoom,
  });

  final SectionMediaItem item;
  final BoxFit fit;
  final Alignment alignment;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final video = item.videoUrl?.trim();
    final image = item.imageUrl?.trim();

    Widget child;
    if (video != null && video.isNotEmpty) {
      child = _NetLoopVideo(url: video, posterUrl: image);
    } else if (image != null && image.isNotEmpty) {
      child = _NetOrAssetImage(url: image, fit: fit, alignment: alignment);
    } else {
      child = const _BlackGoldPlaceholder();
    }

    if (zoom > 1.01) {
      child = Transform.scale(
        scale: zoom,
        alignment: alignment,
        child: child,
      );
    }
    return child;
  }
}

class _BlackGoldPlaceholder extends StatelessWidget {
  const _BlackGoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0E), Color(0xFF16120A), Color(0xFF0A0A0E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: NwsbColors.gold, size: 36),
            SizedBox(height: 8),
            Text(
              'Add media',
              style: TextStyle(
                color: NwsbColors.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetOrAssetImage extends StatelessWidget {
  const _NetOrAssetImage({
    required this.url,
    required this.fit,
    required this.alignment,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
        placeholder: (_, __) => const _BlackGoldPlaceholder(),
        errorWidget: (_, __, ___) => const _BlackGoldPlaceholder(),
      );
    }
    return Image.asset(
      url,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const _BlackGoldPlaceholder(),
    );
  }
}

class _NetLoopVideo extends StatefulWidget {
  const _NetLoopVideo({required this.url, this.posterUrl});

  final String url;
  final String? posterUrl;

  @override
  State<_NetLoopVideo> createState() => _NetLoopVideoState();
}

class _NetLoopVideoState extends State<_NetLoopVideo> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(_NetLoopVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _c?.dispose();
      _c = null;
      _open();
    }
  }

  Future<void> _open() async {
    try {
      final url = widget.url;
      final VideoPlayerController c;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final f = await DefaultCacheManager().getSingleFile(url);
        if (!mounted) return;
        c = VideoPlayerController.file(
          File(f.path),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        c = VideoPlayerController.asset(
          url,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _c = c);
    } catch (_) {
      if (mounted) setState(() => _c = null);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      final poster = widget.posterUrl?.trim();
      if (poster != null && poster.isNotEmpty) {
        return _NetOrAssetImage(
          url: poster,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        );
      }
      return const _BlackGoldPlaceholder();
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}
