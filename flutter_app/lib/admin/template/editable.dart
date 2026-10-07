/// Editable wrappers — the ONLY way new UI should draw a picture, a clip or
/// a piece of fixed copy.
///
///   EditableImage.asset(kHeroArt, slot: 'store.meaning.hero', fit: …)
///   NwsbVideo(asset: kHeroFilm, slot: 'home.normal.hero')
///   EditableLabel('home.normal.hero', 'Start today', style: …)
///   EditableSvg.asset(kHeaderIcon, slot: 'profile.header', …)
///
/// With no override each wrapper builds EXACTLY the widget it replaces
/// (Image.asset, Text, SvgPicture.asset) with the same arguments, so the
/// default look is pixel-identical. With an override it draws the owner's
/// replacement, keeping the default visible until the replacement is ready
/// so nothing ever flashes blank.
///
/// Every wrapper registers its slot while it builds, which is what makes a
/// new section show up in the admin editor with no admin update: build it
/// with these, and the owner can edit it the first time it is on screen.
/// See lib/admin/README.md.
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/word_art.dart';
import '../admin_state.dart';
import '../layout/anims/effects.dart' show LoopFx;
import '../layout/element_flow.dart';
import '../layout/image_frame.dart';
import '../layout/layout_sections.dart' show SectionEntrance;
import '../layout/scopes.dart';
import 'slot_keys.dart';
import 'slot_sheet.dart';
import 'style_apply.dart';
import 'ui_overrides.dart';

/// Records that [key] was drawn (and in which section).
void slotSeen(BuildContext context, String key, SlotType type, String def) {
  SlotRegistry.instance.see(key, type, def, SectionScope.keyOf(context));
}

/// A replacement picture/clip to draw now (pending edit in the preview,
/// else the live one), or null for the default.
UiOverride? mediaOverride(BuildContext context, String key, SlotType type) {
  final o = effectiveOverride(context, key);
  if (o == null || o.type != type || o.url.isEmpty) return null;
  return o;
}

IconData slotIcon(SlotType type) => switch (type) {
      SlotType.text => Icons.edit_rounded,
      SlotType.video => Icons.movie_edit,
      SlotType.image => Icons.image_rounded,
      SlotType.orb => Icons.blur_circular_rounded,
    };

/// A film or picture sitting under a parent button: the tap falls through
/// to that button.
class EditMedia extends StatelessWidget {
  const EditMedia({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: child);
  }
}

/// What goes around an editable element: nothing in the user app (only its
/// saved placement); a tappable marker in the UI Editor's preview.
Widget slotChrome(
  BuildContext context,
  String key,
  SlotType type,
  String def,
  Widget child, {
  String? word,
}) {
  final preview = EditorPreviewScope.peek(context) != null;
  final look = effectiveOverride(context, key)?.style ?? const <String, dynamic>{};
  // A picture's own crop, zoom and frame (layout/image_frame.dart).
  if (type == SlotType.image || type == SlotType.video) {
    final f = framingOf(look);
    if (f != null) child = ImageFrame(framing: f, child: child);
  }
  if (preview) {
    return elementPlacement(look, PreviewSlotMarker(slotKey: key, type: type, defaultValue: def, child: child),
        preview: true);
  }
  return elementPlacement(look, child);
}

