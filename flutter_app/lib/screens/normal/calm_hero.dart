/// The Normal-home hero: one rounded card carousel (auto-rotates, swipe,
/// pauses on touch, no dots) mixing three card designs — Cinema, Depth
/// stack and Word — each with one primary action: begin today's session.
///
/// Photos: Pexels (see assets/CREDITS.md), one colour grade, film grain.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
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
const _hc = 'assets/home/hc';

/// Film grain, drawn over everything at low strength.
class _Grain extends StatelessWidget {
  const _Grain({this.opacity = .07, this.shift = 0});
  final double opacity;
  final double shift;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('$_hc/hc-grain.webp'),
                repeat: ImageRepeat.repeat,
                scale: 2,
                alignment: Alignment(shift, -shift),
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.dst),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

Widget _img(String name, {Alignment align = Alignment.topCenter}) => Image.asset('$_hc/$name.webp',
    fit: BoxFit.cover, alignment: align, filterQuality: FilterQuality.medium, gaplessPlayback: true,
    errorBuilder: (_, __, ___) => const SizedBox.shrink());

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

class _World {
  const _World(this.name, this.photo, this.a, this.b, {this.align = Alignment.center});
  final String name;
  final String photo;
  final Color a, b;
  final Alignment align;
}

const _worlds = [
  _World('Breath', 'hc-d-breath', Color(0xFFE88B5A), Color(0xFF3A1E2B)),
  _World('Sound', 'hc-d-sound', Color(0xFFC9A46A), Color(0xFF2A2219)),
  _World('Sleep', 'hc-d-sleep', Color(0xFF6B7BD6), Color(0xFF0F1433)),
];

