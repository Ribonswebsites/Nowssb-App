/// Two card styles taken from Ribon's Editeaze reference (Oct 31):
///
/// * [EzOrangeCard] (style A): a rounded warm-orange card with a photo,
///   a small title and subtitle top-left, tiny round icon buttons top-right
///   and a small dark comment pill hanging over its left edge.
///   [EzOrangeCarousel] rotates several of them: auto-advances, swipe or
///   drag to move, pauses while touched, and shows no dots or indicator.
/// * [EzSplitStrip] (style B): two photos side by side in rounded tiles with
///   a thin teal divider and handle between them (drag it to resize), and a
///   dashed "Add more" tile.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kEzOrange = Color(0xFFF47A3C);
const kEzTeal = Color(0xFF2CE0C4);
const kEzPill = Color(0xF0151518);

class EzIcon {
  const EzIcon(this.icon, {this.onTap, this.label});
  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
}

class EzComment {
  const EzComment({required this.name, required this.text, this.icon = Icons.self_improvement_rounded});
  final String name;
  final String text;
  final IconData icon;
}

/// Style A. [image] is an asset path; [child] replaces the photo when given.
class EzOrangeCard extends StatelessWidget {
  const EzOrangeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.image,
    this.child,
    this.icons = const [],
    this.comment,
    this.onTap,
    this.color = kEzOrange,
    this.height = 300,
    this.radius = 26,
    this.alignment = Alignment.center,
  });

  final String title;
  final String? subtitle;
  final String? image;
  final Widget? child;
  final List<EzIcon> icons;
  final EzComment? comment;
  final VoidCallback? onTap;
  final Color color;
  final double height;
  final double radius;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final photo = child ??
        (image == null
            ? const SizedBox.shrink()
            : Image.asset(image!, fit: BoxFit.cover, alignment: alignment, cacheWidth: 900,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()));
    final card = Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            Positioned.fill(top: 54, child: photo),
            // Orange fades over the top of the photo so the header reads.
            Positioned(
              left: 0, right: 0, top: 50, height: 46,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16, right: 12, top: 14,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.2)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 10.5, height: 1.2)),
                    ],
                  ]),
                ),
                for (final i in icons) ...[
                  const SizedBox(width: 6),
                  _EzIconButton(i),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
    if (comment == null) return card;
    // The pill hangs 10dp past the card's left edge, as in the reference.
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Stack(clipBehavior: Clip.none, children: [
        card,
        Positioned(left: -10, bottom: height * .26, child: IgnorePointer(child: EzCommentPill(comment!, accent: color))),
      ]),
    );
  }
}

class _EzIconButton extends StatelessWidget {
  const _EzIconButton(this.i);
  final EzIcon i;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: i.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Always claim the tap so a button never falls through to the card.
          onTap: i.onTap ?? () {},
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(9)),
            child: Icon(i.icon, size: 15, color: Colors.white),
          ),
        ),
      );
}

class EzCommentPill extends StatelessWidget {
  const EzCommentPill(this.c, {super.key, this.accent = kEzOrange});
  final EzComment c;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: kEzPill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(c.icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(c.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 9.5)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.favorite_rounded, size: 11, color: Colors.white),
          ),
        ]),
      );
}

class EzSlide {
  const EzSlide({required this.image, required this.title, this.subtitle, this.comment, this.alignment = Alignment.center});
  final String image;
  final String title;
  final String? subtitle;
  final EzComment? comment;
  final Alignment alignment;
}

/// Auto-rotating, swipeable [EzOrangeCard]s. No dots, no indicator.
class EzOrangeCarousel extends StatefulWidget {
  const EzOrangeCarousel({
    super.key,
    required this.slides,
    this.icons = const [],
    this.onTap,
    this.height = 300,
    this.interval = const Duration(seconds: 4),
    this.resumeAfter = const Duration(seconds: 3),
  });
  final List<EzSlide> slides;
  final List<EzIcon> icons;
  final void Function(int index)? onTap;
  final double height;
  final Duration interval;
  final Duration resumeAfter;

  @override
  State<EzOrangeCarousel> createState() => EzOrangeCarouselState();
}

class EzOrangeCarouselState extends State<EzOrangeCarousel> {
  static const _loop = 10000;
  late final PageController _page = PageController(initialPage: _loop * widget.slides.length);
  Timer? _tick;
  Timer? _resume;
  bool _held = false;

