/// The Normal-home hero: one rounded card carousel (auto-rotates, swipe,
/// pauses on touch, no dots): four dot-light film cards (Breath, Sound, Rise,
/// Release) and the day's ritual card, each with one primary action: begin
/// today's session. Films: the client's own clips, muted seamless loops.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../media/golden_breath.dart';
import '../../widgets/concept/ritual_card.dart';
import '../../widgets/concept/ritual_paper_card.dart';

class HeroData {
  const HeroData({
    required this.title,
    required this.partLabel,
    required this.words,
    required this.done,
    required this.total,
    required this.onBegin,
      this.onHear,
    this.isSaved,
    this.onSave,
    this.streak = 0,
    this.sessions = 0,
    this.ritualTime,
    this.onProgress,
  });

  /// Night/Morning Ritual card inputs.
  final int streak;
  final int sessions;
  final RitualTime? ritualTime;
  final VoidCallback? onProgress;

  /// Save: the card's word when it has one, else the session itself.
  final bool Function(String? word)? isSaved;
  final void Function(String? word)? onSave;
  final String title;
  final String partLabel;
  final List<Word> words;
  final int done;
  final int total;
  final VoidCallback onBegin;
  final void Function(Word w)? onHear;

  String get wordsLine => words.isEmpty ? 'Your routine' : '${words.length} words';
}


const _serif = 'CormorantGaramond';

/// Rotation + gesture plumbing shared by A and C.
class _Carousel extends StatefulWidget {
  const _Carousel({super.key, required this.count, required this.height, required this.builder, this.peek = .9});
  final int count;
  final double height;
  final double peek;
  final Widget Function(BuildContext, int i, double offset) builder;
  @override
  State<_Carousel> createState() => HeroCarouselState();
}

class HeroCarouselState extends State<_Carousel> {
  static const _loop = 10000;
  late final PageController _page = PageController(initialPage: _loop * widget.count, viewportFraction: widget.peek);
  Timer? _tick, _resume;
  bool held = false;
  int get index => _page.hasClients ? (_page.page ?? 0).round() % widget.count : 0;

  /// Test hook: show card [i] without animation.
  void jumpTo(int i) => _page.jumpToPage(_loop * widget.count + i);

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 6), (_) {
      if (held || !mounted || !_page.hasClients) return;
      final cur = (_page.page ?? _page.initialPage.toDouble()).round();
      _page.animateToPage(cur + 1, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
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
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          _resume?.cancel();
          _tick?.cancel();
          held = true;
        },
        onPointerUp: (_) => _resume = Timer(const Duration(seconds: 5), () {
          held = false;
          _start();
        }),
        child: SizedBox(
          height: widget.height,
          child: PageView.builder(
            key: const ValueKey('hero-concept-pages'),
            controller: _page,
            padEnds: true,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            onPageChanged: (_) => HapticFeedback.selectionClick(),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _page,
              builder: (context, _) {
                final p = _page.hasClients && _page.position.haveDimensions ? (_page.page ?? i.toDouble()) : (_loop * widget.count).toDouble();
                final off = (i - p).clamp(-1.0, 1.0);
                final e = Curves.easeOutCubic.transform(off.abs());
                return Transform.translate(
                  offset: Offset(off * -14, 0),
                  child: Transform.scale(
                    scale: 1 - e * .05,
                    child: Opacity(opacity: 1 - e * .18, child: widget.builder(context, i % widget.count, off)),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({super.key, required this.text, this.icon, this.onTap, this.dim = false});
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dim;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x40FFFFFF), width: .6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 13, color: dim ? const Color(0xB3FFFFFF) : Colors.white), const SizedBox(width: 5)],
                Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dim ? const Color(0xB3FFFFFF) : Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500, letterSpacing: .2))),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────────── Mixed carousel (v2) ─────────────────────────────
//
// All three ideas as cards in one carousel. Every card is the same height,
// one colour world and one photo each, and one primary action: Begin.

const _cardH = 432.0;

class MixedHero extends StatelessWidget {
  const MixedHero({super.key, required this.data});
  final HeroData data;

  @override
  Widget build(BuildContext context) {
    Word? w(int i) => data.words.isEmpty ? null : data.words[i % data.words.length];
    // Ribon 11-03: the dot-light films — black, gold and white — one per card,
    // with the day's ritual card kept as the only non-film slide.
    final cards = <Widget Function(double off)>[
      (off) => _FilmCard(film: _films[0], data: data, word: w(0), parallax: off),
      (off) => _PaperRitualSlot(data: data),
      (off) => _FilmCard(film: _films[1], data: data, word: w(1), parallax: off),
      (off) => _FilmCard(film: _films[2], data: data, word: w(2), parallax: off),
      (off) => _FilmCard(film: _films[3], data: data, word: w(3), parallax: off),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: _Carousel(
        key: const ValueKey('hero-mixed'),
        count: cards.length,
        height: _cardH,
        peek: .9,
        builder: (context, i, off) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: cards[i](off),
        ),
      ),
    );
  }
}

