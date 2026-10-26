/// Normal home v4: everything from the three-card "Your programmes" rail
/// down to the footer, rebuilt in the white neumorphic look (soft white
/// raised cards, a dark shadow down-right and a white one up-left, on the
/// pale page). Every section carries motion: a NowssB meditation film, or a
/// meditation Lottie. No flowers, no lotus, no stock photos.
///
/// Each card reads the same live data and opens the same screen as the
/// section it replaces.
///
/// Media sources and licences: /workspace/team-plan/research/home-normal/MEDIA-LICENSES.md
library;

import 'package:nowssb/data/day_part.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../admin/template/editable.dart' show EditableLabel;
import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/practice_progress.dart';
import '../../features/circle/circle_screen.dart';
import '../../features/economy/economy_api.dart';
import '../../features/programs/partner_program.dart';
import '../../features/programs/reference_program.dart';
import '../../features/vault/vault_screen.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/earth_day_film.dart';
import '../../widgets/neu_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../daily_tasks.dart';
import '../nwsb_sign_in_sheet.dart';
import 'calm_v3.dart' show CalmGo;

const _ink = NwsbColors.ink;
const _soft = Color(0xFF5F6475);
const _accent = Color(0xFF6C63D9);
const _base = NwsbColors.surface;

/// The v4 shadow pair: dark down-right, white up-left.
const v4Raised = <BoxShadow>[
  BoxShadow(color: Color(0x24000000), offset: Offset(7, 7), blurRadius: 18),
  BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-7, -7), blurRadius: 18),
];
const _raisedSm = <BoxShadow>[
  BoxShadow(color: Color(0x1F000000), offset: Offset(4, 4), blurRadius: 10),
  BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
];
const _inset = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFDDE0E8), Color(0xFFEDEFF4), Color(0xFFF9FAFC)],
);

const _h = TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _ink, height: 1.2, letterSpacing: -.2);
const _sub = TextStyle(fontSize: 13.5, color: _soft, height: 1.35);
const _eyebrow = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _accent, letterSpacing: 1.5);

bool _still(BuildContext c) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) ||
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

void _push(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));

/// A looping meditation Lottie; still under reduced motion and in tests.
class V4Lottie extends StatelessWidget {
  const V4Lottie(this.asset, {super.key, this.size = 56});
  final String asset;
  final double size;

  /// Renders/tests only: hold every V4Lottie at this progress (0–1).
  @visibleForTesting
  static double? debugProgress;
  @override
  Widget build(BuildContext context) => Lottie.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        controller: debugProgress == null ? null : AlwaysStoppedAnimation<double>(debugProgress!),
        animate: debugProgress == null && !_still(context),
        errorBuilder: (_, __, ___) => SizedBox.square(dimension: size),
      );
}

const _meditate = 'assets/home/nm-v4-meditate.json';
const _breath = 'assets/home/nm-calm-breath.json';
const _orb = 'assets/anim/thinking/ring_orb_gold.json';
const _glow = 'assets/anim/thinking/glow_ring_gold.json';
const _infinity = 'assets/anim/loaders/infinity_gold.json';
const _waves = 'assets/anim/loaders/wave_dots_gold.json';
const _sand = 'assets/anim/loaders/sand_clock_gold.json';
/// The eBook line animation; used ONLY where eBooks appear.
const kEbookLottie = 'assets/anim/loaders/book_pages_gold.json';
const _pages = kEbookLottie;
// Concept animations (LottieFiles, Lottie Simple License; see MEDIA-LICENSES.md).
const kCoinsLottie = 'assets/home/nm-anim-coins.json';
const kGiftLottie = 'assets/home/nm-anim-gift.json';
const kRewardsLottie = 'assets/home/nm-anim-rewards.json';
const kSpeakerLottie = 'assets/home/nm-anim-speaker.json';
const kCartLottie = 'assets/home/nm-anim-cart.json';
const kWishlistLottie = 'assets/home/nm-anim-wishlist.json';
const kMeditateLottie = _meditate;
const kPlayLottie = 'assets/home/nm-anim-play.json';
const kStreakLottie = 'assets/home/nm-anim-streak.json';
const kProgressLottie = 'assets/home/nm-anim-progress.json';
const kSearchLottie = 'assets/home/nm-anim-search.json';
const kReaderLottie = 'assets/home/nm-anim-reader.json';
const kQuotesLottie = 'assets/home/nm-anim-quotes.json';
const kConnectLottie = 'assets/home/nm-anim-connect.json';
const kOrdersLottie = 'assets/home/nm-anim-orders.json';
const kPremiumLottie = 'assets/home/nm-anim-premium.json';
const kPartnerLottie = 'assets/home/nm-anim-partner.json';
const kSupportLottie = 'assets/home/nm-anim-support.json';
/// The second meditation animation (line-art yoga); nm-v4-meditate stays.
const kMeditateAltLottie = 'assets/home/nm-anim-meditate-line.json';
const kBagLottie = 'assets/home/nm-anim-bag.json';
const kHeadphonesLottie = 'assets/home/nm-anim-headphones.json';
const kHeartLottie = 'assets/home/nm-anim-heart.json';
const kSunLottie = 'assets/home/nm-anim-sun.json';

