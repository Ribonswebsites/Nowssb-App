/// The intro page every store and library wears before its content.
///
/// The website has nine of these — the Word Atelier, the Meaning Store, the
/// Sound Library, the cart, the wishlist, Fashion Plus and the rest — and
/// they are all the same object: a full-bleed picture, a back arrow and a tag
/// across the top, and at the foot an eyebrow, a big two-line title, a hair
/// rule, a sentence, some stats and one Enter button. Then it slides away and
/// the page is underneath.
///
/// Written once here rather than nine times. That is not only tidiness: nine
/// hand-built copies is what the website has, and it is why fixing the
/// vignette on one of them fixed it on none of the others.
///
/// The picture is a CLIP, and whether it moves is the Fashion Plus switch —
/// off, [NwsbVideo] holds its first frame and costs nothing; on, it plays.
/// Neither case is a different widget.
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class IntroGate extends StatefulWidget {
  const IntroGate({
    super.key,
    required this.tag,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.film,
    required this.enterLabel,
    required this.child,
    this.stats = const [],
    this.onBack,
  });

  /// The small label across the top, beside the back arrow.
  final String tag;

  final String eyebrow;

  /// Two lines, usually. Newlines are honoured.
  final String title;

  final String body;
  final List<String> stats;

  /// The page's own film, behind the words.
  final String film;

  final String enterLabel;

  /// What is underneath, revealed when Enter is pressed.
  final Widget child;

  final VoidCallback? onBack;

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_open)
          Positioned.fill(
            child: _Intro(
              tag: widget.tag,
              eyebrow: widget.eyebrow,
              title: widget.title,
              body: widget.body,
              stats: widget.stats,
              film: widget.film,
              enterLabel: widget.enterLabel,
              onBack: widget.onBack,
              onEnter: () => setState(() => _open = true),
            ),
          ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.tag,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.stats,
    required this.film,
    required this.enterLabel,
    required this.onEnter,
    this.onBack,
  });

  final String tag, eyebrow, title, body, film, enterLabel;
  final List<String> stats;
  final VoidCallback onEnter;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // Still unless motion mode is on. autoplay:false is what makes an
    // unmoving background genuinely free — the pool is never even asked.
    final moving = Settings.instance.fashionPlus;

    return Material(
      color: NwsbColors.deep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NwsbVideo(
            asset: film,
            autoplay: moving,
            priority: ClipPriority.feature,
          ),
          // The vignette. Deep enough at the foot that a title and a
          // paragraph hold their contrast over any frame of any clip.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99060C18),
                  Color(0x66060C18),
                  Color(0xE6060C18),
                  Color(0xFA040912),
                ],
                stops: [0, 0.35, 0.72, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            border:
                                Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 18, color: Color(0xBFFFFFFF)),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.5,
                              color: Color(0xBFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 46,
                        height: 1,
                        color: const Color(0x59FFFFFF),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xB3FFFFFF),
                          height: 1.6,
                        ),
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              if (i > 0)
                                const Text('·',
                                    style: TextStyle(color: Color(0x59FFFFFF))),
                              Text(
                                stats[i],
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0x8CFFFFFF),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: onEnter,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.white,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                enterLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: NwsbColors.ink,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.arrow_forward,
                                  size: 17, color: NwsbColors.ink),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
