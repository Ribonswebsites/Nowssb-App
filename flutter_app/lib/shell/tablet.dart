/// Tablet layout: breakpoints and the small helpers every page uses to fit a
/// wide screen.
///
/// Phones (under [TabletBp.rail] wide) never see any of this: every helper
/// returns its child untouched there, so the phone layout is exactly the one
/// it always was.
///
///   * under 600      phone: drawer + bottom nav, as before.
///   * 600 to 839     a nav rail on the left (see tablet_frame.dart).
///   * 840 and more   a permanent left sidebar; the homes, the Sound Library
///                    and the player also get a right panel once the centre
///                    is wide enough ([TabletBp.panel]).
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TabletBp {
  const TabletBp._();

  /// Smallest width that is laid out as a tablet (nav rail).
  static const double rail = 600;

  /// Smallest width with the full sidebar.
  static const double wide = 840;

  /// Smallest centre width (after the sidebar) that also gets a right panel.
  static const double panel = 980;

  /// Width of the sidebar and the rail.
  static const double sidebarWidth = 256;
  static const double railWidth = 84;

  /// Width of the right panel.
  static const double panelWidth = 300;

  /// Widest the centre panel gets on a page without a right panel.
  static const double page = 780;

  /// Reading width for pages that are one column of panes and rows.
  static const double content = 760;

  /// Width for forms, sign-in and checkout-like pages.
  static const double form = 560;

  /// Width cap for bottom sheets and custom pop-ups.
  static const double sheet = 640;
}

enum TabletWidth { phone, rail, wide }

TabletWidth tabletWidthFor(double width) => width >= TabletBp.wide
    ? TabletWidth.wide
    : width >= TabletBp.rail
        ? TabletWidth.rail
        : TabletWidth.phone;

/// True when the screen this context draws on is a tablet. Reads the
/// app-wide [TabletScope] first (the centre pane is narrower than the
/// screen), then the media width.
bool isTablet(BuildContext context) {
  final scope = TabletScope.maybeOf(context);
  if (scope != null) return scope.width != TabletWidth.phone;
  return MediaQuery.sizeOf(context).width >= TabletBp.rail;
}

/// Grid columns: [phone] on a phone, else as many [minTile]-wide tiles as
/// fit [width] (never fewer than [phone], never more than [max]).
int tabletColumns(BuildContext context, double width,
    {required int phone, double minTile = 180, int max = 6}) {
  if (!isTablet(context)) return phone;
  return math.max(phone, math.min(max, (width / minTile).floor()));
}

/// The app-wide tablet state, published by TabletFrame above the navigator.
class TabletScope extends InheritedWidget {
  const TabletScope({
    super.key,
    required this.width,
    required this.framed,
    required super.child,
  });

  /// The screen's width class (not the centre pane's).
  final TabletWidth width;

  /// True while the sidebar or rail is showing beside the pages, so the
  /// shell hides its own bottom nav and mini player.
  final bool framed;

  static TabletScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabletScope>();

  /// Is the sidebar / rail on screen right now?
  static bool framedOf(BuildContext context) => maybeOf(context)?.framed ?? false;

  @override
  bool updateShouldNotify(TabletScope old) =>
      old.width != width || old.framed != framed;
}

/// Centres [child] at [maxWidth] on a tablet. A phone gets [child] as is.
///
/// Uses padding rather than a loose box so a scroll view keeps tight
/// constraints (and its scroll bar sits at the content's edge).
class TabletContent extends StatelessWidget {
  const TabletContent({
    super.key,
    required this.child,
    this.maxWidth = TabletBp.content,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return child;
    return LayoutBuilder(builder: (context, c) {
      if (!c.hasBoundedWidth || c.maxWidth <= maxWidth) return child;
      final side = (c.maxWidth - maxWidth) / 2;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: side),
        child: child,
      );
    });
  }
}

/// A sliver version of [TabletContent] for CustomScrollViews.
class SliverTabletContent extends StatelessWidget {
  const SliverTabletContent({
    super.key,
    required this.sliver,
    this.maxWidth = TabletBp.content,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return sliver;
    return SliverLayoutBuilder(builder: (context, c) {
      final w = c.crossAxisExtent;
      if (w <= maxWidth) return sliver;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: (w - maxWidth) / 2),
        sliver: sliver,
      );
    });
  }
}