/// Where the owner moved, resized, hid or deleted one element in the UI
/// Editor (override style `dx`, `dy`, `scale`, `hidden`, `removed`), its
/// picture crop and frame (`cropZoom`, `cropX`, `cropY`, `round`, `lift`),
/// plus the `entrance` and `loop` effects dropped on it. A pinch (`scale`)
/// and a vertical move (`dy`) change the room it takes, so what is under
/// it reflows (layout/element_flow.dart); a sideways move is painted only.
/// Deleted elements are gone everywhere (Undo brings them back); hidden
/// ones stay faintly visible in the editor's preview.
Widget elementPlacement(Map<String, dynamic> look, Widget child, {bool preview = false}) {
  if (look.isEmpty) return child;
  double n(String k, double d) => look[k] is num ? (look[k] as num).toDouble() : d;
  if (look['removed'] == true) return const SizedBox.shrink();
  if (look['hidden'] == true) {
    if (!preview) return const SizedBox.shrink();
    child = Opacity(opacity: 0.22, child: child);
  }
  final cz = n('cropZoom', 1).clamp(1.0, 4.0), cx = n('cropX', 0).clamp(-1.0, 1.0), cy = n('cropY', 0).clamp(-1.0, 1.0);
  if (cz > 1.01) child = ClipRect(child: Transform.scale(scale: cz, alignment: Alignment(cx, cy), child: child));
  final round = n('round', 0), lift = n('lift', 0);
  if (round > 0.5) child = ClipRRect(borderRadius: BorderRadius.circular(round), child: child);
  if (lift > 0.5) {
    child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(round),
        boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lift * 2, offset: Offset(0, lift / 2))],
      ),
      child: child,
    );
  }
  final s = n('scale', 1).clamp(0.2, 6.0);
  final dx = n('dx', 0), dy = n('dy', 0);
  if ((s - 1).abs() > 0.01 || dy.abs() > 0.5) child = ElementFlow(scale: s, dy: dy, child: child);
  if (dx.abs() > 0.5) child = Transform.translate(offset: Offset(dx, 0), child: child);
  // Effects dropped on the element (anims/effects.dart).
  final loop = look['loop'];
  if (loop is String && loop != 'none') child = LoopFx(kind: loop, child: child);
  final ent = look['entrance'];
  if (ent is String && ent != 'none') child = SectionEntrance(kind: ent, child: child);
  return child;
}

/// Zoom stored on the shared word picture, else the zoom saved on this slot.
double slotZoom(String slotKey, {String? word}) {
  if (word != null && word.isNotEmpty && WordArt.instance.tracked(word)) {
    return WordArt.instance.scaleOf(word);
  }
  final z = UiOverrides.instance.get(slotKey)?.style['zoom'];
  if (z is num) return z.toDouble().clamp(0.5, 2.6);
  return 1;
}

Widget zoomBox(Widget child, double zoom) {
  if ((zoom - 1).abs() < 0.02) return child;
  return ClipRect(
    child: Transform.scale(scale: zoom, alignment: Alignment.center, child: child),
  );
}

