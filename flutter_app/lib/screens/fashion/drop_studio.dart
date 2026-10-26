/// Fashion "Drop Studio" — one full page that replaces two Fashion home
/// sections: "Today's offers" (EnterCurveStage) and "Make this home yours"
/// (FashCustomize). Opened from the Drop Studio card on the Fashion home.
///
/// [DropStudioScreen] wires every hook of [FashionDropStudio] to real logic:
/// the drop → Store tab, words → WordDetail, own → Store Buy Now (cart +
/// checkout + order), doors → the same customize screens and saved state the
/// home's old "Make this home yours" doors opened, bag → Cart.
/// All imagery is EditableImage (admin-editable slots `concept.DropStudio.*`),
/// all copy is EditableLabel, all words come from ContentStore.library.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/template/editable.dart';
import '../../data/cart_bag.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../widgets/concept/stillwater.dart';
import '../../shell/nav_shell.dart';
import '../../shell/nwsb_links.dart';
import '../fashion_plus.dart';
import '../quick_access.dart';
import '../store/store_actions.dart';
import '../store/store_art.dart';
import '../store/store_cards.dart' show kWordPriceInr, localizedMoney;
import '../widgets_page.dart';
import '../word_detail.dart';

/// The real Drop Studio page: every hook wired.
class DropStudioScreen extends StatefulWidget {
  const DropStudioScreen({super.key, this.controller, this.debugTilt, this.debugPage, this.clock});

  final ScrollController? controller;
  final Offset? debugTilt;
  final double? debugPage;

  /// Wall clock for the hourly word rotation; tests inject one.
  final DateTime Function()? clock;

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const DropStudioScreen()));

  /// The bag item the existing Store word path builds for [w], with the
  /// word's own poster cut-out as its picture.
  static BagItem item(Word w) => wordBagItem(
        name: w.word,
        root: w.organ.isNotEmpty ? w.organ : w.meaning,
        img: dropCutoutFor(w),
        price: kWordPriceInr,
      );

  @override
  State<DropStudioScreen> createState() => _DropStudioScreenState();
}

class _DropStudioScreenState extends State<DropStudioScreen> {
  /// Re-entry guard: a double tap on "Own" adds once and opens one checkout.
  bool _busy = false;

  Future<void> _buy(Word w) async {
    if (_busy) return;
    _busy = true;
    try {
      await storeBuyNow(context, DropStudioScreen.item(w));
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    return FashionDropStudio(
      onBack: () => Navigator.of(context).maybePop(),
      onOpenDrop: () => NavScope.goTo(context, 3),
      onOpenWord: (i) {
        final all = ContentStore.instance.library;
        if (i < 0 || i >= all.length) return;
        push(WordDetail(word: all[i]));
      },
      onBuy: _buy,
      onOpenCart: () => NwsbLinks.cart(context),
      onOpenThemes: () => push(const WidgetsPage()),
      onOpenBackground: () => push(const FashionPlusScreen(mode: FashionPlusMode.background)),
      onOpenStartArt: () => push(const FashionPlusScreen(mode: FashionPlusMode.startArt)),
      onOpenAccess: () => push(const QuickAccessScreen()),
      controller: widget.controller,
      debugTilt: widget.debugTilt,
      debugPage: widget.debugPage,
      clock: widget.clock,
    );
  }
}

/// How many words a drop holds.
const kDropSize = 5;

/// This hour's words: [kDropSize] words with a meaning, rotated through the
/// library by the hour index, so every hour shows the next five, the same
/// five on every device, and the whole library comes round in turn.
List<Word> dropWordsFor(List<Word> library, DateTime at) {
  final pool = library.where((w) => w.meaning.isNotEmpty).toList();
  if (pool.length <= kDropSize) return pool;
  // The local wall-clock hour (so it turns when the hourly timer fires, also
  // in half-hour zones like IST), counted from the epoch.
  final hour = DateTime.utc(at.year, at.month, at.day, at.hour).millisecondsSinceEpoch ~/ Duration.millisecondsPerHour;
  final start = (hour * kDropSize) % pool.length;
  return [for (var k = 0; k < kDropSize; k++) pool[(start + k) % pool.length]];
}

/// The cut-out a word wears on its poster (and in the bag): fixed per word.
String dropCutoutFor(Word w) {
  final i = ContentStore.instance.library.indexWhere((x) => x.key == w.key);
  return _wordCutouts[(i < 0 ? w.word.length : i) % _wordCutouts.length];
}

const _slot = 'drop_studio.DropStudio';
const _gold = Color(0xFFC8A96E);
const _goldSoft = Color(0xFFE8D5A3);
const _violet = Color(0xFF7C4DDB);
const _deep = Color(0xFF060C18);

/// Media the page uses — the same files the two replaced sections ship.
class DropStudioAssets {
  static const figureDrop = 'assets/hero-curve/cleopatra.webp';
  static const figureHome = 'assets/hero-curve/pointer.webp';
  static const stillness = 'assets/hero-curve/stillness.webp';
  static const cosmos = 'assets/hero-curve/cosmos.webp';
  static const body = 'assets/hero-curve/body.webp';
  static const player = 'assets/hero-curve/banner-player.webp';
  static const library = 'assets/hero-curve/banner-library.webp';
  static const listen = 'assets/hero-curve/listen.webp';
}

class FashionDropStudio extends StatefulWidget {
  const FashionDropStudio({
    super.key,
    this.onBack,
    this.onOpenDrop,
    this.onOpenWord,
    this.onBuy,
    this.onOpenThemes,
    this.onOpenBackground,
    this.onOpenStartArt,
    this.onOpenAccess,
    this.onOpenCart,
    this.controller,
    this.debugTilt,
    this.debugPage,
    this.clock,
  });