/// A NowssB film cut to a rounded window.
class V4Film extends StatelessWidget {
  const V4Film(this.asset, {super.key, required this.slot, this.radius = 22, this.circle = false});
  final String asset;
  final String slot;
  final double radius;
  final bool circle;
  @override
  Widget build(BuildContext context) {
    final v = NwsbVideo(asset: asset, priority: ClipPriority.decoration, slot: 'home_v4.$slot');
    return circle
        ? ClipOval(child: v)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: v);
  }
}

/// The soft white raised card every v4 section is built on.
class V4Card extends StatelessWidget {
  const V4Card({
    super.key,
    required this.child,
    this.onTap,
    this.pad = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.fromLTRB(20, 10, 20, 14),
    this.radius = 28,
    this.color = _base,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets pad;
  final EdgeInsets margin;
  final double radius;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: v4Raised,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: Padding(padding: pad, child: child)),
          ),
        ),
      );
}

/// A pressed-in well, for numbers and films.
class _Well extends StatelessWidget {
  const _Well({required this.child, this.size, this.circle = false, this.pad = 6});
  final Widget child;
  final Size? size;
  final bool circle;
  final double pad;
  @override
  Widget build(BuildContext context) => Container(
        width: size?.width,
        height: size?.height,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          gradient: _inset,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(24),
        ),
        child: child,
      );
}

/// Small raised round button holding a mark.
class _Knob extends StatelessWidget {
  const _Knob(this.mark, {this.size = 46, this.tint = _accent, this.lottie});
  final String mark;
  final String? lottie;
  final double size;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _base, shape: BoxShape.circle, boxShadow: _raisedSm),
        child: Center(child: lottie != null ? V4Lottie(lottie!, size: size * .7) : NwsbIcon(mark, size: size * .46, color: tint)),
      );
}

Widget _head(String eyebrow, String title, String lottie) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 4),
      child: WrapHead(eyebrow: eyebrow, title: title, art: V4Lottie(lottie, size: 42)),
    );

/// Two even columns that grow with their text (no fixed heights).
Widget _twoCol(List<Widget> cells, {double gap = 14}) => Column(children: [
      for (var i = 0; i < cells.length; i += 2) ...[
        if (i > 0) SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: cells[i]),
            SizedBox(width: gap),
            Expanded(child: i + 1 < cells.length ? cells[i + 1] : const SizedBox()),
          ]),
        ),
      ],
    ]);

/// The Fashion 'NowssB Store' card, on the light home: a bold black title
/// pill over rich rows (art tile, letter-spaced label, strong title, a line,
/// and a round black action).
class V4PillBlock extends StatelessWidget {
  const V4PillBlock({super.key, required this.title, this.aside, required this.children});
  final String title;
  final String? aside;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => V4Card(
        pad: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Flexible(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            if (aside != null) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: Text(aside!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
              ),
            ],
          ]),
          for (final c in children) ...[const SizedBox(height: 10), c],
        ]),
      );
}

