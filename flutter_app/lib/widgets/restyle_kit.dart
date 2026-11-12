/// The look of the pages Ribon likes (Sound Library, Subscription, the
/// player, Menu and Settings), as a few parts other pages can wear.
///
/// Nothing here is a new look: every value is lifted from those pages.
///  * [KitPane]      a GlassWrap (HeroGlassRecipe) pane opened by the
///                   SectionHead (round white SVG badge, grey eyebrow, bold
///                   title), optional trailing pill.
///  * [KitHero]      the CurrentlyPlayingHero layout: art on the left,
///                   eyebrow / big title / subline and a round white button
///                   on the right, all in one glass pane.
///  * [KitBlackCard] the "NowssB Store" card (StoreNowCard): black plate,
///                   picture, small caps eyebrow, big title, grey line,
///                   round white button.
///  * [KitRow]       the Sound Library track row: square art, bold title,
///                   muted subline, trailing arrow, inside a pane.
///  * [KitWordArt]   word-only art (no photo) for tiles that have none.
///  * [GlassPill] / [SectionHead] / [GlassWrap] are re-exported as-is.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_wrap.dart';
import 'nwsb_icon.dart';

export 'glass_wrap.dart' show GlassWrap, SectionHead;
export 'nwsb_icon.dart' show NwsbMarks;
export 'sound_glass.dart' show GlassPill;

/// Muted white used for sublines on every liked page.
const kKitMuted = Color(0x8CFFFFFF);

/// Small caps eyebrow (CurrentlyPlayingHero / StoreNowCard).
const kKitEyebrow = TextStyle(
  color: Color(0xB3FFFFFF),
  fontSize: 10.5,
  letterSpacing: 1.4,
  fontWeight: FontWeight.w700,
);

/// A glass pane with the badge heading.
class KitPane extends StatelessWidget {
  const KitPane({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.mark,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 14),
  });

  final String eyebrow;
  final String title;
  final String? mark;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassWrap(
        margin: margin,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                  child: SectionHead(
                      eyebrow: eyebrow, title: title, mark: mark)),
              if (trailing != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 14, left: 8),
                    child: trailing!),
            ]),
            child,
          ],
        ),
      ),
    );
  }
}

/// Round white button with a dark glyph (56 on heroes, 46 on cards).
class KitRoundButton extends StatelessWidget {
  const KitRoundButton({
    super.key,
    required this.icon,
    this.size = 46,
    this.onTap,
    this.label,
  });
  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final b = Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, color: const Color(0xFF111118), size: size * 0.55),
    );
    if (onTap == null) return b;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: b,
      ),
    );
  }
}

/// Word-only art: the word's first letter (Devanagari when it has one) and
/// the word, white on near-black. Used where a tile has no picture.
class KitWordArt extends StatelessWidget {
  const KitWordArt({super.key, required this.word, this.deva = ''});
  final String word;
  final String deva;

  @override
  Widget build(BuildContext context) {
    final glyph = deva.isNotEmpty
        ? deva.characters.first
        : (word.isEmpty ? '·' : word.characters.first.toUpperCase());
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 56.0;
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C22), Color(0xFF0A0A0D)],
          ),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Center(
            child: Text(glyph,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: s * 0.42,
                    fontWeight: FontWeight.w800,
                    height: 1.1)),
          ),
          if (s >= 90)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(word.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6)),
            ),
        ]),
      );
    });
  }
}

/// The Currently Playing hero layout for any page's lead block.
class KitHero extends StatelessWidget {
  const KitHero({
    super.key,
    required this.art,
    required this.eyebrow,
    required this.title,
    this.subline,
    this.cornerLabel,
    this.buttonIcon = Icons.play_arrow_rounded,
    this.buttonLabel,
    this.onButton,
    this.footer,
    this.margin = const EdgeInsets.fromLTRB(16, 4, 16, 8),
  });

  final Widget art;
  final String eyebrow;
  final String title;
  final String? subline;
  final String? cornerLabel;
  final IconData buttonIcon;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final Widget? footer;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: margin,
      padding: const EdgeInsets.all(14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: Color(0x33000000), shape: BoxShape.circle),
            child: const Center(
                child: NwsbIcon(NwsbMarks.play, size: 11, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          const Text('NOWSSB',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4)),
          const Spacer(),
          if (cornerLabel != null)
            Flexible(
              child: Text(cornerLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5)),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 128, height: 128, child: art),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kKitEyebrow),
                const SizedBox(height: 4),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4)),
                if (subline != null && subline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subline!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xCCFFFFFF), fontSize: 12.5, height: 1.3)),
                ],
                if (onButton != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    KitRoundButton(
                        icon: buttonIcon,
                        size: 52,
                        onTap: onButton,
                        label: buttonLabel),
                    if (buttonLabel != null) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(buttonLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ],
              ],
            ),
          ),
        ]),
        if (footer != null) ...[const SizedBox(height: 14), footer!],
      ]),
    );
  }
}

/// The "NowssB Store" black card: picture, eyebrow, big title, grey line,
/// round white button.
class KitBlackCard extends StatelessWidget {
  const KitBlackCard({
    super.key,
    required this.art,
    required this.eyebrow,
    required this.title,
    this.line,
    this.icon = Icons.arrow_forward_rounded,
    required this.onTap,
    this.height = 136,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  final Widget art;
  final String eyebrow;
  final String title;
  final String? line;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Semantics(
        button: true,
        label: title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: height,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xF0111114),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                    width: height - 20, height: height - 20, child: art),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kKitEyebrow.copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: 1.6)),
                    const SizedBox(height: 6),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                    if (line != null && line!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(line!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0x99FFFFFF))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              KitRoundButton(icon: icon),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A full-figure cut-out (transparent PNG) on a dark plate, never cropped:
/// the head always stays in the tile.
class KitCutout extends StatelessWidget {
  const KitCutout(this.asset, {super.key});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF26262E), Color(0xFF0E0E12)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Image.asset(asset,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const SizedBox()),
      ),
    );
  }
}

/// The Sound Library track row.
class KitRow extends StatelessWidget {
  const KitRow({
    super.key,
    required this.leading,
    required this.title,
    this.sub,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });

  final Widget leading;
  final String title;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF1A1A1A) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 52, height: 52, child: leading),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (sub != null && sub!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kKitMuted, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing ??
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: kKitMuted),
          ]),
        ),
      ),
    );
  }
}
