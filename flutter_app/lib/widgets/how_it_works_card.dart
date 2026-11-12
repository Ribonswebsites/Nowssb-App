/// Step-by-step "How it works" pop-up.
///
/// Reuses the visual language of the old normal-home Zen Plus reel card
/// (black card, five-person zp-* reel, vignette, viewfinder brackets,
/// thumbnail rail, glass panel, gold CTA with the glint sweep) but the
/// copy is how practice actually works, and each step can open the real
/// place. It is a pop-up, not a home card. Home switching stays in Settings.
///
/// Motion is only what that card already had: 5 s auto-cycle, pause on
/// touch, resume 5 s after lift, 600 ms easeInOutCubic, fades, the glint
/// sweep. No mesh callouts, no pulse meter, no ticker, no Fashion wording.
/// Under reduced motion the reel shows posters and holds still.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/home_widget_sync.dart';
import '../data/models.dart';
import '../features/progress/today_progress_screen.dart';
import '../media/nwsb_video.dart';
import '../screens/practice_player.dart';
import '../screens/word_detail.dart';
import '../shell/nav_shell.dart';
import 'concept/normal/surface.dart';
import 'glass_wrap.dart';

const _gold = Color(0xFFE0B04C);
const _ink = Color(0xFF050505);

class _Person {
  const _Person(this.key);
  final String key;
  String get clip => 'assets/video/zp-$key.mp4';
  String get poster => 'assets/video/zp-$key-poster.webp';
  String get thumb => 'assets/home/hx/zpt-$key.webp';
}

const _people = [
  _Person('man-black'),
  _Person('woman-indian'),
  _Person('man-asian'),
  _Person('woman-silver'),
  _Person('man-latino'),
];

/// One step in the How it works pop-up.
class HowItWorksStep {
  const HowItWorksStep({
    required this.title,
    required this.body,
    required this.cta,
    required this.go,
  });

  final String title;
  final String body;
  final String cta;
  final void Function(BuildContext context) go;
}

Word? howItWorksTodayWord() =>
    HomeWidgetSync.wordFor(DateTime.now(), ContentStore.instance.library);

void _goTodayWord(BuildContext context) {
  final w = howItWorksTodayWord();
  if (w == null) {
    NavScope.goTo(context, 1);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => WordDetail(word: w)),
  );
}

void _goPlayer(BuildContext context) {
  final today = howItWorksTodayWord();
  final words = today != null
      ? <Word>[today]
      : ContentStore.instance.library.take(8).toList();
  if (words.isEmpty) {
    NavScope.goTo(context, 1);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PracticePlayerScreen(
        words: words,
        title: "Today's word",
        showIntro: false,
      ),
    ),
  );
}

void _goProgress(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const TodayProgressScreen()),
  );
}

/// The five steps, in reel order. Copy is short and practical.
final List<HowItWorksStep> kHowItWorksSteps = [
  const HowItWorksStep(
    title: 'A NowssB word',
    body:
        'A NowssB word is a sound, written in Devanagari, split into three to five parts. The roman spelling is just something to hold on to. The recording is what it actually sounds like.',
    cta: "See today's word",
    go: _goTodayWord,
  ),
  const HowItWorksStep(
    title: 'Parts and hold times',
    body:
        'Each part has how long to hold it and how to say it. That is on the word page, with the meaning, the organ it benefits, the mouth position and a common mistake.',
    cta: 'Open the word page',
    go: _goTodayWord,
  ),
  const HowItWorksStep(
    title: 'Hear it',
    body:
        'In the player, tap Play in the middle to hear the recording. Use the arrows to change word. Tap Replay to hear it again.',
    cta: 'Open the player',
    go: _goPlayer,
  ),
  const HowItWorksStep(
    title: 'Say it and get a score',
    body:
        'Tap Practice and say each part as it lights up. The player records you and gives a pronunciation score.',
    cta: 'Open the player',
    go: _goPlayer,
  ),
  const HowItWorksStep(
    title: 'Streak and level',
    body:
        'A finished session counts toward your streak, minutes and level. Today\'s three tasks: sit with one word, open the player, and read one meaning.',
    cta: "Today's progress",
    go: _goProgress,
  ),
];