/// One rich row of a [V4PillBlock].
class V4RichRow extends StatelessWidget {
  const V4RichRow({
    super.key,
    required this.art,
    required this.label,
    required this.title,
    required this.sub,
    required this.onTap,
    this.action = Icons.arrow_forward_rounded,
    this.actionLabel,
  });
  final Widget art;
  final String label;
  final String title;
  final String sub;
  final IconData action;
  final String? actionLabel;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: actionLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _base, borderRadius: BorderRadius.circular(22), boxShadow: _raisedSm),
            child: Row(children: [
              _Well(size: const Size.square(68), pad: 4, child: Center(child: art)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: _soft)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
                  const SizedBox(height: 3),
                  Text(sub, style: const TextStyle(fontSize: 12.5, color: _soft, height: 1.3)),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Icon(action, color: Colors.white, size: 19),
              ),
            ]),
          ),
        ),
      );
}

// ───────────────────────── routineCards ─────────────────────────

/// Sound Library: an orb film set into a pressed well, beside the call.
class V4SoundLibrary extends StatelessWidget {
  const V4SoundLibrary({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-sound'),
        onTap: onTap,
        child: Row(children: [
          const _Well(
            circle: true,
            size: Size.square(96),
            child: V4Film('assets/video/orb-loop.mp4', slot: 'sound', circle: true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Expanded(child: Text('SOUND LIBRARY', style: _eyebrow)),
                V4Lottie(kSpeakerLottie, size: 30),
              ]),
              const SizedBox(height: 6),
              const Text("Open today's Sound Library.", style: _h),
              const SizedBox(height: 12),
              CalmGo(label: 'Listen', onTap: onTap),
            ]),
          ),
        ]),
      );
}

/// Get Started: pastel two-column tiles; every tile opens the Player.
class V4GetStarted extends StatelessWidget {
  const V4GetStarted({super.key, required this.onPlay});
  final VoidCallback onPlay;
  static const routines = [
    ('Trusting the Breath', 'Mindfulness · 4 min', Color(0xFFE4E1FB)),
    ('Positive Self-Talk & Power', 'Life Coaching · 4 mins', Color(0xFFFBE6D8)),
    ('What Your Body Knows', 'Story · 8 min', Color(0xFFDDF1EA)),
    ('Return to Stillness', 'Breathwork · 6 min', Color(0xFFDDEBFA)),
    ('A Softer Inner Voice', 'Sounds · 5 min', Color(0xFFF7E1EC)),
    ('A Quiet Place Within', 'Meditation · 10 min', Color(0xFFF4EFD6)),
  ];
  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('v4-getstarted'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _head('Six short sessions', 'Get Started', _sand),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: _twoCol([
              for (var i = 0; i < routines.length; i++)
                V4Card(
                  key: ValueKey('v4-routine-$i'),
                  margin: EdgeInsets.zero,
                  radius: 24,
                  color: routines[i].$3,
                  pad: const EdgeInsets.all(14),
                  onTap: onPlay,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('0${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _accent)),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Center(child: V4Lottie(kPlayLottie, size: 24)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Text(routines[i].$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(routines[i].$2, style: const TextStyle(fontSize: 12.5, color: _soft)),
                  ]),
                ),
            ]),
          ),
        ],
      );
}

/// Time of day: the Earth film for this hour, and the four parts of the day.
class V4EarthDay extends StatelessWidget {
  const V4EarthDay({super.key, required this.onTap});
  final VoidCallback onTap;
  static const _parts = ['morning', 'afternoon', 'evening', 'night'];
  static const _label = {'morning': 'Morning', 'afternoon': 'Afternoon', 'evening': 'Evening', 'night': 'Night'};
  static const _lines = {
    'morning': 'The first light. Begin here.',
    'afternoon': 'A quieter hour to sit with the sound.',
    'evening': 'Let the day finish in one word.',
    'night': 'Rest is a practice. Stay with the tone.',
  };
  @override
  Widget build(BuildContext context) => DayPartBuilder(builder: (context, p, _) => _build(context, p.slot));

  Widget _build(BuildContext context, String part) {
    return V4Card(
      key: const ValueKey('v4-earth'),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _Well(child: V4Film('assets/video/earth-$part.mp4', slot: 'earth', radius: 18)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          for (final p in _parts)
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: p == part ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: p == part ? _accent : const Color(0xFFCFD3DE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_label[p]!, style: TextStyle(fontSize: 11.5, color: p == part ? _ink : _soft, fontWeight: p == part ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        Text('${_label[part]} practice', style: _h),
        const SizedBox(height: 4),
        Text(_lines[part]!, style: _sub),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: CalmGo(label: 'Begin now', onTap: onTap)),
      ]),
    );
  }
}

