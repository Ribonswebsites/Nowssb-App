/// The Normal-home hero: one rounded card carousel (auto-rotates, swipe,
/// pauses on touch, no dots) mixing three card designs — Cinema, Depth
/// stack and Word — each with one primary action: begin today's session.
///
/// Visuals (Ribon 11-04): the dot-light portrait style — the client's own
/// clips plus new stills and films in the same look. Every slot is unique.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../media/golden_breath.dart';
import '../../media/nwsb_video.dart';
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

/// A visual is either a film ('film:hero-dusk' → assets/video, muted loop,
/// poster under reduced motion, paused offscreen) or a still in assets/home/dl.
Widget _img(String name, {Alignment align = Alignment.center}) {
  if (name.startsWith('film:')) {
    final clip = name.substring(5);
    return GoldenBreathClip(asset: 'assets/video/$clip.mp4', poster: 'assets/video/$clip-poster.webp', alignment: align, slot: 'calm_hero.$clip');
  }
  return Image.asset('assets/home/dl/$name.webp',
      fit: BoxFit.cover, alignment: align, filterQuality: FilterQuality.high, gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink());
}

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

const _black = Color(0xFF050505);

const _worlds = [
  _World('Breath', 'dl-depth-breath', _black, _black),
  _World('Sound', 'dl-depth-sound', _black, _black),
  _World('Sleep', 'dl-depth-sleep', _black, _black),
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
    final word = w(0);
    final cards = <Widget Function(double off)>[
      (off) => _PreviewBoxCard(
        key: const ValueKey('hero-preview'),
        eyebrow: 'NowssB',
        title: data.title.trim().isEmpty ? 'NowssB' : data.title.trim(),
        image: 'assets/home/dl/preview-session.webp',
        video: 'assets/video/sound-face.mp4',
        ground: _black,
        data: data,
      ),
      (off) => _PreviewBoxCard(
        key: const ValueKey('hero-preview-word'),
        eyebrow: "Today's word",
        title: (word == null || word.word.trim().isEmpty) ? 'Practice' : word.word.trim(),
        image: 'assets/home/dl/preview-word.webp',
        ground: _black,
        data: data,
        saveWord: word?.word,
      ),
      (off) => _PaperRitualSlot(data: data),
      (off) => _DepthCard(data: data, parallax: off),
      (off) => _WordCard2(look: const _WordLook('film:hero-breath', _black, _black), data: data, word: w(0), parallax: off),
      (off) => _CinemaCard(photo: 'film:hero-dusk', kicker: 'Dusk', tone: _black, data: data, word: w(1), parallax: off),
      (off) => _WordCard2(look: const _WordLook('film:hero-sound', _black, _black), data: data, word: w(1), parallax: off),
      (off) => _CinemaCard(photo: 'film:hero-release', kicker: 'Release', tone: _black, data: data, word: w(2), parallax: off),
      (off) => _WordCard2(look: const _WordLook('film:hero-rise', _black, _black), data: data, word: w(2), parallax: off),
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

/// Preview box: the portrait fills the card, whole figure visible (no zoom,
/// no grid). The photo's own backdrop is gone so it sits on [ground].
class _PreviewBoxCard extends StatelessWidget {
  const _PreviewBoxCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.data,
    required this.image,
    required this.ground,
    this.video,
    this.saveWord,
  });
  final String eyebrow;
  final String title;
  final HeroData data;
  final String image;
  final String? video;
  final Color ground;
  final String? saveWord;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: ColoredBox(
          color: ground,
          child: Stack(fit: StackFit.expand, children: [
            if (video != null)
              NwsbVideo(
                asset: video!,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                slot: 'calm_hero.preview',
              )
            else
              Image.asset(
                image,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            // Short scrims so the title and the buttons stay readable.
            // The face in the middle is left alone.
            Positioned(
              top: 0, left: 0, right: 0, height: 132,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ground.withValues(alpha: .62), ground.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0, height: 132,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [ground.withValues(alpha: .72), ground.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w500, height: 1.1)),
                const SizedBox(height: 12),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 40, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.1)),
                const Spacer(),
                const Center(child: Text('Preview app', style: TextStyle(color: Color(0xFFD0D0D4), fontSize: 16, fontWeight: FontWeight.w500))),
                const SizedBox(height: 18),
                Row(children: [
                  _PreviewCircle(icon: Icons.share, onTap: () => _sharePreview(title)),
                  const SizedBox(width: 10),
                  Expanded(child: _PreviewOpen(onTap: data.onBegin)),
                  const SizedBox(width: 10),
                  _PreviewMore(data: data, word: saveWord),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

Future<void> _sharePreview(String title) {
  final text = title.trim().isEmpty ? 'NowssB' : '$title on NowssB';
  return SharePlus.instance.share(ShareParams(text: text, subject: 'NowssB'));
}

class _PreviewCircle extends StatelessWidget {
  const _PreviewCircle({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1C1C1E),
            border: Border.all(color: const Color(0xFF2E2E30)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _PreviewOpen extends StatelessWidget {
  const _PreviewOpen({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const ValueKey('hero-preview-open'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF2E2E30)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text('Open', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _PreviewMore extends StatelessWidget {
  const _PreviewMore({required this.data, required this.word});
  final HeroData data;
  final String? word;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return;
          final origin = box.localToGlobal(Offset.zero);
          final selected = await showMenu<String>(
            context: context,
            color: const Color(0xFF1C1C1E),
            position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + box.size.width, origin.dy + box.size.height),
            items: [
              const PopupMenuItem(value: 'open', child: Text('Open', style: TextStyle(color: Colors.white))),
              if (data.onSave != null)
                PopupMenuItem(
                  value: 'save',
                  child: Text(data.isSaved?.call(word) == true ? 'Saved' : 'Save', style: const TextStyle(color: Colors.white)),
                ),
            ],
          );
          if (selected == 'open') data.onBegin();
          if (selected == 'save') data.onSave?.call(word);
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1C1C1E),
            border: Border.all(color: const Color(0xFF2E2E30)),
          ),
          child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
        ),
      );
}

/// Photo plate. No extra scale — the films are already framed wide, and a
/// zoom made the faces soft.
Widget _plate(String photo, double off, {double k = 28, double dy = 0, Alignment align = Alignment.center}) =>
    Transform.translate(offset: Offset(off * k, dy), child: _img(photo, align: align));

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
class _DepthCardState extends State<_DepthCard> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0B0D);
  static const _spring = SpringDescription(mass: 1, stiffness: 260, damping: 24);
  /// Continuous stack position (0 = world 0 in front); springs between ints.
  late final AnimationController _pos = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  double _drag = 0, _start = 0;
  int get front => _pos.value.round() % _worlds.length;
  HeroData get data => widget.data;
  double get parallax => widget.parallax;

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _settle(double target, double velocity) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pos.value = target;
      return;
    }
    _pos.animateWith(SpringSimulation(_spring, _pos.value, target, velocity));
  }

  void _step(int d) {
    HapticFeedback.selectionClick();
    _settle(_start + d, 0);
  }

  @override
  Widget build(BuildContext context) {
    final n = _worlds.length;
    // back → front, as indexes into _worlds; depth = position from front.
    final raw = _pos.value;
    final p = (raw - raw.round()).abs() < .02 ? raw.roundToDouble() : raw;
    double depth(int i) => (i - p) % n; // 0 = front, fractional while moving
    final order = [for (var i = 0; i < n; i++) i]..sort((a, b) => depth(b).compareTo(depth(a)));
    return GestureDetector(
      key: const ValueKey('hero-depth'),
      onTap: data.onBegin,
      onVerticalDragStart: (_) {
        _pos.stop();
        _drag = 0;
        _start = _pos.value.roundToDouble();
      },
      // The front sheet follows the finger (one practice per 140px)…
      onVerticalDragUpdate: (u) {
        _drag += u.delta.dy;
        _pos.value = _start + (-_drag / 140).clamp(-1.0, 1.0);
      },
      // …then a spring carries it home, keeping the fling's speed.
      onVerticalDragEnd: (e) {
        final v = e.primaryVelocity ?? 0;
        final d = (_drag < -24 || v < -250) ? 1 : (_drag > 24 || v > 250) ? -1 : 0;
        if (d != 0) HapticFeedback.selectionClick();
        _pos.animateWith(SpringSimulation(_spring, _pos.value, _start + d, -v / 140));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [
          // White neumorphic plate behind the photo sheets (Normal home is all white).
          const ColoredBox(color: _black),
          Positioned(
            left: 22, top: 20, right: 20,
            child: Row(children: [
              Expanded(child: Text('PRACTICES · ${data.partLabel.toUpperCase()}', style: _kick(const Color(0xE6FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              _SaveButton(data: data, word: data.words.isEmpty ? null : data.words.first.word),
            ]),
          ),
          // The stack lives in its own inset box; nothing escapes the card.
          Positioned(
            left: 16, right: 16, top: 50, bottom: 16,
            child: LayoutBuilder(builder: (context, c) {
              return Stack(clipBehavior: Clip.hardEdge, alignment: Alignment.bottomCenter, children: [
                for (final i in order) _sheet(c, i, depth(i)),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _sheet(BoxConstraints c, int wi, double dd) {
    final world = _worlds[wi];
    final n = _worlds.length;
    // A sheet leaving the front (dd just under n) lifts away and fades.
    final leaving = dd > n - 1 ? dd - n : 0.0; // -1..0
    final d = leaving < 0 ? 0.0 : dd;
    final front = wi == this.front;
    final h = c.maxHeight - 88;
    final tilt = parallax.clamp(-1.0, 1.0);
    final m = Matrix4.identity()
      ..setEntry(3, 2, .001)
      ..translateByDouble(tilt * d * 10, -d * 44.0 + leaving * 160, 0, 1)
      ..scaleByDouble(1 - d * .06, 1 - d * .06, 1, 1)
      ..rotateY(-tilt * .18 * (1 + d * .4));
    return Positioned(
      left: 0, right: 0, bottom: 0, height: h,
      child: Opacity(opacity: (1 + leaving).clamp(0.0, 1.0), child: Transform(
        alignment: Alignment.bottomCenter,
        transform: m,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [world.a, world.b]))),
            Opacity(opacity: .85, child: _plate(world.photo, -tilt, k: 14, align: world.align)),
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
      )),
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
    const drop = 28.0; // a little lower so the word sits above the head, without cropping the person out
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
                  Expanded(child: Text("TODAY'S WORD · ${data.partLabel.toUpperCase()}", style: _kick(const Color(0xE6FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