/// Caps a full-screen pop-up or sheet at [maxWidth] on a tablet, keeping
/// it full height (tight constraints) so a sheet that lays itself out at
/// the bottom still does. A phone gets [child] as is. Taps beside the
/// capped pop-up land on its route's barrier.
class TabletSheet extends StatelessWidget {
  const TabletSheet({
    super.key,
    required this.child,
    this.maxWidth = TabletBp.sheet,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return child;
    return LayoutBuilder(builder: (context, c) {
      if (!c.hasBoundedWidth || c.maxWidth <= maxWidth) return child;
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: maxWidth,
          height: c.hasBoundedHeight ? c.maxHeight : null,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(maxWidth, MediaQuery.sizeOf(context).height),
            ),
            child: child,
          ),
        ),
      );
    });
  }
}

/// [AspectRatio] that does not blow a picture up on a tablet: there the box
/// keeps the full width but is at most [maxHeight] tall (the picture, set
/// to cover, is cropped wider instead of growing). A phone gets a plain
/// [AspectRatio], so its layout is exactly what it was.
class TabletAspectRatio extends StatelessWidget {
  const TabletAspectRatio({
    super.key,
    required this.aspectRatio,
    this.child,
    this.maxHeight,
    this.keepShape = false,
  });

  /// Keep the true aspect ratio on a tablet: a box that would be taller than
  /// [maxHeight] gets narrower instead (centred), for things drawn to their
  /// box's width, like a device frame and the text on its screen.
  final bool keepShape;

  final double aspectRatio;
  final Widget? child;

  /// Defaults to 560 for portrait boxes and 420 for the rest.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return AspectRatio(aspectRatio: aspectRatio, child: child);
    if (keepShape) {
      final cap = maxHeight ?? (aspectRatio < 1 ? 560 : 420);
      return LayoutBuilder(builder: (context, c) {
        final w = c.hasBoundedWidth ? c.maxWidth : cap * aspectRatio;
        final width = math.min(w, cap * aspectRatio);
        return Center(
          child: SizedBox(width: width, child: AspectRatio(aspectRatio: aspectRatio, child: child)),
        );
      });
    }
    return _CappedAspect(
      aspectRatio: aspectRatio,
      maxHeight: maxHeight ?? (aspectRatio < 1 ? 560 : 420),
      child: child,
    );
  }
}

class _CappedAspect extends SingleChildRenderObjectWidget {
  const _CappedAspect({required this.aspectRatio, required this.maxHeight, super.child});
  final double aspectRatio;
  final double maxHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCappedAspect(aspectRatio, maxHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderCappedAspect r) {
    r
      ..aspectRatio = aspectRatio
      ..maxHeight = maxHeight;
  }
}

class _RenderCappedAspect extends RenderProxyBox {
  _RenderCappedAspect(this._aspectRatio, this._maxHeight);

  double _aspectRatio;
  set aspectRatio(double v) {
    if (v == _aspectRatio) return;
    _aspectRatio = v;
    markNeedsLayout();
  }

  double _maxHeight;
  set maxHeight(double v) {
    if (v == _maxHeight) return;
    _maxHeight = v;
    markNeedsLayout();
  }

  Size _sizeFor(BoxConstraints c) {
    if (c.isTight) return c.smallest;
    var w = c.maxWidth;
    double h;
    if (w.isFinite) {
      h = math.min(w / _aspectRatio, _maxHeight);
    } else {
      h = math.min(c.maxHeight, _maxHeight);
      w = h * _aspectRatio;
    }
    if (h > c.maxHeight) {
      h = c.maxHeight;
      if (!c.maxWidth.isFinite) w = h * _aspectRatio;
    }
    return c.constrain(Size(w, h));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      height.isFinite ? height * _aspectRatio : 0;
  @override
  double computeMaxIntrinsicWidth(double height) =>
      height.isFinite ? height * _aspectRatio : 0;
  @override
  double computeMinIntrinsicHeight(double width) =>
      width.isFinite ? math.min(width / _aspectRatio, _maxHeight) : 0;
  @override
  double computeMaxIntrinsicHeight(double width) =>
      width.isFinite ? math.min(width / _aspectRatio, _maxHeight) : 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _sizeFor(constraints);

  @override
  void performLayout() {
    size = _sizeFor(constraints);
    child?.layout(BoxConstraints.tight(size));
  }
}

/// True on a device whose shortest side is a tablet's (600+ logical px).
/// Read before the first frame, from the platform's first display.
bool isTabletDevice() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return false;
  final v = views.first;
  if (v.devicePixelRatio <= 0) return false;
  final size = v.physicalSize / v.devicePixelRatio;
  return size.shortestSide >= TabletBp.rail;
}

/// [tabletColumns] for the width of the pane this context draws in.
int tabletColumnsOf(BuildContext context,
        {required int phone, double minTile = 180, int max = 6}) =>
    tabletColumns(context, MediaQuery.sizeOf(context).width,
        phone: phone, minTile: minTile, max: max);