  final DateTime Function()? clock;

  final VoidCallback? onBack;

  /// Hero tap → the featured drop (store / offers tab, `_go(3)`).
  final VoidCallback? onOpenDrop;

  /// A word card → word detail; index into ContentStore.library.
  final void Function(int libraryIndex)? onOpenWord;

  /// "Own this word" → meaning checkout for that word.
  final void Function(Word word)? onBuy;

  final VoidCallback? onOpenThemes; // → WidgetsPage
  final VoidCallback? onOpenBackground; // → FashionPlusScreen (backdrop)
  final VoidCallback? onOpenStartArt; // → FashionPlusScreen (start art)
  final VoidCallback? onOpenAccess; // → QuickAccessScreen
  final VoidCallback? onOpenCart; // top-bar bag → CartPage

  final ScrollController? controller;
  final Offset? debugTilt;
  final double? debugPage;

  @override
  State<FashionDropStudio> createState() => _FashionDropStudioState();
}

class _FashionDropStudioState extends State<FashionDropStudio> {
  late final ScrollController _scroll = widget.controller ?? ScrollController();
  double _y = 0;

  /// The deck's front card. The pinned bar reads the same index, so the
  /// bar's word, price and buy follow the swipe.
  late final ValueNotifier<int> _top = ValueNotifier(widget.debugPage?.round() ?? 0);
  Timer? _hourly;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  /// Wake at the next top of the hour: new words land, the deck restarts.
  void _armHour() {
    _hourly?.cancel();
    final now = _now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    _hourly = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() => _top.value = 0);
      _armHour();
    });
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    _armHour();
  }

  void _onScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final y = _scroll.offset;
    if ((y - _y).abs() > .5) setState(() => _y = y);
  }

  @override
  void dispose() {
    _hourly?.cancel();
    _top.dispose();
    _scroll.removeListener(_onScroll);
    if (widget.controller == null) _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _deep,
      body: Stack(children: [
        const Positioned.fill(child: _LiquidBackdrop()),
        ListenableBuilder(
          listenable: ContentStore.instance,
          builder: (context, _) {
            final all = ContentStore.instance.library;
            // ONE drop list: the deck and the pinned bar both read it.
            final drop = dropWordsFor(all, _now());
            final safe = MediaQuery.paddingOf(context).bottom;
            const dock = 68.0, dockGap = 22.0;
            return Stack(children: [
              ListView(
                controller: _scroll,
                padding: EdgeInsets.only(top: top + 64, bottom: dock + dockGap + safe + 28),
                children: [
                  _DropHero(scroll: _y, onTap: widget.onOpenDrop, debugTilt: widget.debugTilt),
                  const SizedBox(height: 26),
                  _WordsDeck(
                    words: drop,
                    top: _top,
                    onOpen: (w) => widget.onOpenWord?.call(all.indexOf(w)),
                    onBuy: widget.onBuy,
                  ),
                  const SizedBox(height: 34),
                  _HomeAndDoors(
                    scroll: _y - 900,
                    doors: _Doors(
                      onThemes: widget.onOpenThemes,
                      onBackground: widget.onOpenBackground,
                      onStartArt: widget.onOpenStartArt,
                      onAccess: widget.onOpenAccess,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _HowItFlows(),
                ],
              ),
              Positioned(left: 0, right: 0, top: 0, child: _TopBar(onBack: widget.onBack, onCart: widget.onOpenCart, scroll: _y)),
              // content fades out behind the pinned bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: dock + dockGap + safe + 70,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_deep.withValues(alpha: 0), _deep.withValues(alpha: .92), _deep],
                          stops: const [0, .55, 1]),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: dockGap + safe,
                height: dock,
                child: ValueListenableBuilder<int>(
                  valueListenable: _top,
                  builder: (context, top, _) {
                    final w = drop.isEmpty ? null : drop[top.clamp(0, drop.length - 1)];
                    return _BuyDock(
                      word: w,
                      price: w == null ? null : localizedMoney(context, DropStudioScreen.item(w).price),
                      onBuy: w == null ? null : () => widget.onBuy?.call(w),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}

// ─── backdrop: purple liquid under night water ───────────────────────────

class _LiquidBackdrop extends StatelessWidget {
  const _LiquidBackdrop();
  @override
  Widget build(BuildContext context) => Breath(
        builder: (context, t) => CustomPaint(painter: _LiquidPainter(t)),
      );
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = _deep);
    final a = 2 * math.pi * t;
    void blob(Offset o, double r, Color col) => c.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: r)));
    blob(Offset(s.width * (.15 + .06 * math.sin(a)), s.height * .12), s.width * .9, const Color(0x8A5B2BC4));
    blob(Offset(s.width * (.95 - .05 * math.cos(a)), s.height * .32), s.width * .8, const Color(0x669D4EDD));
    blob(Offset(s.width * .3, s.height * (.78 + .02 * math.sin(a))), s.width * .9, const Color(0x553A1C8C));
    blob(Offset(s.width * .8, s.height * .95), s.width * .5, const Color(0x33C8A96E));
  }

  @override
  bool shouldRepaint(_LiquidPainter o) => o.t != t;
}

// ─── chrome ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({this.onBack, this.onCart, required this.scroll});
  final VoidCallback? onBack;
  final VoidCallback? onCart;
  final double scroll;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final k = (scroll / 120).clamp(0.0, 1.0);
    return ClipRect(
        child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18 * k, sigmaY: 18 * k),
            child: Container(
              padding: EdgeInsets.fromLTRB(12, top + 8, 16, 10),
              decoration: BoxDecoration(
                color: Color.lerp(Colors.transparent, const Color(0xD9100A1E), k),
                border: Border(bottom: BorderSide(color: _gold.withValues(alpha: .25 * k))),
              ),
              child: Row(children: [
                _RoundIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
                const SizedBox(width: 12),
                const Expanded(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    EditableLabel(_slot, 'NowssB.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                            height: 1)),
                    SizedBox(height: 3),
                    EditableLabel(_slot, 'DROP STUDIO',
                        style:
                            TextStyle(color: _goldSoft, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.6)),
                  ]),
                ),
                _RoundIcon(icon: Icons.shopping_bag_outlined, onTap: onCart),
              ]),
            )));
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .08),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

// ─── 1 · hero collage: the drop ──────────────────────────────────────────

/// A tilted poster on its own depth plane.
class _Poster extends StatelessWidget {
  const _Poster(
      {required this.asset, required this.id, required this.width, required this.angle, this.aspect = 1100 / 618});
  final String asset;
  final String id;
  final double width;
  final double angle;
  final double aspect;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: width / aspect,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 14))],
            border: Border.all(color: Colors.white, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: EditableImage.asset(asset, slot: _slot, id: id, fit: BoxFit.cover, filterQuality: FilterQuality.high),
        ),
      );
}

