/// POSTER · Trending — "THE CHART".
/// Variation: a dark chart-topper poster (giant gold outline rank numeral
/// BEHIND the redhead cut-out, the word split across her with line 2 in
/// front), then a ladder of torn paper chart strips 02–07.
library;

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import 'poster_kit.dart';
import 'poster_orbit.dart';

const _slot = 'concept.PosterTrending';

class PosterTrending extends StatelessWidget {
  const PosterTrending({
    super.key,
    required this.onBack,
    required this.onOpenBag,
    required this.onOpenWord,
    required this.onBuy,
    required this.onOpenLibrary,
    this.controller,
    this.now,
    this.debugAngle,
    this.debugTilt,
  });
  final double? debugAngle;
  final Offset? debugTilt;

  final VoidCallback onBack, onOpenBag;

  /// Word detail; index into ContentStore.instance.library.
  final void Function(int libraryIndex) onOpenWord;

  /// "Own it" → meaning / word checkout for that word.
  final void Function(Word word) onBuy;

  /// "Every word" tile → library / sound tab.
  final VoidCallback onOpenLibrary;
  final ScrollController? controller;
  final DateTime? now;

  /// Library word at [i] (null when the library has not loaded).
  static Word? wordAt(int i) {
    final lib = ContentStore.instance.library;
    return i >= 0 && i < lib.length ? lib[i] : null;
  }

  /// Same rotation the live FashTrending banner uses (day + 3), extended to 7.
  static List<int> chart(List<Word> lib, DateTime now) {
    if (lib.isEmpty) return const [];
    final out = <int>[];
    for (var i = 0; out.length < 7 && i < lib.length; i++) {
      final k = (now.day + 3 + i * 5) % lib.length;
      if (!out.contains(k) && lib[k].word.isNotEmpty) out.add(k);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final lib = ContentStore.instance.library;
    final idx = chart(lib, now ?? DateTime.now());
    if (idx.isEmpty) {
      return PosterScaffold(slot: _slot, kicker: 'Trending', onBack: onBack, onOpenBag: onOpenBag, children: const [SizedBox(height: 200)]);
    }
    final top = lib[idx.first];
    return PosterScaffold(
      slot: _slot,
      kicker: 'Trending · The chart',
      controller: controller,
      onBack: onBack,
      onOpenBag: onOpenBag,
      dock: _Dock(word: top, onTap: () => onOpenWord(idx.first)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: PosterOrbitStage(
            slot: _slot,
            word: top,
            onOpenWord: () => onOpenWord(idx.first),
            onBuy: () => onBuy(top),
            debugAngle: debugAngle,
            debugTilt: debugTilt,
          ),
        ),
        const Kicker(_slot, 'Rising fast'),
        if (idx.length > 1) _ChartTopper(word: lib[idx[1]], onOpen: () => onOpenWord(idx[1]), onBuy: () => onBuy(lib[idx[1]])),
        const Kicker(_slot, 'Climbing today'),
        for (var r = 2; r < idx.length; r++) _Strip(rank: r + 1, word: lib[idx[r]], onTap: () => onOpenWord(idx[r]), onBuy: () => onBuy(lib[idx[r]])),
        const Kicker(_slot, 'The whole library'),
        _LibraryTile(onTap: onOpenLibrary),
      ],
    );
  }
}

