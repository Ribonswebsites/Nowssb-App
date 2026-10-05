/// Applies [SectionAnimation] (entry, overlay, scroll) around a section or card.
/// No-op when animation is empty — defaults render unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:lottie/lottie.dart';

import '../../admin/layout/layout_sections.dart' show entranceTransform;
import 'section_config.dart';

class SectionAnimLayer extends StatelessWidget {
  const SectionAnimLayer({
    super.key,
    required this.animation,
    required this.child,
  });

  final SectionAnimation animation;
  final Widget child;

  bool get _empty =>
      animation.entry == SectionEntryAnim.none &&
      animation.scroll == SectionScrollAnim.none &&
      animation.overlay == null;

  @override
  Widget build(BuildContext context) {
    if (_empty) return child;
    Widget w = child;
    if (animation.entry != SectionEntryAnim.none) {
      w = _EntryPlay(kind: animation.entry, child: w);
    }
    if (animation.scroll == SectionScrollAnim.parallax) {
      w = _ParallaxHost(child: w);
    }
    final overlay = animation.overlay;
    if (overlay != null) {
      w = Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          w,
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: overlay.opacity.clamp(0.0, 1.0),
                child: Align(
                  alignment: overlay.align,
                  child: Transform.scale(
                    scale: overlay.scale.clamp(0.2, 4.0),
                    child: _OverlayBody(overlay: overlay),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return w;
  }
}

class _OverlayBody extends StatelessWidget {
  const _OverlayBody({required this.overlay});
  final SectionOverlayAnim overlay;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    switch (overlay.kind) {
      case SectionOverlayKind.lottie:
        if (overlay.asset.isEmpty) return const SizedBox.shrink();
        return Lottie.asset(
          overlay.asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      case SectionOverlayKind.orb:
        OrbState state = OrbState.composing;
        for (final s in OrbState.values) {
          if (s.name == overlay.asset) {
            state = s;
            break;
          }
        }
        return ThinkingOrb(state: state, size: size, theme: OrbTheme.dark);
      case SectionOverlayKind.rive:
        // Rive dep not bundled; show nothing rather than crash.
        return const SizedBox.shrink();
    }
  }
}

class _EntryPlay extends StatefulWidget {
  const _EntryPlay({required this.kind, required this.child});
  final SectionEntryAnim kind;
  final Widget child;

  @override
  State<_EntryPlay> createState() => _EntryPlayState();
}

class _EntryPlayState extends State<_EntryPlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();

  @override
  void didUpdateWidget(_EntryPlay old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _key => switch (widget.kind) {
        SectionEntryAnim.fade => 'fade',
        SectionEntryAnim.slideUp => 'fadeUp',
        SectionEntryAnim.scale => 'scale',
        SectionEntryAnim.none => 'none',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) =>
          entranceTransform(_key, Curves.easeOutCubic.transform(_c.value), child!),
    );
  }
}

/// Light parallax: translates slightly against scroll notifications.
class _ParallaxHost extends StatefulWidget {
  const _ParallaxHost({required this.child});
  final Widget child;

  @override
  State<_ParallaxHost> createState() => _ParallaxHostState();
}

class _ParallaxHostState extends State<_ParallaxHost> {
  double _dy = 0;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final next = (n.metrics.pixels * 0.06).clamp(-24.0, 24.0);
    if ((next - _dy).abs() < 0.5) return false;
    setState(() => _dy = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Transform.translate(
        offset: Offset(0, _dy),
        child: widget.child,
      ),
    );
  }
}

/// Layout-only wrap from [SectionLayout]; identity when empty.
Widget applySectionLayout(SectionLayout layout, Widget child) {
  Widget w = child;
  final pad = layout.padding;
  if (pad != null && pad != EdgeInsets.zero) {
    w = Padding(padding: pad, child: w);
  }
  final h = layout.height;
  if (h != null && h > 0) {
    w = SizedBox(height: h, width: layout.wrapperWidth, child: w);
  } else if (layout.wrapperWidth != null || layout.wrapperHeight != null) {
    w = SizedBox(
      width: layout.wrapperWidth,
      height: layout.wrapperHeight,
      child: w,
    );
  }
  final r = layout.radius;
  if (r != null && r > 0) {
    w = ClipRRect(borderRadius: BorderRadius.circular(r), child: w);
  }
  return w;
}
