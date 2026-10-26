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
  @override
  Widget build(BuildContext context) => Lottie.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        animate: !_still(context),
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
                        child: const Icon(Icons.play_arrow_rounded, size: 18, color: _ink),
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
  Widget build(BuildContext context) {
    final part = EarthDayFilm.slot();
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
                          _Knob(doors[r * 3 + c].$3, lottie: doors[r * 3 + c].$1 == 'player' ? kSpeakerLottie : null),
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
                    const Text('YOUR STREAK', style: _eyebrow),
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
                Icon(Icons.support_agent_rounded, color: _accent),
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
                Icon(Icons.self_improvement_rounded, color: _accent),
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

// ───────────────────────── reader + rewards ─────────────────────────

class V4ReaderRewards extends StatelessWidget {
  const V4ReaderRewards({super.key, required this.onReader});
  final VoidCallback onReader;
  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('v4-reader'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V4Card(
            onTap: onReader,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('NOWSSB READER', style: _eyebrow),
                  const SizedBox(height: 6),
                  const Text('Read every meaning, and every eBook.', style: _h),
                  const SizedBox(height: 12),
                  CalmGo(label: 'Open Reader', onTap: onReader),
                ]),
              ),
              const SizedBox(width: 12),
              const _Well(
                circle: true,
                size: Size.square(88),
                child: V4Film('assets/video/player-box-rings.mp4', slot: 'reader', circle: true),
              ),
            ]),
          ),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) {
              final w = EconomyMirror.instance;
              final signedIn = NwsbFirebase.ready && w.uid != null;
              final nextChest = 40 - (w.coins % 40);
              return V4Card(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    const _Well(circle: true, size: Size.square(64), child: V4Lottie(kRewardsLottie, size: 52)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('NOWSSB REWARDS', style: _eyebrow),
                        const SizedBox(height: 4),
                        if (!signedIn) ...[
                          const Text('Sign in to see your rewards', style: _h),
                          const SizedBox(height: 4),
                          const Text('Your coins and streak stay on your account', style: _sub),
                        ] else ...[
                          Text('${w.coins} coins', style: _h),
                          const SizedBox(height: 4),
                          Text('Streak ${w.streak} · $nextChest coins to the next chest', style: _sub),
                        ],
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: signedIn
                        ? CalmGo(label: 'Open rewards', onTap: () => _push(context, const VaultScreen()))
                        : CalmGo(label: 'Sign in', onTap: () => NwsbSignInPage.open(context)),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _push(context, const ReferenceProgramPage()),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        _Knob(NwsbMarks.reference, size: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Invite a friend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                            SizedBox(height: 2),
                            Text('Share your link. Your friend gets a discount; you earn when they buy for real.', style: _sub),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          ),
        ],
      );
}

// ───────────────────────── trendwd: typography-led ─────────────────────────

class V4Trending extends StatelessWidget {
  const V4Trending({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ContentStore.instance,
        builder: (context, _) {
          final words = ContentStore.instance.library;
          final pick = [
            for (var i = 0; i < 3 && i < words.length; i++) words[(DateTime.now().day + 3 + i * 5) % words.length].word,
          ];
          return V4Card(
            key: const ValueKey('v4-trending'),
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Row(children: [
                Expanded(child: Text('TRENDING NOW', style: _eyebrow)),
                V4Lottie(_waves, size: 44),
              ]),
              const SizedBox(height: 6),
              for (var i = 0; i < pick.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    SizedBox(
                      width: 30,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _accent)),
                    ),
                    Expanded(
                      child: Text(pick[i],
                          style: TextStyle(fontSize: i == 0 ? 26 : 20, fontWeight: FontWeight.w300, color: _ink, letterSpacing: .6)),
                    ),
                  ]),
                ),
              const SizedBox(height: 6),
              const Text('See which words are healing the most people right now', style: _sub),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: CalmGo(label: 'Open the library', onTap: onTap)),
            ]),
          );
        },
      );
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
                    _Knob(r.$1, size: 38),
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

// ───────────────────────── quickrow ─────────────────────────

