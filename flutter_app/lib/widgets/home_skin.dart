/// Which home a section is being drawn on.
///
/// The website has ONE markup for most sections and two stylesheets scoped
/// to `#home` and `#home-nm`. Subscription, Your Edition, Quick Access, the
/// Connect banner, eBooks, My Routines, Personalised Healing, Choose Your
/// Path and the footer are written once in index.html and appear on both
/// homes; what changes between them is the pane the section sits on and the
/// head it opens with, not a single word of the copy.
///
/// This is that, in Flutter. A section asks [SectionPane] and [PaneHead] for
/// the pane and the head, and they ask the scope which home they are on.
/// Writing those sections twice would mean two places to fix every time the
/// copy changes, and the two would drift — which is exactly the problem the
/// website avoided by scoping its stylesheet instead of forking its markup.
library;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'neu_wrap.dart';

enum HomeSkin {
  /// `#home` — a pane of glass over the film.
  fashion,

  /// `#home-nm` — a card raised out of the page.
  normal,
}

class HomeSkinScope extends InheritedWidget {
  const HomeSkinScope({super.key, required this.skin, required super.child});

  final HomeSkin skin;

  /// Defaults to [HomeSkin.fashion] — a section used outside either home
  /// (a preview, a test) gets the dark language, which is what every
  /// sub-screen in the app is.
  static HomeSkin of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeSkinScope>()?.skin ??
      HomeSkin.fashion;

  @override
  bool updateShouldNotify(HomeSkinScope old) => old.skin != skin;
}

/// The pane a section sits on — `.glass-wrap` or `.nmh-sec-wrap`.
///
/// Takes the same `child` [GlassWrap] does, so a section written for one
/// home becomes a section on both by changing this one word.
class SectionPane extends StatelessWidget {
  const SectionPane({super.key, required this.child, this.padding});

  final Widget child;

  /// Overrides the pane's own padding. Wanted where a clip runs to the very
  /// edge of the pane, which on the web is what `padding: 0` does.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return switch (HomeSkinScope.of(context)) {
      HomeSkin.fashion => GlassWrap(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      HomeSkin.normal => SecWrap(
          padding: padding ?? const EdgeInsets.all(14),
          children: [child],
        ),
    };
  }
}

/// The head a section opens with — `.qa-tv-head` or `.nmh-wrap-head`.
/// Outer page gutter for standalone Home children that do not use
/// [SectionPane], [SecWrap] or [GlassWrap]. Keeping this separate from pane
/// padding prevents the Hero card and dashboard internals from changing size.
class HomeGutter extends StatelessWidget {
  const HomeGutter({super.key, required this.child, this.horizontal = 16});

  final Widget child;
  final double horizontal;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: child,
      );
}

class PaneHead extends StatelessWidget {
  const PaneHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.mark,
    this.markViewBox = 24,
    this.art,
  });

  final String eyebrow;
  final String title;
  final String? mark;
  final double markViewBox;
  final Widget? art;

  @override
  Widget build(BuildContext context) {
    return switch (HomeSkinScope.of(context)) {
      HomeSkin.fashion => SectionHead(
          eyebrow: eyebrow,
          title: title,
          mark: mark,
          markViewBox: markViewBox,
          art: art,
        ),
      HomeSkin.normal => WrapHead(
          eyebrow: eyebrow,
          title: title,
          mark: mark,
          markViewBox: markViewBox,
          art: art,
        ),
    };
  }
}