/// A poster set in type only — "YOUR CURE" has no image; copy stays editable.
class _TypePoster extends StatelessWidget {
  const _TypePoster({required this.lines, required this.width, required this.angle, this.dark = false});
  final List<String> lines;
  final double width;
  final double angle;
  final bool dark;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: dark ? Colors.black : const Color(0xFFF4EFE6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: dark ? 3 : 0),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20, offset: Offset(0, 12))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            for (final l in lines)
              EditableLabel(_slot, l,
                  style: TextStyle(
                      color: dark ? Colors.white : Colors.black,
                      fontSize: width * .2,
                      fontWeight: FontWeight.w900,
                      height: .92,
                      letterSpacing: -1.2)),
            const SizedBox(height: 6),
            Container(width: 22, height: 3, color: _violet),
          ]),
        ),
      );
}

class _DropHero extends StatelessWidget {
  const _DropHero({required this.scroll, this.onTap, this.debugTilt});
  final double scroll;
  final VoidCallback? onTap;
  final Offset? debugTilt;

  @override
  Widget build(BuildContext context) {
    final p = (scroll * .18).clamp(-80.0, 80.0); // scroll parallax
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Kicker("Today's offers"),
          const SizedBox(height: 8),
          const EditableLabel(_slot, 'A featured drop\nfor this hour',
              style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  fontSize: 40,
                  height: 1,
                  letterSpacing: -.5)),
          const SizedBox(height: 16),
          DepthTilt(
            rotate: .16,
            debugTilt: debugTilt,
            child: Breath(builder: (context, t) {
              return Container(
                height: 470,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withValues(alpha: .07),
                  border: Border.all(color: Colors.white.withValues(alpha: .22)),
                  boxShadow: const [BoxShadow(color: Color(0x80120428), blurRadius: 40, offset: Offset(0, 24))],
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(clipBehavior: Clip.none, children: [
                    // black collage panel
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(.1, .2),
                            radius: 1.1,
                            colors: [const Color(0xFF1B1030), Colors.black.withValues(alpha: 1)],
                          ),
                        ),
                      ),
                    ),
                    // gold ripple rings breathing behind the figure
                    Positioned.fill(child: CustomPaint(painter: _RingsPainter(t))),
                    // far plane
                    Positioned(
                      left: -18,
                      top: 26 - p * .3,
                      child: Plane(
                          depth: .3,
                          phase: t,
                          drift: 3,
                          child: const _Poster(
                              asset: DropStudioAssets.stillness, id: 'hero.stillness', width: 200, angle: -.14)),
                    ),
                    Positioned(
                      right: -26,
                      top: 70 - p * .45,
                      child: Plane(
                          depth: .45,
                          phase: t + .3,
                          drift: 4,
                          child:
                              const _Poster(asset: DropStudioAssets.cosmos, id: 'hero.cosmos', width: 190, angle: .12)),
                    ),
                    // mid plane
                    Positioned(
                      left: 6,
                      bottom: 70 - p * .2,
                      child: Plane(
                          depth: .6,
                          phase: t + .55,
                          drift: 5,
                          child: const _TypePoster(lines: ['YOUR', 'CURE'], width: 116, angle: -.08)),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 28 - p * .25,
                      child: Plane(
                          depth: .7,
                          phase: t + .8,
                          drift: 5,
                          child: const _Poster(asset: DropStudioAssets.body, id: 'hero.body', width: 170, angle: .09)),
                    ),
                    // near plane: cut-out figure
                    Positioned(
                      left: 40,
                      right: 30,
                      top: 30 + p * .15,
                      bottom: -6,
                      child: Plane(
                        depth: 1,
                        phase: t,
                        drift: 2,
                        child: const EditableImage.asset(DropStudioAssets.figureDrop,
                            slot: _slot,
                            id: 'hero.figure',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.high),
                      ),
                    ),
                    // label chip
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _Chip(text: 'DROP · ${_hourLabel()}'),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold),
                        child: const Icon(Icons.north_east_rounded, color: Color(0xFF14100A), size: 20),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const EditableLabel(_slot, 'Swipe for the words and what they mean.',
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13.5, height: 1.35)),
        ]),
      ),
    );
  }

  static String _hourLabel() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'MORNING'
        : h < 17
            ? 'AFTERNOON'
            : h < 21
                ? 'EVENING'
                : 'NIGHT';
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width * .5, s.height * .42);
    final l = Stillwater.lungs(t);
    for (var i = 0; i < 4; i++) {
      final r = 70.0 + i * 46 + l * 14;
      c.drawCircle(
          o,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = _gold.withValues(alpha: (.34 - i * .07).clamp(0, 1)));
    }
    c.drawCircle(
        o,
        120 + l * 20,
        Paint()
          ..shader = RadialGradient(colors: [_violet.withValues(alpha: .45), _violet.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: 140 + l * 20)));
  }

  @override
  bool shouldRepaint(_RingsPainter o) => o.t != t;
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 18, height: 1.5, color: _gold),
        const SizedBox(width: 8),
        EditableLabel(_slot, text.toUpperCase(),
            style: const TextStyle(color: _goldSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
      ]);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: .55),
          border: Border.all(color: _gold.withValues(alpha: .6)),
        ),
        child: EditableLabel('drop_studio.Chip', text,
            style: const TextStyle(color: _goldSoft, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
      );
}