class _ChartTopper extends StatelessWidget {
  const _ChartTopper({required this.word, required this.onOpen, required this.onBuy});
  final Word word;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) {
    final w = word.word.toUpperCase();
    final id = 'word:${word.word.toLowerCase()}';
    final price = priceOrNull(id, wordPrice(word.word));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Tap(
        onTap: onOpen,
        child: Sway(
          base: .018,
          amp: .006,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 30, offset: Offset(0, 16))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AspectRatio(
                aspectRatio: .9,
                child: ClipRect(
                  child: LayoutBuilder(builder: (context, box) {
                    final W = box.maxWidth, H = box.maxHeight;
                    return Stack(children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3A1F63), Color(0xFF120A1F)],
                            ),
                          ),
                        ),
                      ),
                      // giant rank numeral, behind everything
                      Positioned(
                        left: -W * .06,
                        top: -H * .06,
                        width: W * 1.1,
                        height: H * .62,
                        child: GiantWord('02', style: anton(H * .62, w: FontWeight.w800, ls: -8), outline: kPGold.withValues(alpha: .7)),
                      ),
                      Positioned(
                        right: -W * .08,
                        top: H * .14,
                        width: W * .62,
                        height: H * .86,
                        child: const Cutout(PosterAssets.redhead, slot: _slot, id: 'hero.cutout', align: Alignment.bottomRight),
                      ),
                      // the word, ONE line, in front of her shoulder (scaled to fit, never wrapped)
                      Positioned(
                        left: 14,
                        right: 14,
                        top: H * .30,
                        height: H * .17,
                        child: GiantWord(w,
                            style: anton(H * .2, color: kPPaper, w: FontWeight.w800, ls: -2)
                                .copyWith(shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 18)])),
                      ),
                      const Positioned(left: 14, top: 14, child: GoldTag('Rising fast · No. 2')),
                      Positioned(
                        left: 14,
                        top: 46,
                        width: W * .42,
                        child: Text(word.deva, style: gHello(color: kPGoldSoft)),
                      ),
                    ]);
                  }),
                ),
              ),
              // tag + actions in their own band, never on the figure
              Container(
                width: double.infinity,
                color: const Color(0xFF120A1F),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  InkTag(word.meaning.isEmpty ? word.benefit : word.meaning),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    GoldPill(label: 'Hear it', onTap: onOpen, arrow: true),
                    GoldPill(label: price == null ? ownedLabel(id) : 'Own · $price', onTap: price == null ? onOpen : onBuy, dark: true),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.rank, required this.word, required this.onTap, required this.onBuy});
  final int rank;
  final Word word;
  final VoidCallback onTap, onBuy;
  @override
  Widget build(BuildContext context) {
    final even = rank.isEven;
    final paper = even ? kPPaper : kPGoldSoft;
    return Transform.translate(
      offset: Offset(even ? -6 : 8, 0),
      child: Sway(
        base: even ? -.018 : .014,
        amp: .004,
        bob: 1.5,
        offset: rank * .13,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Tap(
            onTap: onTap,
            child: ClipPath(
              clipper: TornClipper(rank * 7),
              child: Container(
                color: paper,
                padding: const EdgeInsets.fromLTRB(12, 14, 10, 16),
                child: LayoutBuilder(builder: (context, c) {
                  // Narrow or large text: the price drops under the blurb so
                  // the blurb keeps whole words.
                  final stack = c.maxWidth / MediaQuery.textScalerOf(context).scale(1) < 300;
                  final pill = Semantics(
                    button: true,
                    label: 'Own ${word.word}',
                    child: Tap(
                      onTap: onBuy,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: kPInk, border: Border.all(color: kPGold, width: 1.5)),
                        child: Text(priceText('word:${word.word.toLowerCase()}', wordPrice(word.word)),
                            maxLines: 1, softWrap: false, style: gTitle(color: kPGold).copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                  return Row(children: [
                    SizedBox(
                      width: stack ? 52 : 64,
                      child: Text(rank.toString().padLeft(2, '0'),
                          textScaler: TextScaler.noScaling, style: anton(stack ? 42 : 52, color: const Color(0xFF6B4A12), w: FontWeight.w800)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(height: 44, child: GiantWord(word.word.toUpperCase(), style: anton(40, w: FontWeight.w800, ls: -1))),
                        const SizedBox(height: 4),
                        Text([word.organ, word.meaning].where((e) => e.isNotEmpty).join(' · '), style: gSub(dark: false)),
                        if (stack) ...[const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: pill)],
                      ]),
                    ),
                    if (!stack) ...[const SizedBox(width: 6), pill],
                  ]);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Tap(
          onTap: onTap,
          child: Transform.rotate(
            angle: -.03,
            child: ClipPath(
              clipper: const TornClipper(91, depth: 1.6),
              child: SizedBox(
                height: 200,
                child: Stack(fit: StackFit.expand, children: [
                  const Photo(PosterAssets.listen, slot: _slot, id: 'library.photo'),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]))),
                  const Positioned(right: 12, top: 14, child: GoldTag('Every word')),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    height: 92,
                    child: GiantWord('LISTEN', style: anton(110, color: Colors.white, w: FontWeight.w800, ls: -3)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Dock extends StatelessWidget {
  const _Dock({required this.word, required this.onTap});
  final Word word;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xF0120A1F),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: kPGold.withValues(alpha: .6)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              EditableLabel(_slot, 'No. 1 right now', id: 'dock.kicker', style: gSub(color: kPGoldSoft)),
              Text(word.word, style: gTitle()),
            ]),
          ),
          GoldPill(label: 'Hear #1', onTap: onTap, arrow: true),
        ]),
      );
}