class _WordLook {
  const _WordLook(this.photo, this.top, this.bottom);
  final String photo;
  final Color top, bottom;
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
    final cards = <Widget Function(double off)>[
      (off) => _PaperRitualSlot(data: data),
      (off) => _DepthCard(data: data, parallax: off),
      (off) => _WordCard2(look: const _WordLook('hc-c-word', Color(0xFFE6C6A4), Color(0xFF6B3F2B)), data: data, word: w(0), parallax: off),
      (off) => _CinemaCard(photo: 'hc-b-sleep', kicker: 'Dusk', tone: const Color(0xFF0E1230), data: data, word: w(1), parallax: off),
      (off) => _WordCard2(look: const _WordLook('hc-b-heal', Color(0xFFBFDCD3), Color(0xFF173F40)), data: data, word: w(1), parallax: off),
      (off) => _CinemaCard(photo: 'hc-b-sound', kicker: 'Sound', tone: const Color(0xFF1A140C), data: data, word: w(2), parallax: off),
      (off) => _WordCard2(look: const _WordLook('hc-e-word', Color(0xFFE2D4F0), Color(0xFF1E1530)), data: data, word: w(2), parallax: off),
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

/// Soft, shared photo plate: parallax shift against the card on swipe.
Widget _plate(String photo, double off, {double k = 28, double dy = 0}) =>
    Transform.translate(offset: Offset(off * k, dy), child: Transform.scale(scale: 1.06, alignment: Alignment.bottomCenter, child: _img(photo)));

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

// A2 · Cinema: photo, grain, serif title, a clean solid play pill.
class _CinemaCard extends StatelessWidget {
  const _CinemaCard({required this.photo, required this.kicker, required this.tone, required this.data, required this.word, required this.parallax});
  final String photo, kicker;
  final Color tone;
  final HeroData data;
  final Word? word;
  final double parallax;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: data.onBegin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: tone),
            _plate(photo, parallax),
            _plate('$photo-fg', parallax, k: 40),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [tone.withValues(alpha: .45), tone.withValues(alpha: 0), tone.withValues(alpha: 0), tone.withValues(alpha: .94)],
                    stops: const [0, .2, .45, 1]),
              ),
            ),
            const _Grain(opacity: .07),
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
                Text(kicker.toUpperCase(), style: _kick(const Color(0xB3FFFFFF))),
                const SizedBox(height: 8),
                Text(data.title,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 40, height: .98, fontWeight: FontWeight.w500, letterSpacing: -.6)),
                const SizedBox(height: 18),
                Row(children: [
                  Flexible(child: _PlayPill(onTap: data.onBegin, ink: tone)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(word == null ? data.wordsLine : '${word!.word}  ·  ${word!.meaning}',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xCCFFFFFF), fontSize: 11.5, height: 1.35)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

// B2 · Depth: three practices stacked in perspective, fully inside the card.
class _DepthCard extends StatefulWidget {
  const _DepthCard({required this.data, required this.parallax});
  final HeroData data;
  final double parallax;
  @override
  State<_DepthCard> createState() => _DepthCardState();
}

/// The stack scrolls vertically: swipe up brings the next practice to the
/// front, swipe down brings the previous one back (wraps around).
class _DepthCardState extends State<_DepthCard> {
  static const _bg = Color(0xFF0B0B0D);
  int front = 0;
  double _drag = 0;
  HeroData get data => widget.data;
  double get parallax => widget.parallax;

  void _step(int d) {
    HapticFeedback.selectionClick();
    setState(() => front = (front + d) % _worlds.length);
  }

  @override
  Widget build(BuildContext context) {
    final n = _worlds.length;
    // back → front, as indexes into _worlds; depth = position from front.
    final order = [for (var d = n - 1; d >= 0; d--) (front + d) % n];
    return GestureDetector(
      key: const ValueKey('hero-depth'),
      onTap: data.onBegin,
      onVerticalDragStart: (_) => _drag = 0,
      onVerticalDragUpdate: (u) => _drag += u.delta.dy,
      onVerticalDragEnd: (e) {
        final v = e.primaryVelocity ?? 0;
        if (_drag < -24 || v < -250) _step(1);
        if (_drag > 24 || v > 250) _step(n - 1);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment(0, -.6), radius: 1.2, colors: [Color(0xFF3A2A3E), _bg]),
            ),
          ),
          const _Grain(opacity: .06),
          Positioned(
            left: 22, top: 20, right: 20,
            child: Row(children: [
              Expanded(child: Text('PRACTICES · ${data.partLabel.toUpperCase()}', style: _kick(const Color(0xCCFFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              _SaveButton(data: data, word: data.words.isEmpty ? null : data.words.first.word),
            ]),
          ),
          // The stack lives in its own inset box; nothing escapes the card.
          Positioned(
            left: 16, right: 16, top: 50, bottom: 16,
            child: LayoutBuilder(builder: (context, c) {
              return Stack(clipBehavior: Clip.hardEdge, alignment: Alignment.bottomCenter, children: [
                for (final i in order) _sheet(c, i, (i - front) % n),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _sheet(BoxConstraints c, int wi, int d) {
    final world = _worlds[wi];
    final front = d == 0;
    final h = c.maxHeight - 88;
    final tilt = parallax.clamp(-1.0, 1.0);
    final m = Matrix4.identity()
      ..setEntry(3, 2, .001)
      ..translateByDouble(tilt * d * 10, -d * 44.0, 0, 1)
      ..scaleByDouble(1 - d * .06, 1 - d * .06, 1, 1)
      ..rotateY(-tilt * .18 * (1 + d * .4));
    return Positioned(
      left: 0, right: 0, bottom: 0, height: h,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: m,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [world.a, world.b]))),
            Opacity(opacity: .85, child: _plate(world.photo, -tilt, k: 14)),
            if (front && !world.photo.startsWith('hc-d-')) _plate('${world.photo}-fg', -tilt, k: 22),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [world.b.withValues(alpha: .4), world.b.withValues(alpha: 0), world.b.withValues(alpha: .95)], stops: const [0, .35, 1]),
              ),
            ),
            if (!front) ColoredBox(color: Colors.black.withValues(alpha: .18 * d)),
            const _Grain(opacity: .07),
            Positioned(
              left: 16, top: front ? 14 : 8, right: 14,
              child: Row(children: [
                Expanded(child: Text(world.name.toUpperCase(), style: _kick(front ? Colors.white : const Color(0xB3FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (front) ...[
                  Text('${wi + 1}/${_worlds.length}', style: _kick(const Color(0xCCFFFFFF))),
                  const SizedBox(width: 6),
                  const Icon(Icons.swipe_vertical_rounded, size: 14, color: Color(0xCCFFFFFF)),
                ],
              ]),
            ),
            if (front)
              Positioned(
                left: 16, right: 14, bottom: 14,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 30, height: 1, fontWeight: FontWeight.w500, letterSpacing: -.4)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: const Color(0x24FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x38FFFFFF), width: .6),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text(data.words.isEmpty ? data.wordsLine : data.words.first.word,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: .4)),
                              const SizedBox(height: 1),
                              Text(_progress(data).isEmpty ? data.partLabel : _progress(data),
                                  maxLines: 1,
                                  style: TextStyle(color: const Color(0xB3FFFFFF), fontSize: 10.5)),
                            ]),
                          ),
                          Flexible(child: _PlayPill(onTap: data.onBegin, ink: world.b)),
                        ]),
                      ),
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

// C2 · Word: the day's word set large ABOVE the head, fully readable.
class _WordCard2 extends StatelessWidget {
  const _WordCard2({required this.look, required this.data, required this.word, required this.parallax});
  final _WordLook look;
  final HeroData data;
  final Word? word;
  final double parallax;
  @override
  Widget build(BuildContext context) {
    final text = (word?.word ?? 'NOWSSB').toUpperCase();
    final hasAudio = word != null && (word!.audio.isNotEmpty || word!.audioMale.isNotEmpty || word!.audioFemale.isNotEmpty);
    const drop = 96.0; // photo sits lower so the word has open air above the head
    return Builder(builder: (context) => GestureDetector(
          onTap: data.onBegin,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(fit: StackFit.expand, children: [
              DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [look.top, look.bottom]))),
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)], stops: [.18, .42]).createShader(r),
                child: Opacity(opacity: .6, child: _plate(look.photo, parallax, k: 18, dy: drop)),
              ),
              Positioned(
                left: 18, right: 18, top: 44,
                child: Transform.translate(
                  offset: Offset(parallax * -40, 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(text,
                        maxLines: 1,
                        style: TextStyle(fontFamily: 'Anton', fontSize: 104, height: 1.0, letterSpacing: 4.5, color: const Color(0xFFFFFBF5))),
                  ),
                ),
              ),
              if (!look.photo.startsWith('hc-e-')) _plate('${look.photo}-fg', parallax, k: 30, dy: drop),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [look.bottom.withValues(alpha: 0), look.bottom.withValues(alpha: .82), look.bottom], stops: const [.42, .66, .9]),
                ),
              ),
              const _Grain(opacity: .08),
              Positioned(
                left: 22, top: 14, right: 16,
                child: Row(children: [
                  Expanded(child: Text("TODAY'S WORD · ${data.partLabel.toUpperCase()}", style: _kick(look.bottom.withValues(alpha: .85)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  _SaveButton(data: data, word: word?.word),
                ]),
              ),
              Positioned(
                left: 22, right: 22, bottom: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (word != null && word!.phonetic.isNotEmpty)
                    Text(word!.phonetic, style: const TextStyle(fontFamily: 'DM Sans', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: .4, height: 1.1)),
                  if (word != null && word!.meaning.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(word!.meaning, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xD9FFFFFF), fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  _GlassChip(
                        key: const ValueKey('hero-hear'),
                        icon: hasAudio ? Icons.graphic_eq_rounded : Icons.schedule_rounded,
                        text: hasAudio ? 'Hear it' : 'Recording soon',
                        dim: !hasAudio,
                        onTap: hasAudio ? () => data.onHear?.call(word!) : null,
                  ),
                  const SizedBox(height: 14),
                  _PlayPill(onTap: data.onBegin, ink: look.bottom, label: 'Begin ${data.title}'),
                ]),
              ),
            ]),
          ),
        ));
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.data, required this.word});
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
                color: const Color(0x2EFFFFFF),
                border: Border.all(color: const Color(0x40FFFFFF), width: .6),
              ),
              child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
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
  Widget build(BuildContext context) => FittedBox(
        key: const ValueKey('hero-ritual'),
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 360,
          child: PaperRitualCard(
            completed: data.done,
            total: data.total,
            sessionCount: data.sessions,
            streak: data.streak,
            time: data.ritualTime,
            title: data.title,
            onBegin: data.onBegin,
          ),
        ),
      );
}
