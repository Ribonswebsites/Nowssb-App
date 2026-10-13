/// The user app's shared motion and glass widgets. Every number they use
/// comes from `theme/motion_glass.dart`.
///
/// * [GlassSurface]: liquid glass where the renderer can run, a capped
///   BackdropFilter blur + tint where it can't, and tint only inside
///   scrolling lists (no stacked backdrop blurs while scrolling).
/// * [SpringPress]: buttons, chips, cards and tabs sink and spring back.
/// * [BubblePopIn]: a bubble springs out of its origin, wobbles, settles.
/// * [GlassBubble]: a chat / thought bubble with a tail.
/// * [GlassMorphCard]: tap a card and it grows into a glass sheet; tap
///   outside or close and it springs back into place.
/// * [showGlassDialog], [showGlassSheet], [showGlassToast], [SpringIn].
///
/// With reduce-motion on (system "remove animations" or an accessibility
/// service), every one of them falls back to a plain fade.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart' as lgr;

import '../theme/motion_glass.dart';

export '../theme/motion_glass.dart';

// ─── Glass ──────────────────────────────────────────────────────────────────

/// A rounded glass panel.
///
/// [refract] asks for real liquid glass (liquid_glass_renderer). It is used
/// only when [NwsbGlass.rendererAvailable]; otherwise the panel blurs the
/// backdrop with a BackdropFilter (sigma capped by [NwsbGlass.maxBlur]) and
/// lays the tint over it.
///
/// [blur] null means "blur unless inside a scrolling list": a list of glass
/// cards would otherwise stack one BackdropFilter per card and stutter on
/// low-end phones. Pass true or false to decide yourself.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.style = NwsbGlass.card,
    this.padding,
    this.radius,
    this.refract = false,
    this.blur,
  });

  final Widget child;
  final NwsbGlassStyle style;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final bool refract;
  final bool? blur;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? style.radius;
    final br = BorderRadius.circular(r);
    final body = padding == null ? child : Padding(padding: padding!, child: child);
    final sheen = BoxDecoration(
      borderRadius: br,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [style.highlight, style.highlight.withAlpha(0)],
      ),
    );
    if (refract && NwsbGlass.rendererAvailable) {
      return lgr.LiquidGlass.withOwnLayer(
        key: const ValueKey('nwsb-glass-renderer'),
        settings: lgr.LiquidGlassSettings(
          thickness: 18,
          blur: style.sigma * 0.5,
          glassColor: style.tint.withAlpha((style.tint.a * 255 * 0.8).round()),
          lightIntensity: 0.6,
          refractiveIndex: 1.18,
          saturation: 1.4,
        ),
        shape: lgr.LiquidRoundedSuperellipse(borderRadius: r),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(borderRadius: br, border: Border.all(color: style.border)),
          child: DecoratedBox(decoration: sheen, child: body),
        ),
      );
    }
    final tinted = DecoratedBox(
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: br,
        border: Border.all(color: style.border),
      ),
      child: DecoratedBox(decoration: sheen, child: body),
    );
    final wantsBlur = blur ?? Scrollable.maybeOf(context) == null;
    if (!wantsBlur || style.sigma <= 0) {
      return ClipRRect(key: const ValueKey('nwsb-glass-tint'), borderRadius: br, child: tinted);
    }
    return ClipRRect(
      key: const ValueKey('nwsb-glass-blur'),
      borderRadius: br,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: style.sigma, sigmaY: style.sigma),
        child: tinted,
      ),
    );
  }
}

// ─── Press ──────────────────────────────────────────────────────────────────

/// Sinks [child] a little on press and springs it back on release.
///
/// With [onTap] or [onLongPress] it is the tap target. Without them it only
/// listens, so it can wrap a button, chip or tab that handles its own taps.
/// Reduce-motion: dims instead of scaling.
class SpringPress extends StatefulWidget {
  const SpringPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Pressed scale; null takes [NwsbMotionTheme.pressScale] (0.96).
  final double? scale;
  final HitTestBehavior behavior;

  @override
  State<SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<SpringPress> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  Offset? _downAt;

  void _to(double target) {
    if (!mounted) return;
    _c.animateWith(SpringSimulation(NwsbSprings.press, _c.value, target, _c.velocity));
  }

  void _down(Offset at) {
    _downAt = at;
    _to(1);
  }