/// Opens the How it works pop-up. [startAt] is the first step (0..4).
void showHowItWorks(BuildContext context, {int startAt = 0}) {
  showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Close How it works',
    barrierColor: const Color(0xCC000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => HowItWorksDialog(startAt: startAt),
    transitionBuilder: (ctx, a, sa, child) {
      final t = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(t),
          child: child,
        ),
      );
    },
  );
}

class HowItWorksDialog extends StatelessWidget {
  const HowItWorksDialog({super.key, this.startAt = 0});

  final int startAt;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Align(
            alignment: Alignment.center,
            child: HowItWorksCard(
              startAt: startAt,
              onClose: () =>
                  Navigator.of(context, rootNavigator: true).maybePop(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card itself, used in the dialog and in tests / shots.
class HowItWorksCard extends StatefulWidget {
  const HowItWorksCard({
    super.key,
    this.startAt = 0,
    this.autoRotate = true,
    this.onClose,
    this.onCta,
  });

  final int startAt;
  final bool autoRotate;
  final VoidCallback? onClose;

  /// If set, called instead of the step's real destination (tests).
  final void Function(HowItWorksStep step)? onCta;

  /// Renders only: paint this image instead of the clip (its poster by default).
  static ImageProvider Function(String clip)? debugFrame;

  @override
  State<HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<HowItWorksCard>
    with TickerProviderStateMixin {
  static const _every = Duration(seconds: 5);
  static const _glide = Duration(milliseconds: 600);
  static const _base = 1000;

  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: _every);
  late final PageController _page =
      PageController(initialPage: _base * _people.length + widget.startAt);
  late int _ix = _base * _people.length + widget.startAt;
  bool _touching = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  bool get _still =>
      _reduced || !widget.autoRotate || NormalLoop.debugT != null;
  int get _who => _ix % _people.length;
  HowItWorksStep get _step => kHowItWorksSteps[_who];

  @override
  void initState() {
    super.initState();
    _clock.addStatusListener((s) {
      if (s == AnimationStatus.completed &&
          mounted &&
          _page.hasClients &&
          !_touching) {
        _page.animateToPage(_ix + 1,
            duration: _glide, curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _loop.stop();
      _clock.stop();
      _loop.value = NormalLoop.debugT ?? .35;
      _clock.value = NormalLoop.debugT ?? .35;
    } else if (!_touching) {
      if (!_loop.isAnimating) _loop.repeat();
      if (!_clock.isAnimating) {
        _clock.forward(from: _clock.value >= 1 ? 0 : _clock.value);
      }
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _clock.dispose();
    _page.dispose();
    super.dispose();
  }

  void _hold() {
    _touching = true;
    _clock.stop();
  }

  void _release() {
    _touching = false;
    if (!_still) _clock.forward(from: 0);
  }

  void _goto(int who) {
    final cur = _who;
    if (who == cur) return;
    _page.animateToPage(_ix + (who - cur),
        duration: _glide, curve: Curves.easeInOutCubic);
  }

  void _runCta() {
    final step = _step;
    if (widget.onCta != null) {
      widget.onCta!(step);
      return;
    }
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = nav.context;
      if (ctx.mounted) step.go(ctx);
    });
  }

  Widget _video(_Person p) {
    final dbg = HowItWorksCard.debugFrame;
    if (dbg != null) {
      return Image(
        image: dbg(p.clip),
        fit: BoxFit.cover,
        alignment: const Alignment(0, -.25),
        gaplessPlayback: true,
      );
    }
    if (_reduced) {
      return Image.asset(
        p.poster,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -.25),
        gaplessPlayback: true,
      );
    }
    return NwsbVideo(
      asset: p.clip,
      poster: p.poster,
      alignment: const Alignment(0, -.25),
    );
  }

  Widget _tag(String a, String b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x66E0B04C), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(a,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Colors.white)),
          const SizedBox(width: 7),
          Text(b,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: _gold)),
        ]),
      );