// ─── 2 · words deck: tilted posters, swipe the top one away ──────────────

/// Cut-outs (alpha) the word posters layer over their giant type.
const _wordCutouts = [
  'assets/hero-curve/subject.webp',
  'assets/hero-curve/cleopatra.webp',
  'assets/hero-curve/tab-subject.webp',
  'assets/hero-curve/pointer.webp',
];

class _WordsDeck extends StatefulWidget {
  const _WordsDeck({required this.words, required this.top, required this.onOpen, this.onBuy});
  final List<Word> words;
  final ValueNotifier<int> top;
  final ValueChanged<Word> onOpen;
  final ValueChanged<Word>? onBuy;
  @override
  State<_WordsDeck> createState() => _WordsDeckState();
}

class _WordsDeckState extends State<_WordsDeck> {
  double _dx = 0;

  /// The front card, always inside the deck (never "06 / 05").
  int get _top {
    final n = widget.words.length;
    return n == 0 ? 0 : widget.top.value.clamp(0, n - 1);
  }

  set _top(int v) => widget.top.value = v;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.top.addListener(_changed);
  }

  @override
  void didUpdateWidget(_WordsDeck old) {
    super.didUpdateWidget(old);
    if (old.top != widget.top) {
      old.top.removeListener(_changed);
      widget.top.addListener(_changed);
    }
    // The drop shrank under the front card: clamp the shared index (after
    // this frame, so the bar listening to it isn't rebuilt mid-build).
    final n = widget.words.length;
    if (widget.top.value != 0 && widget.top.value >= n) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.top.value >= widget.words.length) widget.top.value = math.max(0, widget.words.length - 1);
      });
    }
  }

  @override
  void dispose() {
    widget.top.removeListener(_changed);
    super.dispose();
  }

  void _end(DragEndDetails d) {
    final n = widget.words.length;
    final v = d.primaryVelocity ?? 0;
    setState(() {
      if (_dx.abs() > 70 || v.abs() > 600) {
        HapticFeedback.selectionClick();
        _top = (_dx + v * .1) < 0 ? (_top + 1) % n : (_top - 1 + n) % n;
      }
      _dx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final n = words.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _Kicker('This hour’s words'),
          const Spacer(),
          if (n > 0)
            Text('${(_top + 1).toString().padLeft(2, '0')} / ${n.toString().padLeft(2, '0')}',
                style:
                    const TextStyle(color: _goldSoft, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
        ]),
        const SizedBox(height: 4),
        const EditableLabel(_slot, 'Swipe the deck. Own one.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
        const SizedBox(height: 10),
        if (n == 0)
          const _EmptyPoster()
        else
          GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
            onHorizontalDragEnd: _end,
            child: SizedBox(
              height: 480,
              child: LayoutBuilder(builder: (context, c) {
                final w = math.min(c.maxWidth - 40, 310.0);
                final behind = math.min(n - 1, 3);
                return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  for (var r = behind; r >= 0; r--)
                    Builder(builder: (context) {
                      final i = (_top + r) % n;
                      final side = r.isOdd ? 1.0 : -1.0;
                      final x = r == 0 ? _dx : side * (14.0 + r * 12);
                      final a = r == 0 ? _dx / 900 : side * (.05 + r * .035);
                      return AnimatedContainer(
                        key: ValueKey(i),
                        duration: Duration(milliseconds: _dx == 0 ? 320 : 0),
                        curve: Curves.easeOutBack,
                        transformAlignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(x, r * -10.0, 0, 1)
                          ..rotateZ(a)
                          ..scaleByDouble(1 - r * .045, 1 - r * .045, 1, 1),
                        child: _WordPoster(
                          word: words[i],
                          n: i + 1,
                          of: n,
                          width: w,
                          cutout: dropCutoutFor(words[i]),
                          front: r == 0,
                          onOpen: r == 0 ? () => widget.onOpen(words[i]) : null,
                          onBuy: r == 0 ? () => widget.onBuy?.call(words[i]) : null,
                        ),
                      );
                    }),
                ]);
              }),
            ),
          ),
      ]),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker(this.text, {this.angle = 0, this.bg = _gold, this.fg = const Color(0xFF14100A), this.size = 11});
  final String text;
  final double angle;
  final Color bg;
  final Color fg;
  final double size;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(1, 3))],
          ),
          child: EditableLabel('drop_studio.Sticker', text,
              style: TextStyle(color: fg, fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1.2, height: 1)),
        ),
      );
}