/// Open a door: nine raised knobs on one card.
class V4Doors extends StatelessWidget {
  const V4Doors({super.key, required this.onOpen});
  final void Function(String id) onOpen;
  static const doors = [
    ('practice', 'Practice', NwsbMarks.play24),
    ('library', 'Library', NwsbMarks.sound),
    ('store', 'Store', NwsbMarks.bag),
    ('reader', 'Reader', NwsbMarks.reader),
    ('healing', 'Healing', NwsbMarks.wishlist),
    ('subscription', 'Subscribe', NwsbMarks.crown),
    ('player', 'Player', NwsbMarks.play),
    ('progress', 'Progress', NwsbMarks.bars),
    ('quotes', 'Quotes', NwsbMarks.word),
  ];
  static const _doorLottie = {
    'player': kSpeakerLottie,
    'practice': kPlayLottie,
    'library': kHeadphonesLottie,
    'store': kBagLottie,
    'healing': kHeartLottie,
    'reader': kReaderLottie,
    'subscription': kPremiumLottie,
    'progress': kProgressLottie,
    'quotes': kQuotesLottie,
  };
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-doors'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NINE DOORS', style: _eyebrow),
                SizedBox(height: 6),
                Text('Open a door', style: _h),
              ]),
            ),
            V4Lottie(_infinity, size: 48),
          ]),
          const SizedBox(height: 14),
          for (var r = 0; r < 3; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                for (var c = 0; c < 3; c++)
                  Expanded(
                    child: InkWell(
                      key: ValueKey('v4-door-${doors[r * 3 + c].$1}'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onOpen(doors[r * 3 + c].$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(children: [
                          _Knob(doors[r * 3 + c].$3, lottie: _doorLottie[doors[r * 3 + c].$1]),
                          const SizedBox(height: 8),
                          Text(doors[r * 3 + c].$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
        ]),
      );
}

// ───────────────────────── herovid: progress-first streak ─────────────────────────

class V4Streak extends StatelessWidget {
  const V4Streak({super.key, required this.onPractice, required this.onOffers});
  final VoidCallback onPractice;
  final VoidCallback onOffers;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PracticeProgress.instance,
        builder: (context, _) {
          final p = PracticeProgress.instance;
          final s = p.streak;
          final lit = s % 7 == 0 && s > 0 ? 7 : s % 7;
          return V4Card(
            key: const ValueKey('v4-streak'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('YOUR STREAK', style: _eyebrow),
                      SizedBox(width: 6),
                      V4Lottie(kStreakLottie, size: 16),
                    ]),
                    const SizedBox(height: 4),
                    Text('$s', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink, height: 1.1)),
                    Text(s == 1 ? 'day in a row' : 'days in a row', style: _sub),
                  ]),
                ),
                const _Well(
                  circle: true,
                  size: Size.square(92),
                  child: V4Film('assets/video/player-aura-bg.mp4', slot: 'streak', circle: true),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < lit ? _accent : null,
                          gradient: i < lit ? null : _inset,
                        ),
                        child: i < lit ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Text('${p.todaySessions} today · ${p.totalSessions} sessions in all', style: _sub),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                CalmGo(label: 'Practice now', onTap: onPractice),
                CalmGo(label: 'Exclusive offers', light: true, onTap: onOffers),
              ]),
            ]),
          );
        },
      );
}

// ───────────────────────── actionbar: help + coach ─────────────────────────