/// Fixed copy. Named Label because Flutter already has an `EditableText`.
class EditableLabel extends StatelessWidget {
  const EditableLabel(
    this.slot,
    this.data, {
    super.key,
    this.id,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  /// Where: `<file>.<Class>` or an author-chosen section name.
  final String slot;
  final String data;

  /// Optional exact element name; defaults to a slug of [data].
  final String? id;

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  String get slotKey => '$slot.${id ?? slotSlug(data)}';

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final key = slotKey;
    slotSeen(context, key, SlotType.text, data);
    final o = effectiveOverride(context, key);
    // A template section's words come from its props only (one source of
    // truth); its overrides still restyle it.
    final text = (o != null && o.type == SlotType.text && o.textSet && !isTemplateSlot(key)) ? o.text : data;
    final look = o?.style ?? const <String, dynamic>{};
    Widget child = Text(
      text,
      style: look.isEmpty ? style : applyTextLook(style, look),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
    if (look.isNotEmpty) child = applyTextDecor(child, look);
    return slotChrome(context, key, SlotType.text, data, child);
  }
}

/// A picture. `.asset` and `.network` mirror Image.asset / Image.network.
class EditableImage extends StatelessWidget {
  const EditableImage.asset(
    this.source, {
    super.key,
    this.slot = 'app',
    this.id,
    this.bundle,
    this.frameBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.scale,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.package,
    this.filterQuality = FilterQuality.medium,
    this.cacheWidth,
    this.cacheHeight,
    this.word,
  })  : network = false,
        loadingBuilder = null,
        headers = null;

  const EditableImage.network(
    this.source, {
    super.key,
    this.slot = 'app',
    this.id,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    double this.scale = 1.0,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.headers,
    this.cacheWidth,
    this.cacheHeight,
    this.word,
  })  : network = true,
        bundle = null,
        package = null;

  final String source;
  final bool network;
  final String slot;
  final String? id;
  final AssetBundle? bundle;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final double? scale;
  final double? width;
  final double? height;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final bool isAntiAlias;
  final String? package;
  final FilterQuality filterQuality;
  final int? cacheWidth;
  final int? cacheHeight;
  final Map<String, String>? headers;

  /// When set, this picture is the word's picture. One upload covers every
  /// place that word is drawn (library, meaning, signature, ebook).
  final String? word;

  String get slotKey =>
      '$slot.${id ?? (word != null && word!.isNotEmpty ? 'word-${WordArt.keyOf(word!)}' : slotMediaId(source))}';

  Widget _picture(String src) {
    if (src.startsWith('http')) {
      return Image.network(
        src,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        gaplessPlayback: true,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
    }
    if (network) {
      return Image.network(
        src,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        scale: scale ?? 1.0,
        width: width,
        height: height,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        headers: headers,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
    }
    return Image.asset(
      src,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  Widget _painted(String src, UiOverride? replaced) {
    if (replaced != null) {
      return Image(
        image: overrideImageProvider(replaced.url, cacheWidth, cacheHeight),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        opacity: opacity,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        gaplessPlayback: true,
        frameBuilder: (context, img, frame, sync) => (frame == null && !sync) ? _picture(src) : img,
        errorBuilder: (_, __, ___) => _picture(src),
      );
    }
    return _picture(src);
  }

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final bound = word;
    if (bound != null && bound.isNotEmpty) {
      return ListenableBuilder(
        listenable: WordArt.instance,
        builder: (context, _) {
          final key = slotKey;
          slotSeen(context, key, SlotType.image, source);
          final slotPic = mediaOverride(context, key, SlotType.image);
          final legacy = mediaOverride(context, '$slot.${slotMediaId(source)}', SlotType.image);
          final seeded = slotPic ?? legacy;
          final saved = WordArt.instance.imageOf(bound);
          if ((saved == null || saved.isEmpty) && seeded != null && seeded.url.startsWith('http')) {
            final url = seeded.url;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              WordArt.instance.set(bound, image: url, pushHistory: false);
            });
          }
          final src = (saved != null && saved.isNotEmpty) ? saved : source;
          final child = zoomBox(
            _painted(src, saved != null && saved.isNotEmpty ? null : seeded),
            WordArt.instance.scaleOf(bound),
          );
          return slotChrome(context, key, SlotType.image, source, child, word: bound);
        },
      );
    }
    final key = slotKey;
    slotSeen(context, key, SlotType.image, source);
    final o = mediaOverride(context, key, SlotType.image);
    final child = zoomBox(_painted(source, o), slotZoom(key));
    return slotChrome(context, key, SlotType.image, source, child);
  }
}

/// The provider for an override picture: the downloaded file once it is on
/// disk, the cached network image until then.
ImageProvider overrideImageProvider(String url, [int? cacheWidth, int? cacheHeight]) {
  if (url.startsWith('asset:')) return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, AssetImage(url.substring(6)));
  final path = UiOverrides.instance.fileFor(url);
  final ImageProvider base =
      path != null ? FileImage(File(path)) : CachedNetworkImageProvider(url);
  return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, base);
}

/// For pictures drawn as a decoration (BoxDecoration / DecorationImage)
/// rather than a widget. Registers the slot and returns the override's
/// provider, or [fallback] when there is none. No pencil badge — find these
/// in Admin → Template editor → All slots.
ImageProvider slotImageProvider(
  BuildContext context,
  String slot,
  String asset,
  ImageProvider fallback,
) {
  UiScope.watch(context);
  final key = '$slot.${slotMediaId(asset)}';
  slotSeen(context, key, SlotType.image, asset);
  final o = mediaOverride(context, key, SlotType.image);
  if (o == null) return fallback;
  return overrideImageProvider(o.url);
}

/// An SVG icon/illustration from the bundle. An override replaces it with
/// the uploaded picture at the same size.
class EditableSvg extends StatelessWidget {
  const EditableSvg.asset(
    this.source, {
    super.key,
    this.slot = 'app',
    this.id,
    this.matchTextDirection = false,
    this.bundle,
    this.package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.clipBehavior = Clip.hardEdge,
    this.colorFilter,
  });