  void _up() {
    _downAt = null;
    _to(0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = nwsbReduceMotion(context);
    final pressed = widget.scale ?? NwsbMotionTheme.of(context).pressScale;
    final visual = AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        if (reduced) return Opacity(opacity: (1 - 0.22 * v.clamp(0.0, 1.0)), child: child);
        return Transform.scale(scale: 1 - (1 - pressed) * v, child: child);
      },
    );
    if (widget.onTap == null && widget.onLongPress == null) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _down(e.position),
        onPointerMove: (e) {
          final at = _downAt;
          if (at != null && (e.position - at).distance > kTouchSlop) _up();
        },
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: visual,
      );
    }
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (d) => _down(d.globalPosition),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: visual,
    );
  }
}

// ─── Pop-in ─────────────────────────────────────────────────────────────────

/// Springs [child] out of [origin] (an alignment on the child, e.g. the
/// corner nearest the avatar or bell): grows from nothing, overshoots,
/// wobbles a little and settles. Reduce-motion: a short fade.
class BubblePopIn extends StatefulWidget {
  const BubblePopIn({
    super.key,
    required this.child,
    this.origin = Alignment.topLeft,
    this.delay = Duration.zero,
    this.wobble = 0.22,
  });

  final Widget child;
  final Alignment origin;
  final Duration delay;

  /// Starting tilt in radians; the spring swings it through zero.
  final double wobble;

  @override
  State<BubblePopIn> createState() => _BubblePopInState();
}

class _BubblePopInState extends State<BubblePopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  Timer? _wait;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = nwsbReduceMotion(context);
    void go() {
      if (!mounted) return;
      if (reduced) {
        _c.animateTo(1, duration: NwsbDurations.fade, curve: Curves.easeOut);
      } else {
        _c.animateWith(SpringSimulation(NwsbSprings.pop, 0, 1, 0));
      }
    }

    if (widget.delay == Duration.zero) {
      go();
    } else {
      _wait = Timer(widget.delay, go);
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = nwsbReduceMotion(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        if (reduced) return Opacity(opacity: v.clamp(0.0, 1.0), child: child);
        // Overshoot is softened so the bubble swells ~10%, not ~30%.
        final scale = v < 1 ? math.max(0.0, v) : 1 + (v - 1) * 0.35;
        return Opacity(
          opacity: (v * 3).clamp(0.0, 1.0),
          child: Transform(
            alignment: widget.origin,
            transform: Matrix4.identity()
              ..scaleByDouble(scale, scale, 1, 1)
              ..rotateZ((1 - v) * widget.wobble),
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Bubbles ────────────────────────────────────────────────────────────────

enum BubbleTail { none, thought, topRight }

/// A glass chat / thought bubble. [tail] draws the little dots (thought,
/// on the left, towards an avatar) or a pointer (top-right, towards a bell).
class GlassBubble extends StatelessWidget {
  const GlassBubble({
    super.key,
    required this.child,
    this.tail = BubbleTail.thought,
    this.style = NwsbGlass.bubble,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 10, 12),
    this.refract = true,
    this.blur,
  });

  final Widget child;
  final BubbleTail tail;
  final NwsbGlassStyle style;
  final EdgeInsetsGeometry padding;
  final bool refract;

  /// See [GlassSurface.blur]. A lone bubble on a scrolling page may pass true.
  final bool? blur;

  @override
  Widget build(BuildContext context) {
    final surface = GlassSurface(style: style, padding: padding, refract: refract, blur: blur, child: child);
    Widget dot(double d) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: style.tint,
            shape: BoxShape.circle,
            border: Border.all(color: style.border),
          ),
        );
    switch (tail) {
      case BubbleTail.none:
        return surface;
      case BubbleTail.thought:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: const EdgeInsets.only(left: 10), child: surface),
            Positioned(left: 0, top: 12, child: dot(7)),
            Positioned(left: -7, top: 4, child: dot(4)),
          ],
        );
      case BubbleTail.topRight:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: const EdgeInsets.only(top: 6), child: surface),
            Positioned(
              right: 22,
              top: 0,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: style.tint,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(3)),
                    border: Border(
                      top: BorderSide(color: style.border),
                      left: BorderSide(color: style.border),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ─── Morph ──────────────────────────────────────────────────────────────────

/// A card that, tapped, grows into a glass sheet over the page (a container
/// transform on a spring). The backdrop blurs as it opens; the card's
/// content cross-fades into [open]. Tap outside, press back, or call
/// `Navigator.pop` from inside [open] and it springs back into place.
class GlassMorphCard extends StatefulWidget {
  const GlassMorphCard({
    super.key,
    required this.closed,
    required this.open,
    this.radius = 18,
    this.openRadius = 28,
    this.style = NwsbGlass.card,
    this.openHeight = 460,
    this.onOpen,
  });

  final Widget closed;
  final WidgetBuilder open;
  final double radius;
  final double openRadius;
  final NwsbGlassStyle style;

  /// Height of the open sheet (shrinks to fit small screens).
  final double openHeight;

  /// Called as the card starts to open.
  final VoidCallback? onOpen;

  @override
  State<GlassMorphCard> createState() => _GlassMorphCardState();
}

class _GlassMorphCardState extends State<GlassMorphCard> {
  bool _away = false;

  Future<void> _open() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final from = box.localToGlobal(Offset.zero) & box.size;
    widget.onOpen?.call();
    setState(() => _away = true);
    await Navigator.of(context).push(GlassMorphRoute<void>(
      from: from,
      closed: widget.closed,
      open: widget.open,
      radius: widget.radius,
      openRadius: widget.openRadius,
      style: widget.style,
      openHeight: widget.openHeight,
    ));
    if (mounted) setState(() => _away = false);
  }

  @override
  Widget build(BuildContext context) => SpringPress(
        onTap: _open,
        child: Opacity(opacity: _away ? 0 : 1, child: widget.closed),
      );
}

