/// The hero header's glass (lib/screens/fashion/header.dart: the top bar):
/// `blur(20px)` → sigma 10 over the film, a 8% white fill and a 10% white
/// hairline. Floating pills and grouped cards use exactly this recipe so all
/// glass on a page reads as one material.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class HeroGlassRecipe {
  const HeroGlassRecipe._();
  static const double blurSigma = 10;
  static const Color fill = Color(0x14FFFFFF);
  static const Color line = Color(0x1AFFFFFF);
}

class HeroGlass extends StatelessWidget {
  const HeroGlass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.constraints,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget pane = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
            sigmaX: HeroGlassRecipe.blurSigma, sigmaY: HeroGlassRecipe.blurSigma),
        child: Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: HeroGlassRecipe.fill,
            borderRadius: r,
            border: Border.all(color: HeroGlassRecipe.line),
          ),
          child: child,
        ),
      ),
    );
    if (margin != null) pane = Padding(padding: margin!, child: pane);
    return pane;
  }
}
