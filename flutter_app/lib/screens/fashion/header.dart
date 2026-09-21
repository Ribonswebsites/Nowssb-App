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
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../theme/tokens.dart';
import '../../widgets/app_thinking_loader.dart';
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
          // `padding: max(env(safe-area-inset-top, 14px), 14px) 20px 14px` —
          // the status bar's height is PART of the header, which is what makes
          // the glass run to the top of the screen instead of starting under a
          // black band.
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 14,
            20,
            14,
          ),
          decoration: const BoxDecoration(
            color: Color(0x14FFFFFF),
            border: Border(
              bottom: BorderSide(color: Color(0x1AFFFFFF)),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/icons/logo-disc.webp',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
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
                        Shadow(
                            color: Color(0x80000000),
                            blurRadius: 8,
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
                  badge > 99 ? '99+' : '$badge',
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

/// Glass search under the Healer greeting.
/// Outer glass rect → inner black pill with composing orb LEFT + centered "Search".
class FashionGreetingSearch extends StatelessWidget {
  const FashionGreetingSearch({super.key, this.onOpen, this.onSubmit, this.controller});

  /// Opens the blurred destination search sheet (preferred).
  final VoidCallback? onOpen;
  final ValueChanged<String>? onSubmit;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: GestureDetector(
        onTap: onOpen ??
            () => showDestinationSearchSheet(context, onSelect: onSubmit),
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              height: 52,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF00C0C0E),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppThinkingLoader(
                        size: 26,
                        state: OrbState.composing,
                      ),
                    ),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Major app destinations for A–Z search suggestions.
const kNwsbSearchDestinations = <(String, String)>[
  ('About', 'about'),
  ('App Settings', 'settings'),
  ('Connect', 'connect'),
  ('Fashion Plus', 'fashion'),
  ('Healer', 'healer'),
  ('Healing Path', 'healing'),
  ('Library', 'library'),
  ('Meaning Store', 'meaning-store'),
  ('Personal Coach', 'coach'),
  ('Player', 'player'),
  ('Practice', 'practice'),
  ('Profile', 'profile'),
  ('Progress', 'progress'),
  ('Quick Access', 'quick-access'),
  ('Reader', 'reader'),
  ('Request Words', 'request-words'),
  ('Sentence Builder', 'sentence'),
  ('Settings', 'settings'),
  ('Sound Library', 'sound-library'),
  ('Store', 'store'),
  ('Subscribe', 'subscribe'),
  ('Word Science', 'word-science'),
  ('Widgets', 'widgets'),
];

Future<void> showDestinationSearchSheet(
  BuildContext context, {
  ValueChanged<String>? onSelect,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Search',
    barrierColor: const Color(0xB7040812),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) {
      return _DestinationSearchSheet(onSelect: onSelect);
    },
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.4, 0, 0.2, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _DestinationSearchSheet extends StatefulWidget {
  const _DestinationSearchSheet({this.onSelect});
  final ValueChanged<String>? onSelect;

  @override
  State<_DestinationSearchSheet> createState() =>
      _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends State<_DestinationSearchSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<(String, String)> get _filtered {
    final q = _q.trim().toLowerCase();
    final all = [...kNwsbSearchDestinations]
      ..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
    if (q.isEmpty) return all;
    return all
        .where((d) =>
            d.$1.toLowerCase().contains(q) || d.$2.toLowerCase().contains(q))
        .toList();
  }

  void _pick(String key) {
    Navigator.of(context).maybePop();
    widget.onSelect?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xE6101014),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const AppThinkingLoader(
                        size: 24,
                        state: OrbState.solving,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: Colors.white70,
                          onChanged: (v) => setState(() => _q = v),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search destinations…',
                            hintStyle: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A0A0E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0x14FFFFFF),
                      ),
                      itemBuilder: (context, i) {
                        final (label, key) = items[i];
                        final letter = label.isEmpty
                            ? ''
                            : label[0].toUpperCase();
                        final showLetter = i == 0 ||
                            items[i - 1].$1[0].toUpperCase() != letter;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showLetter)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    color: Color(0x99E8D5A3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                            ListTile(
                              dense: true,
                              title: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0x66FFFFFF),
                              ),
                              onTap: () => _pick(key),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