  final String source;
  final String slot;
  final String? id;
  final bool matchTextDirection;
  final AssetBundle? bundle;
  final String? package;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool allowDrawingOutsideViewBox;
  final WidgetBuilder? placeholderBuilder;
  final String? semanticsLabel;
  final bool excludeFromSemantics;
  final Clip clipBehavior;
  final ColorFilter? colorFilter;

  String get slotKey => '$slot.${id ?? slotMediaId(source)}';

  Widget _default() => SvgPicture.asset(
        source,
        matchTextDirection: matchTextDirection,
        bundle: bundle,
        package: package,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
        clipBehavior: clipBehavior,
        colorFilter: colorFilter,
      );

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final key = slotKey;
    slotSeen(context, key, SlotType.image, source);
    final o = mediaOverride(context, key, SlotType.image);
    final Widget child = o == null
        ? _default()
        : isSvgUrl(o.url)
            ? overrideSvg(o.url, width: width, height: height, fit: fit, alignment: alignment, colorFilter: colorFilter, fallback: _default)
            : Image(
                image: overrideImageProvider(o.url),
                width: width,
                height: height,
                fit: fit,
                alignment: alignment,
                gaplessPlayback: true,
                frameBuilder: (context, img, frame, sync) =>
                    (frame == null && !sync) ? _default() : img,
                errorBuilder: (_, __, ___) => _default(),
              );
    return slotChrome(context, key, SlotType.image, source, child);
  }
}

/// True for an SVG replacement: a bundled `asset:…svg` or an uploaded .svg.
bool isSvgUrl(String url) => Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? url.toLowerCase().endsWith('.svg');

/// Draws an SVG replacement — from the bundle (`asset:`), the downloaded
/// copy, or the network — at the slot's size. Falls back to the default.
Widget overrideSvg(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  AlignmentGeometry alignment = Alignment.center,
  ColorFilter? colorFilter,
  required Widget Function() fallback,
}) {
  if (url.startsWith('asset:')) {
    return SvgPicture.asset(url.substring(6), width: width, height: height, fit: fit, alignment: alignment, colorFilter: colorFilter,
        placeholderBuilder: (_) => fallback());
  }
  final path = UiOverrides.instance.fileFor(url);
  if (path != null) {
    return SvgPicture.file(File(path), width: width, height: height, fit: fit, alignment: alignment, colorFilter: colorFilter,
        placeholderBuilder: (_) => fallback());
  }
  return SvgPicture.network(url, width: width, height: height, fit: fit, alignment: alignment, colorFilter: colorFilter,
      placeholderBuilder: (_) => fallback());
}

/// In the UI Editor's preview: registers where the element is so the
/// editor can draw a tappable hotspot over it (the page itself does not
/// take taps there, so buttons in the preview never navigate away).
class PreviewSlotMarker extends StatefulWidget {
  const PreviewSlotMarker({
    super.key,
    required this.slotKey,
    required this.type,
    required this.defaultValue,
    required this.child,
  });

  final String slotKey;
  final SlotType type;
  final String defaultValue;
  final Widget child;

  @override
  State<PreviewSlotMarker> createState() => _PreviewSlotMarkerState();
}

class _PreviewSlotMarkerState extends State<PreviewSlotMarker> {
  final GlobalKey _box = GlobalKey();
  EditorPreviewController? _ctl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = EditorPreviewScope.peek(context);
    if (c != _ctl) {
      _ctl?.unmountSlot(_box);
      _ctl = c;
    }
    _ctl?.mountSlot(PreviewSlot(
        widget.slotKey, widget.type, widget.defaultValue, _box, SectionScope.keyOf(context)));
  }

  @override
  void didUpdateWidget(PreviewSlotMarker old) {
    super.didUpdateWidget(old);
    if (old.slotKey != widget.slotKey) {
      _ctl?.mountSlot(PreviewSlot(
          widget.slotKey, widget.type, widget.defaultValue, _box, SectionScope.keyOf(context)));
    }
  }

  @override
  void dispose() {
    _ctl?.unmountSlot(_box);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _box, child: widget.child);
}