  /// Test hooks.
  bool get held => _held;
  int get index => _page.hasClients ? (_page.page ?? 0).round() % widget.slides.length : 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _tick?.cancel();
    if (widget.slides.length < 2) return;
    _tick = Timer.periodic(widget.interval, (_) {
      if (_held || !mounted || !_page.hasClients) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _page.jumpToPage((_page.page ?? 0).round() + 1);
      } else {
        _page.nextPage(duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
      }
    });
  }

  void _down(PointerDownEvent _) {
    _resume?.cancel();
    _held = true;
  }

  void _up(PointerEvent _) {
    _resume?.cancel();
    _resume = Timer(widget.resumeAfter, () {
      _held = false;
      _start();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _resume?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.slides.length;
    final hasPill = widget.slides.any((s) => s.comment != null);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: SizedBox(
        height: widget.height,
        child: PageView.builder(
          key: const ValueKey('ez-carousel'),
          controller: _page,
          clipBehavior: Clip.none,
          onPageChanged: (_) => HapticFeedback.selectionClick(),
          itemBuilder: (context, i) {
            final s = widget.slides[i % n];
            final card = EzOrangeCard(
              title: s.title,
              subtitle: s.subtitle,
              image: s.image,
              alignment: s.alignment,
              comment: s.comment,
              icons: widget.icons,
              height: widget.height,
              onTap: widget.onTap == null ? null : () => widget.onTap!(i % n),
            );
            return hasPill && s.comment == null ? Padding(padding: const EdgeInsets.only(left: 10), child: card) : card;
          },
        ),
      ),
    );
  }
}

class EzTile {
  const EzTile({required this.image, this.label, this.onTap, this.alignment = Alignment.center});
  final String image;
  final String? label;
  final VoidCallback? onTap;
  final Alignment alignment;
}

/// Style B: two photos, teal divider with a handle, dashed "Add more".
class EzSplitStrip extends StatefulWidget {
  const EzSplitStrip({
    super.key,
    required this.left,
    required this.right,
    this.addLabel = 'Add more',
    this.addIcon = Icons.add_rounded,
    this.onAdd,
    this.height = 118,
    this.tileColor = kEzOrange,
    this.dark = true,
  });
  final EzTile left;
  final EzTile right;
  final String addLabel;
  final IconData addIcon;
  final VoidCallback? onAdd;
  final double height;
  final Color tileColor;
  /// Dashed tile colours for a dark (true) or light page.
  final bool dark;

  @override
  State<EzSplitStrip> createState() => _EzSplitStripState();
}