/// The route behind [GlassMorphCard]. Public so other cards can reuse it.
class GlassMorphRoute<T> extends PageRoute<T> {
  GlassMorphRoute({
    required this.from,
    required this.closed,
    required this.open,
    this.radius = 18,
    this.openRadius = 28,
    this.style = NwsbGlass.card,
    this.openHeight = 460,
  });

  final Rect from;
  final Widget closed;
  final WidgetBuilder open;
  final double radius;
  final double openRadius;
  final NwsbGlassStyle style;
  final double openHeight;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'Close';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => NwsbDurations.morph;

  @override
  Duration get reverseTransitionDuration => NwsbDurations.collapse;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      _GlassMorphPage(route: this, animation: animation);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      child;
}

class _GlassMorphPage extends StatefulWidget {
  const _GlassMorphPage({required this.route, required this.animation});
  final GlassMorphRoute<dynamic> route;
  final Animation<double> animation;

  @override
  State<_GlassMorphPage> createState() => _GlassMorphPageState();
}

class _GlassMorphPageState extends State<_GlassMorphPage> {
  late final CurvedAnimation _t = CurvedAnimation(
    parent: widget.animation,
    curve: NwsbSpringCurves.morph,
    reverseCurve: NwsbSpringCurves.collapse,
  );

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final reduced = nwsbReduceMotion(context);
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      final w = math.min(size.width - 32, 520.0);
      final h = math.min(route.openHeight, size.height - pad.vertical - 64);
      final to = Rect.fromLTWH((size.width - w) / 2, pad.top + (size.height - pad.vertical - h) / 2, w, h);
      return AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final fade = widget.animation.value;
          final t = reduced ? 1.0 : _t.value;
          final tc = t.clamp(0.0, 1.0);
          final rect = Rect.lerp(route.from, to, t)!;
          final r = ui.lerpDouble(route.radius, route.openRadius, tc)!;
          final settled = widget.animation.status == AnimationStatus.completed;
          final closedOpacity = reduced ? 0.0 : (1 - tc * 3).clamp(0.0, 1.0);
          final openOpacity = reduced ? 1.0 : ((tc - 0.25) / 0.75).clamp(0.0, 1.0);
          final card = ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: GlassSurface(
              key: const ValueKey('glass-morph-surface'),
              style: route.style,
              radius: r,
              // Real refraction once it has landed; while it moves, the
              // blurred backdrop behind is enough (one blur, not two).
              refract: settled,
              blur: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (closedOpacity > 0)
                    Opacity(
                      opacity: closedOpacity,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: route.from.width,
                        maxWidth: route.from.width,
                        minHeight: route.from.height,
                        maxHeight: route.from.height,
                        child: route.closed,
                      ),
                    ),
                  Opacity(
                    opacity: openOpacity,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: to.width,
                      maxWidth: to.width,
                      minHeight: to.height,
                      maxHeight: to.height,
                      child: Builder(builder: route.open),
                    ),
                  ),
                ],
              ),
            ),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('glass-morph-backdrop'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: NwsbGlass.maxBlur * 0.6 * fade,
                      sigmaY: NwsbGlass.maxBlur * 0.6 * fade,
                    ),
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.42 * fade)),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: reduced ? Opacity(opacity: fade, child: card) : card,
              ),
            ],
          );
        },
      );
    });
  }
}

