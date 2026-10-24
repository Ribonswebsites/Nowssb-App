/// Fashion home cards in the Sound library's look:
/// * [StoreNowCarousel] — glass wrapper, auto-moving "NOW PLAYING" style
///   cards (art left, label, big title, subtitle, white round button).
/// * [NowProgressRail] — sideways "Currently Playing" style cards with a
///   progress bar (coins, progress, profile, tasks).
/// * [AutoMarquee] — slow continuous sideways drift for a row.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/auto_cycle.dart';
import '../../widgets/glass_wrap.dart';

const kHomeStoreArt = 'assets/home/nowssb-store.webp';

const _ink = TextStyle(color: Colors.white, decoration: TextDecoration.none);

/// Section heading used above home rows.
class HomeRowHeading extends StatelessWidget {
  const HomeRowHeading(this.text, {super.key, this.sub});
  final String text;
  final String? sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(text, style: _ink.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: _ink.copyWith(fontSize: 12, color: const Color(0x99FFFFFF))),
            ),
          ],
        ]),
      );
}

/// Drifts its horizontal list slowly and endlessly (items are repeated).
/// A finger on it pauses the drift.
class AutoMarquee extends StatefulWidget {
  const AutoMarquee({super.key, required this.height, required this.children, this.gap = 8, this.speed = 18});
  final double height;
  final List<Widget> children;
  final double gap;

  /// Pixels per second.
  final double speed;

  @override
  State<AutoMarquee> createState() => _AutoMarqueeState();
}

class _AutoMarqueeState extends State<AutoMarquee> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _tick;
  Duration _lastTime = Duration.zero;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_step)
      ..repeat();
  }

  void _step() {
    final now = _tick.lastElapsedDuration ?? Duration.zero;
    var dt = (now - _lastTime).inMicroseconds / 1e6;
    _lastTime = now;
    if (dt < 0 || dt > .2) dt = 0;
    if (_held || !_scroll.hasClients || widget.children.isEmpty) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    var next = _scroll.offset + widget.speed * dt;
    // The list is the children three times over; loop back by one copy.
    final copy = (max + _scroll.position.viewportDimension) / 3;
    if (next >= copy * 2) next -= copy;
    _scroll.jumpTo(next.clamp(0.0, max));
  }

  @override
  void dispose() {
    _tick.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return Listener(
      onPointerDown: (_) => _held = true,
      onPointerUp: (_) => _held = false,
      onPointerCancel: (_) => _held = false,
      child: SizedBox(
        height: widget.height,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: n * 3,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(right: widget.gap),
            child: KeyedSubtree(key: ValueKey('marquee-$i'), child: i < n ? widget.children[i % n] : ExcludeSemantics(child: widget.children[i % n])),
          ),
        ),
      ),
    );
  }
}

/// One Store word for the NOW PLAYING–style card.
class StoreNowItem {
  const StoreNowItem({required this.word, required this.category, required this.price, this.percent = 0, required this.onTap});
  final String word;
  final String category;
  final String price;
  final int percent;
  final VoidCallback onTap;
}

/// Card styled like the Sound library's NOW PLAYING card.
class StoreNowCard extends StatelessWidget {
  const StoreNowCard({super.key, required this.item, this.art = kHomeStoreArt});
  final StoreNowItem item;
  final String art;

  static const double h = 136;

  @override
  Widget build(BuildContext context) {
    final label = item.percent > 0 ? "TODAY'S DEAL · -${item.percent}%" : "TODAY'S WORD";
    return Semantics(
      button: true,
      label: '${item.word}, ${item.category}, ${item.price}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Container(
          height: h,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xF0111114),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(art, width: h - 20, height: h - 20, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: h - 20, color: const Color(0xFF222222))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _ink.copyWith(fontSize: 10.5, letterSpacing: 1.6, color: const Color(0xB3FFFFFF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(item.word.toUpperCase(), maxLines: 1,
                      style: _ink.copyWith(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: .5)),
                ),
                const SizedBox(height: 6),
                Text('${item.category} · ${item.price}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _ink.copyWith(fontSize: 13, color: const Color(0x99FFFFFF))),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.black, size: 22),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Glass wrapper holding an auto-moving row of [StoreNowCard]s.
class StoreNowCarousel extends StatefulWidget {
  const StoreNowCarousel({super.key, required this.items, this.title = 'NowssB Store', this.onHeader});
  final List<StoreNowItem> items;
  final String title;
  final VoidCallback? onHeader;

  @override
  State<StoreNowCarousel> createState() => _StoreNowCarouselState();
}

class _StoreNowCarouselState extends State<StoreNowCarousel> with SingleTickerProviderStateMixin, AutoCycle {
  final _page = PageController(viewportFraction: .92);
  int _ix = 0;

  @override
  Duration get period => const Duration(milliseconds: 3600);

  @override
  void onTick() {
    if (!mounted || !_page.hasClients || widget.items.length < 2) return;
    _ix = (_ix + 1) % widget.items.length;
    _page.animateToPage(_ix, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onHeader,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                  child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Buy · Sell today', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: _ink.copyWith(fontSize: 12, color: const Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(
          height: StoreNowCard.h,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            onPageChanged: (i) => _ix = i,
            itemCount: widget.items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: StoreNowCard(item: widget.items[i]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// One card in the Currently Playing–style rail.
class NowProgressItem {
  const NowProgressItem({
    required this.title,
    required this.sub,
    required this.caption,
    required this.image,
    required this.value,
    required this.left,
    required this.right,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String title;
  final String sub;
  final String caption;
  final String image;
  final double value;
  final String left;
  final String right;
  final VoidCallback onTap;
  final IconData icon;
}

class NowProgressCard extends StatelessWidget {
  const NowProgressCard({super.key, required this.item});
  final NowProgressItem item;

  static const double h = 168;
  static const double w = 318;

  @override
  Widget build(BuildContext context) {
    final v = item.value.clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: '${item.title}, ${item.sub}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Container(
          width: w,
          height: h,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x1FFFFFFF))),
          child: Row(children: [
            SizedBox(
              width: 112,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(item.image, width: 112, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF222222))),
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.caption, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _ink.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _ink.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.sub, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: _ink.copyWith(fontSize: 12.5, color: const Color(0x99FFFFFF), height: 1.25)),
                const Spacer(),
                LayoutBuilder(builder: (_, c) {
                  return SizedBox(
                    height: 14,
                    child: Stack(alignment: Alignment.centerLeft, children: [
                      Container(height: 3, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(2))),
                      Container(width: c.maxWidth * v, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                      Positioned(
                        left: (c.maxWidth - 12) * v,
                        child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(child: Text(item.left, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 11, color: const Color(0x99FFFFFF)))),
                  const Spacer(),
                  Text(item.right, style: _ink.copyWith(fontSize: 11, color: const Color(0x99FFFFFF))),
                ]),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(item.icon, color: Colors.black, size: 22),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Sideways rail of [NowProgressCard]s inside the same glass wrapper and
/// black heading chip as the Sound library's Currently Playing block.
class NowProgressRail extends StatelessWidget {
  const NowProgressRail({super.key, required this.items, this.title = 'Up next for you'});
  final List<NowProgressItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        SizedBox(
          height: NowProgressCard.h,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => NowProgressCard(item: items[i]),
          ),
        ),
      ]),
    );
  }
}