  Widget _thumbs() => Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < _people.length; i++)
          GestureDetector(
            key: ValueKey('how-thumb-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _goto(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 7),
              width: 34,
              height: i == _who ? 46 : 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: i == _who ? _gold : const Color(0x33FFFFFF),
                    width: i == _who ? 1.6 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Opacity(
                  opacity: i == _who ? 1 : .55,
                  child: Image.asset(_people[i].thumb,
                      fit: BoxFit.cover, alignment: const Alignment(.1, -.1)),
                ),
              ),
            ),
          ),
      ]);

  Widget _indicator(double clock) => Row(children: [
        for (var i = 0; i < _people.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            flex: i == _who ? 3 : 1,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.centerLeft,
              child: i == _who
                  ? FractionallySizedBox(
                      widthFactor: clock.clamp(0.0, 1.0),
                      child: Container(
                          decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(2))))
                  : null,
            ),
          ),
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final step = _step;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _clock]),
        builder: (context, _) {
          final t = _loop.value;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(8, 10),
                    blurRadius: 22),
                BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 8),
                    blurRadius: 24),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('how-it-works-well'),
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      key: const ValueKey('how-it-works-reel'),
                      children: [
                        Listener(
                          onPointerDown: (_) => _hold(),
                          onPointerUp: (_) => _release(),
                          onPointerCancel: (_) => _release(),
                          child: PageView.builder(
                            controller: _page,
                            onPageChanged: (i) {
                              setState(() => _ix = i);
                              if (!_touching && !_still) {
                                _clock.forward(from: 0);
                              }
                            },
                            itemBuilder: (_, i) => ColoredBox(
                              color: Colors.black,
                              child: _video(_people[i % _people.length]),
                            ),
                          ),
                        ),
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0, .22, .6, 1],
                                colors: [
                                  Color(0xB3000000),
                                  Color(0x00000000),
                                  Color(0x00000000),
                                  Color(0xF2050505)
                                ],
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-2 + 4 * t, -1),
                                end: Alignment(-1 + 4 * t, 1),
                                colors: const [
                                  Color(0x00FFFFFF),
                                  Color(0x18FFFFFF),
                                  Color(0x00FFFFFF)
                                ],
                              ),
                            ),
                          ),
                        ),
                        const IgnorePointer(
                            child: CustomPaint(painter: _BracketPainter())),
                        Positioned(
                          left: 14,
                          right: 14,
                          top: 14,
                          child: Row(children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _tag('HOW IT WORKS', '0${_who + 1}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                  color: const Color(0xB3000000),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: const Color(0x33FFFFFF))),
                              child: Text(
                                '0${_who + 1} / 0${_people.length}',
                                style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Colors.white),
                              ),
                            ),
                            if (widget.onClose != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                key: const ValueKey('how-it-works-close'),
                                onTap: widget.onClose,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xB3000000),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0x33FFFFFF)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ]),
                        ),
                        Positioned(left: 14, top: 64, child: _thumbs()),
                        Positioned(
                          left: 60,
                          right: 16,
                          bottom: 14,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            transitionBuilder: (c, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(
                                        begin: const Offset(0, .35),
                                        end: Offset.zero)
                                    .animate(a),
                                child: c,
                              ),
                            ),
                            child: Column(
                              key: ValueKey('how-title-$_who'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'How it works',
                                  style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xCCFFFFFF),
                                      height: 1.1),
                                ),
                                Text(
                                  step.title,
                                  style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.08,
                                      letterSpacing: -.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassWrap(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Text(
                            step.body,
                            key: ValueKey('how-body-$_who'),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xE6FFFFFF),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _indicator(_clock.value),
                        const SizedBox(height: 14),
                        GestureDetector(
                          key: const ValueKey('how-it-works-cta'),
                          onTap: _runCta,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Stack(children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                color: Colors.white,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        step.cta,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 17, color: Colors.black),
                                  ],
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(-2 + 4 * t, -1),
                                        end: Alignment(-1 + 4 * t, 1),
                                        colors: const [
                                          Color(0x00FFFFFF),
                                          Color(0x66FFFFFF),
                                          Color(0x00FFFFFF)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Four gold corner brackets, like a viewfinder.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x99E0B04C)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const m = 12.0, l = 16.0, top = 58.0;
    final r = Rect.fromLTRB(m + 50, top, s.width - m, s.height - 16);
    for (final c in [
      [r.topLeft, const Offset(l, 0), const Offset(0, l)],
      [r.topRight, const Offset(-l, 0), const Offset(0, l)],
      [r.bottomLeft, const Offset(l, 0), const Offset(0, -l)],
      [r.bottomRight, const Offset(-l, 0), const Offset(0, -l)],
    ]) {
      final o = c[0];
      canvas.drawPath(
          Path()
            ..moveTo(o.dx + c[1].dx, o.dy + c[1].dy)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx + c[2].dx, o.dy + c[2].dy),
          p);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter o) => false;
}
