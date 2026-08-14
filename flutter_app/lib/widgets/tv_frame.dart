/// The television — the tablet bezel with a clip inside it.
///
/// It appears all over the website (`.hero-tvbox`, `.dev-tab-l`, the streak
/// section's tablet, the store trigger) and it has one rule that broke the
/// web version more than once: THE FRAME KEEPS ITS ASPECT RATIO, ALWAYS.
///
/// On the web, putting `display:flex` on the wrapper made the box a flex
/// item free to be squashed below its ratio — and because the aperture is a
/// percentage of the WIDTH, a shortened frame kept a full-size screen inside
/// a smaller bezel: the art rode up, the picture overflowed, the foot became
/// a white slab. In Flutter an AspectRatio cannot be squashed by its parent
/// the way a flex item can, which is one of the small ways the port is more
/// solid than the thing it replaces.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

class TvFrame extends StatelessWidget {
  const TvFrame({
    super.key,
    required this.asset,
    this.aspect = 1452 / 831,
    this.priority = ClipPriority.feature,
    this.label,
    this.onTap,
  });

  /// The clip on the screen.
  final String asset;

  /// The bezel's own ratio — 1452:831 is the landscape tablet the website
  /// uses. A portrait clip wants roughly 768:1168.
  final double aspect;

  /// The television is the point of its section, so by default it claims a
  /// decoder ahead of any banner near it.
  final ClipPriority priority;

  /// The small wordmark on the bezel, top left. Null for none.
  final String? label;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 22, 8, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // The wordmark and the camera dot sit on the bezel, above the
              // aperture — which is why the top padding is bigger than the
              // rest.
              if (label != null)
                Positioned(
                  top: -16,
                  left: 6,
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              const Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A2E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ColoredBox(
                    color: Colors.black,
                    child: NwsbVideo(asset: asset, priority: priority),
                  ),
                ),
              ),
              // The home indicator on the foot.
              Positioned(
                bottom: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 46,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFBFC8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