class _WordPoster extends StatelessWidget {
  const _WordPoster(
      {required this.word,
      required this.n,
      required this.of,
      required this.width,
      required this.cutout,
      this.front = true,
      this.onOpen,
      this.onBuy});
  final bool front;
  final Word word;
  final int n;
  final int of;
  final double width;
  final String cutout;
  final VoidCallback? onOpen;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final light = n.isOdd;
    final paper = light ? const Color(0xFFF1E8D6) : const Color(0xFF16102A);
    final ink = light ? const Color(0xFF14100A) : _goldSoft;
    final big = word.word.toUpperCase();
    final k = big.length <= 4 ? big.length : (big.length / 2).ceil();
    final l1 = big.substring(0, k);
    final l2 = big.substring(k);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: width,
        height: width * 1.36,
        decoration: BoxDecoration(
          color: paper,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0xCC000000), blurRadius: 30, offset: Offset(0, 18))],
        ),
        // each card clips its own type to its own bounds; paper is opaque
        child: ClipRRect(
          child: Stack(clipBehavior: Clip.hardEdge, children: [
            if (!light)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                        center: const Alignment(.6, -.3),
                        radius: 1,
                        colors: [_violet.withValues(alpha: .8), _violet.withValues(alpha: 0)]),
                  ),
                ),
              ),
            // giant type: two solid lines, cropped only at the right edge; line 2
            // sits above the figure. Back cards hide it so no letters peek out.
            if (front) ...[
              Positioned(
                left: 10,
                top: 30,
                child: Text(l1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 132,
                        height: .8,
                        letterSpacing: -3)),
              ),
            ],
            // cut-out photo layered over the type
            Positioned(
              right: -44,
              bottom: 0,
              width: width * .72,
              height: width * 1.0,
              child: EditableImage.asset(cutout,
                  slot: _slot,
                  id: 'word.$n.cutout',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  filterQuality: FilterQuality.high),
            ),
            if (front) ...[
              Positioned(
                left: 10,
                top: 134,
                child: Text(l2,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 132,
                        height: .8,
                        letterSpacing: -3,
                        shadows: [
                          for (final o in const [Offset(3, 0), Offset(-3, 0), Offset(0, 3), Offset(0, -3)])
                            Shadow(color: paper, offset: o),
                        ])),
              ),
            ],
            Positioned(
                left: 12,
                top: 10,
                child: _Sticker('${n.toString().padLeft(2, '0')} / ${of.toString().padLeft(2, '0')}', angle: -.06)),
            if (word.organ.isNotEmpty)
              Positioned(
                  right: 12,
                  top: 12,
                  child: _Sticker(word.organ.toUpperCase(),
                      angle: .08, bg: Colors.white, fg: const Color(0xFF14100A), size: 10)),
            if (word.deva.isNotEmpty)
              Positioned(
                left: 14,
                top: 252,
                child: _Sticker(word.deva, angle: -.04, bg: _violet, fg: Colors.white, size: 15),
              ),
            Positioned(
              left: 12,
              bottom: 66,
              width: width * .55,
              child: Transform.rotate(
                angle: -.03,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                  color: Colors.black.withValues(alpha: .82),
                  child: Text(word.meaning,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 14,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBuy?.call();
                },
                child: Transform.rotate(
                  angle: .03,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: const EditableLabel('drop_studio.WordPoster', 'Own this word',
                        style: TextStyle(color: Color(0xFF14100A), fontSize: 13, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── 3 · "Make this home yours" collage ──────────────────────────────────

/// Collage + doors share one Stack so the cut-out figure can step down
/// over the doors (it ignores taps, the doors stay tappable).
class _HomeAndDoors extends StatelessWidget {
  const _HomeAndDoors({required this.scroll, required this.doors});
  final double scroll;
  final Widget doors;
  static const double _figTop = -32;
  @override
  Widget build(BuildContext context) {
    final p = (scroll * .15).clamp(-60.0, 60.0);
    return Breath(builder: (context, t) {
      return Stack(clipBehavior: Clip.none, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Kicker('Make this home yours'),
              const SizedBox(height: 8),
              const EditableLabel(_slot, 'Four doors.\nOne tap.',
                  style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      fontSize: 40,
                      height: 1)),
              const SizedBox(height: 6),
              const EditableLabel(_slot, 'Themes · Background\nStart art · Access',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.3)),
              SizedBox(
                height: 230,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: 0,
                    top: 20 - p * .4,
                    child: Plane(
                        depth: .4,
                        phase: t,
                        drift: 4,
                        child:
                            const _Poster(asset: DropStudioAssets.player, id: 'home.player', width: 170, angle: -.12)),
                  ),
                  Positioned(
                    right: 0,
                    top: 90 - p * .6,
                    child: Plane(
                        depth: .6,
                        phase: t + .4,
                        drift: 5,
                        child: const _Poster(
                            asset: DropStudioAssets.stillness, id: 'home.stillness', width: 190, angle: .1)),
                  ),
                  // the figure steps out of the collage and stands BEHIND the
                  // doors: she lives in the collage layer, which paints before
                  // the doors, so door 2's arch crops her lower body.
                  Positioned(
                    left: 154,
                    right: -30,
                    top: _figTop,
                    height: 330,
                    child: IgnorePointer(
                      child: Plane(
                        depth: 1,
                        phase: t,
                        drift: 2,
                        // soft feather on the last strip so the sliver that
                        // peeks past door 2's edge never shows a straight cut
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (r) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [.8, 1],
                            colors: [Colors.white, Colors.transparent],
                          ).createShader(r),
                          child: const EditableImage.asset(DropStudioAssets.figureHome,
                              slot: _slot,
                              id: 'home.figure',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              filterQuality: FilterQuality.high),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          doors,
        ]),
      ]);
    });
  }
}

// ─── 4 · the four doors: arched collage doors ────────────────────────────

class _Doors extends StatelessWidget {
  const _Doors({this.onThemes, this.onBackground, this.onStartArt, this.onAccess});
  final VoidCallback? onThemes;
  final VoidCallback? onBackground;
  final VoidCallback? onStartArt;
  final VoidCallback? onAccess;

  @override
  Widget build(BuildContext context) {
    Widget door(int i, String title, String sub, String asset, VoidCallback? cb, double tilt) => Expanded(
          child: _Door(n: i, title: title, sub: sub, asset: asset, onTap: cb, tilt: tilt),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Breath(
        builder: (context, t) => Column(children: [
          Row(children: [
            door(1, 'Themes', 'Black Edition', DropStudioAssets.library, onThemes, -.02 + .01 * Stillwater.lungs(t)),
            door(2, 'Background', 'Fashion backdrop', DropStudioAssets.cosmos, onBackground,
                .02 - .01 * Stillwater.lungs(t)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            door(3, 'Start art', 'Behind the start', DropStudioAssets.body, onStartArt, .015),
            door(4, 'Access', 'Bottom nav bar', DropStudioAssets.listen, onAccess, -.015),
          ]),
        ]),
      ),
    );
  }
}

class _Door extends StatefulWidget {
  const _Door(
      {required this.n, required this.title, required this.sub, required this.asset, this.onTap, this.tilt = 0});
  final int n;
  final String title;
  final String sub;
  final String asset;
  final VoidCallback? onTap;
  final double tilt;
  @override
  State<_Door> createState() => _DoorState();
}

class _DoorState extends State<_Door> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _down = true);
      },
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .95 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: widget.tilt,
          child: Container(
            margin: const EdgeInsets.all(5),
            height: 210,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(90), bottom: Radius.circular(18)),
              border: Border.all(color: _gold.withValues(alpha: .7), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 22, offset: Offset(0, 12))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(89), bottom: Radius.circular(17)),
              child: Stack(fit: StackFit.expand, children: [
                EditableImage.asset(widget.asset,
                    slot: _slot,
                    id: 'door.${widget.n}',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.25, 1],
                      colors: [Color(0x22060C18), Color(0xF2060C18)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 62,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _goldSoft)),
                      child: Text('${widget.n}',
                          style: const TextStyle(
                              fontFamily: 'CormorantGaramond',
                              color: _goldSoft,
                              fontSize: 16,
                              fontStyle: FontStyle.italic)),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    EditableLabel(_slot, widget.title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Expanded(
                        child: EditableLabel(_slot, widget.sub,
                            style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 11.5)),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: _goldSoft, size: 16),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5 · how the drop flows: three torn tiles + buy dock ─────────────────

class _TornClipper extends CustomClipper<Path> {
  const _TornClipper(this.seed);
  final int seed;
  @override
  Path getClip(Size s) {
    final r = math.Random(seed);
    final p = Path()..moveTo(0, 0);
    for (var x = 0.0; x < s.width; x += 14) {
      p.lineTo(x, r.nextDouble() * 6);
    }
    p.lineTo(s.width, 0);
    for (var y = 0.0; y < s.height; y += 16) {
      p.lineTo(s.width - r.nextDouble() * 5, y);
    }
    p.lineTo(s.width, s.height);
    for (var x = s.width; x > 0; x -= 12) {
      p.lineTo(x, s.height - r.nextDouble() * 9);
    }
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_TornClipper o) => o.seed != seed;
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({required this.word, required this.sub, required this.asset, required this.id, required this.seed});
  final String word;
  final String sub;
  final String asset;
  final String id;
  final int seed;
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _TornClipper(seed),
        child: Container(
          width: 210,
          height: 190,
          color: const Color(0xFFF1E8D6),
          padding: const EdgeInsets.all(6),
          child: Stack(fit: StackFit.expand, children: [
            EditableImage.asset(asset, slot: _slot, id: id, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)]),
              ),
            ),
            Positioned(
              left: -8,
              bottom: 14,
              child: EditableLabel(_slot, word,
                  style: const TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 92,
                      height: .8,
                      letterSpacing: -4)),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _Sticker(sub, angle: .05, size: 9.5),
            ),
          ]),
        ),
      );
}

