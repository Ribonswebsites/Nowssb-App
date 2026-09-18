/// Floating mini-player pill shown above the bottom nav while a practice
/// session is minimized. Tap reopens the Now Playing player.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/playback_session.dart';

const _storeMark = 'assets/store/nowssb-bag-headphones.webp';

class MiniPlayerPill extends StatelessWidget {
  const MiniPlayerPill({
    super.key,
    required this.onOpen,
    this.onPlayPause,
    this.onDismiss,
  });

  final VoidCallback onOpen;
  final VoidCallback? onPlayPause;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlaybackSession.instance,
      builder: (context, _) {
        final session = PlaybackSession.instance;
        if (!session.showPill) return const SizedBox.shrink();
        final art = session.artwork;
        final title = session.word?.word ?? session.title;
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  decoration: BoxDecoration(
                    color: const Color(0x66101014),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: art.isEmpty
                                  ? const ColoredBox(color: Color(0xFF222228))
                                  : art.startsWith('http')
                                      ? Image.network(
                                          art,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const ColoredBox(
                                            color: Color(0xFF222228),
                                          ),
                                        )
                                      : Image.asset(
                                          art,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const ColoredBox(
                                            color: Color(0xFF222228),
                                          ),
                                        ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  _storeMark,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0x55FFFFFF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF5F5F7),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.playing
                                  ? 'Playing · NowssB'
                                  : 'Paused · NowssB',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _WhiteCircleBtn(
                        icon: session.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: onPlayPause ??
                            () => PlaybackSession.instance.togglePlay(),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 22,
                        color: const Color(0x55FFFFFF),
                      ),
                      const SizedBox(width: 6),
                      _WhiteCircleBtn(
                        icon: Icons.close_rounded,
                        size: 18,
                        onTap: onDismiss ??
                            () => PlaybackSession.instance.dismiss(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WhiteCircleBtn extends StatelessWidget {
  const _WhiteCircleBtn({
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0A0A0C), size: size),
      ),
    );
  }
}
