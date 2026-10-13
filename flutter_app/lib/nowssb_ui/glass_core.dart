// Core: NGlass (blur/lite), GlassVideoScaffold, FloatingShapes.
// Builds on existing GlassWrap + NwsbEffects + NwsbMotion in package:nowssb.
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowssb/widgets/app_backdrop.dart' show AppBackdrop;
import 'package:nowssb/theme/liquid_glass_theme.dart' show NwsbEffects;
import 'package:nowssb/widgets/motion.dart' show NwsbMotion;
import 'tokens.dart';

/// The ONE glass wrapper (spec §0.5). blur > 0 => BackdropFilter (large
/// surfaces only); blur == 0 => lite mode. Auto-falls back to lite when
/// NwsbEffects.instance.reduced is true.
class NGlass extends StatefulWidget {
  const NGlass({
    super.key, required this.child, this.radius = NTokens.rCard,
    this.accent = NTokens.violet, this.blur = 0, this.elevation = 1,
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) { setState(() => _down = false); HapticFeedback.selectionClick(); widget.onTap!(); },
      child: AnimatedScale(scale: _down ? NTokens.press : 1, duration: const Duration(milliseconds: 120),
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
    @Deprecated('Ignored: the app background is always used') this.videoAsset,
    @Deprecated('Ignored') this.posterAsset,
    @Deprecated('Ignored: the kit adds no background shapes') this.shapes = false,
    @Deprecated('Ignored') this.dim = 0,
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
          RepaintBoundary(child: background ?? const AppBackdrop()),
          SafeArea(bottom: false, child: body),
        ]),
      );
}

/// Optional decorative shapes. NOT used by any kit background.
/// Floating 3D torus (pink) + capsule pills (mint), slow drift (8s loop).
class FloatingShapes extends StatefulWidget {
  const FloatingShapes({super.key, this.items = FloatingShapes.defaults});
  final List<ShapeSpec> items;
  static const defaults = [
    ShapeSpec.torus(Alignment(-1.05, -0.15), 120, NTokens.pink),
    ShapeSpec.capsule(Alignment(-0.55, -0.72), 44, NTokens.mint),
    ShapeSpec.capsule(Alignment(0.92, 0.55), 52, NTokens.mint),
    ShapeSpec.torus(Alignment(0.95, -0.85), 70, NTokens.pink),
  ];
  @override
  State<FloatingShapes> createState() => _FloatingShapesState();
}

class ShapeSpec {
  const ShapeSpec.torus(this.at, this.size, this.color) : torus = true;
  const ShapeSpec.capsule(this.at, this.size, this.color) : torus = false;
  final Alignment at; final double size; final Color color; final bool torus;
}

class _FloatingShapesState extends State<FloatingShapes> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  @override
  void dispose() { _a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (NwsbEffects.instance.reduced) return _layer(0);
    return AnimatedBuilder(animation: _a, builder: (_, __) => _layer(_a.value));
  }
  Widget _layer(double t) => Stack(children: [
        for (var i = 0; i < widget.items.length; i++)
          Align(alignment: widget.items[i].at, child: Transform.translate(
            offset: Offset(0, math.sin((t + i * .25) * 2 * math.pi) * 8),
            child: Transform.rotate(angle: math.sin((t + i * .3) * 2 * math.pi) * .12,
              child: CustomPaint(size: Size.square(widget.items[i].size),
                painter: _ShapePainter(widget.items[i]))))),
      ]);
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.s);
  final ShapeSpec s;
  @override
  void paint(Canvas canvas, Size size) {
    final c = s.color;
    if (s.torus) {
      final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width, height: size.height * .62);
      final stroke = size.width * .14;
      final p = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke
        ..shader = LinearGradient(colors: [Color.lerp(c, Colors.white, .45)!, c, Color.lerp(c, Colors.black, .35)!],
            begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect);
      canvas.drawOval(rect.deflate(stroke / 2), p);
      canvas.drawOval(rect.deflate(stroke / 2).translate(0, -stroke * .18),
          Paint()..style = PaintingStyle.stroke..strokeWidth = stroke * .22..color = Colors.white.withValues(alpha: .35));
    } else {
      final rect = Rect.fromLTWH(0, size.height * .2, size.width, size.height * .6);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
      canvas.drawRRect(rr, Paint()..shader = RadialGradient(center: const Alignment(-.4, -.5),
          colors: [Color.lerp(c, Colors.white, .5)!, c, Color.lerp(c, Colors.black, .3)!]).createShader(rect));
    }
  }
  @override
  bool shouldRepaint(covariant _ShapePainter o) => false;
}