TextStyle _kick(Color c) => TextStyle(color: c, fontSize: 10, letterSpacing: 2.4, fontWeight: FontWeight.w600);

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.onTap, required this.ink, this.label = 'Begin'});
  final VoidCallback onTap;
  final Color ink;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: "Begin today's session",
        excludeSemantics: true,
        child: GestureDetector(
          key: const ValueKey('hero-primary'),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(14, 0, 20, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F3),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow_rounded, color: ink, size: 22),
              const SizedBox(width: 4),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: .1))),
            ]),
          ),
        ),
      );
}

String _progress(HeroData d) => d.total == 0 ? '' : '${d.done} of ${d.total} done';

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.data, required this.word, this.light = false});
  final bool light;
  final HeroData data;
  final String? word;
  @override
  Widget build(BuildContext context) {
    if (data.onSave == null) return const SizedBox.shrink();
    final saved = data.isSaved?.call(word) ?? false;
    return Semantics(
      button: true,
      label: saved ? 'Saved' : 'Save',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('hero-save'),
        behavior: HitTestBehavior.opaque,
        onTap: () => data.onSave!(word),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: light ? const Color(0xFFF0F2F7) : const Color(0x2EFFFFFF),
                border: Border.all(color: light ? const Color(0xFFFFFFFF) : const Color(0x40FFFFFF), width: .6),
                boxShadow: light ? const [BoxShadow(color: Color(0x26000000), offset: Offset(2, 2), blurRadius: 5)] : null,
              ),
              child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 16, color: light ? const Color(0xFF1A1A2E) : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}


// D · Film: one dot-light clip (muted, seamless loop; poster under reduced
// motion; NwsbVideo pauses it offscreen), black ground, gold and white type.
class _Film {
  const _Film(this.clip, this.kicker, this.line, {this.align = Alignment.center});
  final String clip, kicker, line;
  final Alignment align;
}

const _films = [
  _Film('hero-breath', 'Breath', 'Let the word leave you as light', align: Alignment(0, -.2)),
  _Film('hero-sound', 'Sound', 'Every sound returns to its root'),
  _Film('hero-rise', 'Rise', 'Feel it climb, then let it go'),
  _Film('hero-release', 'Release', 'Breathe out what you carry'),
];

const _gold = Color(0xFFE8C98A);

class _FilmCard extends StatelessWidget {
  const _FilmCard({required this.film, required this.data, required this.word, required this.parallax});
  final _Film film;
  final HeroData data;
  final Word? word;
  final double parallax;
  @override
  Widget build(BuildContext context) {
    final hasAudio = word != null && (word!.audio.isNotEmpty || word!.audioMale.isNotEmpty || word!.audioFemale.isNotEmpty);
    return GestureDetector(
      key: ValueKey('hero-film-${film.kicker.toLowerCase()}'),
      onTap: data.onBegin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.black),
          Transform.translate(
            offset: Offset(parallax * 24, 0),
            child: Transform.scale(scale: 1.06, child: GoldenBreathClip(
              asset: 'assets/video/${film.clip}.mp4', poster: 'assets/video/${film.clip}-poster.webp',
              alignment: film.align, slot: 'calm_hero.FilmCard')),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xF2000000)],
                  stops: [0, .22, .5, .92]),
            ),
          ),
          Positioned(
            left: 22, top: 20, right: 20,
            child: Row(children: [
              Expanded(child: Text('TODAY · ${data.partLabel.toUpperCase()}', style: _kick(const Color(0xE6FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (data.total > 0) _GlassChip(text: _progress(data)),
              const SizedBox(width: 8),
              _SaveButton(data: data, word: word?.word),
            ]),
          ),
          Positioned(
            left: 22, right: 22, bottom: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                for (var i = 0; i < 3; i++) Container(width: 3, height: 3, margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withValues(alpha: 1 - i * .3))),
                const SizedBox(width: 4),
                Text(film.kicker.toUpperCase(), style: _kick(_gold)),
              ]),
              const SizedBox(height: 8),
              Text(data.title, maxLines: 2,
                  style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 40, height: .98, fontWeight: FontWeight.w500, letterSpacing: -.6)),
              const SizedBox(height: 6),
              Text(word == null ? film.line : '${word!.word}  ·  ${word!.meaning}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.35)),
              const SizedBox(height: 16),
              Row(children: [
                Flexible(child: _PlayPill(onTap: data.onBegin, ink: Colors.black)),
                if (hasAudio) ...[
                  const SizedBox(width: 10),
                  _GlassChip(key: const ValueKey('hero-hear'), icon: Icons.graphic_eq_rounded, text: 'Hear it', onTap: () => data.onHear?.call(word!)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Night/Morning ritual as a hero slide: the white-neumorphic cut-paper card
/// (Ribon 11-02), following the time of day, with real progress.
class _PaperRitualSlot extends StatelessWidget {
  const _PaperRitualSlot({required this.data});
  final HeroData data;
  @override
  Widget build(BuildContext context) => PaperRitualCard(
        key: const ValueKey('hero-ritual'),
        fullBleed: true,
        completed: data.done,
        total: data.total,
        sessionCount: data.sessions,
        streak: data.streak,
        time: data.ritualTime,
        title: data.title,
        onBegin: data.onBegin,
      );
}