class _HowItFlows extends StatelessWidget {
  const _HowItFlows();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Kicker('How the drop flows'),
        const SizedBox(height: 10),
        SizedBox(
          height: 470,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              top: 0,
              child: Transform.rotate(
                angle: -.09,
                child: const _FlowTile(
                    word: 'PICK', sub: 'A WORD THIS HOUR', asset: DropStudioAssets.cosmos, id: 'flow.pick', seed: 3),
              ),
            ),
            Positioned(
              right: 0,
              top: 140,
              child: Transform.rotate(
                angle: .07,
                child: const _FlowTile(
                    word: 'HEAR', sub: 'ITS SOUND', asset: DropStudioAssets.listen, id: 'flow.hear', seed: 7),
              ),
            ),
            Positioned(
              left: 20,
              top: 280,
              child: Transform.rotate(
                angle: -.04,
                child: const _FlowTile(
                    word: 'OWN', sub: 'KEEP IT', asset: DropStudioAssets.library, id: 'flow.own', seed: 11),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _BuyDock extends StatelessWidget {
  const _BuyDock({this.word, this.price, this.onBuy});
  final Word? word;
  final String? price;
  final VoidCallback? onBuy;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: const Color(0xE6100A1E),
          border: Border.all(color: _gold.withValues(alpha: .5)),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const EditableLabel('drop_studio.BuyDock', "THIS HOUR'S DROP",
                  style: TextStyle(color: _goldSoft, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(word?.word ?? '—',
                    key: const ValueKey('drop-dock-word'),
                    style:
                        const TextStyle(fontFamily: 'CormorantGaramond', color: Colors.white, fontSize: 22, height: 1.1)),
                if (price != null) ...[
                  const SizedBox(width: 8),
                  Text(price!,
                      key: const ValueKey('drop-dock-price'),
                      style: const TextStyle(color: _goldSoft, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ]),
            ]),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onBuy?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(30)),
              child: const Row(children: [
                EditableLabel('drop_studio.BuyDock', 'Own the drop',
                    style: TextStyle(color: Color(0xFF14100A), fontSize: 14, fontWeight: FontWeight.w800)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Color(0xFF14100A), size: 18),
              ]),
            ),
          ),
        ]),
      );
}

