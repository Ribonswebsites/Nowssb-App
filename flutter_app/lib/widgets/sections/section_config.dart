/// Shared section-type config schema for admin-fillable store / home rows.
///
/// Every new UI section type (glassy carousel, hyped row, spotlight, and
/// Maker-owned coupon / artist / category rows) reads one [SectionConfig].
/// Chief of Staff's section editor (CS-3…CS-7) saves the whole JSON per
/// section [id] through the server (with history for undo); the app reads
/// it live.
///
/// Rules:
///   * Top-level [id] is required (same id as the [LSection] / app_pages slot).
///   * Every other field is optional with defaults so older saved configs
///     still render.
///   * [fromJson] tolerates unknown keys (forward-compatible).
///   * Every model has [toJson] and [copyWith].
///
/// See /workspace/team-plan/ui-section-schema.md for the field contract.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// ─── Type ids ───────────────────────────────────────────────────────────────

/// Stable string ids for section types. Prefer these constants over raw
/// strings when registering builders or writing defaults.
abstract final class SectionTypeId {
  static const glassyCarousel = 'glassyCarousel';
  static const couponBanner = 'couponBanner';
  static const hypedRow = 'hypedRow';
  static const artistCards = 'artistCards';
  static const categoryTiles = 'categoryTiles';
  static const spotlight = 'spotlight';

  /// Dark media shelves (icon row + today card, collage, programs).
  static const todayDeck = 'todayDeck';
  static const madeForYou = 'madeForYou';
  static const programsForYou = 'programsForYou';

  /// Existing template kinds (kept so the registry can wrap them later).
  static const imageBanner = 'imageBanner';
  static const videoBanner = 'videoBanner';
  static const splitPromo = 'splitPromo';
  static const cardRow = 'cardRow';
  static const textBlock = 'textBlock';
  static const cta = 'cta';

  static const all = <String>{
    glassyCarousel,
    couponBanner,
    hypedRow,
    artistCards,
    categoryTiles,
    spotlight,
    todayDeck,
    madeForYou,
    programsForYou,
    imageBanner,
    videoBanner,
    splitPromo,
    cardRow,
    textBlock,
    cta,
  };
}

// ─── Helpers ────────────────────────────────────────────────────────────────