class V4HelpCoach extends StatelessWidget {
  const V4HelpCoach({super.key, required this.onSupport, required this.onCoach});
  final VoidCallback onSupport;
  final VoidCallback onCoach;
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-help'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WE ARE HERE', style: _eyebrow),
                SizedBox(height: 6),
                Text('How can we help today?', style: _h),
              ]),
            ),
            V4Lottie(_glow, size: 52),
          ]),
          const SizedBox(height: 14),
          _twoCol([
            V4Card(
              margin: EdgeInsets.zero,
              radius: 22,
              pad: const EdgeInsets.all(14),
              onTap: onSupport,
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                V4Lottie(kSupportLottie, size: 24),
                SizedBox(height: 8),
                Text('Help and support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
              ]),
            ),
            V4Card(
              margin: EdgeInsets.zero,
              radius: 22,
              pad: const EdgeInsets.all(14),
              onTap: onCoach,
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                V4Lottie(kMeditateAltLottie, size: 24),
                SizedBox(height: 8),
                Text('Personal Coach', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
              ]),
            ),
          ]),
        ]),
      );
}

// ───────────────────────── store + earn ─────────────────────────

class V4StoreEarn extends StatelessWidget {
  const V4StoreEarn({super.key, required this.onStore});
  final VoidCallback onStore;
  @override
  Widget build(BuildContext context) {
    void earn() => _push(context, const CircleScreen());
    return Column(key: const ValueKey('v4-store'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _head('Meaning Store', 'Offers and earning', _sand),
      V4Card(
        onTap: onStore,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AspectRatio(
            aspectRatio: 2.2,
            child: _Well(child: V4Film('assets/video/hero-meaning-store.mp4', slot: 'store', radius: 18)),
          ),
          const SizedBox(height: 14),
          const Text('Words that carry meaning', style: _h),
          const SizedBox(height: 4),
          const Text('Every word in the store comes with its sound and its story.', style: _sub),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: CalmGo(label: 'Open the store', onTap: onStore)),
        ]),
      ),
      V4Card(
        onTap: earn,
        child: Row(children: [
          const _Well(circle: true, size: Size.square(64), child: V4Lottie(kCoinsLottie, size: 52)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NOWSSB EARN', style: _eyebrow),
              const SizedBox(height: 4),
              const Text('Your share of the net.', style: _h),
              const SizedBox(height: 4),
              const Text('Commission on net. Two levels. Never a third.', style: _sub),
              const SizedBox(height: 10),
              CalmGo(label: 'Join today', onTap: earn),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ───────────────────────── feed ─────────────────────────

class V4Community extends StatelessWidget {
  const V4Community({super.key, required this.onTap});
  final VoidCallback onTap;
  static const _rows = [
    (NwsbMarks.feed, 'Community Feed', 'Share your daily practice'),
    (NwsbMarks.stories, 'Stories', '24-hour frequency moments'),
    (NwsbMarks.reels, 'Reels', 'Short healing reels'),
    (NwsbMarks.discover, 'Discover Creators', 'People worth following'),
  ];
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-community'),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AspectRatio(
            aspectRatio: 2.4,
            child: _Well(child: V4Film('assets/video/connect-banner.mp4', slot: 'connect', radius: 18)),
          ),
          const SizedBox(height: 14),
          const Text('NOWSSB CONNECT', style: _eyebrow),
          const SizedBox(height: 6),
          const Text('Practise together', style: _h),
          const SizedBox(height: 12),
          _twoCol(gap: 10, [
            for (final r in _rows)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Knob(r.$1, size: 38, lottie: r.$1 == NwsbMarks.feed ? kConnectLottie : null),
                    const SizedBox(height: 8),
                    Text(r.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                    Text(r.$3, style: const TextStyle(fontSize: 12.5, color: _soft, height: 1.3)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: CalmGo(label: 'Open Connect', onTap: onTap)),
        ]),
      );
}

// ───────────────────────── healing ─────────────────────────

class V4Healing extends StatelessWidget {
  const V4Healing({super.key, this.onTap, this.onFemale, this.onMale});
  final VoidCallback? onTap;
  final VoidCallback? onFemale;
  final VoidCallback? onMale;
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-healing'),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AspectRatio(
            aspectRatio: 2.4,
            child: _Well(child: V4Film('assets/video/healing-path-bg.mp4', slot: 'healing', radius: 18)),
          ),
          const SizedBox(height: 14),
          const Text('HEALTH JOURNEY', style: _eyebrow),
          const SizedBox(height: 6),
          const Text('Customise your healing path', style: _h),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            CalmGo(label: 'Her path', onTap: onFemale),
            CalmGo(label: 'His path', light: true, onTap: onMale),
          ]),
        ]),
      );
}
