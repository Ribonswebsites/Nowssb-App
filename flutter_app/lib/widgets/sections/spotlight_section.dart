/// Spotlight carousel — large card PageView with page dots (MK-6 / ref 5).
///
/// Soft dark rounded cards, optional badge from meta['badge'], title +
/// subtitle under each card, elongated active pill dots. Autoplay when
/// behavior.autoplay (default true); pauses while the user drags.
/// Horizontal PageView only — bounded height, safe inside the home scroll.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../hype_rail.dart';
import 'section_config.dart';

List<SectionMediaItem> _itemsFromConfig(SectionConfig? config) {
  final items = config?.items ?? const <SectionMediaItem>[];
  if (items.isNotEmpty) {
    final cap = config?.behavior.itemCount;
    return cap == null
        ? List<SectionMediaItem>.from(items)
        : items.take(cap).toList();
  }

  // Fallback: NowssB programme / feature posters from the hyped rail.
  final cap = config?.behavior.itemCount ?? 4;
  final cards = kHypeCards.take(cap.clamp(1, kHypeCards.length)).toList();
  return [
    for (var i = 0; i < cards.length; i++)
      SectionMediaItem(
        id: cards[i].id,
        imageUrl: cards[i].asset,
        title: cards[i].title,
        subtitle: cards[i].line,
        ctaLink: cards[i].id,
        meta: {
          if (i == 0) 'badge': 'Sale is live',
          if (i == 1) 'badge': 'Today',
          if (i == 2) 'badge': 'Featured',
        },
      ),
  ];
}

String? _badgeOf(SectionMediaItem item) {
  final raw = item.meta['badge'];
  if (raw == null) return null;
  if (raw is bool) return raw ? 'Sale is live' : null;
  final s = '$raw'.trim();
  return s.isEmpty ? null : s;
}

/// Large spotlight card carousel for [SectionTypeId.spotlight].
class SpotlightSection extends StatefulWidget {
  const SpotlightSection({
    super.key,
    this.config,
    this.onTap,
  });

  final SectionConfig? config;
  final ValueChanged<SectionMediaItem>? onTap;

  @override
  State<SpotlightSection> createState() => _SpotlightSectionState();
}

class _SpotlightSectionState extends State<SpotlightSection> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;
  var _userPaging = false;

  List<SectionMediaItem> get _items => _itemsFromConfig(widget.config);

  /// Standalone (no config) always autoplays; config opts in via autoplay.
  bool get _autoplay {
    final b = widget.config?.behavior;
    if (b == null) return true;
    return b.autoplay;
  }

  int get _autoplayMs {
    final ms = widget.config?.behavior.autoplayMs ?? 4500;
    return ms.clamp(1800, 20000);
  }

  bool get _loop => widget.config?.behavior.loop ?? true;

  double get _cardHeight => widget.config?.layout.cardHeight ??
      widget.config?.layout.height ??
      320;

  double get _radius => widget.config?.layout.radius ?? 20;

  @override
  void initState() {
    super.initState();
    final start = widget.config?.behavior.startIndex ?? 0;
    final n = _items.length;
    _index = n == 0 ? 0 : start.clamp(0, n - 1);
    _page = PageController(initialPage: _index);
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant SpotlightSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _armTimer();
    }
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_autoplay) return;
    _timer = Timer.periodic(Duration(milliseconds: _autoplayMs), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      if (!_page.hasClients) return;
      final n = _items.length;
      if (n <= 1) return;
      final next = _index + 1;
      if (next >= n) {
        if (!_loop) return;
        _page.animateToPage(
          0,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      } else {
        _page.animateToPage(
          next,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _handleTap(SectionMediaItem item) {
    if (editModeOn(context)) return;
    if (widget.onTap != null) {
      widget.onTap!(item);
      return;
    }
    final link = (item.ctaLink ?? '').trim();
    if (link.isEmpty) return;
    final opener = openHypeCard;
    if (opener != null && kHypeCards.any((c) => c.id == link)) {
      opener(context, link);
      return;
    }
    NwsbLinks.cta(context, link);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    if (widget.config != null && !widget.config!.enabled) {
      return const SizedBox.shrink();
    }

    final sectionId = widget.config?.id ?? 'spotlight';
    // PageView is card-only; title/subtitle sit below so text scale cannot
    // overflow a brittle cardHeight+88 box (Hunter H-009).
    final safeIndex = _index.clamp(0, items.length - 1);
    final caption = items[safeIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: EditableLabel(
              '$sectionId.heading',
              'In the spotlight',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _userPaging = true;
              } else if (n is ScrollEndNotification) {
                _userPaging = false;
              }
              return false;
            },
            child: SizedBox(
              height: _cardHeight,
              child: PageView.builder(
                controller: _page,
                itemCount: items.length,
                // Horizontal only — never nest vertical scroll inside home.
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return _SpotlightPage(
                    item: item,
                    sectionId: sectionId,
                    cardHeight: _cardHeight,
                    radius: _radius,
                    onTap: () => _handleTap(item),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SpotlightCaption(
            item: caption,
            sectionId: sectionId,
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: on ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: on
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpotlightPage extends StatelessWidget {
  const _SpotlightPage({
    required this.item,
    required this.sectionId,
    required this.cardHeight,
    required this.radius,
    required this.onTap,
  });

  final SectionMediaItem item;
  final String sectionId;
  final double cardHeight;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slot = '$sectionId.${item.id}';
    final badge = _badgeOf(item);
    final fit = item.fit == SectionMediaFit.contain
        ? BoxFit.contain
        : BoxFit.cover;
    final alignment = Alignment(item.focalX, item.focalY);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: cardHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: const Color(0x22FFFFFF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SpotlightImage(
                    imageUrl: item.imageUrl,
                    slot: '$slot.image',
                    alignment: alignment,
                    fit: fit,
                    zoom: item.zoom,
                  ),
                  // Soft bottom fade so the card edge stays dark.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x99000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1A1A1A),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0x33FFFFFF),
                          ),
                        ),
                        child: EditableLabel(
                          '$slot.badge',
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title + subtitle under the PageView (sizes with text scale; H-009).
class _SpotlightCaption extends StatelessWidget {
  const _SpotlightCaption({
    required this.item,
    required this.sectionId,
  });

  final SectionMediaItem item;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final slot = '$sectionId.${item.id}';
    final title =
        (item.title ?? '').trim().isEmpty ? 'NowssB' : item.title!.trim();
    final subtitle = (item.subtitle ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditableLabel(
            '$slot.title',
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            EditableLabel(
              '$slot.subtitle',
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpotlightImage extends StatelessWidget {
  const _SpotlightImage({
    required this.imageUrl,
    required this.slot,
    required this.alignment,
    required this.fit,
    required this.zoom,
  });

  final String? imageUrl;
  final String slot;
  final Alignment alignment;
  final BoxFit fit;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    Widget child;
    if (url.isEmpty) {
      child = ColoredBox(
        color: const Color(0xFF111111),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: NwsbColors.gold.withValues(alpha: 0.45),
            size: 48,
          ),
        ),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      child = EditableImage.network(
        url,
        fit: fit,
        alignment: alignment,
        slot: slot,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: Color(0xFF111111)),
      );
    } else {
      child = EditableImage.asset(
        url,
        fit: fit,
        alignment: alignment,
        slot: slot,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: Color(0xFF111111)),
      );
    }
    if ((zoom - 1).abs() < 0.02) return child;
    return ClipRect(
      child: Transform.scale(
        scale: zoom.clamp(1.0, 8.0),
        alignment: alignment,
        child: child,
      ),
    );
  }
}
