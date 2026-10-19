/// How the player works — one film behind black boxes and colour boxes,
/// so the home explains itself before anyone has to hunt for a button.
library;

import 'package:flutter/material.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../widgets/nwsb_icon.dart';

class PlayerExplainer extends StatefulWidget {
  const PlayerExplainer({super.key, this.onOpen});

  final VoidCallback? onOpen;

  @override
  State<PlayerExplainer> createState() => _PlayerExplainerState();
}

class _PlayerExplainerState extends State<PlayerExplainer> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned.fill(
              child: NwsbVideo(
                asset: 'assets/video/player-box-rings.mp4',
                poster: 'assets/video/player-box-rings-poster.webp',
                priority: ClipPriority.feature,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xC407070C), Color(0xE607070C), Color(0xF207070C)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'HOW THE PLAYER WORKS',
                          style: TextStyle(
                            color: Color(0xFFE8D5A3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: _spin,
                        child: CustomPaint(
                          size: const Size(28, 28),
                          painter: _RingPainter(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Listen, speak, keep the word. Five things, nothing hidden.',
                    style: TextStyle(
                      color: Color(0xCCffffff),
                      fontSize: 13,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _ListenCard(),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _InfoBox(
                              color: Color(0xFF5B2BE0),
                              title: 'Practice',
                              body: 'Record your voice and see the score.',
                              mark: NwsbMarks.sound,
                            ),
                            SizedBox(height: 8),
                            _InfoBox(
                              color: Color(0xFF8A6A2F),
                              title: 'Library',
                              body: 'Words you own, and sentences you build.',
                              mark: NwsbMarks.book,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          color: Color(0xFF0E6E78),
                          title: 'Voice',
                          body: 'Male or female, loop, reps.',
                          mark: NwsbMarks.gear,
                          compact: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          color: Color(0xFF8E2458),
                          title: 'Store',
                          body: 'A new word joins the library.',
                          mark: NwsbMarks.bag,
                          compact: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          color: Color(0xFF000000),
                          title: 'Score',
                          body: 'Each repeat builds the streak.',
                          mark: NwsbMarks.rewards,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: widget.onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Open the player',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Center(
                                  child: NwsbIcon(NwsbMarks.enterArrow, size: 16, color: Color(0xFF07070A), viewBox: 12, strokeWidth: 1.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenCard extends StatelessWidget {
  const _ListenCard();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 118,
              child: Image.asset(
                'assets/player/guide/02.webp',
                fit: BoxFit.cover,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Listen',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, decoration: TextDecoration.none),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Play the word. Replay it. Step to the next.',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.3, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.color,
    required this.title,
    required this.body,
    required this.mark,
    this.compact = false,
  });

  final Color color;
  final String title;
  final String body;
  final String mark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, compact ? 10 : 12, 10, compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: NwsbIcon(mark, size: 16, color: const Color(0xFF07070A), strokeWidth: 1.8),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 11.5, height: 1.25, decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE8D5A3);
    canvas.drawArc(Offset.zero & size, -0.6, 3.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
