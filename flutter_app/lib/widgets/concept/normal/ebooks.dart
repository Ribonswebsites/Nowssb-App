/// NowssB eBooks — the one real book (Ribon 17-11: "there is only one
/// ebook"). Its jacket sits in the inset well beside the title, the line it
/// opens with and its chapter count, with the glint sweep (the existing
/// [NormalLoop] sweep) and the eBook line animation (book_pages_gold) in the
/// header. No shelf of stand-in books.
library;

import 'package:flutter/material.dart';
import 'surface.dart';

/// The eBook line animation (kept from home_v4; used only for eBooks).
const kNEbookLottie = 'assets/anim/loaders/book_pages_gold.json';

/// Bundled jacket per catalogue key. Only one NowssB eBook really exists —
/// The Shabdapathy Codex — so only it is listed; its jacket is the real
/// NowssB eBook art (white book in white NowssB headphones on black), the
/// same picture the Ebooks store uses. A catalogue book without art is left
/// out (never a stand-in).
const kNEbookArt = {
  'shabdapathy-codex': (
    asset: 'assets/ebooks/ebooks-headphones.jpg',
    tint: Color(0xFF1C1C1E),
    title: 'The Shabdapathy Codex',
    tag: 'Origin science',
    icon: Icons.menu_book_rounded,
    align: Alignment(.15, 0),
  ),
};

class NEbooks extends StatefulWidget {
  const NEbooks({super.key, required this.onBrowse, required this.books, this.chapters = const {}});
  final VoidCallback onBrowse;
  /// Catalogue books as (key, title), store_catalog.dart kEbBooks order.
  final List<(String, String)> books;
  /// Opening line and chapter count per catalogue key (from kEbBooks).
  final Map<String, ({String sub, int chapters})> chapters;
  @override
  State<NEbooks> createState() => _NEbooksState();
}

class _NEbooksState extends State<NEbooks> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 5);

  List<(String, String)> get _shown => [for (final b in widget.books) if (kNEbookArt.containsKey(b.$1)) b].take(1).toList();

  Widget _cover(int i, double t) {
    final glint = (t * 2) % 2;
    final c = kNEbookArt[_shown[i].$1]!;
    return AspectRatio(
      aspectRatio: .70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: c.tint.withValues(alpha: .38), offset: const Offset(0, 8), blurRadius: 14)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(c.asset, fit: BoxFit.cover, alignment: c.align,
                errorBuilder: (_, __, ___) => ColoredBox(color: c.tint)),
            // jacket wash, deepest under the title
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0, .38, 1],
                colors: [const Color(0x00000000), c.tint.withValues(alpha: 0), c.tint.withValues(alpha: .35)]))),
            // spine
            Positioned(left: 0, top: 0, bottom: 0, width: 7, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: .55), Colors.white.withValues(alpha: .18), Colors.black.withValues(alpha: .0)])))),
            Positioned(left: 11, top: 9, child: Text('NOWSSB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.6,
                color: Colors.white.withValues(alpha: .92)))),
            Positioned(right: 7, top: 6, child: Icon(c.icon, size: 15, color: nGold)),
            // The jacket carries its own lettering; the title is set beside
            // it, and Semantics keeps it readable here.
            Semantics(label: c.title, child: const SizedBox.expand()),
            // the sweep only runs while the loop moves (never frozen in Still)
            if (loop.isAnimating && glint < 1)
              DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment(-2 + 4 * glint, -1), end: Alignment(-1 + 4 * glint, 1),
                colors: const [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)]))),
          ]),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String big, String label) => Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: neu(r: 16, pressed: true),
        child: Column(children: [
          Icon(icon, size: 18, color: nAccent),
          const SizedBox(height: 4),
          Text(big, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: nInk, height: 1.15)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: nSoft, height: 1.2)),
        ]),
      ));

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown.isEmpty) return const SizedBox.shrink();
    final art = kNEbookArt[shown.first.$1]!;
    final book = widget.chapters[shown.first.$1];
    final chapters = book?.chapters ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Open eBook', onTap: widget.onBrowse, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NowssB eBooks', style: nHello),
              Text('Read anywhere', style: nTitle),
            ])),
            Container(
              width: 56, height: 56,
              decoration: neu(r: 18, pressed: true),
              child: const Center(child: NLottie(kNEbookLottie, size: 44)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Word science and sound healing, page by page.', style: nSub),
          const SizedBox(height: 14),
          Container(decoration: neu(r: 22, pressed: true), padding: const EdgeInsets.all(10),
            child: AnimatedBuilder(animation: loop, builder: (_, __) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(width: 118, child: _cover(0, loop.value)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(art.tag.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: nAccent)),
                const SizedBox(height: 6),
                Text(art.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: nInk, height: 1.2)),
                if (book != null) ...[
                  const SizedBox(height: 6),
                  Text(book.sub, style: nSub),
                ],
                const SizedBox(height: 10),
                Text('By Adv. Sanjaykumar Gadge', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: nSoft.withValues(alpha: .9), height: 1.2)),
              ])),
            ]))),
          const SizedBox(height: 12),
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _stat(Icons.auto_stories_outlined, chapters > 0 ? '$chapters chapters' : '1 book', 'in one volume'),
            const SizedBox(width: 10),
            _stat(Icons.record_voice_over_outlined, 'Sound', 'and word science'),
            const SizedBox(width: 10),
            _stat(Icons.devices_rounded, 'Any screen', 'read anywhere'),
          ])),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Text('Open the book and start at page one.', style: nSub)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(40),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 5), blurRadius: 10)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Open eBook', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16, color: nGold),
              ]),
            ),
          ]),
        ]),
      )));
  }
}
