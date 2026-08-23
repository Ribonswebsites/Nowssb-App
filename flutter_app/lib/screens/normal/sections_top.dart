/// Normal home sections, first half — in `REG.norm.items` order.
///
/// greet · search · herovid · streak · storedisc · practice · tiles ·
/// store · reader · trendwd · custom
///
/// These are the ones that exist only on this home, or that say something
/// different here than they do on the Fashion home. The nine written once
/// for both are in lib/screens/shared_sections.dart.
///
/// Copy is transcribed from index.html rather than paraphrased. Line numbers
/// on each class say where.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';

import '../../data/content.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/neu_wrap.dart';
import '../../widgets/neumorphic.dart';

/// The time-of-day greeting the home renders — app/js/part012.js.
String nmGreetHello([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

IconData nmGreetMark([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h < 12) return Icons.wb_twilight;
  if (h < 17) return Icons.wb_sunny_outlined;
  return Icons.nightlight_outlined;
}

/// 1 · greet — index.html:908. `.nmh-greet-block`: a raised disc holding a
/// mark for the time of day, then the greeting, the name and one line.
class NmGreeting extends StatelessWidget {
  const NmGreeting({super.key, this.name = 'Healer'});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: NwsbColors.surface,
              shape: BoxShape.circle,
              boxShadow: NwsbShadows.raisedXs,
            ),
            child: Icon(nmGreetMark(), size: 26, color: WrapHead.markGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nmGreetHello(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w300,
                    color: NwsbColors.inkSoft,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: NwsbColors.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Ready for today's healing practice?",
                  style: TextStyle(fontSize: 12.5, color: NwsbColors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2 · search — index.html:927. `.nmh-search`.
///
/// One bar, at the top, that searches words and meanings together. It
/// replaced two separate search sections AND the AI Prescription block on
/// this home, which is why `rx`, `wsearch` and `msearch` have registry rows
/// here but no markup behind them.
class NmSearch extends StatelessWidget {
  const NmSearch({super.key, this.onSearch});

  /// Called with what was typed, empty when the bar itself is tapped.
  final void Function(String query)? onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _SearchBar(onSearch: onSearch),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({this.onSearch});
  final void Function(String query)? onSearch;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go() => widget.onSearch?.call(_c.text.trim());

  @override
  Widget build(BuildContext context) {
    // Pressed IN, not raised: a field is something you put something into,
    // and every raised control on this home is something you press.
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: NwsbColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: NwsbShadows.raisedSm,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: NwsbColors.inkFaint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _go(),
              style: const TextStyle(fontSize: 14, color: NwsbColors.ink),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search any word or meaning…',
                hintStyle: TextStyle(fontSize: 14, color: NwsbColors.inkFaint),
              ),
            ),
          ),
          GestureDetector(
            onTap: _go,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: NwsbColors.surface,
                shape: BoxShape.circle,
                boxShadow: NwsbShadows.raisedXs,
              ),
              child: const Icon(Icons.search, size: 19, color: NwsbColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3 · herovid — index.html:983. `.nmh-streakvid-wrap`: the head and the
/// streak clip on the landscape tablet. A banner and a section are different
/// things, so this and the streak below it are two wrappers, not one.
class NmStreakVideo extends StatelessWidget {
  const NmStreakVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SecWrap(
      children: [
        const WrapHead(
          eyebrow: 'Today, on film',
          title: 'Streak',
          mark: NwsbMarks.flame,
        ),
        // No tablet round it. The clip runs to the pane's own edges, and the
        // black bar under it says where it goes — the shape every other
        // banner on this home has.
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                asset: 'assets/video/tv-screen.mp4',
                priority: ClipPriority.decoration,
              ),
            ),
          ),
        ),
        SecBanner(
          title: 'Keep Your Streak',
          sub: 'Practice today and the run carries on',
          mark: NwsbMarks.flame,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// 4 · streak — index.html:998. `.nmh-streak-wrap`: the head, the heading
/// and its line, the streak bar, and the Daily Streak banner.
class NmStreak extends StatelessWidget {
  const NmStreak({super.key, this.days = 0, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SecWrap(
      children: [
        // No head. "Start Building Your Streak Today" is the heading of this
        // card, and an orb with "Your Streak" over the top of it was the
        // same thing said twice.
        const Text(
          'Start Building Your Streak Today',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: NwsbColors.ink,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const Text(
          'Practice daily to keep it alive — and unlock exclusive offers',
          style: TextStyle(
            fontSize: 13,
            color: NwsbColors.inkSoft,
            height: 1.45,
          ),
        ),
        // `.nmh-streak-bar` — pressed in, so the count reads as something
        // filling up rather than another button.
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: NwsbColors.surface,
            borderRadius: BorderRadius.circular(NwsbRadius.bar),
            boxShadow: NwsbShadows.raisedXs,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: NwsbColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs,
                ),
                child: const Icon(Icons.water_drop,
                    size: 26, color: NwsbColors.gold),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: NwsbColors.ink,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'day streak',
                    style: TextStyle(fontSize: 11, color: NwsbColors.inkFaint),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'KEEP GOING',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0x4D000000),
                  ),
                ),
              ),
            ],
          ),
        ),
        SecBanner(
          title: 'Daily Streak',
          sub: 'Practice daily to keep your healing streak alive',
          mark: NwsbMarks.flame,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// 5 · storedisc and 14 · condisc — index.html:1033 and :1358. `.npc-card`.
///
/// A wide plate — 1080:411 — with a spinning ring around a disc at one end
/// and a line of copy at the other. The lines change every 1900ms and the
/// picture with them, which is app/js/part049.js:110 and :121.
///
/// One widget for both because they differ only in their gradient and their
/// contents, which is exactly what `.npc-blue` and `.npc-purple` are: two
/// declarations on top of one `.npc-card`.
class NmPromoDisc extends StatefulWidget {
  const NmPromoDisc({
    super.key,
    required this.gradient,
    required this.slides,
    this.onTap,
  });

  final List<Color> gradient;

  /// (picture URL, the lines shown while it is up).
  final List<(String, List<String>)> slides;
  final VoidCallback? onTap;

  /// `.npc-purple` — the store.
  static const purple = [
    Color(0xFF150F3A),
    Color(0xFF2C1A5C),
    Color(0xFF5A3184),
    Color(0xFF7D4A9E),
    Color(0xFF9E6FAE),
  ];

  /// `.npc-blue` — Connect.
  static const blue = [
    Color(0xFF041022),
    Color(0xFF082A52),
    Color(0xFF0D4B8F),
    Color(0xFF1673C9),
    Color(0xFF4AA3EC),
  ];

  static const storeSlides = [
    (
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto,w_240/v1778571518/1000038291_no_bg-1778521337465_slhlrx.png',
      ['Enter the NowssB Store.', 'Own words that heal — yours alone.'],
    ),
    (
      'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto,w_240/v1779558987/c9c4e860-56cf-11f1-8fad-095787cce754_t6k8gb.png',
      ['Your cart is waiting.', 'Coupons up to 50% off today.'],
    ),
  ];

  static const connectSlides = [
    (
      'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_240/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
      ['Your circle just got bigger.', 'Connect with learners like you.'],
    ),
    (
      'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783162597/file_00000000029c71fa8c210e0f09870964_uwh8sc.png',
      ['Stand out with a badge.', 'Blue, Silver, Gold or Diamond — your pick.'],
    ),
    (
      'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000029c7208b5e915d9af2c480c_tuccwo.png',
      ['New voices, new stories.', 'Discover creators worth following.'],
    ),
  ];

  @override
  State<NmPromoDisc> createState() => _NmPromoDiscState();
}

class _NmPromoDiscState extends State<NmPromoDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  Timer? _t;
  int _slide = 0;
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() {
        final lines = widget.slides[_slide].$2;
        if (_line + 1 < lines.length) {
          _line++;
        } else {
          _line = 0;
          _slide = (_slide + 1) % widget.slides.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (img, lines) = widget.slides[_slide];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // `border: 10px solid #f0f2f7` — the page's own colour, so the
          // plate reads as sunk into the page rather than laid on it.
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: NwsbColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: NwsbShadows.raised,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1080 / 411,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradient,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        // The ring spins; the disc inside it does not.
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RotationTransition(
                                turns: _spin,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Color(0xFF38B6FF),
                                        Color(0xFF7B5CFF),
                                        Color(0xFFFF5CB8),
                                        Color(0xFFFFB35C),
                                        Color(0xFF38B6FF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment(-0.24, -0.36),
                                      colors: [
                                        Color(0xFF0E1A2C),
                                        Color(0xFF030812),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: NwsbImage(
                                      url: img,
                                      fit: BoxFit.contain,
                                      fallback: const Icon(
                                        Icons.auto_awesome,
                                        size: 22,
                                        color: Color(0xB3FFFFFF),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            child: Text(
                              lines[_line],
                              key: ValueKey('$_slide/$_line'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.35,
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
          ),
        ),
      ),
    );
  }
}

/// 6 · practice — index.html:1046. `.nmh-plyr-wrap`: the spill, then
/// `.nmh-practice` — a raised card with the artwork behind the words, the
/// word of the hour, its meaning, and Enter at the foot.
class NmPractice extends StatelessWidget {
  const NmPractice({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final w = words.isEmpty ? null : words[DateTime.now().day % words.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Your daily word ritual',
            mark: NwsbMarks.play,
            onTap: onTap,
          ),
          NeuCard(
            onTap: onTap,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Practice",
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.gold,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: NwsbColors.surface,
                    borderRadius: BorderRadius.circular(NwsbRadius.pill),
                    boxShadow: NwsbShadows.raisedXs,
                  ),
                  child: const Icon(Icons.graphic_eq,
                      size: 28, color: NwsbColors.gold),
                ),
                const SizedBox(height: 16),
                Text(
                  w?.word ?? 'Loading...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: NwsbColors.ink,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (w?.meaning.isNotEmpty ?? false)
                      ? w!.meaning
                      : 'Your personalized word ritual for right now.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: NwsbColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Enter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.gold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: NwsbColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: NwsbShadows.raisedXs,
                      ),
                      child: const NwsbIcon(NwsbMarks.arrow,
                          size: 16, color: NwsbColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 7 · tiles — index.html:1157. `.nmh-tiles-wrap`: the tip rail and the
/// four buttons.
///
/// The four are NOT the Fashion home's four: Sound Library, My Progress,
/// Word Science, My Profile.
class NmTiles extends StatelessWidget {
  const NmTiles({super.key, this.onTile});

  /// Called with the tile's destination tab index.
  final void Function(int)? onTile;

  /// (title, sub, cover URL, icon, destination).
  static const _tiles = [
    (
      'Sound Library',
      'Root frequencies',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899463/file_000000008bf881faa9949f7b7d9824bf_niqhps.png',
      Icons.graphic_eq,
      2,
    ),
    (
      'My Progress',
      'Healing journey',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899471/file_00000000345481faafd2bea97c8320ab_oknybe.png',
      Icons.show_chart,
      4,
    ),
    (
      'Word Science',
      'NOWSBANSIU texts',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899472/file_00000000a24081fa83eeab9164647db8_w2fzuq.png',
      Icons.science_outlined,
      2,
    ),
    (
      'My Profile',
      'Your settings',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784896734/file_0000000080688207a9599e17a28e7710_oefkxy.png',
      Icons.person_outline,
      4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SecWrap(
      children: [
        // `.htg-rail` — "Tap to restyle" at one end, "Begin your healing"
        // at the other.
        Row(
          children: [
            const Icon(Icons.chevron_left, size: 15, color: NwsbColors.gold),
            const Icon(Icons.chevron_left, size: 15, color: NwsbColors.gold),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Tap to restyle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: NwsbColors.inkSoft),
              ),
            ),
            const Spacer(),
            Container(width: 1, height: 14, color: const Color(0x1A000000)),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Begin your healing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: NwsbColors.inkFaint),
              ),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            for (final (title, sub, cover, icon, dest) in _tiles)
              _NmTile(
                title: title,
                sub: sub,
                cover: cover,
                icon: icon,
                onTap: () => onTile?.call(dest),
              ),
          ],
        ),
      ],
    );
  }
}

/// `.nmh-tile` — the cover art behind, a raised mark, a rule, the two lines
/// and Enter. Raised out of the page, unlike the Fashion home's, which are
/// black tiles cut into it.
class _NmTile extends StatelessWidget {
  const _NmTile({
    required this.title,
    required this.sub,
    required this.cover,
    required this.icon,
    this.onTap,
  });

  final String title, sub, cover;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: NwsbColors.surface,
          borderRadius: BorderRadius.circular(NwsbRadius.tile),
          boxShadow: NwsbShadows.raisedSm,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NwsbImage(
              url: cover,
              fallback: const ColoredBox(color: NwsbColors.surface),
            ),
            // `.nmh-tile-cover-scrim` — the art is a wash behind the words,
            // not a photograph in front of them.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD9F0F2F7), Color(0xF7F0F2F7)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: NwsbColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: NwsbShadows.raisedXs,
                    ),
                    child: Icon(icon, size: 20, color: NwsbColors.gold),
                  ),
                  const Spacer(),
                  Container(
                      height: 1, width: 26, color: const Color(0x1A000000)),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NwsbColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: NwsbColors.inkFaint),
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

/// 8 · store — index.html:1572. `.nmh-store-wrap`: the banner clip that
/// app/js/part067.js:25 drops in at the top, then the trigger card.
///
/// THREE pills here, not the Fashion home's four — the Normal card drops
/// "AI-Decoded".
class NmStore extends StatelessWidget {
  const NmStore({super.key, this.onTap});
  final VoidCallback? onTap;

  static const _pills = ['Word Library', 'Meaning Library', 'Organ Targeting'];

  @override
  Widget build(BuildContext context) {
    return SecWrap(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                asset: 'assets/video/store-banner.mp4',
                priority: ClipPriority.decoration,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const NwsbVideo(asset: 'assets/video/store-section.mp4'),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x33000000),
                          Color(0xF2000000),
                        ],
                        stops: [0, 0.42, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shabdapathy · Collections',
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: NwsbColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 27,
                              color: Colors.white,
                              height: 1.15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Enter the\n',
                                style: TextStyle(fontWeight: FontWeight.w300),
                              ),
                              TextSpan(
                                text: 'NowssB Store',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Word Library & Meaning Library — own the sounds '
                          'that heal, unlock the origins that were hidden.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xB3FFFFFF),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final p in _pills)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0x2EFFFFFF)),
                                ),
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xD9FFFFFF),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Explore Store',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: NwsbColors.ink,
                                ),
                              ),
                              SizedBox(width: 8),
                              NwsbIcon(NwsbMarks.arrow,
                                  size: 14, color: NwsbColors.ink),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 9 · reader — index.html:1250. `.nmh-rdsec-wrap`: the spill, the clip,
/// the copy, and the bar. Nothing is laid over the clip.
class NmReader extends StatelessWidget {
  const NmReader({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spill(
            label: 'Meanings and eBooks, in one place',
            mark: NwsbMarks.reader,
            onTap: onTap,
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const AspectRatio(
                aspectRatio: 16 / 9,
                child: NwsbImage(
                  url:
                      'https://res.cloudinary.com/eenvubod/video/upload/v1785403688/grok_video_2026-07-30-14-57-37_tbzpox.mp4',
                  fallback: NwsbVideo(
                    asset: 'assets/video/word-acts.mp4',
                    priority: ClipPriority.decoration,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'NowssB',
            style: TextStyle(fontSize: 14, color: NwsbColors.inkSoft),
          ),
          const Text(
            'Reader',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: NwsbColors.ink,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Read every meaning, and every eBook.',
            style: TextStyle(fontSize: 13, color: NwsbColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Align(
              alignment: Alignment.centerLeft, child: EnterPill(onTap: onTap)),
          const SizedBox(height: 16),
          SecBanner(
            title: 'Reader',
            sub: 'Meanings and eBooks, in one place',
            mark: NwsbMarks.reader,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 10 · trendwd — index.html:1287. `.nmh-trend-wrap`: the clip with the
/// trending word over it, and its bar.
class NmTrending extends StatelessWidget {
  const NmTrending({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final word = words.isEmpty
        ? ''
        : words[(DateTime.now().day + 3) % words.length].word;

    return SecWrap(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const NwsbImage(
                    url:
                        'https://res.cloudinary.com/eenvubod/video/upload/f_auto,q_auto/v1784370276/grok_video_2026-07-18-15-53-02_ubjx5b.mp4',
                    fallback: NwsbVideo(
                      asset: 'assets/video/word-acts.mp4',
                      priority: ClipPriority.decoration,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xCC000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SecBanner(
          title: "Today's Trending",
          sub: 'See which words are healing the most people right now',
          mark: NwsbMarks.trending,
          markViewBox: 22,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// 11 · custom — index.html:1310. `.nmh-cust-panel`: the head that opens
/// the Customize hub. The rows below it are rendered from the same list the
/// hub uses; reordering is out of scope, so this is the door rather than a
/// list of handles that would not move anything.
class NmCustomize extends StatelessWidget {
  const NmCustomize({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: NeuCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: NwsbColors.surface,
                shape: BoxShape.circle,
                boxShadow: NwsbShadows.raisedXs,
              ),
              child: const Icon(Icons.tune, size: 20, color: NwsbColors.gold),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Customize',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: NwsbColors.ink,
                    ),
                  ),
                  Text(
                    'Make this home yours',
                    style: TextStyle(fontSize: 12, color: NwsbColors.inkFaint),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: NwsbColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