double? _d(dynamic v) => v is num ? v.toDouble() : null;
int? _i(dynamic v) => v is num ? v.toInt() : null;
bool? _b(dynamic v) => v is bool ? v : null;
String? _s(dynamic v) {
  if (v == null) return null;
  final t = '$v'.trim();
  return t.isEmpty ? null : t;
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> _mapList(dynamic v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

// ─── Animation ──────────────────────────────────────────────────────────────

/// Overlay kind for a per-section or per-card animation layer.
enum SectionOverlayKind { lottie, rive, orb }

/// Entry animation when the section (or card) appears.
enum SectionEntryAnim { fade, slideUp, scale, none }

/// Scroll-linked motion.
enum SectionScrollAnim { parallax, none }

/// Optional overlay drawn on top of a section or a single card.
@immutable
class SectionOverlayAnim {
  const SectionOverlayAnim({
    this.kind = SectionOverlayKind.orb,
    this.asset = '',
    this.align = Alignment.center,
    this.scale = 1,
    this.opacity = 1,
  });

  final SectionOverlayKind kind;
  final String asset;
  final Alignment align;
  final double scale;
  final double opacity;

  static SectionOverlayAnim? fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return null;
    return SectionOverlayAnim(
      kind: _overlayKind(_s(m['kind'])) ?? SectionOverlayKind.orb,
      asset: _s(m['asset']) ?? '',
      align: _align(m['align']) ?? Alignment.center,
      scale: _d(m['scale']) ?? 1,
      opacity: _d(m['opacity']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (asset.isNotEmpty) 'asset': asset,
        'align': _alignToJson(align),
        if (scale != 1) 'scale': scale,
        if (opacity != 1) 'opacity': opacity,
      };

  SectionOverlayAnim copyWith({
    SectionOverlayKind? kind,
    String? asset,
    Alignment? align,
    double? scale,
    double? opacity,
  }) =>
      SectionOverlayAnim(
        kind: kind ?? this.kind,
        asset: asset ?? this.asset,
        align: align ?? this.align,
        scale: scale ?? this.scale,
        opacity: opacity ?? this.opacity,
      );

  static SectionOverlayKind? _overlayKind(String? s) => switch (s) {
        'lottie' => SectionOverlayKind.lottie,
        'rive' => SectionOverlayKind.rive,
        'orb' => SectionOverlayKind.orb,
        _ => null,
      };

  static Alignment? _align(dynamic v) {
    if (v is String) {
      return switch (v) {
        'topLeft' => Alignment.topLeft,
        'topCenter' => Alignment.topCenter,
        'topRight' => Alignment.topRight,
        'centerLeft' => Alignment.centerLeft,
        'center' => Alignment.center,
        'centerRight' => Alignment.centerRight,
        'bottomLeft' => Alignment.bottomLeft,
        'bottomCenter' => Alignment.bottomCenter,
        'bottomRight' => Alignment.bottomRight,
        _ => null,
      };
    }
    if (v is Map) {
      final x = _d(v['x']);
      final y = _d(v['y']);
      if (x != null && y != null) return Alignment(x, y);
    }
    return null;
  }

  static Object _alignToJson(Alignment a) {
    final named = <Alignment, String>{
      Alignment.topLeft: 'topLeft',
      Alignment.topCenter: 'topCenter',
      Alignment.topRight: 'topRight',
      Alignment.centerLeft: 'centerLeft',
      Alignment.center: 'center',
      Alignment.centerRight: 'centerRight',
      Alignment.bottomLeft: 'bottomLeft',
      Alignment.bottomCenter: 'bottomCenter',
      Alignment.bottomRight: 'bottomRight',
    };
    return named[a] ?? {'x': a.x, 'y': a.y};
  }
}

/// Section- or card-level animation block.
@immutable
class SectionAnimation {
  const SectionAnimation({
    this.overlay,
    this.entry = SectionEntryAnim.none,
    this.scroll = SectionScrollAnim.none,
  });

  static const empty = SectionAnimation();

  final SectionOverlayAnim? overlay;
  final SectionEntryAnim entry;
  final SectionScrollAnim scroll;

  static SectionAnimation fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return empty;
    return SectionAnimation(
      overlay: SectionOverlayAnim.fromJson(m['overlay']),
      entry: _entry(_s(m['entry'])) ?? SectionEntryAnim.none,
      scroll: _scroll(_s(m['scroll'])) ?? SectionScrollAnim.none,
    );
  }

  Map<String, dynamic> toJson() => {
        if (overlay != null) 'overlay': overlay!.toJson(),
        if (entry != SectionEntryAnim.none) 'entry': entry.name,
        if (scroll != SectionScrollAnim.none) 'scroll': scroll.name,
      };

  SectionAnimation copyWith({
    SectionOverlayAnim? overlay,
    SectionEntryAnim? entry,
    SectionScrollAnim? scroll,
    bool clearOverlay = false,
  }) =>
      SectionAnimation(
        overlay: clearOverlay ? null : (overlay ?? this.overlay),
        entry: entry ?? this.entry,
        scroll: scroll ?? this.scroll,
      );

  static SectionEntryAnim? _entry(String? s) => switch (s) {
        'fade' => SectionEntryAnim.fade,
        'slideUp' => SectionEntryAnim.slideUp,
        'scale' => SectionEntryAnim.scale,
        'none' => SectionEntryAnim.none,
        _ => null,
      };

  static SectionScrollAnim? _scroll(String? s) => switch (s) {
        'parallax' => SectionScrollAnim.parallax,
        'none' => SectionScrollAnim.none,
        _ => null,
      };
}

// ─── Media item ─────────────────────────────────────────────────────────────

/// How an item's image fills its card.
enum SectionMediaFit { cover, contain }

/// One media card / tile inside a section.
@immutable
class SectionMediaItem {
  const SectionMediaItem({
    required this.id,
    this.imageUrl,
    this.videoUrl,
    this.title,
    this.subtitle,
    this.ctaLabel,
    this.ctaLink,
    this.rank,
    this.icon,
    this.meta = const {},
    this.focalX = 0,
    this.focalY = 0,
    this.zoom = 1,
    this.fit = SectionMediaFit.cover,
    this.animation,
  });

  /// Stable id for drag-reorder in the section editor.
  final String id;
  final String? imageUrl;
  final String? videoUrl;
  final String? title;
  final String? subtitle;
  final String? ctaLabel;
  final String? ctaLink;
  final int? rank;
  final String? icon;

  /// Free-form extras the section type understands (e.g. badge text).
  final Map<String, dynamic> meta;

  /// Image alignment inside the card, −1..1 (0 = center).
  final double focalX;
  final double focalY;

  /// Pinch-zoom inside the card, ≥1.
  final double zoom;
  final SectionMediaFit fit;

  /// Optional per-card overlay / entry / scroll animation.
  final SectionAnimation? animation;

  static SectionMediaItem? fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return null;
    final id = _s(m['id']);
    if (id == null) return null;
    final zoom = (_d(m['zoom']) ?? 1).clamp(1.0, 8.0);
    return SectionMediaItem(
      id: id,
      imageUrl: _s(m['imageUrl']),
      videoUrl: _s(m['videoUrl']),
      title: _s(m['title']),
      subtitle: _s(m['subtitle']),
      ctaLabel: _s(m['ctaLabel']),
      ctaLink: _s(m['ctaLink']),
      rank: _i(m['rank']),
      icon: _s(m['icon']),
      meta: _map(m['meta']) ?? const {},
      focalX: (_d(m['focalX']) ?? 0).clamp(-1.0, 1.0),
      focalY: (_d(m['focalY']) ?? 0).clamp(-1.0, 1.0),
      zoom: zoom,
      fit: _fit(_s(m['fit'])) ?? SectionMediaFit.cover,
      animation: m.containsKey('animation')
          ? SectionAnimation.fromJson(m['animation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (ctaLabel != null) 'ctaLabel': ctaLabel,
        if (ctaLink != null) 'ctaLink': ctaLink,
        if (rank != null) 'rank': rank,
        if (icon != null) 'icon': icon,
        if (meta.isNotEmpty) 'meta': meta,
        if (focalX != 0) 'focalX': focalX,
        if (focalY != 0) 'focalY': focalY,
        if (zoom != 1) 'zoom': zoom,
        if (fit != SectionMediaFit.cover) 'fit': fit.name,
        if (animation != null) 'animation': animation!.toJson(),
      };

  SectionMediaItem copyWith({
    String? id,
    String? imageUrl,
    String? videoUrl,
    String? title,
    String? subtitle,
    String? ctaLabel,
    String? ctaLink,
    int? rank,
    String? icon,
    Map<String, dynamic>? meta,
    double? focalX,
    double? focalY,
    double? zoom,
    SectionMediaFit? fit,
    SectionAnimation? animation,
    bool clearImageUrl = false,
    bool clearVideoUrl = false,
    bool clearTitle = false,
    bool clearSubtitle = false,
    bool clearCtaLabel = false,
    bool clearCtaLink = false,
    bool clearRank = false,
    bool clearIcon = false,
    bool clearAnimation = false,
  }) =>
      SectionMediaItem(
        id: id ?? this.id,
        imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
        videoUrl: clearVideoUrl ? null : (videoUrl ?? this.videoUrl),
        title: clearTitle ? null : (title ?? this.title),
        subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
        ctaLabel: clearCtaLabel ? null : (ctaLabel ?? this.ctaLabel),
        ctaLink: clearCtaLink ? null : (ctaLink ?? this.ctaLink),
        rank: clearRank ? null : (rank ?? this.rank),
        icon: clearIcon ? null : (icon ?? this.icon),
        meta: meta ?? this.meta,
        focalX: focalX ?? this.focalX,
        focalY: focalY ?? this.focalY,
        zoom: zoom ?? this.zoom,
        fit: fit ?? this.fit,
        animation: clearAnimation ? null : (animation ?? this.animation),
      );

  static SectionMediaFit? _fit(String? s) => switch (s) {
        'cover' => SectionMediaFit.cover,
        'contain' => SectionMediaFit.contain,
        _ => null,
      };
}

// ─── Layout / behavior / style ──────────────────────────────────────────────

@immutable
class SectionLayout {
  const SectionLayout({
    this.height,
    this.cardWidth,
    this.cardHeight,
    this.spacing,
    this.radius,
    this.padding,
    this.wrapperWidth,
    this.wrapperHeight,
    this.aspect,
  });

  static const empty = SectionLayout();

  final double? height;
  final double? cardWidth;
  final double? cardHeight;
  final double? spacing;
  final double? radius;
  final EdgeInsets? padding;

  /// Glass / outer wrapper size (CS-5 layout handles).
  final double? wrapperWidth;
  final double? wrapperHeight;

  /// Card aspect ratio (width / height). Alternative to [cardHeight].
  final double? aspect;

  static SectionLayout fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return empty;
    return SectionLayout(
      height: _d(m['height']),
      cardWidth: _d(m['cardWidth']),
      cardHeight: _d(m['cardHeight']),
      spacing: _d(m['spacing']),
      radius: _d(m['radius']),
      padding: _padding(m['padding']),
      wrapperWidth: _d(m['wrapperWidth']),
      wrapperHeight: _d(m['wrapperHeight']),
      aspect: _d(m['aspect']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (height != null) 'height': height,
        if (cardWidth != null) 'cardWidth': cardWidth,
        if (cardHeight != null) 'cardHeight': cardHeight,
        if (spacing != null) 'spacing': spacing,
        if (radius != null) 'radius': radius,
        if (padding != null) 'padding': _paddingToJson(padding!),
        if (wrapperWidth != null) 'wrapperWidth': wrapperWidth,
        if (wrapperHeight != null) 'wrapperHeight': wrapperHeight,
        if (aspect != null) 'aspect': aspect,
      };

  SectionLayout copyWith({
    double? height,
    double? cardWidth,
    double? cardHeight,
    double? spacing,
    double? radius,
    EdgeInsets? padding,
    double? wrapperWidth,
    double? wrapperHeight,
    double? aspect,
    bool clearHeight = false,
    bool clearCardWidth = false,
    bool clearCardHeight = false,
    bool clearSpacing = false,
    bool clearRadius = false,
    bool clearPadding = false,
    bool clearWrapperWidth = false,
    bool clearWrapperHeight = false,
    bool clearAspect = false,
  }) =>
      SectionLayout(
        height: clearHeight ? null : (height ?? this.height),
        cardWidth: clearCardWidth ? null : (cardWidth ?? this.cardWidth),
        cardHeight: clearCardHeight ? null : (cardHeight ?? this.cardHeight),
        spacing: clearSpacing ? null : (spacing ?? this.spacing),
        radius: clearRadius ? null : (radius ?? this.radius),
        padding: clearPadding ? null : (padding ?? this.padding),
        wrapperWidth: clearWrapperWidth ? null : (wrapperWidth ?? this.wrapperWidth),
        wrapperHeight: clearWrapperHeight ? null : (wrapperHeight ?? this.wrapperHeight),
        aspect: clearAspect ? null : (aspect ?? this.aspect),
      );

  static EdgeInsets? _padding(dynamic v) {
    if (v is num) {
      final n = v.toDouble();
      return EdgeInsets.all(n);
    }
    if (v is Map) {
      final all = _d(v['all']);
      if (all != null) return EdgeInsets.all(all);
      return EdgeInsets.fromLTRB(
        _d(v['left']) ?? _d(v['l']) ?? 0,
        _d(v['top']) ?? _d(v['t']) ?? 0,
        _d(v['right']) ?? _d(v['r']) ?? 0,
        _d(v['bottom']) ?? _d(v['b']) ?? 0,
      );
    }
    if (v is List && v.length == 4) {
      return EdgeInsets.fromLTRB(
        (v[0] as num).toDouble(),
        (v[1] as num).toDouble(),
        (v[2] as num).toDouble(),
        (v[3] as num).toDouble(),
      );
    }
    return null;
  }

  static Object _paddingToJson(EdgeInsets p) {
    if (p.left == p.right && p.left == p.top && p.left == p.bottom) {
      return p.left;
    }
    return {'left': p.left, 'top': p.top, 'right': p.right, 'bottom': p.bottom};
  }
}

@immutable
class SectionBehavior {
  const SectionBehavior({
    this.autoplay = false,
    this.autoplayMs = 4000,
    this.startIndex = 0,
    this.itemCount,
    this.loop = true,
  });

  static const defaults = SectionBehavior();

  final bool autoplay;
  final int autoplayMs;
  final int startIndex;

  /// Cap how many items to show; null = all.
  final int? itemCount;
  final bool loop;

  static SectionBehavior fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return defaults;
    return SectionBehavior(
      autoplay: _b(m['autoplay']) ?? false,
      autoplayMs: _i(m['autoplayMs']) ?? 4000,
      startIndex: _i(m['startIndex']) ?? 0,
      itemCount: _i(m['itemCount']),
      loop: _b(m['loop']) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (autoplay) 'autoplay': autoplay,
        if (autoplayMs != 4000) 'autoplayMs': autoplayMs,
        if (startIndex != 0) 'startIndex': startIndex,
        if (itemCount != null) 'itemCount': itemCount,
        if (!loop) 'loop': loop,
      };

  SectionBehavior copyWith({
    bool? autoplay,
    int? autoplayMs,
    int? startIndex,
    int? itemCount,
    bool? loop,
    bool clearItemCount = false,
  }) =>
      SectionBehavior(
        autoplay: autoplay ?? this.autoplay,
        autoplayMs: autoplayMs ?? this.autoplayMs,
        startIndex: startIndex ?? this.startIndex,
        itemCount: clearItemCount ? null : (itemCount ?? this.itemCount),
        loop: loop ?? this.loop,
      );
}

@immutable
class SectionStyle {
  const SectionStyle({
    this.glass = false,
    this.glowColor,
    this.accent,
  });

  static const empty = SectionStyle();

  final bool glass;

  /// ARGB int, e.g. 0xFFE8D5A3.
  final int? glowColor;
  final int? accent;

  static SectionStyle fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return empty;
    return SectionStyle(
      glass: _b(m['glass']) ?? false,
      glowColor: _i(m['glowColor']),
      accent: _i(m['accent']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (glass) 'glass': glass,
        if (glowColor != null) 'glowColor': glowColor,
        if (accent != null) 'accent': accent,
      };

  SectionStyle copyWith({
    bool? glass,
    int? glowColor,
    int? accent,
    bool clearGlowColor = false,
    bool clearAccent = false,
  }) =>
      SectionStyle(
        glass: glass ?? this.glass,
        glowColor: clearGlowColor ? null : (glowColor ?? this.glowColor),
        accent: clearAccent ? null : (accent ?? this.accent),
      );
}

// ─── Top-level config ───────────────────────────────────────────────────────

/// One section's full config blob, keyed by [id] on the server.
@immutable
class SectionConfig {
  const SectionConfig({
    required this.id,
    this.type = SectionTypeId.cardRow,
    this.version = 0,
    this.enabled = true,
    this.items = const [],
    this.layout = SectionLayout.empty,
    this.behavior = SectionBehavior.defaults,
    this.style = SectionStyle.empty,
    this.animation = SectionAnimation.empty,
  });

  /// Same id as the [LSection] / app_pages slot. Required.
  final String id;

  /// One of [SectionTypeId] (or a future string the registry knows).
  final String type;

  /// Bumped on every editor save; used for undo / rollback.
  final int version;

  final bool enabled;
  final List<SectionMediaItem> items;
  final SectionLayout layout;
  final SectionBehavior behavior;
  final SectionStyle style;
  final SectionAnimation animation;

  /// Parse JSON. Unknown keys are ignored. Returns null only when [id] is
  /// missing / empty — every other field falls back to defaults.
  static SectionConfig? fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return null;
    final id = _s(m['id']);
    if (id == null) return null;
    final items = <SectionMediaItem>[
      for (final e in _mapList(m['items']))
        if (SectionMediaItem.fromJson(e) case final item?) item,
    ];
    return SectionConfig(
      id: id,
      type: _s(m['type']) ?? SectionTypeId.cardRow,
      version: _i(m['version']) ?? 0,
      enabled: _b(m['enabled']) ?? true,
      items: items,
      layout: SectionLayout.fromJson(m['layout']),
      behavior: SectionBehavior.fromJson(m['behavior']),
      style: SectionStyle.fromJson(m['style']),
      animation: SectionAnimation.fromJson(m['animation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'version': version,
        'enabled': enabled,
        if (items.isNotEmpty) 'items': [for (final i in items) i.toJson()],
        if (layout.toJson().isNotEmpty) 'layout': layout.toJson(),
        if (behavior.toJson().isNotEmpty) 'behavior': behavior.toJson(),
        if (style.toJson().isNotEmpty) 'style': style.toJson(),
        if (animation.toJson().isNotEmpty) 'animation': animation.toJson(),
      };

  SectionConfig copyWith({
    String? id,
    String? type,
    int? version,
    bool? enabled,
    List<SectionMediaItem>? items,
    SectionLayout? layout,
    SectionBehavior? behavior,
    SectionStyle? style,
    SectionAnimation? animation,
  }) =>
      SectionConfig(
        id: id ?? this.id,
        type: type ?? this.type,
        version: version ?? this.version,
        enabled: enabled ?? this.enabled,
        items: items ?? this.items,
        layout: layout ?? this.layout,
        behavior: behavior ?? this.behavior,
        style: style ?? this.style,
        animation: animation ?? this.animation,
      );
}
