/// `.home-header` — index.html:763. Fixed above the Fashion home, never
/// scrolls.
///
/// The logo disc and the wordmark on the left; on the right three bare
/// marks separated by hairlines — notifications, the way back to the Normal
/// home, and the menu. Bare marks and not buttons: on the web these were
/// three CDN photographs of icons, three requests before the header could
/// finish, each a picture of a shape that takes four lines to draw. They are
/// drawn here for the same reason.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.notifications = 0,
    this.onNotifications,
    this.onNormalHome,
    this.onMenu,
  });

  final int notifications;
  final VoidCallback? onNotifications;
  final VoidCallback? onNormalHome;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    // `background: rgba(255,255,255,0.08)` with `blur(20px)` — WHITE glass
    // over the film, not a dark bar laid on top of it. This was an opaque
    // near-black slab, which is why it read as a night bar bolted to the
    // page instead of the page showing through it.
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0x14FFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              'assets/icons/logo-disc.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF14141C),
                child: Icon(Icons.headphones, size: 22, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // `Nowsb` heavy, `ansiu` light — one word with a break in the
          // weight, the way the mark is drawn everywhere else.
          const Flexible(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x80000000), blurRadius: 8,
                        offset: Offset(0, 1)),
                  ],
                ),
                children: [
                  TextSpan(
                    text: 'Nowsb',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'ansiu',
                    style: TextStyle(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _HdrIcon(
            mark: NwsbMarks.bell,
            badge: notifications,
            onTap: onNotifications,
          ),
          const _HdrRule(),
          _HdrIcon(mark: NwsbMarks.house, onTap: onNormalHome),
          const _HdrRule(),
          _HdrIcon(mark: NwsbMarks.menu, stroke: 1.9, onTap: onMenu),
        ],
      ),
        ),
      ),
    );
  }
}

class _HdrRule extends StatelessWidget {
  const _HdrRule();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0x2EFFFFFF),
      );
}

class _HdrIcon extends StatelessWidget {
  const _HdrIcon({
    required this.mark,
    this.badge = 0,
    this.stroke = 1.7,
    this.onTap,
  });

  final String mark;
  final int badge;
  final double stroke;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              // `.hdr-svg { width: 68%; height: 68% }` of a 38px button.
              child: NwsbIcon(mark, size: 38 * 0.68, strokeWidth: stroke),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8434F),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: NwsbColors.deep, width: 1.5),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.hs-greet` — app/js/part083.js:506. The greeting ABOVE the hero card:
/// a disc holding a mark that reads the clock, a light line, a heavy one
/// with your name, and one line under it.
class HeroGreeting extends StatelessWidget {
  const HeroGreeting({super.key, this.name = 'NowssB'});
  final String name;

  /// hello() — app/js/part083.js:153. Five bands, not three.
  static String hello([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  /// timeMark() — :177. The sun climbing, the sun high, the sun setting,
  /// the moon. The paths are the app's own; see [NwsbMarks.forHour].
  static String mark([DateTime? at]) =>
      NwsbMarks.forHour((at ?? DateTime.now()).hour);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: Center(
              child: NwsbIcon(mark(), size: 27, color: NwsbColors.goldLight),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${hello()},',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Color(0xA6FFFFFF),
                    height: 1.15,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Ready for today's healing practice?",
                  style: TextStyle(fontSize: 13.5, color: Color(0x8CFFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
