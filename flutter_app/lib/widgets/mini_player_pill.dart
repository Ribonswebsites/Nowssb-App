/// Floating mini-player pill shown above the bottom nav while a practice
/// session is minimized. Tap opens the hearing-safety expanded player.
library;

import 'package:flutter/material.dart';

import '../data/playback_session.dart';

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
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xF2141418),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x28FFFFFF)),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: art.isEmpty
                          ? const ColoredBox(color: Color(0xFF222228))
                          : art.startsWith('http')
                              ? Image.network(
                                  art,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(color: Color(0xFF222228)),
                                )
                              : Image.asset(
                                  art,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(color: Color(0xFF222228)),
                                ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.playing ? 'Playing · NowssB' : 'Paused · NowssB',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onPlayPause ?? () => PlaybackSession.instance.togglePlay(),
                    icon: Icon(
                      session.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFFF5F5F7),
                      size: 28,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss ?? () => PlaybackSession.instance.dismiss(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFB0B0B5), size: 20),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