class _EzSplitStripState extends State<EzSplitStrip> {
  double _split = .5;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: LayoutBuilder(builder: (context, c) {
          final addW = (c.maxWidth * .22).clamp(64.0, 92.0);
          final pair = c.maxWidth - addW - 10;
          final lw = (pair - 2) * _split;
          return Row(children: [
            SizedBox(
              width: pair,
              child: Stack(clipBehavior: Clip.none, children: [
                Row(children: [
                  SizedBox(width: lw, child: _tile(widget.left, const BorderRadius.horizontal(left: Radius.circular(18)))),
                  const SizedBox(width: 2),
                  Expanded(child: _tile(widget.right, const BorderRadius.horizontal(right: Radius.circular(18)))),
                ]),
                // Divider line + handle; drag it to change the split.
                Positioned(
                  left: lw - 14, top: -8, bottom: -8, width: 30,
                  child: GestureDetector(
                    key: const ValueKey('ez-split-handle'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => setState(() => _split = ((lw + d.delta.dx) / (pair - 2)).clamp(.28, .72)),
                    child: const CustomPaint(painter: _HandlePainter()),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            SizedBox(width: addW, child: _add()),
          ]);
        }),
      );

  Widget _tile(EzTile t, BorderRadius r) => Semantics(
        button: t.onTap != null,
        label: t.label,
        child: GestureDetector(
          onTap: t.onTap,
          child: ClipRRect(
            borderRadius: r,
            child: ColoredBox(
              color: widget.tileColor,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(t.image, fit: BoxFit.cover, alignment: t.alignment, cacheWidth: 500,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                if (t.label != null)
                  Positioned(
                    left: 8, bottom: 8, right: 8,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kEzPill, borderRadius: BorderRadius.circular(9)),
                        child: Text(t.label!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );

  Widget _add() {
    final fg = widget.dark ? const Color(0xDDFFFFFF) : const Color(0xFF2B2D33);
    return Semantics(
      button: true,
      label: widget.addLabel,
      child: GestureDetector(
        key: const ValueKey('ez-add-more'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onAdd,
        child: CustomPaint(
          painter: _DashPainter(widget.dark ? const Color(0x66FFFFFF) : const Color(0x552B2D33),
              widget.dark ? const Color(0x14FFFFFF) : const Color(0x0A000000)),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                child: Icon(widget.addIcon, size: 15, color: widget.dark ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(widget.addLabel, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 10.5, height: 1.2)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  const _HandlePainter();
  @override
  void paint(Canvas c, Size s) {
    final x = s.width / 2;
    final p = Paint()
      ..color = kEzTeal
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x, 2), Offset(x, s.height - 2), p);
    c.drawLine(Offset(x - 6, 2), Offset(x + 6, 2), p);
    c.drawLine(Offset(x - 6, s.height - 2), Offset(x + 6, s.height - 2), p);
  }

  @override
  bool shouldRepaint(_HandlePainter o) => false;
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.line, this.fill);
  final Color line;
  final Color fill;
  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)).deflate(.75);
    c.drawRRect(rr, Paint()..color = fill);
    final path = Path()..addRRect(rr);
    final p = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        c.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.line != line || o.fill != fill;
}

/// One hero card: a solid colour with a studio cut-out photo standing on it.
class EzHeroCard {
  const EzHeroCard({
    required this.color,
    required this.image,
    required this.title,
    this.subtitle,
    this.saved = false,
    this.onSave,
  });
  final Color color;
  final String image;
  final String title;
  final String? subtitle;
  final bool saved;
  final VoidCallback? onSave;
}

/// The Normal home hero, as on the Editeaze phone screen: rounded solid
/// colour cards, a person photographed on a plain backdrop blending into
/// the card, a small white title and subtitle top-left and two tiny icon
/// buttons top-right. Auto-rotates, swipe or drag to move, pauses while
/// touched, the next card peeks at the edge. No dots, no indicator.
class EzHeroCarousel extends StatefulWidget {
  const EzHeroCarousel({
    super.key,
    required this.cards,
    this.onOpen,
    this.height = 268,
    this.peek = .86,
    this.interval = const Duration(seconds: 4),
    this.resumeAfter = const Duration(seconds: 3),
  });
  final List<EzHeroCard> cards;
  final void Function(int index)? onOpen;
  final double height;
  final double peek;
  final Duration interval;
  final Duration resumeAfter;

  @override
  State<EzHeroCarousel> createState() => EzHeroCarouselState();
}

class EzHeroCarouselState extends State<EzHeroCarousel> {
  static const _loop = 10000;
  late final PageController _page =
      PageController(initialPage: _loop * widget.cards.length, viewportFraction: widget.peek);
  Timer? _tick;
  Timer? _resume;
  bool _held = false;

  /// Test hooks.
  bool get held => _held;
  int get index => _page.hasClients ? (_page.page ?? 0).round() % widget.cards.length : 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _tick?.cancel();
    if (widget.cards.length < 2) return;
    _tick = Timer.periodic(widget.interval, (_) {
      if (_held || !mounted || !_page.hasClients) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _page.jumpToPage((_page.page ?? 0).round() + 1);
      } else {
        _page.nextPage(duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
      }
    });
  }

  void _down(PointerDownEvent _) {
    _resume?.cancel();
    _held = true;
  }

  void _up(PointerEvent _) {
    _resume?.cancel();
    _resume = Timer(widget.resumeAfter, () {
      _held = false;
      _start();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _resume?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: SizedBox(
        height: widget.height,
        child: PageView.builder(
          key: const ValueKey('ez-carousel'),
          controller: _page,
          padEnds: false,
          onPageChanged: (_) => HapticFeedback.selectionClick(),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(left: 20, right: 2),
            child: _EzHeroTile(
              card: widget.cards[i % n],
              onOpen: widget.onOpen == null ? null : () => widget.onOpen!(i % n),
            ),
          ),
        ),
      ),
    );
  }
}

class _EzHeroTile extends StatelessWidget {
  const _EzHeroTile({required this.card, this.onOpen});
  final EzHeroCard card;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Material(
        color: card.color,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(fit: StackFit.expand, children: [
            Positioned(
              left: 0, right: 0, top: 52, bottom: 0,
              child: Image.asset(card.image,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  cacheHeight: 720,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            Positioned(
              left: 16, right: 12, top: 14,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.2)),
                    if (card.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(card.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 11, height: 1.2)),
                    ],
                  ]),
                ),
                const SizedBox(width: 8),
                _EzIconButton(EzIcon(Icons.play_arrow_rounded, label: 'Play', onTap: onOpen)),
                const SizedBox(width: 6),
                _EzIconButton(EzIcon(card.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    label: card.saved ? 'Saved' : 'Save', onTap: card.onSave)),
              ]),
            ),
          ]),
        ),
      );
}