// ─── Fashion home entry ───────────────────────────────────────────────────

/// The one Fashion-home card that opens Drop Studio, where "Make this home
/// yours" used to be: a small cut of the Drop hero — tilted posters behind
/// the cut-out figure, the gold drop chip, and this hour's word in giant
/// cropped type.
class DropStudioEntry extends StatelessWidget {
  const DropStudioEntry({super.key, this.onTap, this.clock});
  final VoidCallback? onTap;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Semantics(
        button: true,
        label: 'Open Drop Studio',
        child: GestureDetector(
          key: const ValueKey('drop-studio-entry'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap ?? () => DropStudioScreen.open(context),
          child: Container(
            height: 214,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _gold.withValues(alpha: .45)),
              gradient: const RadialGradient(
                center: Alignment(.3, .1),
                radius: 1.1,
                colors: [Color(0xFF2A1450), Colors.black],
              ),
              boxShadow: const [BoxShadow(color: Color(0x80120428), blurRadius: 30, offset: Offset(0, 16))],
            ),
            child: ListenableBuilder(
              listenable: ContentStore.instance,
              builder: (context, _) {
                final word = dropWordsFor(ContentStore.instance.library, (clock ?? DateTime.now)()).firstOrNull;
                return Stack(clipBehavior: Clip.hardEdge, children: [
                  Positioned.fill(child: CustomPaint(painter: _RingsPainter(.42))),
                  // posters, far to near
                  const Positioned(
                    left: -22,
                    top: 34,
                    child: _Poster(asset: DropStudioAssets.stillness, id: 'entry.stillness', width: 150, angle: -.14),
                  ),
                  const Positioned(
                    right: -30,
                    top: 18,
                    child: _Poster(asset: DropStudioAssets.cosmos, id: 'entry.cosmos', width: 150, angle: .12),
                  ),
                  const Positioned(
                    left: 96,
                    bottom: 18,
                    child: _Poster(asset: DropStudioAssets.body, id: 'entry.body', width: 112, angle: .07),
                  ),
                  // the word, giant and cropped by the card
                  if (word != null)
                    Positioned(
                      left: -6,
                      bottom: -26,
                      child: Text(word.word.toUpperCase(),
                          key: const ValueKey('drop-studio-entry-word'),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: .94),
                              fontSize: 112,
                              height: .8,
                              letterSpacing: -3,
                              shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 18)])),
                    ),
                  // cut-out figure in front of everything
                  const Positioned(
                    right: 6,
                    top: 14,
                    bottom: -4,
                    width: 168,
                    child: EditableImage.asset(DropStudioAssets.figureDrop,
                        slot: _slot,
                        id: 'entry.figure',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high),
                  ),
                  Positioned(left: 14, top: 14, child: _Chip(text: 'DROP STUDIO · ${_DropHero._hourLabel()}')),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold),
                      child: const Icon(Icons.north_east_rounded, color: Color(0xFF14100A), size: 19),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Stands in for the deck when the library has no words with a meaning yet.
class _EmptyPoster extends StatelessWidget {
  const _EmptyPoster();
  @override
  Widget build(BuildContext context) => Center(
        child: Transform.rotate(
          angle: -.03,
          child: Container(
            key: const ValueKey('drop-empty-poster'),
            width: 260,
            height: 200,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1E8D6),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Color(0xCC000000), blurRadius: 30, offset: Offset(0, 18))],
            ),
            child: const EditableLabel(_slot, 'Words land\non the hour',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF14100A),
                    fontSize: 38,
                    height: .95)),
          ),
        ),
      );
}
