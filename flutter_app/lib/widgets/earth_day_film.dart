/// Earth film that follows the day. Sits above Open a door only.
///
/// Morning, afternoon, evening, night. The clip stays clear — no dark plate
/// over it. Start practice, the enter arrow, and the composing orb sit at
/// the bottom right.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../shell/nav_shell.dart';
import 'app_thinking_loader.dart';

class EarthDayFilm extends StatelessWidget {
  const EarthDayFilm({super.key, this.height = 228});

  final double height;

  static String slot([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    if (h < 21) return 'evening';
    return 'night';
  }

  static const _label = {
    'morning': 'Morning',
    'afternoon': 'Afternoon',
    'evening': 'Evening',
    'night': 'Night',
  };

  static const _sub = {
    'morning': 'The first light. Begin here.',
    'afternoon': 'A quieter hour to sit with the sound.',
    'evening': 'Let the day finish in one word.',
    'night': 'Rest is a practice. Stay with the tone.',
  };

  void _start(BuildContext context) => NavScope.goTo(context, 1);

  @override
  Widget build(BuildContext context) {
    final part = slot();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(
                asset: 'assets/video/earth-$part.mp4',
                priority: ClipPriority.decoration,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NowssB',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.4,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label[part] ?? part,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 168,
                      child: Text(
                        _sub[part] ?? '',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 28,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AppThinkingLoader(
                      size: 40,
                      state: OrbState.composing,
                      blackCircle: true,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _start(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Start your practice',
                          style: TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _start(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF111111),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
