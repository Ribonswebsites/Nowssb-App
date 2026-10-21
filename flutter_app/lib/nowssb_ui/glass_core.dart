// Core: NGlass (blur/lite), GlassVideoScaffold.
// FloatingShapes was removed: backgrounds are the app's original video only.
// Builds on existing GlassWrap + NwsbEffects + NwsbMotion in package:nowssb.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_video_backdrop.dart';
import 'package:flutter/services.dart';
import 'package:nowssb/theme/liquid_glass_theme.dart' show NwsbEffects;
import 'package:nowssb/widgets/motion.dart' show NwsbMotion;
import 'tokens.dart';

/// The ONE glass wrapper (spec §0.5). blur > 0 => BackdropFilter (large
/// surfaces only); blur == 0 => lite mode. Auto-falls back to lite when
/// NwsbEffects.instance.reduced is true.
class NGlass extends StatefulWidget {
  const NGlass({
    super.key, required this.child, this.radius = NTokens.rCard,
    this.accent = NTokens.neutral, this.blur = 0, this.elevation = 1,
    this.padding = const EdgeInsets.all(16), this.onTap, this.tint,
  });
  final Widget child;
  final double radius, blur, elevation;
  final Color accent;
  final Color? tint;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  State<NGlass> createState() => _NGlassState();
}

class _NGlassState extends State<NGlass> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final reduced = NwsbEffects.instance.reduced;
    final useBlur = widget.blur > 0 && !reduced;
    final r = BorderRadius.circular(widget.radius);
    final top = useBlur ? NTokens.glassTop : NTokens.glassLiteTop;
    final bot = useBlur ? NTokens.glassBottom : NTokens.glassLiteBottom;
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [widget.tint == null ? top : Color.alphaBlend(widget.tint!.withValues(alpha: .10), top), bot],
        ),
        border: Border.all(color: NTokens.border, width: 1),
      ),
      child: Stack(children: [
        // inner top highlight
        const Positioned(left: 12, right: 12, top: 0, height: 1.2,
          child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [
            Colors.transparent, NTokens.highlight, Colors.transparent])))),
        Padding(padding: widget.padding, child: widget.child),
      ]),
    );
    if (useBlur) {
      body = RepaintBoundary(child: ClipRRect(borderRadius: r, child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur), child: body)));
    } else {
      body = ClipRRect(borderRadius: r, child: body);
    }
    body = DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: NTokens.glow(widget.accent, widget.elevation)),
      child: body);
    if (widget.onTap == null) return body;
    // Press feedback is motion too: none when the phone asks for less.
    final still = reduced || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) { setState(() => _down = false); HapticFeedback.selectionClick(); widget.onTap!(); },
      child: AnimatedScale(scale: _down && !still ? NTokens.press : 1, duration: still ? Duration.zero : const Duration(milliseconds: 120),
        curve: NwsbMotion.curve, child: body),
    );
  }
}

/// Every screen: the app's ORIGINAL background ([AppBackdrop]: the saved
/// Fashion Plus film, or its still / poster when the film is off or effects
/// are reduced) with glass content on top. The kit adds NO background of its
/// own: no gradient, no orbs, no floating shapes.
/// [videoAsset] and [shapes] are kept only for source compatibility and are
/// ignored. [background] lets tests inject a frame or photo.
class GlassVideoScaffold extends StatelessWidget {
  const GlassVideoScaffold({
    super.key, required this.body, this.appBar, this.bottomBar, this.background,
    this.videoAsset,
    this.posterAsset,
    this.shapes = false,
    this.dim = 0,
  });
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? background;
  final String? videoAsset, posterAsset;
  final bool shapes;
  final double dim;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: appBar,
        bottomNavigationBar: bottomBar,
        body: Stack(fit: StackFit.expand, children: [
          RepaintBoundary(child: background ?? const NAppBackdrop()),
          SafeArea(bottom: false, child: body),
        ]),
      );
}
