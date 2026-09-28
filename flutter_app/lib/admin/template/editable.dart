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

import '../admin_state.dart';
import 'slot_keys.dart';
import 'slot_sheet.dart';
import 'ui_overrides.dart';

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
    SlotRegistry.instance.see(key, SlotType.text, data);
    final text = UiOverrides.instance.textFor(key) ?? data;
    final child = Text(
      text,
      style: style,
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
    if (!EditMode.instance.on) return child;
    return SlotBadge(slotKey: key, type: SlotType.text, defaultValue: data, child: child);
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

  String get slotKey => '$slot.${id ?? slotMediaId(source)}';

  Widget _default() {
    if (network) {
      return Image.network(
        source,
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
      source,
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

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final key = slotKey;
    SlotRegistry.instance.see(key, SlotType.image, source);
    final o = UiOverrides.instance.mediaFor(key, SlotType.image);
    final Widget child = o == null
        ? _default()
        : Image(
            image: overrideImageProvider(o.url, cacheWidth, cacheHeight),
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
            frameBuilder: (context, img, frame, sync) =>
                (frame == null && !sync) ? _default() : img,
            errorBuilder: (_, __, ___) => _default(),
          );
    if (!EditMode.instance.on) return child;
    return SlotBadge(slotKey: key, type: SlotType.image, defaultValue: source, child: child);
  }
}

/// The provider for an override picture: the downloaded file once it is on
/// disk, the cached network image until then.
ImageProvider overrideImageProvider(String url, [int? cacheWidth, int? cacheHeight]) {
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
  SlotRegistry.instance.see(key, SlotType.image, asset);
  final o = UiOverrides.instance.mediaFor(key, SlotType.image);
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
    SlotRegistry.instance.see(key, SlotType.image, source);
    final o = UiOverrides.instance.mediaFor(key, SlotType.image);
    final Widget child = o == null
        ? _default()
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
    if (!EditMode.instance.on) return child;
    return SlotBadge(slotKey: key, type: SlotType.image, defaultValue: source, child: child);
  }
}

/// The pencil drawn on an editable element in edit mode. Only ever built
/// when [EditMode.on], so it costs nothing for everyone else.
class SlotBadge extends StatelessWidget {
  const SlotBadge({
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
  Widget build(BuildContext context) {
    final overridden = UiOverrides.instance.get(slotKey) != null;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: overridden ? const Color(0xCC34D399) : const Color(0x99E8D5A3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openSlotSheet(
              context,
              slotKey: slotKey,
              type: type,
              defaultValue: defaultValue,
            ),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: overridden ? const Color(0xFF34D399) : const Color(0xFFE8D5A3),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
              ),
              child: Icon(
                type == SlotType.text
                    ? Icons.edit_rounded
                    : (type == SlotType.video ? Icons.movie_edit : Icons.image_rounded),
                size: 13,
                color: const Color(0xFF060C18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