// ─── Dialogs, sheets, toasts, lists ─────────────────────────────────────────

/// The pop used by glass dialogs: fade in while scaling up on the settle
/// spring, with the page behind blurring in. Reduce-motion: fade only.
Widget nwsbDialogTransition(BuildContext context, Animation<double> a, Animation<double> s, Widget child) {
  final fade = CurvedAnimation(parent: a, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
  if (nwsbReduceMotion(context)) return FadeTransition(opacity: fade, child: child);
  final spring = CurvedAnimation(parent: a, curve: NwsbSpringCurves.settle, reverseCurve: Curves.easeInCubic);
  return Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: a,
            builder: (_, __) => BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6 * a.value, sigmaY: 6 * a.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(spring), child: child),
      ),
    ],
  );
}

/// [showDialog], but it springs in over a blurred page.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x73000000),
    transitionDuration: NwsbDurations.dialog,
    pageBuilder: (context, _, __) => Builder(builder: builder),
    transitionBuilder: nwsbDialogTransition,
  );
}

/// [showModalBottomSheet] on the settle spring, inside a glass sheet
/// (pass `wrap: false` to keep the builder's own background).
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool wrap = true,
}) {
  final reduced = nwsbReduceMotion(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x73000000),
    sheetAnimationStyle: reduced
        ? const AnimationStyle(duration: NwsbDurations.fade, reverseDuration: NwsbDurations.fade)
        : const AnimationStyle(
            duration: NwsbDurations.sheet,
            reverseDuration: NwsbDurations.collapse,
            curve: NwsbSpringCurves.sheet,
            reverseCurve: Curves.easeInCubic,
          ),
    builder: (context) => wrap
        ? GlassSurface(
            style: NwsbGlass.sheet.copyWith(radius: 28),
            refract: true,
            blur: true,
            child: SafeArea(top: false, child: builder(context)),
          )
        : builder(context),
  );
}

/// A small glass toast that pops up from the bottom and fades away.
/// Returns a function that removes it early.
VoidCallback showGlassToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration hold = const Duration(milliseconds: 2400),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return () {};
  late final OverlayEntry entry;
  var gone = false;
  final leaving = ValueNotifier<bool>(false);
  void remove() {
    if (gone) return;
    gone = true;
    entry.remove();
    leaving.dispose();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.paddingOf(context).bottom + 88,
      child: IgnorePointer(
        child: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: leaving,
            builder: (context, out, child) => AnimatedOpacity(
              opacity: out ? 0 : 1,
              duration: NwsbDurations.fade,
              onEnd: out ? remove : null,
              child: child,
            ),
            child: BubblePopIn(
              origin: Alignment.bottomCenter,
              wobble: 0.08,
              child: Material(
                type: MaterialType.transparency,
                child: GlassSurface(
                  key: const ValueKey('glass-toast'),
                  style: NwsbGlass.toast,
                  blur: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: const Color(0xFFE8D5A3)),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(hold, () {
    if (!gone) leaving.value = true;
  });
  return remove;
}

/// List rows that rise into place on a spring, a few at a time
/// ([index] staggers them; rows past the eighth don't wait).
/// Reduce-motion: fade only.
class SpringIn extends StatefulWidget {
  const SpringIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  Timer? _wait;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = nwsbReduceMotion(context);
    void go() {
      if (!mounted) return;
      if (reduced) {
        _c.animateTo(1, duration: NwsbDurations.fade, curve: Curves.easeOut);
      } else {
        _c.animateWith(SpringSimulation(NwsbSprings.settle, 0, 1, 0));
      }
    }

    final delay = Duration(milliseconds: 36 * math.min(widget.index, 8));
    if (delay == Duration.zero) {
      go();
    } else {
      _wait = Timer(delay, go);
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = nwsbReduceMotion(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        final o = Opacity(opacity: v.clamp(0.0, 1.0), child: child);
        if (reduced) return o;
        return Transform.translate(offset: Offset(0, (1 - v) * 18), child: o);
      },
    );
  }
}