class V4Quick extends StatelessWidget {
  const V4Quick({super.key, this.onCart, this.onWishlist, this.onOrders});
  final VoidCallback? onCart;
  final VoidCallback? onWishlist;
  final VoidCallback? onOrders;
  @override
  Widget build(BuildContext context) {
    Widget item(String mark, String label, VoidCallback? tap, [String? lottie]) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                _Knob(mark, size: 52, lottie: lottie),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              ]),
            ),
          ),
        );
    return V4Card(
      key: const ValueKey('v4-quick'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EVERYTHING YOU OWN', style: _eyebrow),
              SizedBox(height: 6),
              Text('On one screen', style: _h),
            ]),
          ),
          V4Lottie(kCartLottie, size: 46),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          item(NwsbMarks.cart, 'Cart', onCart, kCartLottie),
          item(NwsbMarks.wishlist, 'Wishlist', onWishlist, kWishlistLottie),
          item(NwsbMarks.order, 'Orders', onOrders),
        ]),
      ]),
    );
  }
}

// ───────────────────────── edition ─────────────────────────

class V4Edition extends StatelessWidget {
  const V4Edition({super.key, required this.onEdition});
  final VoidCallback onEdition;
  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('v4-edition'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V4Card(
            onTap: onEdition,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const AspectRatio(
                aspectRatio: 2.4,
                child: _Well(child: V4Film('assets/video/normal-glass-background.mp4', slot: 'edition', radius: 18)),
              ),
              const SizedBox(height: 14),
              const Text('FREE PLAN · UPGRADE ANY TIME', style: _eyebrow),
              const SizedBox(height: 6),
              const Text('NowssB Edition', style: _h),
              const SizedBox(height: 4),
              const Text('Get your subscription today', style: _sub),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: CalmGo(label: 'Join NowssB', onTap: onEdition)),
            ]),
          ),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) => V4Card(
              onTap: () => _push(context, const PartnerProgramPage()),
              child: Row(children: [
                const _Knob(NwsbMarks.crown),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${EconomyMirror.instance.partnerPoints} partner points',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 2),
                    const Text('Spark · Glow · Radiant. Points come only from real purchases through your links.', style: _sub),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      );
}

// ───────────────────────── ebooks ─────────────────────────

class V4Ebooks extends StatelessWidget {
  const V4Ebooks({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-ebooks'),
        onTap: onTap,
        child: Row(children: [
          const _Well(
            size: Size(96, 120),
            child: V4Film('assets/video/hero-ebooks.mp4', slot: 'ebooks', radius: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Expanded(child: Text('NOWSSB EBOOKS', style: _eyebrow)),
                V4Lottie(_pages, size: 40),
              ]),
              const SizedBox(height: 6),
              const Text('Word science and sound healing, read anywhere.', style: _h),
              const SizedBox(height: 12),
              CalmGo(label: 'Browse eBooks', onTap: onTap),
            ]),
          ),
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

// ───────────────────────── fashsw ─────────────────────────

class V4FashionSwitch extends StatelessWidget {
  const V4FashionSwitch({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => V4Card(
        key: const ValueKey('v4-fashion'),
        onTap: onTap,
        child: Row(children: [
          const _Well(
            circle: true,
            size: Size.square(76),
            child: V4Film('assets/video/practice-orb.mp4', slot: 'fashion', circle: true),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DISCOVER THE EXPERIENCE', style: _eyebrow),
              SizedBox(height: 6),
              Text('Fashion Mode', style: _h),
              SizedBox(height: 2),
              Text('Dark · Cinematic · Editorial', style: _sub),
            ]),
          ),
          CalmGo(label: 'Switch', onTap: onTap),
        ]),
      );
}

// ───────────────────────── footer ─────────────────────────

class V4Footer extends StatelessWidget {
  const V4Footer({super.key, required this.onLink});
  final void Function(String key) onLink;
  static const _links = [
    ('About', 'about'),
    ('Word Science', 'word-science'),
    ('Sound Library', 'sound-library'),
    ('Meaning Store', 'meaning-store'),
    ('Practice', 'practice'),
    ('Profile', 'profile'),
  ];
  @override
  Widget build(BuildContext context) => Padding(
        key: const ValueKey('v4-footer'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const V4Lottie(_meditate, size: 96),
          const SizedBox(height: 6),
          const EditableLabel('home_v4.V4Footer', 'NowssB',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: _ink, letterSpacing: 4)),
          const SizedBox(height: 4),
          const Text('Different words. One root.', textAlign: TextAlign.center, style: _sub),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 12, children: [
            for (final l in _links)
              Container(
                decoration: BoxDecoration(color: _base, borderRadius: BorderRadius.circular(40), boxShadow: _raisedSm),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onLink(l.$2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text(l.$1, style: const TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
}
